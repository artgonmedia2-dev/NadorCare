<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Catalogue\SearchServices;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ServiceCategoryResource;
use App\Http\Resources\Api\V1\ServiceResource;
use App\Models\ServiceCategory;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Le catalogue se consulte sans compte : l'application le montre avant la connexion
 * et le site public s'en sert pour ses pages de services.
 */
#[Group('Catalogue', weight: 5)]
class CatalogueController extends Controller
{
    /**
     * Catégories de services
     *
     * Seules les catégories actives qui contiennent au moins un service actif sont renvoyées.
     *
     * @unauthenticated
     */
    public function categories(): AnonymousResourceCollection
    {
        $active = fn (Builder $services) => $services->where('is_active', true);

        return ServiceCategoryResource::collection(
            ServiceCategory::query()
                ->where('is_active', true)
                ->whereHas('services', $active)
                ->withCount(['services' => $active])
                ->orderBy('sort')
                ->orderBy('id')
                ->get()
        );
    }

    /**
     * Services
     *
     * Les textes suivent l'en-tête `Accept-Language`. Le prix est indicatif.
     *
     * @unauthenticated
     */
    public function services(Request $request, SearchServices $search): AnonymousResourceCollection
    {
        $filters = $request->validate([
            // Identifiant lisible (`slug`) d'une catégorie.
            'category' => ['sometimes', 'string', 'max:120'],
            // Recherche dans le nom et la description, sans tenir compte des accents. Deux caractères au moins.
            'q' => ['sometimes', 'nullable', 'string', 'max:80'],
        ]);

        return ServiceResource::collection($search->handle($filters['category'] ?? null, $filters['q'] ?? null));
    }

    /**
     * Détail d'un service
     *
     * @unauthenticated
     */
    public function service(string $slug, SearchServices $search): ServiceResource
    {
        return new ServiceResource($search->findBySlug($slug));
    }
}
