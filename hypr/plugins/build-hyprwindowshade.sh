#!/usr/bin/env bash
# Local Guix build of HyprWindowShade (Hyprland 0.56.0), pinned to the
# running compositor's store headers. No hyprpm, no /usr/include, no network.
#
# Repo: https://github.com/ManofJELLO/HyprWindowShade
# Local source: $HOME/.config/hypr/plugins/plugins-src/hyprwindowshade
set -euo pipefail

SOURCE="$HOME/.config/hypr/plugins/plugins-src/hyprwindowshade"
PLUGIN_DIR="$HOME/.local/share/hyprland/plugins"
PLUGIN_PATH="$PLUGIN_DIR/HyprWindowShade.so"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

# --- Resolve store paths by matching the running compositor commit --------
RUN_COMMIT=$(hyprctl version -j | grep -oP '(?<="commit": ")[0-9a-f]+')
[ -n "$RUN_COMMIT" ] || { echo -e "${RED}[Error] cannot read running hyprland commit${NC}"; exit 1; }

HYPRLAND=""
for d in /gnu/store/*-hyprland-0.56.0; do
  [ -d "$d" ] || continue
  vh="$d/include/hyprland/src/version.h"
  if [ -f "$vh" ] && grep -q "$RUN_COMMIT" "$vh"; then HYPRLAND="$d"; break; fi
done
[ -n "$HYPRLAND" ] || { echo -e "${RED}[Error] no hyprland store with commit $RUN_COMMIT${NC}"; exit 1; }
echo -e "[OK] compositor headers: $HYPRLAND (commit ${RUN_COMMIT:0:10})"

# --- Build dependency include dirs (verified store paths) -----------------
HYPRUTILS=/gnu/store/620v6cmxxqm7sv92p4643xiskyqdmhjc-hyprutils-0.13.1/include
LUA=/gnu/store/xd46xr7i26ir42gh6ixzghxnwh8vgd49-lua-5.5.0/include
MESA=/gnu/store/y915fdk2y6404zmz2jwk5fgwdf8nndq9-mesa-25.2.3
MESA_INC="$MESA/include"
MESA_LIB="$MESA/lib"
GLVND=/gnu/store/z46gk13zhg1lf63zzh7y0v52yg67m5x5-libglvnd-1.7.0/include
CAIRO=/gnu/store/qdxqidkv9s9ghznzf9l9r1dbh7960317-cairo-1.18.4/include
FREETYPE=/gnu/store/nyqw0rg6xa1c3vi5jjfxblmma6pcvgiq-freetype-2.13.3/include
LIBPNG=/gnu/store/hx885kw7pqi7x1hxyy1ig7v9py6577i5-libpng-1.6.39/include
PIXMAN=/gnu/store/zf1cvjcdy4ybx1c69s390lrhw3gjqjhx-pixman-0.46.4/include
LIBDRM=/gnu/store/vmwsdvihyb0xan175wcc9n8j7372l122-libdrm-2.4.124/include
LINUX=/gnu/store/m058c2xd0zpjk3ispxzsah58wl4q9zzj-linux-libre-headers-6.12.17/include
LIBINPUT=/gnu/store/yqiy6x5517jkkdbakkd445l9r5gk03xk-libinput-1.29.1/include
UDEV=/gnu/store/7wjir0lnfq6kljig7ajklkgcvnawzg6d-eudev-3.2.14/include
WAYLAND=/gnu/store/s7pdd7m9v62ik16chndn0hr46w1js3yr-wayland-1.25.0/include
HYPRGRAPHICS=/gnu/store/50pv75cza5rmv1s92m9m590v7f9k20vl-hyprgraphics-0.5.1/include
HYPRCURSOR=/gnu/store/34azp0h2n0sqj9x2ycgkyrhgr4hw4856-hyprcursor-0.1.13/include
HYPRLANG=/gnu/store/kzs87ig050mc77r2gcmm96pmy97lx6yn-hyprlang-0.6.8/include
AQUAMARINE=/gnu/store/0bvgiz1ai42p375c0di9517a8y70vb0q-aquamarine-0.12.1/include
GLSLANG=/gnu/store/6gq93jsak3q2kh6sv29mjfiln9bcvnhl-glslang-1.4.335.0/include
XKBCOMMON=/gnu/store/5vgzbnwaqaldacsrsxsprfi3nwsysghj-libxkbcommon-1.13.1/include

for D in "$HYPRUTILS" "$LUA" "$MESA" "$GLVND" "$CAIRO" "$FREETYPE" "$LIBPNG" "$PIXMAN" "$LIBDRM" "$LINUX" "$LIBINPUT" "$UDEV" "$WAYLAND" "$HYPRGRAPHICS" "$HYPRCURSOR" "$HYPRLANG" "$AQUAMARINE" "$GLSLANG" "$XKBCOMMON"; do
  [ -d "$D" ] || { echo -e "${RED}[Error] missing include dir: $D${NC}"; exit 1; }
done

INCLUDES=(
  -I"$HYPRLAND/include"
  -I"$HYPRLAND/include/hyprland"
  -I"$HYPRLAND/include/hyprland/src"
  -I"$HYPRLAND/include/hyprland/protocols"
  -I"$HYPRUTILS"
  -I"$LUA"
  -I"$MESA_INC"
  -I"$GLVND"
  -I"$CAIRO"
  -I"$FREETYPE"
  -I"$LIBPNG"
  -I"$PIXMAN"
  -I"$PIXMAN/pixman-1"
  -I"$LIBDRM"
  -I"$LIBDRM/libdrm"
  -I"$LINUX"
  -I"$LIBINPUT"
  -I"$UDEV"
  -I"$WAYLAND"
  -I"$HYPRGRAPHICS"
  -I"$HYPRCURSOR"
  -I"$HYPRLANG"
  -I"$AQUAMARINE"
  -I"$GLSLANG"
  -I"$XKBCOMMON"
)

# --- Build ----------------------------------------------------------------
cd "$SOURCE" || { echo -e "${RED}[Error] no plugin source at $SOURCE${NC}"; exit 1; }

hyprctl plugin unload "$PLUGIN_PATH" >/dev/null 2>&1 || true
sleep 1

g++ -shared -fPIC -O3 -std=c++23 *.cpp -o HyprWindowShade.so \
    "${INCLUDES[@]}" -L"$MESA_LIB" -lGLESv2 -lEGL -lGL

mkdir -p "$PLUGIN_DIR"
rm -f "$PLUGIN_PATH"
mv "$(pwd)/HyprWindowShade.so" "$PLUGIN_PATH"
echo -e "${GREEN}[OK] installed $PLUGIN_PATH${NC}"

hyprctl plugin load "$PLUGIN_PATH"
echo -e "${GREEN}[Success] HyprWindowShade live!${NC}"