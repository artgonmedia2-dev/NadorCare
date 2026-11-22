<?php

namespace App\Console\Commands;

use App\Models\ProfessionalDocument;
use Illuminate\Console\Command;

/**
 * Marque comme périmés les justificatifs approuvés dont la date de validité est passée
 * (cahier des charges §3 : l'expiration de l'assurance est suivie par le système).
 *
 * L'affectation vérifie déjà la date elle-même : cette commande met le statut à jour pour
 * que le dossier et le back-office disent la vérité.
 */
class ExpireDocuments extends Command
{
    protected $signature = 'nadorcare:expire-documents';

    protected $description = 'Marque comme périmés les justificatifs dont la date de validité est passée';

    public function handle(): int
    {
        $expired = ProfessionalDocument::query()
            ->where('status', ProfessionalDocument::STATUS_APPROVED)
            ->whereDate('expires_at', '<', today())
            ->update(['status' => ProfessionalDocument::STATUS_EXPIRED]);

        $this->info("$expired justificatif(s) périmé(s).");

        return self::SUCCESS;
    }
}
