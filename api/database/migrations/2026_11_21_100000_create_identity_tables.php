<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis');

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('phone', 20)->index();
            $table->string('code_hash', 64);
            $table->string('purpose', 20)->default('login');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->timestampTz('expires_at');
            $table->timestampTz('consumed_at')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });

        Schema::create('devices', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('app', 10); // patient | pro
            $table->string('platform', 10); // ios | android
            $table->string('fcm_token', 512)->unique();
            $table->string('locale', 5)->nullable();
            $table->timestampTz('last_seen_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('consents', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->ulid('patient_profile_id')->nullable()->index();
            $table->string('type', 30); // cgu | privacy | health_data
            $table->string('document_version', 20);
            $table->timestampTz('accepted_at');
            $table->string('ip', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestampTz('revoked_at')->nullable();
            $table->index(['user_id', 'type']);
        });

        Schema::create('data_requests', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20); // access | rectification | deletion
            $table->string('status', 20)->default('open')->index();
            $table->text('details')->nullable();
            $table->foreignUlid('handled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('handled_at')->nullable();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('data_requests');
        Schema::dropIfExists('consents');
        Schema::dropIfExists('devices');
        Schema::dropIfExists('otp_codes');
    }
};
