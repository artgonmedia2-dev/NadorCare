/**
 * Garde-malade : tarifs par jour de garde.
 *
 * Provisoire. Ces tarifs suivent la grille fournie par le client le 2026-11-23 (tarif de jour de
 * référence + 150 DH), mais la garde-malade n'est pas encore dans le catalogue de l'API : elle se
 * vend au forfait (jour, semaine, nuit) et ne rentre pas dans une réservation par créneau. Dès
 * qu'elle y entre, ce fichier disparaît et la page lit l'API. Les forfaits à la semaine ne sont pas
 * affichés tant que leur règle de prix n'est pas confirmée.
 */

/** Ajouté au tarif de référence, en dirhams : la même règle que pour les soins. */
const MARKUP = 150;

export const guardShifts = ['guardShiftDay', 'guardShiftLongDay', 'guardShiftNight', 'guardShiftFull'] as const;

/** Tarif de référence par jour, en dirhams, dans l'ordre de `guardShifts` ; `null` si non proposé. */
const reference = [
  { role: 'guardRoleCarer', prices: [360, 420, 420, 540] },
  { role: 'guardRoleAuxNurse', prices: [420, 480, 480, 660] },
  { role: 'guardRoleNurse', prices: [null, 540, 660, 960] },
] as const;

/** Tarifs affichés, en centimes de dirham comme partout dans le projet. */
export const guardRates = reference.map(({ role, prices }) => ({
  role,
  prices: prices.map((price) => (price === null ? null : (price + MARKUP) * 100)),
}));
