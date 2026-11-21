<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\ClientApp;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class VerifyOtpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['phone' => PhoneNumber::normalize($this->input('phone')) ?? $this->input('phone')]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'phone' => ['required', 'string', 'regex:/^\+[1-9]\d{7,14}$/'],
            // Code reçu par SMS.
            'code' => ['required', 'string', 'digits_between:4,8'],
            // Application qui se connecte : `patient` ou `pro`.
            'app' => ['required', Rule::enum(ClientApp::class)],
            // Nom de l'appareil, affiché dans la liste des sessions.
            'device_name' => ['required', 'string', 'max:100'],
            // Obligatoire à `true` pour créer un compte : acceptation des conditions générales,
            // de la politique de confidentialité et du traitement des données de santé.
            'accept_terms' => ['sometimes', 'boolean'],
            'locale' => ['sometimes', Rule::in(config('nadorcare.locales'))],
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
