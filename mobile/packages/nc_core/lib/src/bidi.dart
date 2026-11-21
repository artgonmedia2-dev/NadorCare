/// Entoure un texte des marques Unicode « isolat gauche-à-droite » (U+2066 et U+2069).
///
/// À utiliser pour un numéro de téléphone ou une référence insérés dans une phrase :
/// ils restent lisibles de gauche à droite au milieu d'un texte en arabe.
String isolateLtr(String text) => '${String.fromCharCode(0x2066)}$text${String.fromCharCode(0x2069)}';
