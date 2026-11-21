<?php

return [

    // Langues prises en charge par l'API, le back-office et les notifications.
    'locales' => ['fr', 'ar', 'en'],

    // Fuseau des horaires de service et des créneaux. Les dates restent stockées en UTC.
    'timezone' => env('SERVICE_TIMEZONE', 'Africa/Casablanca'),

    // Documentation OpenAPI en ligne (/docs/api) hors environnement local.
    'api_docs_enabled' => (bool) env('SCRAMBLE_ENABLED', false),

    'otp' => [
        'length' => (int) env('OTP_LENGTH', 6),
        'ttl_seconds' => (int) env('OTP_TTL_SECONDS', 300),
        'max_attempts' => (int) env('OTP_MAX_ATTEMPTS', 5),
        'resend_seconds' => (int) env('OTP_RESEND_SECONDS', 60),
        // Code fixe pour le développement et les tests. Jamais pris en compte en production.
        'static_code' => env('OTP_STATIC_CODE'),
    ],

    // Plafonds par compte, contre les abus.
    'limits' => [
        'patient_profiles' => (int) env('LIMIT_PATIENT_PROFILES', 10),
        'addresses' => (int) env('LIMIT_ADDRESSES', 20),
    ],

    'legal' => [
        'documents_version' => env('LEGAL_DOCUMENTS_VERSION', '2026-11'),
    ],

    'files' => [
        'disk' => env('PRIVATE_FILES_DISK', 'local'),
        'key' => env('FILES_ENCRYPTION_KEY'),
        'key_version' => 1,
    ],

    'health' => [
        // Durée pendant laquelle le professionnel garde l'accès au dossier après la fin
        // de l'intervention, pour terminer son compte rendu.
        'post_completion_access_hours' => (int) env('HEALTH_POST_COMPLETION_ACCESS_HOURS', 24),
    ],

    // Pilotes des services externes. "fake" tant que les contrats ne sont pas signés.
    'drivers' => [
        'sms' => env('SMS_DRIVER', 'fake'),
        'whatsapp' => env('WHATSAPP_DRIVER', 'fake'),
        'push' => env('PUSH_DRIVER', 'fake'),
        'payment' => env('PAYMENT_DRIVER', 'fake'),
        'maps' => env('MAPS_DRIVER', 'fake'),
    ],

    'payzone' => [
        'merchant_id' => env('PAYZONE_MERCHANT_ID'),
        'secret_key' => env('PAYZONE_SECRET_KEY'),
        'base_url' => env('PAYZONE_BASE_URL'),
    ],

];
