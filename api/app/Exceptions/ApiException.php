<?php

namespace App\Exceptions;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Erreur métier renvoyée par l'API au format unique :
 * { "message": "texte traduit", "code": "identifiant_stable", ...données }
 *
 * `code` est stable et sert aux applications ; `message` est traduit dans la langue de la requête.
 */
class ApiException extends RuntimeException
{
    /**
     * @param  array<string, mixed>  $data
     * @param  array<string, mixed>  $replace
     */
    public function __construct(
        public readonly string $errorCode,
        public readonly int $status = 422,
        public readonly array $data = [],
        public readonly array $replace = [],
    ) {
        parent::__construct($errorCode);
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'message' => __('api.errors.'.$this->errorCode, $this->replace),
            'code' => $this->errorCode,
            ...$this->data,
        ], $this->status);
    }
}
