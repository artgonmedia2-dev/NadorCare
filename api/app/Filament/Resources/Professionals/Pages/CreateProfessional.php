<?php

namespace App\Filament\Resources\Professionals\Pages;

use App\Actions\Professionals\ManageTeam;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\ProfessionalResource;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Exceptions\Halt;
use Illuminate\Database\Eloquent\Model;

/**
 * Ajout d'un soignant à l'équipe de l'agence. La règle métier est dans `ManageTeam`.
 */
class CreateProfessional extends CreateRecord
{
    protected static string $resource = ProfessionalResource::class;

    public function getTitle(): string
    {
        return __('admin.professionals.create');
    }

    protected function handleRecordCreation(array $data): Model
    {
        try {
            return app(ManageTeam::class)->create(auth()->user(), $data);
        } catch (ApiException $exception) {
            Notification::make()->title(__('api.errors.'.$exception->errorCode))->danger()->send();

            // Arrête l'enregistrement sans fermer le formulaire : la saisie reste à l'écran.
            throw new Halt;
        }
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return __('admin.professionals.created');
    }

    protected function getRedirectUrl(): string
    {
        return ProfessionalResource::getUrl('view', ['record' => $this->getRecord()]);
    }
}
