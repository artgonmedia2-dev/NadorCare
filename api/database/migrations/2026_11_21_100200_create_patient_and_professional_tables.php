<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_profiles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('relationship', 20)->default('self');
            $table->string('first_name');
            $table->string('last_name');
            $table->date('birth_date')->nullable();
            $table->string('sex', 10)->nullable();
            $table->string('phone', 20)->nullable();
            $table->text('care_notes')->nullable(); // chiffré
            $table->ulid('default_address_id')->nullable();
            $table->timestampsTz();
            $table->softDeletesTz();
        });

        Schema::create('addresses', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('patient_profile_id')->nullable()->constrained()->nullOnDelete();
            $table->string('label');
            $table->string('line');
            $table->string('city')->default('Nador');
            $table->geography('location', subtype: 'point', srid: 4326);
            $table->text('access_notes')->nullable();
            $table->foreignUlid('zone_id')->nullable()->constrained()->nullOnDelete();
            $table->timestampsTz();
            $table->softDeletesTz();
            $table->spatialIndex('location');
        });

        Schema::create('professionals', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignUlid('professional_category_id')->constrained()->restrictOnDelete();
            $table->string('verification_status', 20)->default('draft')->index();
            $table->timestampTz('verified_at')->nullable();
            $table->foreignUlid('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('suspension_reason')->nullable();
            $table->string('license_number')->nullable();
            $table->string('order_number')->nullable();
            $table->boolean('is_online')->default(false)->index();
            $table->geography('last_location', subtype: 'point', srid: 4326)->nullable();
            $table->timestampTz('last_location_at')->nullable();
            $table->decimal('rating_avg', 3, 2)->nullable();
            $table->unsignedInteger('rating_count')->default(0);
            $table->text('payout_details')->nullable(); // chiffré
            $table->timestampsTz();
            $table->softDeletesTz();
            $table->spatialIndex('last_location');
        });

        Schema::create('professional_specialty', function (Blueprint $table) {
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('specialty_id')->constrained()->cascadeOnDelete();
            $table->primary(['professional_id', 'specialty_id']);
        });

        Schema::create('professional_zone', function (Blueprint $table) {
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('zone_id')->constrained()->cascadeOnDelete();
            $table->primary(['professional_id', 'zone_id']);
        });

        Schema::create('availabilities', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('weekday'); // 0 = dimanche
            $table->time('start_time');
            $table->time('end_time');
            $table->timestampsTz();
            $table->index(['professional_id', 'weekday']);
        });

        Schema::create('professional_documents', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->string('type', 40);
            $table->foreignUlid('file_id')->constrained()->restrictOnDelete();
            $table->date('expires_at')->nullable()->index();
            $table->string('status', 20)->default('pending')->index();
            $table->foreignUlid('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('reviewed_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestampsTz();
        });

        Schema::create('document_reviews', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_document_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('reviewer_id')->constrained('users')->restrictOnDelete();
            $table->string('decision', 20);
            $table->text('comment')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        foreach (['document_reviews', 'professional_documents', 'availabilities', 'professional_zone',
            'professional_specialty', 'professionals', 'addresses', 'patient_profiles'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
