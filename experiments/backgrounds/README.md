# Background experiments

Run commands from the repository root. Requires Bash and Python 3.

```bash
./scripts/apply-background.sh list
./scripts/apply-background.sh dark softer
./scripts/apply-background.sh light warm
./scripts/apply-background.sh dark reset
./scripts/apply-background.sh light reset
```

Each mode has an independent selection, automatically used when switching
Obsidian's appearance. `original` explicitly applies the original surface values;
`reset` removes that mode's override, restoring the base theme's behavior.
The current preferred configuration is dark `deeper` with light `vanilla-latte`.
Light and dark choices are independent: changing light leaves dark Deeper and
both heading palettes untouched.

| Mode | Name | Editor / primary alt | Sidebar / code | Secondary alt | Border |
| --- | --- | --- | --- | --- | --- |
| Dark | original | `#2E3440` | `#3B4252` | `#434C5E` | `#434C5E` |
| Dark | softer | `#343B48` | `#414959` | `#495365` | `#495365` |
| Dark | deeper | `#292F3A` | `#353C4B` | `#3E4758` | `#3E4758` |
| Dark | warm | `#34363F` | `#41444F` | `#4A4E5B` | `#4A4E5B` |
| Light | original | `#FFFFFF` | `#ECEFF4` | `#E5E9F0` | `#E5E9F0` |
| Light | cool | `#F7F9FC` | `#E9EEF5` | `#E1E7F0` | `#E1E7F0` |
| Light | warm | `#FAF9F6` | `#EEEDE8` | `#E6E4DE` | `#E6E4DE` |
| Light | muted | `#F1F3F5` | `#E5E9EE` | `#DDE2E9` | `#DDE2E9` |
| Light | vanilla-latte | `#FBF7EF` | `#F0E8DB` | `#E6DAC9` | `#D9CBB8` |
| Light | mocha-frappe | `#F5EFE6` | `#E9DFD2` | `#DDD0C1` | `#CEBEAD` |
| Light | oat-milk | `#F8F6F1` | `#EEEAE2` | `#E5DFD5` | `#D8D0C5` |

Vanilla Latte combines creamy off-white with warm beige. Mocha Frappé adds
richer beige and taupe; Oat Milk stays closer to Nord Warm with restrained warm
gray surfaces. All three use the suggested colors without changes to text or headings.

```bash
./scripts/apply-background.sh light vanilla-latte
./scripts/apply-background.sh light mocha-frappe
./scripts/apply-background.sh light oat-milk
```

To return to the previously preferred light Warm palette:

```bash
./scripts/apply-background.sh light warm
```

To select the current preferred pair:

```bash
./scripts/apply-background.sh dark deeper
./scripts/apply-background.sh light vanilla-latte
```

## Scope and heading palettes

The base theme defines shared Nord tokens in `:root`, also used for text,
accents, tags, graphs, and diagrams. These experiments leave those tokens alone.
Both appearance selectors define the same semantic property names independently:
`--background-primary`, `--background-primary-alt`, `--background-secondary`,
`--background-secondary-alt`, `--background-modifier-border`, and
`--code-background`. These cover editor/reading surfaces, sidebar/navigation
surfaces, alternate panels, borders, and code. Obsidian determines which specific
controls inherit these properties. Table borders also consume background values;
explicit table fills, selection highlights, tags, and accent hover fills stay as-is.

Each background mode has its own uniquely marked block at the end of `theme.css`.
Only that block is replaced or removed. Heading palettes use separate markers,
so either script preserves the other script's configuration. Background selection
never changes heading colors, typography, or accents.

The current preferred headings are dark Sage and light Slate Blue, supplied by
`experiments/palette-custom.css`. To select that heading combination explicitly:

```bash
./scripts/apply-palette.sh custom
```

Other heading selections deliberately change headings; they do not reset backgrounds.

## Manual visual check in Obsidian

1. Apply one dark and one light experiment using the commands above.
2. In Obsidian, use Settings → Appearance to switch between Dark and Light.
   The existing theme symlink points to this repository, so changes should reload.
   If they do not, reload Obsidian.
3. Inspect an existing note in source, Live Preview, and Reading view. Compare
   the editor with the file explorer, search/navigation panels, tabs, and code.
   Check readable text, panel boundaries, and all six heading levels.
4. Compare each mode with `original`, and confirm changing one mode leaves the
   other mode's selection intact. Check any plugins or CSS snippets you use;
   they may override these properties or use their own surface colors.
5. Reset either mode independently when finished. To return to the initial
   background state, reset both modes. Leave the custom heading palette active.

No notes or vault settings are modified by these scripts. Visual application
testing requires Obsidian; automated checks do not establish visual quality.

## Automated checks

```bash
bash -n scripts/apply-background.sh scripts/apply-palette.sh
python3 scripts/test-background.py
```

The integration checks run in a temporary repository copy and leave the active
theme untouched.
