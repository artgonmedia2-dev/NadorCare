<?php

namespace Tests\Feature\Auth;

use App\Enums\Role;
use App\Models\Consent;
use App\Models\OtpCode;
use App\Models\Professional;
use App\Models\User;
use Tests\TestCase;

class OtpLoginTest extends TestCase
{
    private const PHONE = '+212612345678';

    private function requestOtp(string $phone = self::PHONE, array $headers = [])
    {
        return $this->postJson('/api/v1/auth/otp/request', ['phone' => $phone], $headers);
    }

    private function verify(array $overrides = [], array $headers = [])
    {
        return $this->postJson('/api/v1/auth/otp/verify', array_merge([
            'phone' => self::PHONE,
            'app' => 'patient',
            'device_name' => 'Pixel 8',
        ], $overrides), $headers);
    }

    public function test_requesting_a_code_sends_an_sms_and_stores_only_a_hash(): void
    {
        $this->requestOtp()
            ->assertStatus(202)
            ->assertJsonStructure(['message', 'expires_in', 'resend_in']);

        $code = $this->otpSentTo(self::PHONE);
        $stored = OtpCode::query()->where('phone', self::PHONE)->sole();

        $this->assertNotSame($code, $stored->code_hash);
        $this->assertStringNotContainsString($code, $stored->code_hash);
        $this->assertTrue($stored->expires_at->isFuture());
    }

    public function test_a_local_moroccan_number_is_normalised_to_e164(): void
    {
        $this->requestOtp('06 12 34 56 78')->assertStatus(202);

        $this->assertNotNull($this->sms()->lastMessageTo(self::PHONE));
    }

    public function test_an_invalid_phone_number_is_rejected(): void
    {
        $this->requestOtp('12345')
            ->assertStatus(422)
            ->assertJsonPath('code', 'validation_failed')
            ->assertJsonValidationErrors('phone');

        $this->assertCount(0, $this->sms()->sent);
    }

    public function test_a_second_code_cannot_be_requested_immediately(): void
    {
        $this->requestOtp()->assertStatus(202);

        $this->requestOtp()
            ->assertStatus(429)
            ->assertJsonPath('code', 'otp_too_soon')
            ->assertJsonStructure(['retry_after']);

        $this->assertCount(1, $this->sms()->sent);
    }

    public function test_a_new_code_invalidates_the_previous_one(): void
    {
        $this->requestOtp();
        $first = $this->otpSentTo(self::PHONE);

        $this->travel(61)->seconds();
        $this->requestOtp()->assertStatus(202);
        $second = $this->otpSentTo(self::PHONE);

        if ($first !== $second) {
            $this->verify(['code' => $first, 'accept_terms' => true])->assertStatus(422)->assertJsonPath('code', 'otp_invalid');
        }

        $this->verify(['code' => $second, 'accept_terms' => true])->assertOk();
    }

    public function test_a_new_number_creates_a_patient_account_with_dated_consents(): void
    {
        $this->requestOtp();

        $response = $this->verify(['code' => $this->otpSentTo(self::PHONE), 'accept_terms' => true, 'locale' => 'ar'])
            ->assertOk()
            ->assertJsonPath('is_new_user', true)
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.phone', self::PHONE)
            ->assertJsonPath('user.locale', 'ar')
            ->assertJsonPath('user.roles', [Role::Patient->value]);

        $user = User::query()->where('phone', self::PHONE)->sole();
        $this->assertNotNull($user->phone_verified_at);

        $consents = $user->consents()->get();
        $this->assertEqualsCanonicalizing(
            [Consent::TYPE_TERMS, Consent::TYPE_PRIVACY, Consent::TYPE_HEALTH_DATA],
            $consents->pluck('type')->all(),
        );
        $this->assertTrue($consents->every(fn (Consent $consent) => $consent->accepted_at !== null
            && $consent->document_version === config('nadorcare.legal.documents_version')));

        $this->getJson('/api/v1/me', ['Authorization' => 'Bearer '.$response->json('token')])
            ->assertOk()
            ->assertJsonPath('data.phone', self::PHONE);
    }

    public function test_an_account_is_not_created_without_consent_and_the_code_stays_valid(): void
    {
        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);

        $this->verify(['code' => $code])
            ->assertStatus(422)
            ->assertJsonPath('code', 'consent_required');

        $this->assertDatabaseMissing('users', ['phone' => self::PHONE]);

