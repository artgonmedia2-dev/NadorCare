<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\CatalogueController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\PatientProfileController;
use App\Http\Controllers\Api\V1\PrescriptionController;
use App\Http\Controllers\Api\V1\Pro\InterventionController;
use App\Http\Controllers\Api\V1\Pro\MissionController;
use App\Http\Controllers\Api\V1\Pro\ProfileController;
use App\Http\Controllers\Api\V1\Pro\ScheduleRequestController;
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
        Route::get('/professional-categories', [CatalogueController::class, 'professionalCategories'])->name('professional-categories');
        Route::get('/zones', [CatalogueController::class, 'zones'])->name('zones');
        Route::get('/surcharges', [CatalogueController::class, 'surcharges'])->name('surcharges');
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
        Route::get('/profile', [ProfileController::class, 'show'])->name('profile.show');
        Route::post('/profile/documents', [ProfileController::class, 'uploadDocument'])->name('profile.documents.store');
        Route::post('/profile/submit', [ProfileController::class, 'submit'])->name('profile.submit');
        Route::get('/schedule-requests', [ScheduleRequestController::class, 'index'])->name('schedule-requests.index');
        Route::post('/schedule-requests', [ScheduleRequestController::class, 'store'])->middleware('throttle:20,1')->name('schedule-requests.store');
        Route::delete('/schedule-requests/{scheduleRequest}', [ScheduleRequestController::class, 'destroy'])->name('schedule-requests.destroy');

        Route::get('/missions', [MissionController::class, 'index'])->name('missions.index');
        Route::get('/missions/{mission}', [MissionController::class, 'show'])->name('missions.show');
        Route::post('/missions/{mission}/confirm', [MissionController::class, 'confirm'])->name('missions.confirm');
        Route::post('/missions/{mission}/decline', [MissionController::class, 'decline'])->name('missions.decline');

        Route::post('/missions/{mission}/depart', [InterventionController::class, 'depart'])->name('missions.depart');
        Route::post('/missions/{mission}/location', [InterventionController::class, 'location'])->middleware('throttle:120,1')->name('missions.location');
        Route::post('/missions/{mission}/arrive', [InterventionController::class, 'arrive'])->name('missions.arrive');
        Route::post('/missions/{mission}/start', [InterventionController::class, 'start'])->name('missions.start');
        Route::get('/missions/{mission}/teleconsultation', [InterventionController::class, 'teleconsultation'])->middleware('throttle:60,1')->name('missions.teleconsultation');
        Route::get('/missions/{mission}/reference', [InterventionController::class, 'reference'])->name('missions.reference');
        Route::get('/missions/{mission}/intervention', [InterventionController::class, 'show'])->name('missions.intervention');
        Route::put('/missions/{mission}/report', [InterventionController::class, 'saveReport'])->name('missions.report');
        Route::post('/missions/{mission}/report/photos', [InterventionController::class, 'addPhoto'])->name('missions.report.photos');
        Route::post('/missions/{mission}/report/signature', [InterventionController::class, 'sign'])->name('missions.report.signature');
        Route::post('/missions/{mission}/complete', [InterventionController::class, 'complete'])->name('missions.complete');
        Route::post('/interventions/{intervention}/amendments', [InterventionController::class, 'amend'])->name('interventions.amend');
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
        Route::get('/bookings/{booking}/report', [BookingController::class, 'report'])->name('bookings.report');
        Route::get('/bookings/{booking}/teleconsultation', [BookingController::class, 'teleconsultation'])->middleware('throttle:60,1')->name('bookings.teleconsultation');
    });
});
