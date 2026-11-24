<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Modèle « agence » : le planning est tenu par la coordination. Un soignant propose une
 * nouvelle semaine type ou signale une indisponibilité datée ; rien ne change tant que la
 * coordination n'a pas accepté.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('schedule_requests', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('professional_id')->constrained()->cascadeOnDelete();
            $table->string('kind', 20); // weekly, unavailability
            $table->string('status', 20)->default('pending'); // pending, accepted, refused, cancelled
            // Indisponibilité : journées entières, bornes comprises (dates de Nador).
            $table->date('starts_on')->nullable();
            $table->date('ends_on')->nullable();
            // Semaine type proposée : [{weekday, start_time, end_time}].
            $table->jsonb('slots')->nullable();
            // Précision du soignant (peut évoquer sa santé) : chiffrée.
            $table->text('note')->nullable();
            $table->foreignUlid('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('decided_at')->nullable();
            $table->string('decision_note', 500)->nullable();
            $table->timestampsTz();
            $table->index(['professional_id', 'status']);
            $table->index(['kind', 'status', 'starts_on', 'ends_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('schedule_requests');
    }
};
