<?php

namespace App\Services\Files;

use App\Enums\AccessAction;
use App\Models\File;
use App\Models\User;
use App\Services\Health\AccessLogger;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Encryption\Encrypter;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Stockage des fichiers privés (ordonnances, justificatifs, photos, signatures, reçus).
 *
 * Le contenu est chiffré par l'application (AES-256-GCM) avant d'atteindre le disque ou le
 * stockage objet : l'hébergeur ne voit jamais un fichier en clair. Chaque lecture est journalisée.
 */
class EncryptedFileStore
{
    private const CIPHER = 'aes-256-gcm';

    public function __construct(private readonly AccessLogger $logger) {}

    public function store(string $contents, string $category, string $mime, ?Model $owner = null, ?User $uploader = null): File
    {
        $disk = (string) config('nadorcare.files.disk');
        $path = sprintf('%s/%s/%s.enc', $category, now()->format('Y/m'), Str::ulid());

        Storage::disk($disk)->put($path, $this->encrypter()->encrypt($contents, false));

        return File::create([
            'disk' => $disk,
            'path' => $path,
            'category' => $category,
            'mime' => $mime,
            'size' => strlen($contents),
            'sha256' => hash('sha256', $contents),
            'is_encrypted' => true,
            'key_version' => (int) config('nadorcare.files.key_version'),
            'owner_type' => $owner?->getMorphClass(),
            'owner_id' => $owner?->getKey(),
            'uploaded_by' => $uploader?->getKey(),
        ]);
    }

    /**
     * Déchiffre et renvoie le contenu. L'appelant doit avoir vérifié le droit d'accès au préalable.
     */
    public function read(File $file, ?User $actor = null, ?string $patientProfileId = null, ?string $bookingId = null): string
    {
        $raw = Storage::disk($file->disk)->get($file->path);

        if ($raw === null) {
            throw new RuntimeException("Fichier [{$file->getKey()}] introuvable sur le disque [{$file->disk}].");
        }

        $contents = $file->is_encrypted ? $this->encrypter()->decrypt($raw, false) : $raw;

        if (! hash_equals($file->sha256, hash('sha256', $contents))) {
            throw new RuntimeException("Fichier [{$file->getKey()}] altéré : empreinte différente.");
        }

        $this->logger->record(AccessAction::Download, $file, $patientProfileId, $bookingId, $actor);

        return $contents;
    }

    public function delete(File $file): void
    {
        Storage::disk($file->disk)->delete($file->path);
        $file->delete();
    }

    private function encrypter(): Encrypter
    {
        $key = config('nadorcare.files.key');

        if (is_string($key) && $key !== '') {
            $binary = base64_decode(Str::after($key, 'base64:'), true);
        } else {
            // Repli sur APP_KEY, toléré en développement seulement.
            if (app()->isProduction()) {
                throw new RuntimeException('FILES_ENCRYPTION_KEY est obligatoire en production.');
            }
            $binary = base64_decode(Str::after((string) config('app.key'), 'base64:'), true);
        }

        if ($binary === false || ! Encrypter::supported($binary, self::CIPHER)) {
            throw new RuntimeException('Clé de chiffrement des fichiers invalide : 32 octets encodés en base64 attendus.');
        }

        return new Encrypter($binary, self::CIPHER);
    }
}
