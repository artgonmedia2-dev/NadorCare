<?php

namespace App\Http\Resources\Api\V1;

use App\Models\BookingOffer;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;

/**
 * Proposition de mission vue par le professionnel AVANT d'accepter : le soin, le créneau,
 * la zone et la distance. Ni le nom du patient, ni son adresse, ni aucune donnée de santé
 * (cahier des charges §5 : « uniquement les informations nécessaires à la mission en cours »).
 *
 * @mixin BookingOffer
 */
class MissionOfferResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $booking = $this->booking;
        $timezone = (string) config('nadorcare.timezone');
        $start = $booking->scheduled_at->copy()->setTimezone($timezone);

        $zoneId = $booking->address_snapshot['zone_id'] ?? null;
        $zoneName = $zoneId ? DB::table('zones')->where('id', $zoneId)->value('name') : null;

        return [
            'id' => $this->id,
            'status' => $this->status,
            /** Moment après lequel la proposition n'est plus valable. */
            'expires_at' => $this->expires_at?->toIso8601String(),
            'service' => [
                'name' => Translated::pick($booking->service->name),
                'duration_minutes' => $booking->service->duration_minutes,
            ],
            'scheduled_at' => $booking->scheduled_at->toIso8601String(),
            /** Jour et heure du soin à Nador. */
            'scheduled_date' => $start->format('Y-m-d'),
            'scheduled_time' => $start->format('H:i'),
            'zone' => $zoneName ? Translated::pick(json_decode($zoneName, true)) : null,
            /** Distance depuis la dernière position connue du professionnel, en mètres. */
            'distance_meters' => $this->distance_m,
        ];
    }
}
