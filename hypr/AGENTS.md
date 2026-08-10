# Hyprland Config — Agent Reference

Literate-adjacent modular Hyprland config: `hyprland.lua` requires per-feature modules under `modules/`. Guix System host.

## Config architecture
- **Entry:** `hyprland.lua` — just a list of `require("modules/...")`, loaded in order.
- **Module style:** each module calls the `hl.*` Lua API (Hyprland 0.56 Lua config). No shell `exec`, no dispatcher strings — use `hl.*` everywhere.
- **Layout:** `layout = "scrolling"` (`modules/general.lua`). Binds use `mod = "SUPER"`.
- **Terminal:** `com.mitchellh.ghostty` (`modules/programs.lua`). **Never use `kitty`.**
- Reload: `hyprctl reload`. Check errors: `hyprctl configerrors`. Lua syntax errors are silent-fail → always check `configerrors` after edits.

## Modules (`modules/*.lua`)
| File | Purpose |
|------|---------|
| `monitor.lua` | Monitor setup |
| `env.lua` | env vars (XDG, cursor theme `rose-pine-hyprcursor`, QT wayland plugins) |
| `programs.lua` | App paths — `terminal = "ghostty"` |
| `autostart.lua` | `hyprland.start` hook: **loads HyprWindowShade plugin**, awww-daemon+wallpaper, ghostty, hypridle, omarchy-tui-shell |
| `general.lua` | gaps, border size/color, decoration colors, layout `scrolling` |
| `decoration.lua` | rounding, opacity (0.80 active / 0.50 inactive), shadow, blur off |
| `animations.lua` | `hl.curve` (bezier/spring) + `hl.animation` per leaf. NOTE: `speed` here is LOW (2.5–4) = FAST. Higher values = SLOWER. |
| `misc.lua` / `input.lua` / `devices.lua` | misc, keyboard/input, devices |
| `binds.lua` | `mod=SUPER` binds + HyprWindowShade shader toggles at the bottom |
| `windowrules.lua` | Window rules incl. the HyprWindowShade **global shader tag** |
| `scrolling.lua` | Scrolling layout config |
| `mode_indicator.lua` | Mode indicator |
| `hyprglass.lua` | HyprGlass plugin config (static `hl.config`) — see plugin section |

## Animations (critical gotcha)
- `hl.animation({..., speed = N, ...})`: **low `speed` = fast**, high `speed` = slow. Current settings use 2.5–4 for snappy behavior.
- Spawn/kill "pop" is controlled by `windows` / `windowsIn` / `windowsOut` leaves via `style = "popin <pct>"`. This is the **native** open/close animation — do NOT expect the shader plugin to do this.
- `bezier` vs `spring`: springs have `mass/stiffness/dampening`. Higher dampening = less bounce = faster settle.

## HyprWindowShade plugin (per-window shaders)
- **Repo:** https://github.com/ManofJELLO/HyprWindowShade
- **Local source clone:** `plugins-src/hyprwindowshade/` (NOT `/tmp` — user loses stuff there; keep plugin sources in this dir)
- **Build script:** `build-hyprwindowshade.sh` in THIS dir — Guix-native, resolves store header paths, pins to the **running compositor commit**, compiles `*.cpp` → `.so`, installs to `~/.local/share/hyprland/plugins/HyprWindowShade.so`, and loads it. Rerun after any Hyprland upgrade (ABI pins to the commit).
- **Which store paths it needs:** hyprland (via commit match), hyprutils 0.13.1, lua 5.5.0, mesa (GLES2/EGL/GL), libglvnd, cairo, freetype, libpng, pixman (`/pixman-1`), libdrm (`/libdrm` + base), linux-libre headers, libinput, eudev, wayland, hyprgraphics, hyprcursor, hyprlang, aquamarine, glslang, libxkbcommon.

### What the plugin does / does NOT do
- **Does:** apply a GLSL fragment shader to **window content** (ripple, dim, glitch, grayscale) based on window tags, dispatchers, or Lua functions.
- **Does NOT:** create spawn/kill animations. The open/close "boom" is Hyprland's native `windows(In/Out)` animation, configured in `animations.lua`.

### How shaders are applied (two paths)
1. **Window rule tag** (`modules/windowrules.lua`) — global tag `+shader:/path` on every window. Plugin listens for `window.updateRules` and reads the tag.
2. **Lua functions** — `hl.plugin.HyprWindowShade.<fn>(args)` callable only inside config (NOT via `hyprctl dispatch`). Used in `binds.lua` toggles.

### Lua functions
- `togglewindowshader(path)` — toggle on focused window
- `toggleclassshader(class, path)` — toggle on all windows of a class
- `classshader(class, path)` / `togglelayershader(ns, path)` / `layershader(ns, path)`
- `reloadshaders()` — re-read `.glsl` from disk (not needed for ordinary edits; auto-reloads by mtime)

