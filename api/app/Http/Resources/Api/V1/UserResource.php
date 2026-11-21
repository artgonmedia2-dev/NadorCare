<?php

namespace App\Http\Resources\Api\V1;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'phone' => $this->phone,
            'name' => $this->name,
            'locale' => $this->locale,
            'status' => $this->status->value,
            /** @var list<string> */
            'roles' => $this->getRoleNames()->values()->all(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
