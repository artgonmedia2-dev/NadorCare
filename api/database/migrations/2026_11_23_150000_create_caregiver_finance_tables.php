<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Suivi financier du modèle « agence » (règles n° 6 et 10 du 2026-11-23) : plus de commission
 * ni de reversement automatique. Le comptable pointe les espèces que chaque soignant remet à
 * l'agence, et saisit la rémunération due pour chaque mois. Les tables `payouts` et
 * `ledger_entries` de l'ancien modèle restent en base, inutilisées.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Espèces remises à l'agence par un soignant.
        Schema::create('cash_handovers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('amount'); // centimes de dirham
            $table->date('handed_on'); // jour de la remise, à Nador
            $table->string('note', 500)->nullable();
            $table->foreignUlid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
            $table->index(['professional_id', 'handed_on']);
        });

        // Rémunération due à un soignant pour un mois, saisie à la main par le comptable.
        Schema::create('caregiver_remunerations', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->date('period'); // premier jour du mois
            $table->unsignedInteger('amount'); // centimes de dirham
            $table->string('note', 500)->nullable();
            $table->foreignUlid('set_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
            $table->unique(['professional_id', 'period']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('caregiver_remunerations');
        Schema::dropIfExists('cash_handovers');
    }
};
