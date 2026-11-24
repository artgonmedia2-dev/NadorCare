<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Modèle « agence » (règle n° 8 du 2026-11-23) : l'assurance responsabilité civile personnelle
 * d'un soignant devient facultative, en attendant l'avis du juriste ; l'agence enregistre sa
 * propre assurance au back-office.
 */
return new class extends Migration
{
    public function up(): void
    {
        foreach (DB::table('professional_categories')->get(['id', 'required_document_types']) as $category) {
            $types = json_decode((string) $category->required_document_types, true);

            if (! is_array($types) || ! in_array('rc_insurance', $types, true)) {
                continue;
            }

            DB::table('professional_categories')->where('id', $category->id)->update([
                'required_document_types' => json_encode(array_values(array_diff($types, ['rc_insurance']))),
            ]);
        }

        Schema::create('agency_insurances', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('insurer', 120);
            $table->string('policy_number', 80);
            $table->date('expires_on');
            // Attestation, chiffrée comme tout fichier privé.
            $table->foreignUlid('file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
            $table->index('expires_on');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agency_insurances');
    }
};
