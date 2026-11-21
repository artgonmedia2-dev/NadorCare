<?php

namespace App\Http\Resources\Api\V1;

use App\Models\ServiceCategory;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ServiceCategory
 */
class ServiceCategoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'name' => Translated::pick($this->name),
            'icon' => $this->icon,
            /** Nombre de services proposés dans la catégorie. */
            'services_count' => (int) ($this->services_count ?? 0),
        ];
    }
}
