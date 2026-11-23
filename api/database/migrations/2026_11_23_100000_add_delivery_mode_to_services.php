<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mode de réalisation d'un soin : à domicile, ou à distance (téléconsultation).
 * Décision du 2026-11-23 : la téléconsultation entre dans la première version.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('services', function (Blueprint $table) {
            $table->string('delivery_mode', 10)->default('home')->index(); // home | remote
        });
    }

    public function down(): void
    {
        Schema::table('services', function (Blueprint $table) {
            $table->dropColumn('delivery_mode');
        });
    }
};
