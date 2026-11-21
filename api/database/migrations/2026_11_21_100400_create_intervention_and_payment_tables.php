<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('interventions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->unique()->constrained()->restrictOnDelete();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->timestampTz('arrived_at')->nullable();
            $table->geography('arrival_location', subtype: 'point', srid: 4326)->nullable();
            $table->timestampTz('ended_at')->nullable();
            $table->geography('end_location', subtype: 'point', srid: 4326)->nullable();
            $table->string('status', 20)->default('in_progress')->index();
            $table->timestampsTz();
        });

        Schema::create('intervention_acts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('intervention_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('act_id')->nullable()->constrained()->nullOnDelete();
            $table->string('label');
            $table->unsignedSmallInteger('quantity')->default(1);
        });

        Schema::create('intervention_consumables', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('intervention_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('consumable_id')->nullable()->constrained()->nullOnDelete();
            $table->string('label');
            $table->decimal('quantity', 8, 2)->default(1);
        });

        Schema::create('intervention_reports', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('intervention_id')->constrained()->restrictOnDelete();
            $table->unsignedSmallInteger('version')->default(1);
            $table->ulid('parent_report_id')->nullable();
            $table->text('vitals')->nullable(); // chiffré (JSON)
            $table->text('observations')->nullable(); // chiffré
            $table->foreignUlid('signature_file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->string('signed_by_name')->nullable();
            $table->timestampTz('signed_at')->nullable();
            $table->foreignUlid('author_id')->constrained('users')->restrictOnDelete();
            $table->text('amendment_reason')->nullable();
            $table->string('content_hash', 64)->nullable();
            $table->timestampTz('client_created_at')->nullable();
            $table->timestampTz('validated_at')->nullable();
            $table->timestampsTz();
            $table->unique(['intervention_id', 'version']);
        });

        Schema::table('intervention_reports', function (Blueprint $table) {
            $table->foreign('parent_report_id')->references('id')->on('intervention_reports')->restrictOnDelete();
        });

        Schema::create('location_pings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->geography('location', subtype: 'point', srid: 4326);
            $table->unsignedSmallInteger('accuracy_m')->nullable();
            $table->timestampTz('recorded_at')->index();
            $table->index(['booking_id', 'recorded_at']);
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->restrictOnDelete();
            $table->string('method', 10); // cash | card
            $table->string('provider', 20); // cash | fake | payzone
            $table->string('status', 30)->default('pending')->index();
            $table->unsignedInteger('amount');
            $table->string('currency', 3)->default('MAD');
            $table->string('provider_reference')->nullable()->index();
            $table->text('provider_payload')->nullable(); // chiffré (JSON)
            $table->string('idempotency_key', 80)->nullable()->unique();
            $table->foreignUlid('collected_by')->nullable()->constrained('professionals')->nullOnDelete();
            $table->timestampTz('paid_at')->nullable();
            $table->string('receipt_number', 30)->nullable()->unique();
            $table->foreignUlid('receipt_file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->timestampsTz();
        });

        Schema::create('refunds', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('payment_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('amount');
            $table->text('reason')->nullable();
            $table->string('status', 20)->default('pending');
            $table->string('provider_reference')->nullable();
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
        });

        Schema::create('payment_events', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('provider', 20);
            $table->string('event_id');
            $table->text('payload'); // chiffré (JSON)
            $table->timestampTz('processed_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->unique(['provider', 'event_id']);
        });

        Schema::create('payouts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->date('period_start');
            $table->date('period_end');
            $table->integer('gross_amount');
            $table->integer('commission_amount');
            $table->integer('net_amount');
            $table->string('status', 20)->default('draft')->index();
            $table->string('method', 20)->nullable();
            $table->string('reference')->nullable();
            $table->foreignUlid('validated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('paid_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('ledger_entries', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('booking_id')->nullable()->constrained()->restrictOnDelete();
            $table->foreignUlid('payment_id')->nullable()->constrained()->restrictOnDelete();
            $table->foreignUlid('payout_id')->nullable()->constrained()->restrictOnDelete();
            $table->string('type', 30)->index();
            $table->integer('amount'); // signé, en centimes
            $table->timestampTz('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        foreach (['ledger_entries', 'payouts', 'payment_events', 'refunds', 'payments', 'location_pings',
            'intervention_reports', 'intervention_consumables', 'intervention_acts', 'interventions'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
