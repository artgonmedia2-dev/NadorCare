<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Modèle « agence » (décision du 2026-11-23) : c'est l'agence qui fait entrer un soignant dans
 * son équipe. On garde qui a créé sa fiche et quand il a été invité à ouvrir l'application.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('professionals', function (Blueprint $table) {
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('invited_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('professionals', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by');
            $table->dropColumn('invited_at');
        });
    }
};
