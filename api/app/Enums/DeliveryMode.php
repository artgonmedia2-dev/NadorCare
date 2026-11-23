<?php

namespace App\Enums;

/**
 * Mode de réalisation d'un soin.
 */
enum DeliveryMode: string
{
    case Home = 'home';       // le professionnel se déplace chez le patient
    case Remote = 'remote';   // téléconsultation : appel vidéo dans l'application
}
