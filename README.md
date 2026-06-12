# Aether — Beautiful Garmin Watch Face

Aether is an elegant, modern, weather-first watch face for Garmin Connect IQ. Full reign was given to design a premium, information-rich experience that feels luxurious yet perfectly usable on both MIP and AMOLED displays (Fenix, Epix, Venu, Forerunner, etc.).

Weather is front and center because it matters to you. Everything else is thoughtfully arranged so you always have the information you need at a glance, with deep customization through the Garmin Connect app on your phone.

## Design Philosophy
- Clean, refined analog + digital hybrid
- Prominent, beautiful procedural weather icons + current temp + daily hi/lo
- Four highly customizable complication slots
- Multiple layout styles (Balanced, Weather Hero, Minimal Analog, Data Rich)
- Sophisticated color accents (Rose Gold, Arctic Teal, Ember, Midnight Gold, Forest, Lavender, Pearl, Solar)
- Background treatments including subtle horizon and weather-adaptive tinting
- Premium thin hands, elegant markers, jewel center cap
- Full AOD / burn-in protection support with intelligent shifting

## Key Features & Information Always Available
- Elegant analog hands (hour/minute + optional delicate second hand)
- Large digital time (optional)
- Date with subtle phone connection + notification indicators
- **Weather (always beautiful and prominent)**: Stylized sun/cloud/rain/snow/storm icons, live temperature (auto °C/°F), condition label, daily high/low from forecast
- Four flexible complication positions (top-left, top-right, bottom-left, bottom-right) with 20+ data options including:
  - Steps + progress ring
  - Heart rate (with heart icon)
  - Battery + solar when available
  - Body Battery, Stress, Recovery Time, Floors, Altitude, Barometer, Respiration, Active Minutes, Distance, Calories, Sunrise/Sunset, Notifications, Alarms, HR sparkline, and more
- Layout presets that change emphasis (especially Weather Hero puts the weather module center stage)
- Background styles: Pure Midnight, Subtle Horizon, Weather Adaptive

## Customization (Garmin Connect Phone App)
All settings live in the Garmin Connect (or Connect IQ) app under your installed watch faces:

- Show/hide seconds hand, digital time, date, weather
- Choose Layout Style
- Choose Background Style
- Pick from 8 beautiful accent color themes
- Independently configure each of the four complication slots

Changes apply instantly when you save in the phone app (onSettingsChanged triggers a refresh).

## Building & Running

### Prerequisites
- Garmin Connect IQ SDK (9.2+ recommended) via the official SDK Manager
- Java 11+ (the build script defaults to a common Android OpenJDK location; edit build_config.json if needed)
- PowerShell (included on Windows)

### Build
```powershell
# From the aether-watchface folder
.\build.ps1 -Device fenix8solar51mm
# or for packaging to .iq for the store
.\build.ps1 -Export
```

### Run in Simulator
```powershell
.\build.ps1 -Device fenix8solar51mm -Run
```

The script handles copying settings JSON so the simulator App Settings editor works correctly with your custom properties.

Common good test devices: `fenix8solar51mm`, `epix2pro51mm`, `venu3`, `fr965`, `fenix7`.

## Project Structure
- `source/AetherApp.mc` — App entry + settings change handling
- `source/AetherView.mc` — All drawing, data, weather, complications, AOD logic
- `resources/settings/` — properties.xml + settings.xml (drives the phone customization UI)
- `resources/strings/strings.xml` — All user-facing labels
- `resources/drawables/launcher_icon.svg` — The beautiful launcher icon
- `assets/` — Generated hero, screenshots, and store graphics
- `build.ps1` / `build_config.json` — Windows build & simulator helper (uses latest SDK)

## Store Assets Included
- Multiple high-quality preview renders (hero banner, balanced layout, Weather Hero layout, icon concepts)
- Use these (or regenerate similar) when submitting to the Connect IQ store.

## Permissions
- SensorHistory (for Body Battery, Stress, HR history)
- Positioning (for enhanced weather/sun data on supported devices)

Weather, activity, and most sensors work without extra user grants on modern watches.

## Tips for Best Experience
- On AMOLED watches (Fenix 8, Epix, Venu 3, etc.) enable AOD — Aether handles burn-in protection gracefully.
- Weather updates come from Garmin's on-device service (refreshed ~every 15 min when connected).
- Choose "Weather Hero" + "Weather Adaptive" background + your favorite accent for a truly special daily look.
- The four slots give you essentially "all the information" while staying elegant.

## License / Use
Free to use, modify, and submit as your own watch face. Credit is appreciated but not required.

Enjoy Aether — may your forecasts always be favorable and your watch always beautiful.

---

Built with love for weather-aware Garmin users who appreciate refined design.