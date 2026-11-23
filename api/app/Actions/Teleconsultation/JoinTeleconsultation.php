<?php

namespace App\Actions\Teleconsultation;

use App\Contracts\VideoGateway;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\User;
use App\Services\Settings\Settings;
use App\Services\Video\VideoAccess;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;

/**
 * Donne accès à la salle vidéo d'une téléconsultation.
 *
 * Seuls deux comptes y entrent : celui qui a réservé et le professionnel affecté. La salle
 * s'ouvre quelques minutes avant l'heure prévue et se ferme un peu après la fin prévue.
 */
class JoinTeleconsultation
{
    /** Marge après la fin prévue pendant laquelle on peut encore rejoindre l'appel, en minutes. */
    private const GRACE_MINUTES = 30;

    public function __construct(
        private readonly VideoGateway $video,
        private readonly Settings $settings,
    ) {}

    public function handle(Booking $booking, User $actor, ?CarbonInterface $now = null): VideoAccess
    {
        $now = CarbonImmutable::instance($now ?? now());

        // Le mode est relu en base : la relation chargée peut n'avoir que quelques colonnes.
        if (! $booking->service()->first()?->isRemote()) {
            throw new ApiException('not_a_teleconsultation', 409);
        }

        $isBooker = $booking->user_id === $actor->getKey();
        $isProfessional = $booking->professional_id !== null
            && $booking->professional_id === $actor->professional()->value('id');

        if (! $isBooker && ! $isProfessional) {
            throw new ApiException('forbidden', 403);
        }

        if (! in_array($booking->status, [BookingStatus::Assigned, BookingStatus::InProgress], true)) {
            throw new ApiException('teleconsultation_not_open', 409);
        }

        [$opensAt, $closesAt] = $this->window($booking);

        if ($now->lt($opensAt) || $now->gt($closesAt)) {
            throw new ApiException('teleconsultation_not_open', 409, ['opens_at' => $opensAt->toIso8601String()]);
        }

        return $this->video->access(
            room: self::room($booking),
            // Un identifiant qui ne dit rien de la personne : son rôle et l'identifiant de la réservation.
            participant: ($isProfessional ? 'pro-' : 'patient-').$booking->getKey(),
            isHost: $isProfessional,
            expiresAt: $closesAt,
        );
    }

    /**
     * Période pendant laquelle la salle est ouverte.
     *
     * @return array{CarbonImmutable, CarbonImmutable}
     */
    public function window(Booking $booking): array
    {
        $start = CarbonImmutable::instance($booking->scheduled_at);
        $end = CarbonImmutable::instance($booking->scheduled_end_at ?? $booking->scheduled_at);

        return [
            $start->subMinutes($this->settings->int(Settings::TELECONSULTATION_JOIN_BEFORE_MINUTES)),
            $end->addMinutes(self::GRACE_MINUTES),
        ];
    }

    /** Nom de salle opaque : il ne révèle ni le patient ni le soin. */
    public static function room(Booking $booking): string
    {
        return 'nc-'.strtolower((string) $booking->getKey());
    }
}
