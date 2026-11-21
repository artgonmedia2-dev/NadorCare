<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Création (POST) ou modification partielle (PATCH) d'une adresse.
 */
class AddressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';
        $coordinates = $this->isMethod('POST') ? ['required'] : [];

        return [
            // Nom donné à l'adresse : « Maison », « Chez ma mère »…
            'label' => [$required, 'string', 'min:1', 'max:60'],
            'line' => [$required, 'string', 'min:3', 'max:255'],
            'city' => ['sometimes', 'string', 'max:80'],
            // Coordonnées GPS. Toujours fournies ensemble.
            // Pas de `sometimes` ici : il ferait sauter la règle « ensemble » en modification.
            'latitude' => [...$coordinates, 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => [...$coordinates, 'required_with:latitude', 'numeric', 'between:-180,180'],
            // Repères d'accès pour le soignant : étage, code, couleur de la porte…
            'access_notes' => ['sometimes', 'nullable', 'string', 'max:500'],
            // Profil du patient qui habite à cette adresse, parmi ceux du compte.
            'patient_profile_id' => [
                'sometimes', 'nullable', 'string',
                Rule::exists('patient_profiles', 'id')->where('user_id', $this->user()->getKey())->whereNull('deleted_at'),
            ],
        ];
    }
}
