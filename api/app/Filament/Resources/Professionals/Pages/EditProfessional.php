<?php

namespace App\Filament\Resources\Professionals\Pages;

use App\Actions\Professionals\ManageTeam;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\Professional;
use App\Models\User;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Exceptions\Halt;
use Illuminate\Database\Eloquent\Model;

/**
 * Modification de la fiche d'un soignant de l'équipe. La règle métier est dans `ManageTeam`.
 */
class EditProfessional extends EditRecord
{
    protected static string $resource = ProfessionalResource::class;

    public function getTitle(): string
    {
        return __('admin.professionals.edit');
    }

    /**
     * Le nom et le téléphone appartiennent au compte du soignant : ils sont relus en base.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeFill(array $data): array
    {
        $user = User::query()->find($data['user_id'] ?? null);

        return [...$data, 'name' => $user?->name, 'phone' => $user?->phone];
    }

    protected function handleRecordUpdate(Model $record, array $data): Model
    {
        /** @var Professional $record */
        try {
            return app(ManageTeam::class)->update($record, auth()->user(), $data);
        } catch (ApiException $exception) {
            Notification::make()->title(__('api.errors.'.$exception->errorCode))->danger()->send();

            // Arrête l'enregistrement sans fermer le formulaire : la saisie reste à l'écran.
            throw new Halt;
        }
    }

    protected function getSavedNotificationTitle(): ?string
    {
        return __('admin.professionals.updated');
    }

    protected function getRedirectUrl(): string
    {
        return ProfessionalResource::getUrl('view', ['record' => $this->getRecord()]);
    }
}
