<?php

namespace App\Actions\Catalogue;

use App\Models\Service;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

/**
 * Services proposés au public : actifs, dans une catégorie active.
 * La recherche porte sur le nom et la description dans les trois langues, sans tenir compte
 * des accents ni de la casse : une personne peut chercher en français dans l'application en arabe.
 */
class SearchServices
{
    private const LOCALES = ['fr', 'ar', 'en'];

    /**
     * @return Collection<int, Service>
     */
    public function handle(?string $categorySlug = null, ?string $term = null): Collection
    {
        return $this->visible()
            ->when($categorySlug, fn (Builder $query) => $query->whereHas('category', fn (Builder $category) => $category->where('slug', $categorySlug)))
            ->when($this->normalise($term), fn (Builder $query, string $needle) => $query->where(function (Builder $match) use ($needle) {
                foreach (self::LOCALES as $locale) {
                    $match->orWhereRaw("unaccent(name->>'$locale') ILIKE unaccent(?)", [$needle])
                        ->orWhereRaw("unaccent(description->>'$locale') ILIKE unaccent(?)", [$needle]);
                }
            }))
            ->orderBy('sort')
            ->orderBy('id')
            ->get();
    }

    public function findBySlug(string $slug): Service
    {
        return $this->visible()->where('slug', $slug)->firstOrFail();
    }

    /**
     * @return Builder<Service>
     */
    private function visible(): Builder
    {
        return Service::query()
            ->with(['category:id,name,slug', 'professionalCategory:id,name,code'])
            ->where('is_active', true)
            ->whereHas('category', fn (Builder $category) => $category->where('is_active', true));
    }

    /**
     * Motif ILIKE : les caractères spéciaux saisis par l'utilisateur sont neutralisés.
     */
    private function normalise(?string $term): ?string
    {
        $term = trim((string) $term);

        if (mb_strlen($term) < 2) {
            return null;
        }

        return '%'.addcslashes($term, '%_\\').'%';
    }
}
