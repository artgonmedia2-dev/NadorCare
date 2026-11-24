<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Modèle « agence » : le coordinateur affecte, le soignant confirme ou signale son
 * indisponibilité avec un motif. Les propositions à minuterie disparaissent ; la table
 * `booking_offers` est gardée pour l'historique, plus rien n'y écrit.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            // Heure limite de la confirmation par le soignant affecté.
            $table->timestampTz('assignment_confirm_by')->nullable();
            $table->timestampTz('assignment_confirmed_at')->nullable();
            // Dernière indisponibilité signalée, tant que la demande n'est pas réaffectée.
            $table->timestampTz('assignment_declined_at')->nullable();
            $table->string('assignment_decline_reason', 20)->nullable();
            // Précision du soignant (peut évoquer sa santé) : chiffrée.
            $table->text('assignment_decline_note')->nullable();
            $table->foreignUlid('assignment_declined_by')->nullable()->constrained('professionals')->nullOnDelete();
        });

        // Les missions déjà affectées sont considérées comme confirmées.
        DB::table('bookings')
            ->whereNotNull('professional_id')
            ->update(['assignment_confirmed_at' => DB::raw('updated_at')]);

        DB::table('settings')->where('key', 'offer.response_seconds')->delete();

        foreach (['assignment.confirm_minutes_same_day' => 15, 'assignment.confirm_minutes_later' => 120] as $key => $value) {
            DB::table('settings')->insertOrIgnore([
                'key' => $key, 'value' => json_encode($value), 'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        DB::table('settings')->whereIn('key', ['assignment.confirm_minutes_same_day', 'assignment.confirm_minutes_later'])->delete();

        Schema::table('bookings', function (Blueprint $table) {
            $table->dropConstrainedForeignId('assignment_declined_by');
            $table->dropColumn([
                'assignment_confirm_by', 'assignment_confirmed_at', 'assignment_declined_at',
                'assignment_decline_reason', 'assignment_decline_note',
            ]);
        });
    }
};
