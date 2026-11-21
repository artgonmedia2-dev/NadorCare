<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_series', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('patient_profile_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('service_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('address_id')->constrained()->restrictOnDelete();
            $table->string('frequency', 20); // daily | every_n_days | weekly
            $table->unsignedSmallInteger('interval')->default(1);
            $table->jsonb('weekdays')->nullable();
            $table->time('time_of_day');
            $table->date('starts_on');
            $table->date('ends_on')->nullable();
            $table->unsignedSmallInteger('occurrences')->nullable();
            $table->foreignUlid('preferred_professional_id')->nullable()->constrained('professionals')->nullOnDelete();
            $table->string('status', 20)->default('active')->index();
            $table->timestampsTz();
        });

        Schema::create('bookings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('reference', 20)->unique();
            $table->foreignUlid('user_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('patient_profile_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('address_id')->constrained()->restrictOnDelete();
            $table->jsonb('address_snapshot')->nullable();
            $table->foreignUlid('service_id')->constrained()->restrictOnDelete();
            $table->foreignUlid('professional_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUlid('series_id')->nullable()->constrained('booking_series')->nullOnDelete();
            $table->unsignedSmallInteger('series_index')->nullable();
            $table->string('channel', 20)->default('app'); // app | web | phone | whatsapp
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type', 20)->default('scheduled'); // immediate | scheduled
            $table->timestampTz('scheduled_at')->index();
            $table->timestampTz('scheduled_end_at')->nullable();
            $table->string('status', 20)->default('pending')->index();
            $table->unsignedInteger('base_price');
            $table->unsignedInteger('surcharges_total')->default(0);
            $table->unsignedInteger('total_price');
            $table->jsonb('price_snapshot')->nullable();
            $table->string('payment_method', 10)->default('cash'); // cash | card
            $table->text('patient_note')->nullable(); // chiffré
            $table->foreignUlid('prescription_file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->timestampTz('escalated_at')->nullable();
            $table->foreignUlid('cancelled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('cancellation_reason')->nullable();
            $table->unsignedInteger('cancellation_fee')->default(0);
            $table->timestampsTz();
            $table->index(['professional_id', 'status']);
            $table->index(['user_id', 'status']);
        });

        Schema::create('booking_surcharges', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('surcharge_id')->nullable()->constrained()->nullOnDelete();
            $table->string('label');
            $table->unsignedInteger('amount');
        });

        Schema::create('booking_status_history', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->string('from_status', 20)->nullable();
            $table->string('to_status', 20);
            $table->foreignUlid('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_role', 30)->nullable();
            $table->text('reason')->nullable();
            $table->jsonb('meta')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->index(['booking_id', 'created_at']);
        });

        Schema::create('booking_offers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->string('status', 20)->default('pending')->index();
            $table->string('source', 20)->default('auto'); // auto | coordinator
            $table->foreignUlid('offered_by')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('score', 8, 3)->nullable();
            $table->unsignedInteger('distance_m')->nullable();
            $table->timestampTz('sent_at')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->timestampTz('responded_at')->nullable();
            $table->text('decline_reason')->nullable();
            $table->timestampsTz();
            $table->index(['professional_id', 'status']);
        });

        // Une seule offre acceptée par réservation.
        DB::statement("CREATE UNIQUE INDEX booking_offers_one_accepted ON booking_offers (booking_id) WHERE status = 'accepted'");
    }

    public function down(): void
    {
        foreach (['booking_offers', 'booking_status_history', 'booking_surcharges', 'bookings', 'booking_series'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
