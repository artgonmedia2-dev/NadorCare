<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Journal des accès aux données de santé (loi 09-08). Insertion seule.
        Schema::create('access_logs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->ulid('actor_id')->nullable()->index();
            $table->string('actor_role', 30)->nullable();
            $table->string('action', 20); // view | download | create | update | export
            $table->string('subject_type', 60);
            $table->ulid('subject_id')->nullable();
            $table->ulid('patient_profile_id')->nullable()->index();
            $table->ulid('booking_id')->nullable()->index();
            $table->string('ip', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('route')->nullable();
            $table->timestampTz('created_at')->useCurrent()->index();
            $table->index(['subject_type', 'subject_id']);
        });

        // Journal des actions sensibles du back-office. Insertion seule.
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->ulid('actor_id')->nullable()->index();
            $table->string('event', 60)->index();
            $table->string('auditable_type', 60)->nullable();
            $table->ulid('auditable_id')->nullable();
            $table->jsonb('old_values')->nullable();
            $table->jsonb('new_values')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestampTz('created_at')->useCurrent()->index();
            $table->index(['auditable_type', 'auditable_id']);
        });

        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->string('key', 80);
            $table->ulid('user_id');
            $table->string('request_hash', 64);
            $table->unsignedSmallInteger('response_status')->nullable();
            $table->jsonb('response')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->primary(['user_id', 'key']);
        });

        DB::unprepared(<<<'SQL'
            CREATE OR REPLACE FUNCTION nadorcare_forbid_change() RETURNS trigger AS $$
            BEGIN
                RAISE EXCEPTION 'Table % en insertion seule : % interdit', TG_TABLE_NAME, TG_OP;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER access_logs_append_only BEFORE UPDATE OR DELETE ON access_logs
                FOR EACH ROW EXECUTE FUNCTION nadorcare_forbid_change();

            CREATE TRIGGER audit_logs_append_only BEFORE UPDATE OR DELETE ON audit_logs
                FOR EACH ROW EXECUTE FUNCTION nadorcare_forbid_change();

            CREATE TRIGGER booking_status_history_append_only BEFORE UPDATE OR DELETE ON booking_status_history
                FOR EACH ROW EXECUTE FUNCTION nadorcare_forbid_change();

            CREATE TRIGGER ledger_entries_append_only BEFORE UPDATE OR DELETE ON ledger_entries
                FOR EACH ROW EXECUTE FUNCTION nadorcare_forbid_change();

            -- Un compte rendu validé est immuable : toute correction passe par un avenant (nouvelle version).
            CREATE OR REPLACE FUNCTION nadorcare_protect_validated_report() RETURNS trigger AS $$
            BEGIN
                IF OLD.validated_at IS NOT NULL THEN
                    RAISE EXCEPTION 'Compte rendu validé : modification interdite, créer un avenant';
                END IF;
                IF TG_OP = 'DELETE' THEN
                    RETURN OLD;
                END IF;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER intervention_reports_immutable BEFORE UPDATE OR DELETE ON intervention_reports
                FOR EACH ROW EXECUTE FUNCTION nadorcare_protect_validated_report();
        SQL);
    }

    public function down(): void
    {
        DB::unprepared(<<<'SQL'
            DROP TRIGGER IF EXISTS intervention_reports_immutable ON intervention_reports;
            DROP TRIGGER IF EXISTS ledger_entries_append_only ON ledger_entries;
            DROP TRIGGER IF EXISTS booking_status_history_append_only ON booking_status_history;
            DROP FUNCTION IF EXISTS nadorcare_protect_validated_report();
        SQL);

        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('access_logs');

        DB::unprepared('DROP FUNCTION IF EXISTS nadorcare_forbid_change()');
    }
};
