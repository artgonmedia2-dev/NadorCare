<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBookingRequest extends FormRequest
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
        $userId = $this->user()->getKey();

        return [
            'service_id' => ['required', 'string'],
            // Profil du patient à soigner, parmi ceux du compte.
            'patient_profile_id' => [
                'required', 'string',
                Rule::exists('patient_profiles', 'id')->where('user_id', $userId)->whereNull('deleted_at'),
            ],
            // Adresse où le soignant se rend, parmi celles du compte.
            'address_id' => [
                'required', 'string',
                Rule::exists('addresses', 'id')->where('user_id', $userId)->whereNull('deleted_at'),
            ],
            // `immediate` (dès que possible) ou `scheduled` (créneau choisi).
            'type' => ['required', Rule::in(['immediate', 'scheduled'])],
            // Début du créneau, parmi ceux renvoyés par `GET /bookings/slots`. Obligatoire si `type` vaut `scheduled`.
            'scheduled_at' => ['required_if:type,scheduled', 'nullable', 'date'],
            // `cash` (espèces à domicile). Le paiement par carte n'est pas encore ouvert.
            'payment_method' => ['required', Rule::in(['cash', 'card'])],
            // Note pour le soignant. Donnée de santé, chiffrée.
            'patient_note' => ['sometimes', 'nullable', 'string', 'max:1000'],
            // Identifiant renvoyé par `POST /files/prescriptions`. Obligatoire si le soin exige une ordonnance.
            'prescription_file_id' => ['sometimes', 'nullable', 'string'],
        ];
    }
}
