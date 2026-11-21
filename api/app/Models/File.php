<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * Fichier privé (ordonnance, justificatif, photo de compte rendu, signature, reçu).
 * Le contenu se lit uniquement par App\Services\Files\EncryptedFileStore.
 */
class File extends Model
{
    use HasUlids;

    protected $fillable = ['disk', 'path', 'category', 'mime', 'size', 'sha256', 'is_encrypted', 'key_version', 'owner_type', 'owner_id', 'uploaded_by'];

    protected $hidden = ['disk', 'path'];

    protected function casts(): array
    {
        return [
            'is_encrypted' => 'boolean',
        ];
    }

    public function owner(): MorphTo
    {
        return $this->morphTo();
    }
}
