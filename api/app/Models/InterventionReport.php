<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Support\Carbon;

/**
 * Compte rendu d'intervention. La version 1 est l'original ; toute correction après
 * validation crée un avenant (version suivante). Une fois validée, une version est
 * immuable : la base elle-même refuse la modification.
 *
 * @property string $id
 * @property string $intervention_id
 * @property int $version
 * @property string|null $parent_report_id
 * @property array<string, mixed>|null $vitals
 * @property string|null $observations
 * @property string|null $signature_file_id
 * @property string|null $signed_by_name
 * @property Carbon|null $signed_at
 * @property string $author_id
 * @property string|null $amendment_reason
 * @property string|null $content_hash
 * @property Carbon|null $validated_at
 * @property Carbon|null $created_at
 * @property-read Intervention $intervention
 */
class InterventionReport extends Model
{
    use HasUlids;

    /** Constantes acceptées, avec leurs bornes plausibles. */
    public const VITALS = [
        'systolic' => [50, 260],      // tension systolique, mmHg
        'diastolic' => [30, 160],     // tension diastolique, mmHg
        'pulse' => [20, 250],         // pouls, battements par minute
        'temperature' => [30, 44],    // température, °C
        'glucose' => [0.1, 9],        // glycémie, g/L
        'spo2' => [50, 100],          // saturation en oxygène, %
    ];

    protected $fillable = [
        'intervention_id', 'version', 'parent_report_id', 'vitals', 'observations', 'signature_file_id',
        'signed_by_name', 'signed_at', 'author_id', 'amendment_reason', 'client_created_at',
    ];

    protected function casts(): array
    {
        return [
            // Données de santé : chiffrées au repos.
            'vitals' => 'encrypted:array',
            'observations' => 'encrypted',
            'signed_at' => 'datetime',
            'client_created_at' => 'datetime',
            'validated_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Intervention, $this>
     */
    public function intervention(): BelongsTo
    {
        return $this->belongsTo(Intervention::class);
    }

    /**
     * Photos jointes au compte rendu.
     *
     * @return MorphMany<File, $this>
     */
    public function photos(): MorphMany
    {
        return $this->morphMany(File::class, 'owner')->where('category', 'report_photo');
    }

    public function isValidated(): bool
    {
        return $this->validated_at !== null;
    }
}
