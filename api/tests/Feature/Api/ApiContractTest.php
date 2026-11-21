<?php

namespace Tests\Feature\Api;

use App\Contracts\MapsService;
use App\Contracts\PaymentGateway;
use App\Contracts\PushGateway;
use App\Contracts\SmsGateway;
use App\Contracts\WhatsAppGateway;
use App\Enums\Role;
use App\Services\Payment\FakePaymentGateway;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\TestCase;

class ApiContractTest extends TestCase
{
    public function test_the_api_is_versioned_under_v1(): void
    {
        $this->getJson('/api/v1/health')->assertOk()->assertExactJson(['status' => 'ok', 'version' => 'v1']);
        $this->getJson('/api/health')->assertNotFound();
    }

    public function test_errors_share_one_format_with_a_stable_code(): void
    {
        $this->getJson('/api/v1/me')
            ->assertStatus(401)
            ->assertExactJson(['message' => __('api.errors.unauthenticated'), 'code' => 'unauthenticated']);

        $this->getJson('/api/v1/unknown')
            ->assertStatus(404)
            ->assertExactJson(['message' => __('api.errors.not_found'), 'code' => 'not_found']);

        $this->postJson('/api/v1/auth/otp/request', [])
            ->assertStatus(422)
            ->assertJsonStructure(['message', 'code', 'errors' => ['phone']])
            ->assertJsonPath('code', 'validation_failed');
    }

    public function test_code_requests_are_rate_limited_per_phone_number(): void
    {
        config(['nadorcare.otp.resend_seconds' => 0]);

        foreach (range(1, 5) as $ignored) {
            $this->postJson('/api/v1/auth/otp/request', ['phone' => '+212612345678'])->assertStatus(202);
        }

        $this->postJson('/api/v1/auth/otp/request', ['phone' => '+212612345678'])
            ->assertStatus(429)
            ->assertJsonPath('code', 'too_many_requests')
            ->assertHeader('Retry-After');
    }

    public function test_the_account_holder_updates_name_and_language(): void
    {
        $user = $this->userWithRole(Role::Patient);
        Sanctum::actingAs($user, ['app:patient']);

        $this->patchJson('/api/v1/me', ['name' => 'Fatima Zahra', 'locale' => 'ar'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Fatima Zahra')
            ->assertJsonPath('data.locale', 'ar');

        $this->patchJson('/api/v1/me', ['locale' => 'de'])->assertStatus(422);
        $this->patchJson('/api/v1/me', ['phone' => '+212600000000'])->assertOk();
        $this->assertSame($user->phone, $user->fresh()->phone);
    }

    public function test_external_services_use_fake_implementations_until_contracts_are_signed(): void
    {
        foreach ([SmsGateway::class, WhatsAppGateway::class, PushGateway::class, PaymentGateway::class, MapsService::class] as $contract) {
            $this->assertStringContainsString('Fake', class_basename(app($contract)), $contract);
        }

        $this->assertInstanceOf(FakePaymentGateway::class, app(PaymentGateway::class));
    }

    public function test_an_unknown_driver_fails_with_a_clear_message(): void
    {
        config(['nadorcare.drivers.payment' => 'payzone']);
        $this->app->forgetInstance(PaymentGateway::class);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('payzone');
        app(PaymentGateway::class);
    }

    public function test_the_fake_services_behave_like_real_ones(): void
    {
        $route = app(MapsService::class)->estimateRoute(35.1688, -2.9335, 35.1740, -2.9280);
        $this->assertGreaterThan(500, $route->distanceMeters);
        $this->assertLessThan(2000, $route->distanceMeters);
        $this->assertGreaterThan(0, $route->durationSeconds);

        $gateway = app(PaymentGateway::class);
        $session = $gateway->createSession('01TEST', 15000, 'MAD', 'https://example.test/retour', 'fr');
        $result = $gateway->parseNotification(['event_id' => 'evt-1', 'reference' => $session->providerReference, 'status' => 'paid', 'amount' => 15000]);

        $this->assertTrue($result->isPaid());
        $this->assertSame(15000, $result->amount);
        $this->assertStringContainsString($session->providerReference, $session->redirectUrl);
    }

    public function test_the_openapi_document_describes_the_v1_endpoints(): void
    {
        $document = $this->getJson('/docs/api.json')->assertOk()->json();

        $this->assertSame('Nador Care — API', $document['info']['title']);
        $this->assertArrayHasKey('/auth/otp/request', $document['paths']);
        $this->assertArrayHasKey('/auth/otp/verify', $document['paths']);
        $this->assertArrayHasKey('/me', $document['paths']);
    }
}