        $this->verify(['code' => $code, 'accept_terms' => true])->assertOk();
    }

    public function test_an_existing_user_logs_in_without_new_consents(): void
    {
        $user = $this->userWithRole(Role::Patient, ['phone' => self::PHONE]);

        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE)])
            ->assertOk()
            ->assertJsonPath('is_new_user', false)
            ->assertJsonPath('user.id', $user->id);

        $this->assertSame(0, $user->consents()->count());
        $this->assertNotNull($user->fresh()->last_login_at);
    }

    public function test_the_professional_app_opens_only_for_a_member_of_the_team(): void
    {
        // Numéro inconnu : personne ne s'inscrit seul dans l'application professionnel.
        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE), 'app' => 'pro', 'accept_terms' => true])
            ->assertForbidden()
            ->assertJsonPath('code', 'pro_account_unknown');
        $this->assertSame(0, User::query()->where('phone', self::PHONE)->count());

        // Un patient connu n'est pas pour autant un soignant de l'équipe.
        $patient = User::factory()->withRole(Role::Patient)->create(['phone' => self::PHONE]);
        $this->travel(2)->minutes();
        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE), 'app' => 'pro'])
            ->assertForbidden()
            ->assertJsonPath('code', 'pro_account_unknown');

        // Une fois rattaché à l'équipe par l'agence, le même numéro ouvre l'application.
        Professional::factory()->create(['user_id' => $patient->id]);
        $this->travel(2)->minutes();
        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE), 'app' => 'pro'])
            ->assertOk()
            ->assertJsonPath('user.id', $patient->id);
        $this->assertTrue($patient->fresh()->hasRole(Role::Professionnel->value));
    }

    public function test_otp_login_never_grants_a_back_office_role(): void
    {
        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE), 'app' => 'administrateur', 'accept_terms' => true])
            ->assertStatus(422)
            ->assertJsonValidationErrors('app');
    }

    public function test_a_wrong_code_is_rejected_and_counted(): void
    {
        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->verify(['code' => $wrong, 'accept_terms' => true])
            ->assertStatus(422)
            ->assertJsonPath('code', 'otp_invalid');

        $this->assertSame(1, OtpCode::query()->where('phone', self::PHONE)->sole()->attempts);
        $this->assertDatabaseMissing('users', ['phone' => self::PHONE]);
    }

    public function test_the_code_is_locked_after_too_many_wrong_attempts(): void
    {
        config(['nadorcare.otp.max_attempts' => 3]);

        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);
        $wrong = $code === '000000' ? '111111' : '000000';

        foreach (range(1, 3) as $ignored) {
            $this->verify(['code' => $wrong, 'accept_terms' => true])->assertStatus(422);
        }

        // Même le bon code est refusé une fois le plafond atteint.
        $this->verify(['code' => $code, 'accept_terms' => true])
            ->assertStatus(429)
            ->assertJsonPath('code', 'otp_locked');
    }

    public function test_an_expired_code_is_rejected(): void
    {
        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);

        $this->travel(config('nadorcare.otp.ttl_seconds') + 1)->seconds();

        $this->verify(['code' => $code, 'accept_terms' => true])
            ->assertStatus(422)
            ->assertJsonPath('code', 'otp_invalid');
    }

    public function test_a_code_cannot_be_used_twice(): void
    {
        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);

        $this->verify(['code' => $code, 'accept_terms' => true])->assertOk();
        $this->verify(['code' => $code])->assertStatus(422)->assertJsonPath('code', 'otp_invalid');
    }

    public function test_a_code_sent_to_one_number_does_not_work_for_another(): void
    {
        $this->requestOtp();
        $code = $this->otpSentTo(self::PHONE);

        $this->requestOtp('+212698765432');

        $this->verify(['phone' => '+212698765432', 'code' => $code, 'accept_terms' => true])
            ->assertStatus($code === $this->otpSentTo('+212698765432') ? 200 : 422);
    }

    public function test_a_suspended_account_cannot_log_in(): void
    {
        User::factory()->suspended()->create(['phone' => self::PHONE]);

        $this->requestOtp();
        $this->verify(['code' => $this->otpSentTo(self::PHONE)])
            ->assertStatus(403)
            ->assertJsonPath('code', 'account_suspended');
    }

    public function test_the_static_code_is_ignored_in_production(): void
    {
        config(['nadorcare.otp.static_code' => '123456']);
        $this->requestOtp();
        $real = $this->otpSentTo(self::PHONE);

        if ($real === '123456') {
            $this->markTestSkipped('Le code tiré au hasard est identique au code fixe.');
        }

        $this->app->detectEnvironment(fn () => 'production');
        $this->verify(['code' => '123456', 'accept_terms' => true])->assertStatus(422);

        $this->app->detectEnvironment(fn () => 'testing');
        $this->verify(['code' => '123456', 'accept_terms' => true])->assertOk();
    }

    public function test_the_token_expires_and_logout_revokes_it(): void
    {
        $this->requestOtp();
        $token = $this->verify(['code' => $this->otpSentTo(self::PHONE), 'accept_terms' => true])->json('token');
        $headers = ['Authorization' => 'Bearer '.$token];

        $user = User::query()->where('phone', self::PHONE)->sole();
        $this->assertNotNull($user->tokens()->sole()->expires_at);
        $this->assertSame(['app:patient'], $user->tokens()->sole()->abilities);

        $this->postJson('/api/v1/auth/logout', [], $headers)->assertOk();
        $this->assertSame(0, $user->tokens()->count());

        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/me', $headers)->assertStatus(401)->assertJsonPath('code', 'unauthenticated');
    }

    public function test_messages_follow_the_requested_language(): void
    {
        $this->requestOtp(self::PHONE, ['Accept-Language' => 'ar'])
            ->assertStatus(202)
            ->assertHeader('Content-Language', 'ar')
            ->assertJsonPath('message', __('api.otp.sent', locale: 'ar'));

        $this->assertStringContainsString('Nador Care', $this->sms()->lastMessageTo(self::PHONE));
        $this->assertSame(1, preg_match('/\p{Arabic}/u', $this->sms()->lastMessageTo(self::PHONE)));

        $this->verify(['code' => 'abc'], ['Accept-Language' => 'en'])
            ->assertStatus(422)
            ->assertJsonPath('message', __('api.errors.validation_failed', locale: 'en'));
    }
}
