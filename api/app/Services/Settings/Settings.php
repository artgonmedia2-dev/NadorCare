<?php

namespace App\Services\Settings;

use Illuminate\Support\Facades\DB;

/**
 * Paramètres de gestion modifiables sans développement (cahier des charges §4, §5).
 * Les valeurs par défaut ci-dessous s'appliquent tant qu'une ligne n'existe pas en base.
 */
class Settings
{
    public const DAY_START = 'booking.day_start';

    public const DAY_END = 'booking.day_end';

    public const SLOT_MINUTES = 'booking.slot_minutes';

    public const MIN_LEAD_MINUTES = 'booking.min_lead_minutes';

    public const MAX_DAYS_AHEAD = 'booking.max_days_ahead';

    public const FREE_CANCELLATION_MINUTES = 'booking.free_cancellation_minutes';

    public const LATE_CANCELLATION_FEE_PERCENT = 'booking.late_cancellation_fee_percent';

    /**
     * Valeurs de départ. Les horaires et les frais d'annulation sont provisoires :
     * ils attendent la décision du client (points à trancher n° 5 et question 15).
     */
    public const DEFAULTS = [
        self::DAY_START => '08:00',
        self::DAY_END => '20:00',
        self::SLOT_MINUTES => 30,
        self::MIN_LEAD_MINUTES => 60,
        self::MAX_DAYS_AHEAD => 30,
        self::FREE_CANCELLATION_MINUTES => 120,
        self::LATE_CANCELLATION_FEE_PERCENT => 0,
        'booking.escalation_minutes' => 10,
        'offer.response_seconds' => 120,
        'location.retention_days' => 30,
    ];

    public function get(string $key): mixed
    {
        $raw = DB::table('settings')->where('key', $key)->value('value');

        return $raw === null ? (self::DEFAULTS[$key] ?? null) : json_decode($raw, true);
    }

    public function int(string $key): int
    {
        return (int) $this->get($key);
    }

    public function string(string $key): string
    {
        return (string) $this->get($key);
    }

    public function set(string $key, mixed $value): void
    {
        DB::table('settings')->upsert(
            [['key' => $key, 'value' => json_encode($value), 'created_at' => now(), 'updated_at' => now()]],
            ['key'],
            ['value', 'updated_at'],
        );
    }
}
