<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Patients\DeleteAddress;
use App\Actions\Patients\SaveAddress;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AddressRequest;
use App\Http\Resources\Api\V1\AddressResource;
use App\Models\Address;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

#[Group('Adresses', weight: 4)]
class AddressController extends Controller
{
    /**
     * Mes adresses
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        return AddressResource::collection(
            $request->user()->addresses()->with('zone:id,name,is_active')->orderBy('created_at')->get()
        );
    }

    /**
     * Ajouter une adresse
     *
     * L'adresse est rattachée à la zone qui contient ses coordonnées. `is_covered` indique
     * si le service y est ouvert ; une adresse hors zone est tout de même enregistrée.
     */
    public function store(AddressRequest $request, SaveAddress $save): JsonResponse
    {
        $address = $save->create($request->user(), $request->validated());

        return (new AddressResource($address->load('zone:id,name,is_active')))->response()->setStatusCode(201);
    }

    /**
     * Modifier une adresse
     */
    public function update(AddressRequest $request, string $address, SaveAddress $save): AddressResource
    {
        $saved = $save->update($this->find($request, $address), $request->validated());

        return new AddressResource($saved->load('zone:id,name,is_active'));
    }

    /**
     * Retirer une adresse
     *
     * Refusé (`address_in_use`) tant qu'un soin est prévu ou en cours à cette adresse.
     */
    public function destroy(Request $request, string $address, DeleteAddress $delete): Response
    {
        $delete->handle($this->find($request, $address));

        return response()->noContent();
    }

    private function find(Request $request, string $id): Address
    {
        return $request->user()->addresses()->findOrFail($id);
    }
}
