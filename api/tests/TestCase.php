<?php

namespace Tests;

use App\Contracts\SmsGateway;
use App\Enums\Role;
use App\Models\User;
use App\Services\Sms\FakeSmsGateway;
use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    /**
     * Les rôles et permissions font partie du socle : ils sont présents dans chaque test.
     */
    protected bool $seed = true;

    protected string $seeder = RolesAndPermissionsSeeder::class;

    protected function userWithRole(Role $role, array $attributes = []): User
    {
        return User::factory()->withRole($role)->create($attributes);
    }

    protected function sms(): FakeSmsGateway
    {
        $gateway = app(SmsGateway::class);
        $this->assertInstanceOf(FakeSmsGateway::class, $gateway);

        return $gateway;
    }

    /**
     * Code OTP contenu dans le dernier SMS envoyé à ce numéro.
     */
    protected function otpSentTo(string $phone): string
    {
        $message = $this->sms()->lastMessageTo($phone);
        $this->assertNotNull($message, "Aucun SMS envoyé à $phone.");
        $this->assertSame(1, preg_match('/\d{6}/', $message, $matches));

        return $matches[0];
    }
}
