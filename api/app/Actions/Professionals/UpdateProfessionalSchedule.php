<?php

namespace App\Actions\Professionals;

use App\Exceptions\ApiException;
use App\Models\Professional;
use Illuminate\Support\Facades\DB;

/**
 * Disponibilités d'un professionnel (cahier des charges §5) : zones couvertes et agenda
 * hebdomadaire.
 *
 * Modèle « agence » : les zones et l'agenda ne se règlent plus depuis l'application. Passer
 * par `ManagePlanning`, qui sait qui décide et trace la décision.
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
        $this->assertValidSlots($slots);

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
     * Une plage finit après son début, sur un jour de 0 (dimanche) à 6 (samedi), et deux plages
     * d'un même jour ne se chevauchent pas.
     *
     * @param  list<array{weekday: int, start_time: string, end_time: string}>  $slots
     */
    public function assertValidSlots(array $slots): void
    {
        $byDay = [];
        foreach ($slots as $slot) {
            $times = [$slot['start_time'], $slot['end_time']];
            if ($slot['weekday'] < 0 || $slot['weekday'] > 6
                || preg_grep('/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/', $times) !== $times
                || $slot['start_time'] >= $slot['end_time']) {
                throw new ApiException('availability_invalid');
            }
            foreach ($byDay[$slot['weekday']] ?? [] as $other) {
                if ($slot['start_time'] < $other['end_time'] && $other['start_time'] < $slot['end_time']) {
                    throw new ApiException('availability_invalid');
                }
            }
            $byDay[$slot['weekday']][] = $slot;
        }
    }
}
