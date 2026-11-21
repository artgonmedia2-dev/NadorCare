<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('phone', 20)->unique(); // E.164
            $table->timestampTz('phone_verified_at')->nullable();
            $table->string('name')->nullable();
            $table->string('email')->nullable()->unique();
            $table->string('locale', 5)->default('fr');
            $table->string('status', 20)->default('active')->index();
            // Mot de passe et double facteur : comptes du back-office uniquement.
            $table->string('password')->nullable();
            $table->text('app_authentication_secret')->nullable();
            $table->text('app_authentication_recovery_codes')->nullable();
            $table->rememberToken();
            $table->timestampTz('last_login_at')->nullable();
            $table->timestampsTz();
            $table->softDeletesTz();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestampTz('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignUlid('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
