<?php

namespace Tests\Unit;

use App\Enums\BookingStatus;
use PHPUnit\Framework\TestCase;

class BookingStatusTest extends TestCase
{
    public function test_the_eight_statuses_of_the_specification_exist(): void
    {
        $this->assertSame(
            ['pending', 'confirmed', 'assigned', 'en_route', 'in_progress', 'completed', 'cancelled', 'disputed'],
            array_map(fn (BookingStatus $status) => $status->value, BookingStatus::cases()),
        );
    }

    public function test_the_transition_table_matches_the_validated_design(): void
    {
        $expected = [
            'pending' => ['confirmed', 'cancelled'],
            'confirmed' => ['assigned', 'cancelled'],
            'assigned' => ['en_route', 'confirmed', 'cancelled'],
            'en_route' => ['in_progress', 'confirmed', 'cancelled'],
            'in_progress' => ['completed', 'disputed'],
            'completed' => ['disputed'],
            'cancelled' => ['disputed'],
            'disputed' => ['completed', 'cancelled'],
        ];

        foreach (BookingStatus::cases() as $status) {
            $this->assertSame(
                $expected[$status->value],
                array_map(fn (BookingStatus $target) => $target->value, $status->allowedTargets()),
                $status->value,
            );
        }
    }

    public function test_nothing_leads_back_to_pending_and_no_status_loops_on_itself(): void
    {
        foreach (BookingStatus::cases() as $status) {
            $this->assertFalse($status->canTransitionTo(BookingStatus::Pending), $status->value);
            $this->assertFalse($status->canTransitionTo($status), $status->value);
        }
    }
}
