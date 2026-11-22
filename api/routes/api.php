<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\CatalogueController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\PatientProfileController;
use App\Http\Controllers\Api\V1\PrescriptionController;
use App\Http\Controllers\Api\V1\Pro\MissionController;
use Illuminate\Support\Facades\Route;

/*
| API Nador Care — version 1. Toutes les routes sont préfixées par /api/v1.
| Une version ultérieure s'ajoutera dans un groupe /v2 sans toucher à celui-ci.
*/

Route::prefix('v1')->name('api.v1.')->group(function () {
    Route::get('/health', fn () => response()->json(['status' => 'ok', 'version' => 'v1']))->name('health');

    Route::prefix('catalogue')->name('catalogue.')->group(function () {
        Route::get('/categories', [CatalogueController::class, 'categories'])->name('categories');
        Route::get('/services', [CatalogueController::class, 'services'])->name('services');
        Route::get('/services/{slug}', [CatalogueController::class, 'service'])->name('service');
    });

    Route::prefix('auth')->name('auth.')->group(function () {
        Route::post('/otp/request', [AuthController::class, 'requestOtp'])->middleware('throttle:otp-request')->name('otp.request');
        Route::post('/otp/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:otp-verify')->name('otp.verify');
        Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum')->name('logout');
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [MeController::class, 'show'])->name('me.show');
        Route::patch('/me', [MeController::class, 'update'])->name('me.update');
        Route::post('/me/devices', [DeviceController::class, 'store'])->name('me.devices.store');
    });

    // Réservé aux jetons de l'application professionnel.
    Route::middleware(['auth:sanctum', 'ability:app:pro'])->prefix('pro')->name('pro.')->group(function () {
        Route::get('/offers', [MissionController::class, 'offers'])->name('offers.index');
        Route::post('/offers/{offer}/accept', [MissionController::class, 'accept'])->name('offers.accept');
        Route::post('/offers/{offer}/decline', [MissionController::class, 'decline'])->name('offers.decline');
        Route::get('/missions', [MissionController::class, 'index'])->name('missions.index');
        Route::get('/missions/{mission}', [MissionController::class, 'show'])->name('missions.show');
        Route::post('/missions/{mission}/withdraw', [MissionController::class, 'withdraw'])->name('missions.withdraw');
    });

    // Réservé aux jetons de l'application patient (et du site) : un jeton de l'application
    // professionnel ne gère pas de profils de patients.
    Route::middleware(['auth:sanctum', 'ability:app:patient'])->group(function () {
        Route::apiResource('patient-profiles', PatientProfileController::class);
        Route::apiResource('addresses', AddressController::class)->except('show');

        Route::post('/files/prescriptions', [PrescriptionController::class, 'store'])->name('prescriptions.store');

        Route::get('/bookings/slots', [BookingController::class, 'slots'])->name('bookings.slots');
        Route::post('/bookings/quote', [BookingController::class, 'quote'])->name('bookings.quote');
        Route::get('/bookings', [BookingController::class, 'index'])->name('bookings.index');
        Route::post('/bookings', [BookingController::class, 'store'])->name('bookings.store');
        Route::get('/bookings/{booking}', [BookingController::class, 'show'])->name('bookings.show');
        Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel'])->name('bookings.cancel');
    });
});
