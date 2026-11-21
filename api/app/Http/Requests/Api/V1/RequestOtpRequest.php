<?php

namespace App\Http\Requests\Api\V1;

use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;

class RequestOtpRequest extends FormRequest
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
            // Numéro de téléphone. Format international (+212612345678) ou marocain local (0612345678).
            'phone' => ['required', 'string', 'regex:/^\+[1-9]\d{7,14}$/'],
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
