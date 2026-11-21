<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\PatientRelationship;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Création (POST) ou modification partielle (PATCH) d'un profil de patient.
 */
class PatientProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('phone')) {
            $this->merge(['phone' => PhoneNumber::normalize($this->input('phone')) ?? $this->input('phone')]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'first_name' => [$required, 'string', 'min:1', 'max:80'],
            'last_name' => [$required, 'string', 'min:1', 'max:80'],
            // Lien avec le titulaire du compte : `self`, `parent`, `child`, `spouse`, `other`.
            'relationship' => [$required, Rule::enum(PatientRelationship::class)],
            'birth_date' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'before_or_equal:today', 'after:1900-01-01'],
            'sex' => ['sometimes', 'nullable', Rule::in(['female', 'male'])],
            // Numéro du patient lui-même, s'il diffère de celui du compte.
            'phone' => ['sometimes', 'nullable', 'string', 'regex:/^\+[1-9]\d{7,14}$/'],
            // Informations utiles au soignant (allergies, mobilité…). Donnée de santé, chiffrée.
            'care_notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return ['phone.regex' => __('api.errors.phone_invalid')];
    }
}
