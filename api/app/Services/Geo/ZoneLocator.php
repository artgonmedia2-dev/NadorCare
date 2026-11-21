<?php

namespace App\Services\Geo;

use App\Models\Zone;
use Illuminate\Support\Facades\DB;

/**
 * Trouve la zone qui contient un point. Une zone active passe avant une zone inactive
 * quand deux polygones se chevauchent.
 */
class ZoneLocator
{
    public function locate(float $latitude, float $longitude): ?Zone
    {
        $id = DB::table('zones')
            ->whereRaw('ST_Covers(boundary, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)', [$longitude, $latitude])
            ->orderByDesc('is_active')
            ->orderBy('sort')
            ->value('id');

        return $id ? Zone::query()->select(['id', 'name', 'slug', 'is_active', 'sort'])->find($id) : null;
    }
}
