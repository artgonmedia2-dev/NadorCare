<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Numérotation des réservations (NC-2026-000123) : une séquence garantit des numéros
     * uniques même quand deux réservations sont créées au même instant.
     */
    public function up(): void
    {
        DB::statement('CREATE SEQUENCE IF NOT EXISTS booking_reference_seq START 1');
    }

    public function down(): void
    {
        DB::statement('DROP SEQUENCE IF EXISTS booking_reference_seq');
    }
};
