<?php

use App\Enums\Permission;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function (User $user, string $id) {
    return $user->getKey() === $id;
});

// Suivi d'une réservation : le demandeur, le professionnel affecté et la coordination.
Broadcast::channel('bookings.{bookingId}', function (User $user, string $bookingId) {
    $booking = Booking::query()->find($bookingId);

    if (! $booking) {
        return false;
    }

    return $booking->user_id === $user->getKey()
        || ($booking->professional_id !== null && $booking->professional_id === $user->professional()->value('id'))
        || $user->can(Permission::BookingsView->value);
});
