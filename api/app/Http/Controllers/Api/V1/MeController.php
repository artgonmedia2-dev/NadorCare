<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateMeRequest;
use App\Http\Resources\Api\V1\UserResource;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\Request;

#[Group('Compte', weight: 2)]
class MeController extends Controller
{
    /**
     * Mon compte
     */
    public function show(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    /**
     * Modifier mon nom ou ma langue
     */
    public function update(UpdateMeRequest $request): UserResource
    {
        $request->user()->update($request->validated());

        return new UserResource($request->user());
    }
}
