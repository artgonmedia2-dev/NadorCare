<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('zones', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->jsonb('name');
            $table->string('slug')->unique();
            $table->geography('boundary', subtype: 'multipolygon', srid: 4326);
            $table->boolean('is_active')->default(false)->index();
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestampsTz();
            $table->spatialIndex('boundary');
        });

        Schema::create('professional_categories', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('code', 50)->unique();
            $table->jsonb('name');
            $table->boolean('has_order')->default(false);
            $table->jsonb('required_document_types')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('specialties', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_category_id')->constrained()->cascadeOnDelete();
            $table->jsonb('name');
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('service_categories', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->jsonb('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->unsignedSmallInteger('sort')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('services', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('service_category_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('professional_category_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('specialty_id')->nullable()->constrained()->nullOnDelete();
            $table->jsonb('name');
            $table->string('slug')->unique();
            $table->jsonb('description')->nullable();
            $table->unsignedSmallInteger('duration_minutes');
            $table->unsignedInteger('base_price'); // centimes de dirham
            $table->boolean('requires_prescription')->default(false);
            $table->boolean('allows_series')->default(false);
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestampsTz();
            $table->softDeletesTz();
        });

        Schema::create('surcharges', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('type', 20); // night | holiday | distance
            $table->jsonb('name');
            $table->string('mode', 10); // percent | fixed
            $table->unsignedInteger('value');
            $table->jsonb('config')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('holidays', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->date('date')->unique();
            $table->jsonb('name');
            $table->timestampsTz();
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->jsonb('value');
            $table->timestampsTz();
        });

        Schema::create('acts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->jsonb('name');
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('service_act', function (Blueprint $table) {
            $table->foreignUlid('service_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('act_id')->constrained()->cascadeOnDelete();
            $table->primary(['service_id', 'act_id']);
        });

        Schema::create('consumables', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->jsonb('name');
            $table->string('unit', 20)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('files', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('disk', 30);
            $table->string('path');
            $table->string('category', 40)->index();
            $table->string('mime', 100);
            $table->unsignedBigInteger('size');
            $table->string('sha256', 64);
            $table->boolean('is_encrypted')->default(true);
            $table->unsignedSmallInteger('key_version')->default(1);
            $table->nullableUlidMorphs('owner');
            $table->foreignUlid('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        foreach (['files', 'consumables', 'service_act', 'acts', 'settings', 'holidays', 'surcharges', 'services',
            'service_categories', 'specialties', 'professional_categories', 'zones'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
