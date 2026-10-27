# Daftary · دفتري: brag plan

**What it is:** A people-first money notebook for Arabic-speaking users. It shows who owes you and who you owe, as one running balance per person.
**For:** Egyptians who lend and borrow informally with friends and family and keep track in their heads or on paper (a *daftar*).
**Sets it apart:** People, not categories. Arabic is a real RTL experience. It works offline on the device. Bank SMS turn into suggested entries without leaving the phone.
**Hook:** The doubt everyone knows: "Lent Ahmed money. Was it 1,500… or 1,000?" over a scribbled paper notebook.
**Visual hook:** A cream notebook page with crossed-out Arabic scribbles, then the green field with the Daftary notebook-and-coin icon.
**Real UI shown:** The project's own README screenshots (`docs/screenshots`). People list, tap Ahmed, his balance ("owes you 1,700.00 EGP"), the same screen in Arabic, then bank messages and the review screen.
**Tone:** `default`: punchy, playful, clean, soft transitions.
**Share caption:** see share-copy.txt.

## Identity
- Colors from `lib/core/design_system/tokens.dart`: primary #1F6F5C, field deep #0E3D32, page #FFFDF6 / #F6EDD8, coin #F2B233, ribbon #F0735C, positive #1A7347, negative #AB4136.
- Type: Inter Display for English, Noto Kufi Arabic (titles) and Noto Naskh Arabic (scribbles). The app itself uses the system fonts.
- Logo: `assets/icon/icon.png` / `foreground.png`.

## Music
120 BPM (beat 0.5s, bar 2s), D major, I–V–vi–IV. The hook is sparse: pad plus pencil scratches on the grid. The groove drops at 3.0s. Every cut lands on a beat.

## Storyboard (20.0s, 1920×1080, 30fps)
| # | Time | Scene |
|---|---|---|
| 1 Hook | 0.0–3.0 | A paper page with scribbles drawn in: "أحمد ١٥٠٠", crossed out, then "١٠٠٠؟". Text: "Lent Ahmed money." / "Was it 1,500… or 1,000?" |
| 2 Reveal | 3.0–6.0 | Green circle wipe from the coin. The icon pops in. "Daftary · دفتري". "A notebook that remembers who owes who." |
| 3 Balances | 6.0–10.0 | Phone with the People list. A tap on Ahmed pushes to his detail. The balance glows. Text: "One person. One running balance." Chips: They owe you · You owe them · Settled |
| 4 Arabic | 10.0–13.5 | The English and Arabic person screens side by side, the Arabic one sliding in from the left. "Arabic first. Real right-to-left, not a mirror." |
| 5 Bank SMS | 13.5–17.0 | A bank SMS bubble flies into the Bank messages screen, then cuts to Review. "Bank texts → suggested entries." Chip: "On-device · You confirm each one" |
| 6 Outro | 17.0–20.0 | Green field, icon, "Daftary · دفتري", "Offline-first · Arabic & English · Android & iOS" |

## Data note
All names, amounts and the bank ("National Bank of Egypt •••• 4821", "Example Market") come from the demo data already in the published README screenshots. No real user data is used. The SMS bubble text was written to match that demo record.
