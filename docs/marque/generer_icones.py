"""Produit les icônes PNG de Nador Care à partir du symbole (piste C « Maison-pouls »).

Même géométrie que icone-patient.svg et icone-soignant.svg (grille de 64). Le dessin est fait
quatre fois plus grand puis réduit, pour des bords nets à toutes les tailles.

    python docs/marque/generer_icones.py      (depuis la racine du dépôt ; Pillow requis)

Écrit : icônes Android (anciennes et adaptatives) et iOS des deux applications, favicons du site
et du back-office.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OVERSAMPLE = 4

ROOF = [(13, 30), (32, 14.5), (51, 30)]
PULSE = [(13, 42), (22.5, 42), (26.2, 35.5), (31, 49.5), (35.8, 27.5), (39.5, 42), (51, 42)]

THEMES = {
    # Application patient, site, back-office : fond teal, symbole blanc.
    'patient': {'bg': '#0F766E', 'roof': '#FFFFFF', 'pulse': '#FFFFFF'},
    # Application soignant : fond teal profond, pouls orange clair.
    'pro': {'bg': '#083F3B', 'roof': '#FFFFFF', 'pulse': '#FDBA8C'},
}


def _polyline(draw, points, color, width):
    """Trait aux angles arrondis (joint « curve ») et aux extrémités arrondies (un disque à chaque bout)."""
    width = round(width)
    draw.line(points, fill=color, width=width, joint='curve')
    r = (width - 1) / 2
    for x, y in (points[0], points[-1]):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def render(size, theme, *, shape='rounded', stroke=None, square=64.0, offset=0.0, transparent=True):
    """Icône de `size` px.

    shape : 'rounded' (carré arrondi, rayon 15/64), 'full' (plein cadre, pour iOS) ou 'none'
    (symbole seul sur fond transparent, premier plan d'une icône adaptative Android).
    square et offset placent le carré de 64 dans l'image (en unités de 64).
    """
    colors = THEMES[theme]
    big = size * OVERSAMPLE
    unit = big / 64
    image = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    scale = unit * square / 64
    shift = offset * unit

    def place(points):
        return [(shift + x * scale, shift + y * scale) for x, y in points]

    if shape == 'rounded':
        draw.rounded_rectangle((shift, shift, shift + 64 * scale, shift + 64 * scale), radius=15 * scale, fill=colors['bg'])
    elif shape == 'full':
        draw.rectangle((0, 0, big, big), fill=colors['bg'])

    # Un trait un peu plus épais en petit, pour rester lisible.
    width = (stroke or (6 if size <= 48 else 5)) * scale
    _polyline(draw, place(ROOF), colors['roof'], width)
    _polyline(draw, place(PULSE), colors['pulse'], width)

    image = image.resize((size, size), Image.LANCZOS)
    return image if transparent else image.convert('RGB')


def android(app, theme):
    res = ROOT / 'mobile' / 'apps' / app / 'android' / 'app' / 'src' / 'main' / 'res'
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, factor in densities.items():
        folder = res / f'mipmap-{name}'
        folder.mkdir(exist_ok=True)
        # Ancienne icône (Android 7 et avant) : carré arrondi avec une petite marge.
        legacy = round(48 * factor)
        render(legacy, theme, square=58, offset=3).save(folder / 'ic_launcher.png', optimize=True)
        # Premier plan de l'icône adaptative : 108 dp, le carré de 64 ramené à 72 dp au centre.
        fg = round(108 * factor)
        render(fg, theme, shape='none', square=64 * 72 / 108, offset=64 * 18 / 108).save(
            folder / 'ic_launcher_foreground.png', optimize=True
        )

    adaptive = res / 'mipmap-anydpi-v26'
    adaptive.mkdir(exist_ok=True)
    (adaptive / 'ic_launcher.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Icône adaptative (Android 8 et plus), produite par docs/marque/generer_icones.py. -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '</adaptive-icon>\n',
        encoding='utf-8',
    )
    (res / 'values' / 'ic_launcher_background.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{THEMES[theme]["bg"]}</color>\n'
        '</resources>\n',
        encoding='utf-8',
    )


def ios(app, theme):
    folder = ROOT / 'mobile' / 'apps' / app / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
    for file in sorted(folder.glob('Icon-App-*.png')):
        # « Icon-App-83.5x83.5@2x.png » : 83,5 points × 2. iOS arrondit lui-même : plein cadre, sans transparence.
        points, scale = file.stem.removeprefix('Icon-App-').split('@')
        size = round(float(points.split('x')[0]) * int(scale.removesuffix('x')))
        render(size, theme, shape='full', transparent=False).save(file, optimize=True)


def favicons():
    # Site : icône d'onglet et icône d'écran d'accueil iOS (180 px, plein cadre).
    web = ROOT / 'web' / 'src' / 'app'
    render(180, 'patient', shape='full', transparent=False).save(web / 'apple-icon.png', optimize=True)
    # Back-office : favicon.ico (16, 32, 48).
    sizes = [16, 32, 48]
    images = [render(s, 'patient') for s in sizes]
    images[-1].save(ROOT / 'api' / 'public' / 'favicon.ico', sizes=[(s, s) for s in sizes], append_images=images[:-1])


if __name__ == '__main__':
    android('patient', 'patient')
    android('pro', 'pro')
    ios('patient', 'patient')
    ios('pro', 'pro')
    favicons()
    print('Icônes écrites.')
