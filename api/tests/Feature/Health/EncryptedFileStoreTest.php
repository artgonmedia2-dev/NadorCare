<?php

namespace Tests\Feature\Health;

use App\Enums\AccessAction;
use App\Models\AccessLog;
use App\Models\PatientProfile;
use App\Services\Files\EncryptedFileStore;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Tests\TestCase;

class EncryptedFileStoreTest extends TestCase
{
    private const CONTENT = 'ORDONNANCE — Amoxicilline 1 g, 2 fois par jour pendant 7 jours';

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    public function test_a_file_is_stored_encrypted_and_read_back_identical(): void
    {
        $profile = PatientProfile::factory()->create();
        $store = app(EncryptedFileStore::class);

        $file = $store->store(self::CONTENT, 'prescription', 'image/jpeg', $profile, $profile->user);

        $onDisk = Storage::disk('local')->get($file->path);
        $this->assertStringNotContainsString('Amoxicilline', $onDisk);
        $this->assertStringNotContainsString('ORDONNANCE', $onDisk);
        $this->assertTrue($file->is_encrypted);
        $this->assertSame(strlen(self::CONTENT), $file->size);

        $this->assertSame(self::CONTENT, $store->read($file, $profile->user, $profile->id));
    }

    public function test_every_read_is_written_to_the_access_log(): void
    {
        $profile = PatientProfile::factory()->create();
        $store = app(EncryptedFileStore::class);
        $file = $store->store(self::CONTENT, 'prescription', 'image/jpeg', $profile, $profile->user);

        $store->read($file, $profile->user, $profile->id);

        $log = AccessLog::query()->sole();
        $this->assertSame(AccessAction::Download, $log->action);
        $this->assertSame($file->id, $log->subject_id);
        $this->assertSame($profile->id, $log->patient_profile_id);
    }

    public function test_a_tampered_file_is_refused(): void
    {
        $store = app(EncryptedFileStore::class);
        $file = $store->store(self::CONTENT, 'prescription', 'image/jpeg');
        $other = $store->store('autre contenu', 'prescription', 'image/jpeg');

        // On remplace le fichier chiffré par un autre, valide mais différent.
        Storage::disk('local')->put($file->path, Storage::disk('local')->get($other->path));

        $this->expectException(RuntimeException::class);
        $store->read($file);
    }

    public function test_a_dedicated_key_is_mandatory_in_production(): void
    {
        config(['nadorcare.files.key' => null]);
        $this->app->detectEnvironment(fn () => 'production');

        $this->expectException(RuntimeException::class);
        app(EncryptedFileStore::class)->store(self::CONTENT, 'prescription', 'image/jpeg');
    }
}
