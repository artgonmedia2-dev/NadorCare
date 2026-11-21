<?php

namespace App\Console\Commands;

use App\Enums\Role;
use App\Enums\UserStatus;
use App\Models\User;
use App\Support\PhoneNumber;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

use function Laravel\Prompts\password;
use function Laravel\Prompts\select;
use function Laravel\Prompts\text;

/**
 * Crée un compte du back-office. Le mot de passe est saisi au clavier : il n'apparaît
 * ni dans le code, ni dans .env, ni dans l'historique du terminal.
 */
class CreateStaffUser extends Command
{
    protected $signature = 'nadorcare:create-staff';

    protected $description = 'Crée un compte coordinateur, administrateur ou comptable pour le back-office';

    public function handle(): int
    {
        $role = select('Rôle', Role::staffValues(), default: Role::Administrateur->value);
        $name = text('Nom complet', required: true);
        $email = text('Adresse e-mail (identifiant de connexion)', required: true);
        $phone = PhoneNumber::normalize(text('Téléphone', placeholder: '0612345678', required: true));
        $password = password('Mot de passe (12 caractères au moins)', required: true);

        $validator = Validator::make(compact('name', 'email', 'phone', 'password'), [
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['required', 'string', 'unique:users,phone'],
            'password' => ['required', Password::min(12)->mixedCase()->numbers()],
        ]);

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }

        $user = new User([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'password' => $password,
            'status' => UserStatus::Active,
        ]);
        $user->phone_verified_at = now();
        $user->save();
        $user->assignRole($role);

        $this->info("Compte $role créé pour $email. Le double facteur sera demandé à la première connexion sur /admin.");

        return self::SUCCESS;
    }
}
