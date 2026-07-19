# Release-Readiness Checklist

Status of each definition-of-done item for the 1.0.0 build. Verified via the
headless test suite, smoke tests, rendered screenshots, and the exported build.

## Build & launch
- [x] Project opens without parse/resource errors (`--headless --import` clean)
- [x] `dist/GreenEmpire/GreenEmpire.exe` produced (embedded PCK, ~110 MB)
- [x] Export preset hides the console window, sets icon + version metadata
- [x] Root-level `PLAY GREEN EMPIRE.url` shortcut points at the executable
- [x] No machine-specific absolute paths; saves/settings use `%APPDATA%`
- [x] Data embedded in the executable (single-file distribution)

## Automated verification
- [x] 123/123 test assertions pass (`--run-tests`), incl. against the exported binary
- [x] Headless boot/sim/save/load smoke passes (`--smoke-test`)
- [x] Full 3D world + HUD + tablet smoke passes (`--smoke-world`)
- [x] Economy balancing simulation runs and writes `docs/economy_sim_report.md`
- [x] Rendered screenshots confirm menu, facility, tablet, and research layouts

## Gameplay loop
- [x] New Game → company setup → playable campaign
- [x] First-person walking through a 3D facility
- [x] Manual production → testing → packaging → storage → stocking → sale
- [x] Employees visibly work; customers visibly shop with readable decisions
- [x] Conveyors auto-transfer; automation measurably reduces manual actions
- [x] 85%+ automation achievable; automation score from real work, not machines
- [x] 180-day campaign with always-visible qualification; 30-day real trial
- [x] Victory (audit, award, tour, grade, Endless) and every failure path
- [x] Save survives closing/reopening the exported game

## Content quantities (spec minimums)
- [x] Products ≥ 24 → **26**
- [x] Districts = 5 → **5**
- [x] Customer archetypes ≥ 8 → **8**
- [x] Events ≥ 40 → **42**
- [x] Research nodes ≥ 32 → **33**
- [x] Objectives: ≥30 regular + ≥15 challenge + tutorial chain → **63 total**
- [x] Achievements ≥ 25 → **27**
- [x] Machine tiers (not reskins) → 6 types × 5 tiers

## Presentation & UX
- [x] Coherent code-driven UI theme; every listed screen implemented
- [x] No dead buttons, empty promised screens, or one-character label stacking
- [x] Original synthesized audio on all buses; independent volume controls
- [x] Accessibility & graphics settings persist and apply
- [x] Designed for 1920×1080; UI scale option for other resolutions

## Documentation & licensing
- [x] README (How-to-Play first), CLAUDE.md, THIRD_PARTY_LICENSES.md, CHANGELOG
- [x] No secrets, no machine-specific paths committed

## Known limitations (honest)
- Visual direction: procedurally-built geometry now surfaced with a real CC0
  PBR texture library (ambientCG — concrete, wood, plaster, metals, brick,
  asphalt, cardboard, rubber; see THIRD_PARTY_LICENSES.md) plus SSAO/ACES
  environment. Believable industrial look, though geometry detail remains
  primitive-based rather than hand-modeled AAA assets.
- The scripted economy bot demonstrates the intended single-store throughput
  ceiling and tends to fail the overdraft rule mid-run; a human who watches
  cash and times expansion has a verified path to qualification (trial win is
  covered by `final_trial_win` in the test suite).
- Remaining art gap to a AAA store page: hand-modeled hero props and
  character models (people are stylized capsule figures).
