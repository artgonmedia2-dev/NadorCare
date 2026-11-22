<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ClientApp;
use App\Http\Controllers\Controller;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

#[Group('Compte', weight: 2)]
class DeviceController extends Controller
{
    /**
     * Enregistrer l'appareil pour les notifications
     *
     * À appeler après la connexion et à chaque renouvellement du jeton de notification.
     * Un jeton déjà connu est rattaché au compte qui vient de se connecter.
     */
    public function store(Request $request): Response
    {
        $input = $request->validate([
            'app' => ['required', Rule::enum(ClientApp::class)],
            'platform' => ['required', Rule::in(['android', 'ios'])],
            // Jeton Firebase Cloud Messaging de l'appareil.
            'fcm_token' => ['required', 'string', 'max:512'],
        ]);

        DB::table('devices')->upsert(
            [[
                'id' => (string) str()->ulid(),
                'user_id' => $request->user()->getKey(),
                'app' => $input['app'],
                'platform' => $input['platform'],
                'fcm_token' => $input['fcm_token'],
                'locale' => app()->getLocale(),
                'last_seen_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]],
            ['fcm_token'],
            ['user_id', 'app', 'platform', 'locale', 'last_seen_at', 'updated_at'],
        );

        return response()->noContent();
    }
}
