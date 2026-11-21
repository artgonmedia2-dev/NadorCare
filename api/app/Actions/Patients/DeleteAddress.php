<?php

namespace App\Actions\Patients;

use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Address;
use App\Models\Booking;

/**
 * Retire une adresse. Refusé tant qu'un soin est prévu ou en cours à cette adresse.
 */
class DeleteAddress
{
    public function handle(Address $address): void
    {
        $hasOpenBooking = Booking::query()
            ->where('address_id', $address->getKey())
            ->whereNotIn('status', [BookingStatus::Completed, BookingStatus::Cancelled])
            ->exists();

        if ($hasOpenBooking) {
            throw new ApiException('address_in_use', 409);
        }

        $address->delete();
    }
}
