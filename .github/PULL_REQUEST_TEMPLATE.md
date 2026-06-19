<!-- Thanks for contributing to Aether! -->

## Description

<!-- What does this PR change and why? Link any related issue, e.g. "Closes #12". -->

## Type of change

- [ ] Bug fix
- [ ] New feature (new complication, weather/forecast behavior, theme, etc.)
- [ ] Layout / readability improvement
- [ ] New device support
- [ ] Art / icon assets
- [ ] Documentation
- [ ] Other:

## Devices tested

<!-- Aether runs on all CIQ round watch faces. Please cover both an AMOLED and a MIP panel. -->

- [ ] `fenix847mm` (454×454, AMOLED)
- [ ] `fenix8solar51mm` (280×280, MIP)

## Checklist

- [ ] `.\build.ps1 -Device <device>` compiles with no warnings
- [ ] Verified in the simulator in both active and Always-On / low-power modes
- [ ] Complications fill from live data and degrade gracefully when a value is
      unavailable (e.g. weather/HR → `--`)
- [ ] Layout holds on both AMOLED and MIP panels (no clipping at the round edge,
      secondary text stays legible on small MIP screens)
- [ ] Updated `README.md` if this is a user-facing change

## Screenshots

<!-- Before/after simulator screenshots for any visual change (see savescreenshot.ps1 if present). -->
