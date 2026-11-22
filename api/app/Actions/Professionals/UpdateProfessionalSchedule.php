<?php

namespace App\Actions\Professionals;

use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Models\Professional;
use Illuminate\Support\Facades\DB;

/**
 * Disponibilités d'un professionnel (cahier des charges §5) : zones couvertes, agenda
 * hebdomadaire, et bascule en ligne / hors ligne.
 */
class UpdateProfessionalSchedule
{
    /**
     * Remplace les zones couvertes. Seules les zones ouvertes au service sont acceptées.
     *
     * @param  list<string>  $zoneIds
     */
    public function setZones(Professional $professional, array $zoneIds): void
    {
        $active = DB::table('zones')->where('is_active', true)->whereIn('id', $zoneIds)->pluck('id')->all();

        if (count($active) !== count(array_unique($zoneIds))) {
            throw new ApiException('zone_unavailable');
        }

        $professional->zones()->sync($active);
    }

    /**
     * Remplace l'agenda hebdomadaire. Les heures sont celles de Nador.
     *
     * @param  list<array{weekday: int, start_time: string, end_time: string}>  $slots
     */
    public function setAvailabilities(Professional $professional, array $slots): void
    {
        // Deux plages d'un même jour ne se chevauchent pas.
        $byDay = [];
        foreach ($slots as $slot) {
            if ($slot['start_time'] >= $slot['end_time']) {
                throw new ApiException('availability_invalid');
            }
            foreach ($byDay[$slot['weekday']] ?? [] as $other) {
                if ($slot['start_time'] < $other['end_time'] && $other['start_time'] < $slot['end_time']) {
                    throw new ApiException('availability_invalid');
                }
            }
            $byDay[$slot['weekday']][] = $slot;
        }

        DB::transaction(function () use ($professional, $slots) {
            DB::table('availabilities')->where('professional_id', $professional->id)->delete();

            foreach ($slots as $slot) {
                DB::table('availabilities')->insert([
                    'id' => (string) str()->ulid(),
                    'professional_id' => $professional->id,
                    'weekday' => $slot['weekday'],
                    'start_time' => $slot['start_time'],
                    'end_time' => $slot['end_time'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });
    }

    /**
     * Seul un professionnel vérifié peut se mettre en ligne.
     */
    public function setOnline(Professional $professional, bool $online): Professional
    {
        if ($online && $professional->verification_status !== VerificationStatus::Verified) {
            throw new ApiException('professional_not_verified', 409);
        }

        $professional->forceFill(['is_online' => $online])->save();

        return $professional;
    }
}
