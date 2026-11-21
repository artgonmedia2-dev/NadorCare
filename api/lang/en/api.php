<?php

return [
    'otp' => [
        'sms' => ':code is your Nador Care code. It expires in :minutes minutes. Do not share it with anyone.',
        'sent' => 'If this number is valid, a code has just been sent to it by SMS.',
    ],
    'auth' => [
        'logged_out' => 'You are signed out.',
    ],
    'errors' => [
        'phone_invalid' => 'This phone number is not valid.',
        'otp_invalid' => 'This code is incorrect or has expired.',
        'otp_locked' => 'Too many attempts. Request a new code.',
        'otp_too_soon' => 'Wait :seconds seconds before requesting a new code.',
        'consent_required' => 'You must accept the terms and the privacy policy to create an account.',
        'account_suspended' => 'This account is suspended. Contact the coordination team.',
        'unauthenticated' => 'Sign in to continue.',
        'forbidden' => 'You are not allowed to do this.',
        'not_found' => 'Item not found.',
        'too_many_requests' => 'Too many requests. Try again in a moment.',
        'validation_failed' => 'Some information is incorrect.',
        'transition_not_allowed' => 'This status change is not possible.',
        'transition_forbidden' => 'You are not allowed to change this status.',
        'professional_required' => 'A professional must be selected.',
        'server_error' => 'Something went wrong. Try again later.',
    ],
];
