<?php

namespace App\Console\Commands;

use App\Models\BookingOffer;
use Illuminate\Console\Command;

/**
 * Clôt les propositions de mission restées sans réponse après le délai (cahier des charges §5).
 * La réservation redevient proposable à un autre professionnel.
 */
class ExpireOffers extends Command
{
    protected $signature = 'nadorcare:expire-offers';

    protected $description = 'Marque comme expirées les propositions de mission sans réponse';

    public function handle(): int
    {
        $expired = BookingOffer::query()
            ->where('status', BookingOffer::STATUS_PENDING)
            ->where('expires_at', '<=', now())
            ->update(['status' => BookingOffer::STATUS_EXPIRED, 'responded_at' => now()]);

        $this->info("$expired proposition(s) expirée(s).");

        return self::SUCCESS;
    }
}
