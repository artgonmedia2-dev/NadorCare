<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class GenerateFilesKey extends Command
{
    protected $signature = 'nadorcare:files-key';

    protected $description = 'Génère une clé de chiffrement pour les fichiers de santé (FILES_ENCRYPTION_KEY)';

    public function handle(): int
    {
        $this->line('FILES_ENCRYPTION_KEY=base64:'.base64_encode(random_bytes(32)));
        $this->warn('À copier dans .env et à sauvegarder hors du serveur : sans cette clé, les fichiers stockés sont illisibles.');

        return self::SUCCESS;
    }
}
