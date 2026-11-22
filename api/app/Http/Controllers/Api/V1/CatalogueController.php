<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Catalogue\SearchServices;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ServiceCategoryResource;
use App\Http\Resources\Api\V1\ServiceResource;
use App\Models\ProfessionalCategory;
use App\Models\ServiceCategory;
use App\Models\Zone;
use App\Support\Translated;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
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
     * Professions
     *
     * Professions de santé acceptées sur la plateforme, avec les justificatifs exigés pour
     * chacune. Sert à l'inscription d'un professionnel.
     *
     * @unauthenticated
     */
    public function professionalCategories(): JsonResponse
    {
        return response()->json([
            'data' => ProfessionalCategory::query()->where('is_active', true)->orderBy('code')->get()
                ->map(fn (ProfessionalCategory $category) => [
                    'id' => $category->id,
                    'code' => $category->code,
                    'name' => Translated::pick($category->name),
                    /** La profession a un Ordre : son inscription est exigée. */
                    'has_order' => $category->has_order,
                    /** @var list<string> */
                    'required_documents' => array_values($category->required_document_types ?? []),
                ])->all(),
        ]);
    }

    /**
     * Zones desservies
     *
     * Zones où le service est ouvert.
     *
     * @unauthenticated
     */
    public function zones(): JsonResponse
    {
        return response()->json([
            'data' => Zone::query()->where('is_active', true)->orderBy('sort')->get(['id', 'name', 'slug'])
                ->map(fn (Zone $zone) => [
                    'id' => $zone->id,
                    'slug' => $zone->slug,
                    'name' => Translated::pick($zone->name),
                ])->all(),
        ]);
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
