"""Renders Daftary's launcher icon sources (SVG -> PNG via headless Chrome).

Outputs, all 1024x1024:
  icon.png             full icon (iOS, legacy Android, store listing)
  foreground.png       adaptive-icon foreground, transparent, safe-zone sized
  background.png       adaptive-icon background gradient
  monochrome.png       Android 13+ themed-icon silhouette

Run: python3 assets/icon/build_icon.py
"""
import pathlib
import subprocess
import tempfile

HERE = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

DEFS = """
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#2E9A7E"/>
    <stop offset="0.55" stop-color="#1F6F5C"/>
    <stop offset="1" stop-color="#0E3D32"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.25" cy="0.18" r="0.75">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>
    <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="page" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFFDF6"/>
    <stop offset="1" stop-color="#F6EDD8"/>
  </linearGradient>
  <linearGradient id="spine" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#0F4538"/>
    <stop offset="1" stop-color="#1A6452"/>
  </linearGradient>
  <linearGradient id="coin" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#FFD66B"/>
    <stop offset="0.6" stop-color="#F2B233"/>
    <stop offset="1" stop-color="#D38E12"/>
  </linearGradient>
  <linearGradient id="ribbon" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#F0735C"/>
    <stop offset="1" stop-color="#D24E3B"/>
  </linearGradient>
  <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
    <feDropShadow dx="0" dy="22" stdDeviation="26" flood-color="#062A22" flood-opacity="0.45"/>
  </filter>
  <filter id="coinShadow" x="-40%" y="-40%" width="180%" height="180%">
    <feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#3A2600" flood-opacity="0.35"/>
  </filter>
</defs>
"""

# The mark, drawn around the canvas centre (512, 512).
MARK = """
<g filter="url(#shadow)">
  <!-- page stack edge -->
  <rect x="318" y="262" width="416" height="528" rx="44" fill="#E3D5B4"/>
  <!-- front page -->
  <rect x="300" y="240" width="416" height="528" rx="44" fill="url(#page)"/>
  <!-- spine -->
  <path d="M344 240 H392 V768 H344 A44 44 0 0 1 300 724 V284 A44 44 0 0 1 344 240 Z" fill="url(#spine)"/>
  <g fill="#FFFDF6" opacity="0.55">
    <circle cx="346" cy="318" r="9"/><circle cx="346" cy="426" r="9"/>
    <circle cx="346" cy="534" r="9"/><circle cx="346" cy="642" r="9"/>
  </g>
  <!-- ledger lines -->
  <g stroke-linecap="round" stroke-width="26">
    <line x1="448" y1="350" x2="640" y2="350" stroke="#1F6F5C"/>
    <line x1="448" y1="440" x2="656" y2="440" stroke="#1F6F5C" stroke-opacity="0.28"/>
    <line x1="448" y1="530" x2="600" y2="530" stroke="#1F6F5C" stroke-opacity="0.28"/>
  </g>
  <!-- bookmark ribbon -->
  <path d="M602 240 H654 V312 L628 294 L602 312 Z" fill="url(#ribbon)"/>
</g>
<!-- coin -->
<g filter="url(#coinShadow)">
  <circle cx="676" cy="676" r="124" fill="url(#coin)"/>
  <circle cx="676" cy="676" r="98" fill="none" stroke="#FFF1C2" stroke-width="10" stroke-opacity="0.7"/>
  <text x="676" y="668" text-anchor="middle" dominant-baseline="middle"
        font-family="'Geeza Pro', 'Noto Kufi Arabic', sans-serif" font-weight="700"
        font-size="176" fill="#8A5500">د</text>
</g>
"""

MONO = """
<defs>
  <mask id="cut">
    <rect width="1024" height="1024" fill="#fff"/>
    <rect x="392" y="240" width="14" height="528" fill="#000"/>
    <g stroke="#000" stroke-linecap="round" stroke-width="26">
      <line x1="448" y1="350" x2="640" y2="350"/>
      <line x1="448" y1="440" x2="656" y2="440"/>
      <line x1="448" y1="530" x2="560" y2="530"/>
    </g>
    <circle cx="676" cy="676" r="146" fill="#000"/>
  </mask>
  <mask id="letter">
    <circle cx="676" cy="676" r="124" fill="#fff"/>
    <text x="676" y="668" text-anchor="middle" dominant-baseline="middle"
          font-family="'Geeza Pro', sans-serif" font-weight="700" font-size="176" fill="#000">د</text>
  </mask>
</defs>
<g fill="#fff">
  <rect x="300" y="240" width="416" height="528" rx="44" mask="url(#cut)"/>
  <rect width="1024" height="1024" mask="url(#letter)"/>
</g>
"""


def svg_group(body, scale):
    """Scales [body] about the canvas centre."""
    return f'<g transform="translate(512 512) scale({scale}) translate(-512 -512)">{body}</g>'


def svg(body, scale=1.0):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
            f'viewBox="0 0 1024 1024">{DEFS}{svg_group(body, scale)}</svg>')


BG = '<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#glow)"/>'

MARK_CENTRED = f'<g transform="translate(-24 -20)">{MARK}</g>'
MONO_CENTRED = f'<g transform="translate(-24 -20)">{MONO}</g>'


def render(name, markup):
    with tempfile.TemporaryDirectory() as tmp:
        html = pathlib.Path(tmp, "i.html")
        html.write_text(f'<html><body style="margin:0;background:transparent">{markup}</body></html>',
                        encoding="utf-8")
        out = HERE / f"{name}.png"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--force-device-scale-factor=1", "--window-size=1024,1024",
                        "--default-background-color=00000000",
                        f"--screenshot={out}", html.as_uri()],
                       check=True, capture_output=True)
        print("wrote", out)


if __name__ == "__main__":
    # Adaptive icons: flutter_launcher_icons insets the foreground 16% per side
    # (drawn at 68%), so 1.18 here lands the mark at ~0.8 of its full-icon
    # size, inside the launcher mask's 66dp-of-108dp safe circle. The full
    # icon's mark is scaled up to fill the iOS squircle.
    render("icon", svg(BG + svg_group(MARK_CENTRED, 1.1)))
    render("background", svg(BG))
    render("foreground", svg(MARK_CENTRED, 1.18))
    render("monochrome", svg(MONO_CENTRED, 1.18))
