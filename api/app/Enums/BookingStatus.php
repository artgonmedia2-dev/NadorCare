<?php

namespace App\Enums;

enum BookingStatus: string
{
    case Pending = 'pending';          // en attente de validation par un coordinateur
    case Confirmed = 'confirmed';      // validée, recherche d'un professionnel
    case Assigned = 'assigned';        // un professionnel est affecté
    case EnRoute = 'en_route';         // le professionnel est en chemin
    case InProgress = 'in_progress';   // arrivée pointée
    case Completed = 'completed';      // fin pointée, compte rendu validé
    case Cancelled = 'cancelled';
    case Disputed = 'disputed';        // en litige

    /**
     * Transitions autorisées depuis ce statut.
     *
     * @return list<self>
     */
    public function allowedTargets(): array
    {
        return match ($this) {
            self::Pending => [self::Confirmed, self::Cancelled],
            self::Confirmed => [self::Assigned, self::Cancelled],
            self::Assigned => [self::EnRoute, self::Confirmed, self::Cancelled],
            self::EnRoute => [self::InProgress, self::Confirmed, self::Cancelled],
            self::InProgress => [self::Completed, self::Disputed],
            self::Completed => [self::Disputed],
            self::Cancelled => [self::Disputed],
            self::Disputed => [self::Completed, self::Cancelled],
        };
    }

    public function canTransitionTo(self $target): bool
    {
        return in_array($target, $this->allowedTargets(), true);
    }

    /**
     * Statuts pendant lesquels le professionnel affecté est en mission.
     *
     * @return list<self>
     */
    public static function activeMission(): array
    {
        return [self::Assigned, self::EnRoute, self::InProgress];
    }
}
