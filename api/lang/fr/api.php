<?php

return [
    'otp' => [
        'sms' => ':code est votre code Nador Care. Il expire dans :minutes minutes. Ne le partagez avec personne.',
        'sent' => 'Si ce numéro est valide, un code vient de lui être envoyé par SMS.',
    ],
    'auth' => [
        'logged_out' => 'Vous êtes déconnecté.',
    ],
    'errors' => [
        'phone_invalid' => 'Ce numéro de téléphone n\'est pas valide.',
        'otp_invalid' => 'Ce code est incorrect ou a expiré.',
        'otp_locked' => 'Trop de tentatives. Demandez un nouveau code.',
        'otp_too_soon' => 'Patientez :seconds secondes avant de demander un nouveau code.',
        'consent_required' => 'Vous devez accepter les conditions générales et la politique de confidentialité pour créer un compte.',
        'account_suspended' => 'Ce compte est suspendu. Contactez la coordination.',
        'unauthenticated' => 'Connectez-vous pour continuer.',
        'forbidden' => 'Vous n\'avez pas le droit de faire cette action.',
        'not_found' => 'Élément introuvable.',
        'too_many_requests' => 'Trop de demandes. Réessayez dans un instant.',
        'validation_failed' => 'Certaines informations sont incorrectes.',
        'transition_not_allowed' => 'Ce changement de statut n\'est pas possible.',
        'transition_forbidden' => 'Vous n\'avez pas le droit de changer ce statut.',
        'professional_required' => 'Un professionnel doit être désigné.',
        'self_profile_exists' => 'Ce compte a déjà un profil pour vous-même.',
        'profile_limit_reached' => 'Vous avez atteint le nombre maximum de profils.',
        'profile_in_use' => 'Ce profil a un soin prévu ou en cours. Annulez-le ou attendez sa fin.',
        'address_limit_reached' => 'Vous avez atteint le nombre maximum d\'adresses.',
        'address_in_use' => 'Un soin est prévu ou en cours à cette adresse.',
        'server_error' => 'Une erreur est survenue. Réessayez plus tard.',
    ],
];
