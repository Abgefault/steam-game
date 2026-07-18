# GREEN EMPIRE: Industrial Cannabis Tycoon

A first-person 3D business-simulation and factory-automation tycoon game set in
the fictional city of **Verdantia**. Inherit a nearly bankrupt, temporarily
licensed company, turn a dirty workshop into a highly automated citywide
supplier, and win the exclusive ten-year **Verdantia City Supply Contract**
within 180 in-game days.

Everything in the game is fictional and abstract. There are no real-world
cultivation, chemical, or extraction instructions anywhere in the project.

---

## ▶ How to Play (nontechnical users)

1. Open the `dist/GreenEmpire/` folder.
2. **Double-click `GreenEmpire.exe`.**

That's it. No installer, no Godot, no Python, no terminal, no console window.
The game starts at the main menu; choose **New Game** and follow the on-screen
tutorial hints.

> The single file `dist/GreenEmpire/GreenEmpire.exe` is the whole game — the game
> data is embedded inside it. You can copy that one file anywhere and it still
> runs. A convenience shortcut, **`PLAY GREEN EMPIRE.url`**, sits in the project
> root and points at the executable.

If Windows SmartScreen warns about an unknown publisher (normal for unsigned
indie builds), choose **More info → Run anyway**.

---

## Controls

| Action | Key |
|---|---|
| Move | **W A S D** |
| Look | **Mouse** |
| Sprint / Crouch | **Shift** / **Ctrl** |
| Jump | **Space** |
| Interact (machines, doors, shelves, checkout) | **E** |
| Drop carried container | **G** |
| Open/close the company tablet | **Tab** |
| Pause / speed | **1** (pause) · **2** (1×) · **3** (2×) · **4** (4×) |
| End the day early | **End Day** button (top bar) |
| Quicksave / Quickload | **F5** / **F9** |
| Pause menu | **Esc** |

The **tablet (Tab)** is your command center: Overview, Campaign progress,
Orders, Finances, Inventory, Products & pricing, Production, Automation,
Staff, Stores & City Map, Market, Research, Compliance, Objectives, and Events.

## The goal

Before **day 150** you must qualify for the city contract:

- Company valuation ≥ $2,500,000, startup loan repaid, no overdue debt
- 3 owned & profitable stores, a Tier 5 main facility
- Automation ≥ 85%, Compliance ≥ 90, Reputation ≥ 80
- All licenses unlocked, and ≥ 30 days left for the trial

Then pass the **30-day final supply trial**: deliver 12,000 packaged units at
Select quality or better, < 3% rejects, ≥ 98% on-time, no major violations, and
finish in profit. The trial uses your real factory, inventory, staffing and
delivery systems. Win to see the audit, contract award, facility tour, your
final grade (C–S) and Endless Mode.

The campaign can also be **lost** — miss the deadline, stay under the overdraft
limit for five days, miss three loan payments or two payrolls, or lose your
license to repeated violations. The Game Over screen explains exactly why.

## Save location

Saves and settings live in the standard Windows user-data folder:

```
%APPDATA%\Godot\app_userdata\Green Empire - Industrial Cannabis Tycoon\
```

Five manual slots plus autosave and quicksave. A log file is written to the same
folder (`logs/`) rather than to a console window.

## Settings

In-game **Settings** (main menu or pause menu) cover audio (Master / Music /
Ambience / SFX), mouse sensitivity and invert-Y, field of view, window mode and
resolution, graphics quality (Low/Medium/High/Ultra), UI scale, reduced motion,
head-bob and screen-shake toggles, notification duration, autosave frequency,
tutorial hints, and pause-on-focus-loss.

## Troubleshooting

- **Nothing happens on launch / antivirus prompt** — unsigned indie builds can
  trip SmartScreen; choose *Run anyway*. Saves go to `%APPDATA%` as above.
- **Low frame rate** — open Settings and lower Graphics quality to Medium or Low.
- **Reset the game** — delete the user-data folder above (this erases saves).

---

## For developers

The repository is a complete Godot 4.7 project (Forward+ renderer, typed
GDScript, no external runtime dependencies).

### Run from source

```bash
godot --path .                                 # open/play in the editor
godot --path . --headless -- --run-tests       # 123-assertion test suite
godot --path . --headless -- --smoke-test      # boot + sim + save/load smoke
godot --path . --headless -- --smoke-world     # full 3D world + UI smoke
godot --path . --headless -- --economy-sim     # balancing simulation report
```

### Regenerate content and assets

```bash
python3 tools/generate_data.py      # writes data/*.json (products, events, …)
python3 tools/generate_audio.py     # writes assets/audio/*.wav (synthesized)
```

### Build the Windows release

```bash
godot --path . --headless --export-release "Windows Desktop" dist/GreenEmpire/GreenEmpire.exe
```

Export templates for Godot 4.7.1 must be installed. The preset embeds the PCK
inside the `.exe`, hides the console window, and sets the application icon and
version metadata.

See **CLAUDE.md** for architecture, conventions, data locations, and the save
format, and **docs/RELEASE_CHECKLIST.md** for the release-readiness list.

## Screenshots

Located in `docs/`: `screenshot_menu.png`, `screenshot_facility.png`,
`screenshot_tablet.png`, `screenshot_research.png` (rendered from the actual
build via the `--smoke-world --screenshot` harness).
