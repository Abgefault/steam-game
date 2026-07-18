# Changelog

All notable changes to Green Empire: Industrial Cannabis Tycoon.
Format loosely follows Keep a Changelog. This project uses semantic versioning.

## [1.0.0] — Initial release

First complete, playable release.

### Gameplay
- Fixed 180-day campaign to win the Verdantia City Supply Contract, with a
  continuously visible qualification checklist and a 30-day final supply trial
  driven by the player's real production, inventory, staffing and delivery.
- Six company stages (Garage Operation → Contract Contender) with visible
  facility transformation, and an Endless Mode after victory.
- First-person controller: walk / sprint / crouch / jump, mouse-look, object
  interaction, carrying containers, head-bob and reduced-motion options.
- Full abstract production chain — Cultivation → Conditioning → Processing →
  Product → Laboratory → Packaging → Warehouse → Dispatch — with FEFO lot
  tracking, testing status, expiry, quality tiers and per-lot history.
- Machines with five tiers each, wear, breakdowns, repair, upgrades, and
  conveyor auto-transfer + robotic auto-feed for automation.
- Formal 0–100% automation score computed from real work done per department
  (never from equipment owned).
- Retail across five districts with eight customer archetypes making
  understandable purchase decisions; visible in-store customers use the same
  logic as background stores.
- Employees (eight roles) that visibly work, gain XP, level up, and have
  morale/traits; hiring, bonuses, and staff welfare affect the final score.
- Economy: cash, overdraft, startup loan, rent, payroll, utilities, taxes,
  supplier costs, depreciation, wholesale orders, and daily accounting.
- Market simulation with demand drift, trends, competitor pressure and supplier
  conditions; 42 authored events with prerequisites, cooldowns and choices.
- Compliance rating with scheduled and surprise audits that inspect real state.
- 33-node research tree across five branches; 63 objectives (tutorial chain +
  regular + 15 challenges) and 27 achievements.

### Content
- 26 fictional products across seven categories; 6 strains; 5 districts;
  6 machine types × 5 tiers. All data-driven in `data/*.json`.

### Presentation
- Procedural 3D facility (storefront, production hall, warehouse, office,
  exterior street, delivery van) with PBR-style materials and zone lighting.
- Original synthesized audio: menu/calm/tension music, store/office/workshop
  ambience, machine, UI, and stinger sounds (40 clips, zero third-party audio).
- Coherent code-driven UI: main menu, company setup, HUD, 15-page tablet, daily
  report, event popups, pause, settings, save/load, victory, game over, credits.

### Technical
- Typed GDScript, authoritative-state/presentation separation, autoload
  services, data validation on boot, seedable RNG, versioned atomic saves with
  migration hooks and a debug-only developer panel.
- 123-assertion automated test suite, headless boot/world smoke tests, and a
  scripted economy-balancing simulation (`docs/economy_sim_report.md`).
- One-file Windows release: `dist/GreenEmpire/GreenEmpire.exe` (embedded PCK,
  no console window, application icon and version metadata), plus a Linux
  export. Steam integration is stubbed behind `SteamFacade` and optional.