### Shader toggles (binds.lua, bottom)
- `SUPER + R` → reading/ripple shader (focused window)
- `SUPER + SHIFT + G` → grayscale (focused window)
- `SUPER + SHIFT + J` → glitch (focused window)
- `SUPER + SHIFT + K` → reading shader on all `com.mitchellh.ghostty` windows

### Shaders (`shaders/*.glsl`)
GLSL ES 3.20, interface: `in vec2 v_texcoord; out vec4 fragColor; uniform sampler2D tex;`. Available uniforms: `time`, `plugin_alpha`, `resolution`, `surface_size`, `mouse`, `is_active`, `is_floating`, `is_fullscreen`. All compile-verified with `glslangValidator -S frag`.
| File | Effect |
|------|--------|
| `reading_mode.glsl` | Horizontal ripple (`time`) + dims inactive windows (`is_active`) |
| `grayscale.glsl` | Static desaturation; full color when focused |
| `glitch.glsl` | Time-based random slice offsets + RGB channel swaps |

Validate a shader after edits (no `;` on GLSL reserved words like `active`):
```bash
/gnu/store/6gq93jsak3q2kh6sv29mjfiln9bcvnhl-glslang-1.4.335.0/bin/glslangValidator -S frag shaders/<name>.glsl
```

## HyprGlass plugin (Apple-style liquid glass on transparent windows)
- **Repo:** https://github.com/hyprnux/hyprglass (pinned commit `c96940a`, v0.7.0)
- **Build:** `build-hyprglass.sh` in THIS dir — same Guix approach as HyprWindowShade. Adds `-I"$LIBDRM/libdrm"` for `drm_fourcc.h`.
- **Loads:** `~/.local/share/hyprland/plugins/hyprglass.so`, loaded from `autostart.lua` alongside HyprWindowShade.

### Config mechanism — THE critical gotcha
- HyprGlass registers every value with **colon namespaced keys** (`plugin:hyprglass:glass_opacity` etc.) via `addConfigValueV2` (see `plugins-src/hyprglass/src/PluginConfig.cpp` `ConfigKeys`).
- **Configure it with a STATIC top-level `hl.config({ plugin = { hyprglass = { ... } } })` in `modules/hyprglass.lua`** — same style as every other module. This parses at load/reload time and values persist (`getoption` shows `set: true`).
- **DO NOT** configure it via `hl.plugin.hyprglass.config({...})` inside a `hyprland.start` handler. That wrapper flattens keys to dots (`plugin.hyprglass.glass_opacity`) that do NOT match the registered colon keys, only runs at boot (not on reload), and values stay at defaults (`set: false`). This was the bug that made it "not work".
- Plugin Lua functions `hyprglass.preset` / `hyprglass.layer` / `hyprglass.config` exist, but the static `hl.config` form is what to use for ordinary settings.
- **Verify persistence:** `hyprctl getoption plugin:hyprglass:glass_opacity` → should show your value AND `set: true`. `default_preset`/`default_theme` accept strings.

### Useful keys (global level)
`enabled` (int), `manage_window_blur` (int), `default_theme` ("dark"/"light"), `default_preset`, `glass_opacity` (0–1, lower = more transparent), `blur_strength`, `blur_iterations`, `refraction_strength`, `chromatic_aberration`, `fresnel_strength`, `specular_strength`, `edge_thickness`, `lens_distortion`, `tint_color` (hex int), `brightness`, `contrast`, `saturation`, `vibrancy`, `adaptive_dim`, `adaptive_boost`. Theme overrides under `dark:`/`light:` and layer-surface keys under `layers:` namespaces (all in `PluginConfig.hpp`).

### Current values
`glass_opacity = 0.75` (more transparent glass was requested), `default_preset = "clear"`, theme `dark`, opacity/blur/chroma/specular mods tuned in `modules/hyprglass.lua`.

## Other files
- `hypridle.conf` — idle/suspend config
- `build-hyprwindowshade.sh` — see plugin section
- `build-hyprglass.sh` — see HyprGlass section

## Common tasks
- **Add a new shader:** create `shaders/x.glsl`, compile-verify it, add a toggle in `binds.lua`. Window rule auto-applies if tagged.
- **Change open/close pop:** edit `windows`/`windowsIn`/`windowsOut` in `animations.lua`.
- **After a Hyprland upgrade:** run `./build-hyprwindowshade.sh` to rebuild the plugin against the new commit.
- **Always check** `hyprctl plugins list` (plugin loaded) and `hyprctl configerrors` (no Lua errors) after changes.