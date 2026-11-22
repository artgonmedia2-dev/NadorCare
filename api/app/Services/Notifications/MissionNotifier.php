<?php

namespace App\Services\Notifications;

use App\Contracts\PushGateway;
use App\Models\Professional;
use Illuminate\Support\Facades\DB;

/**
 * Prévient un professionnel sur son téléphone. Le message ne contient aucune donnée
 * du patient : il invite seulement à ouvrir l'application.
 */
class MissionNotifier
{
    public function __construct(private readonly PushGateway $push) {}

    public function missionOffered(Professional $professional, string $offerId): void
    {
        $this->send($professional, 'offer', ['type' => 'mission_offer', 'offer_id' => $offerId]);
    }

    public function missionAssigned(Professional $professional, string $bookingId): void
    {
        $this->send($professional, 'assigned', ['type' => 'mission_assigned', 'booking_id' => $bookingId]);
    }

    public function missionWithdrawn(Professional $professional, string $bookingId): void
    {
        $this->send($professional, 'withdrawn', ['type' => 'mission_withdrawn', 'booking_id' => $bookingId]);
    }

    /**
     * @param  array<string, string>  $data
     */
    private function send(Professional $professional, string $message, array $data): void
    {
        $tokens = DB::table('devices')
            ->where('user_id', $professional->user_id)
            ->where('app', 'pro')
            ->pluck('fcm_token')
            ->all();

        if ($tokens === []) {
            return;
        }

        // Dans la langue du compte, pas dans celle de la personne qui déclenche l'envoi.
        $locale = (string) DB::table('users')->where('id', $professional->user_id)->value('locale');

        $this->push->send(
            $tokens,
            __("api.push.$message.title", locale: $locale),
            __("api.push.$message.body", locale: $locale),
            $data,
        );
    }
}
