#!/bin/sh

# Directory where you store local wallpaper videos
WALLPAPER_DIR="$HOME/.config/mpvpaper/"

# Predefined YouTube URLs (you can add as many as you like)
YOUTUBE_LINKS=$(cat <<EOF
https://www.youtube.com/live/jfKfPfyJRdk?si=HyGJH0l9M7WhXwta # lofi hip hop radio
EOF
)

# Combine local files + youtube links into one fzf menu
CHOICE=$( (find "$WALLPAPER_DIR" -type f; echo "$YOUTUBE_LINKS") | fzf --prompt="🎥 Pick your wallpaper: " )

# If nothing picked, just exit quietly
[ -z "$CHOICE" ] && exit 0

# Kill swww if running (avoid surface conflict)
pkill swww-daemon 2>/dev/null

# Kill any previous mpvpaper instance
pkill mpvpaper 2>/dev/null

# Determine if it's a YouTube URL or file
if echo "$CHOICE" | grep -q "http"; then
    VIDEO_URL=$(yt-dlp -g "$CHOICE")
else
    VIDEO_URL="$CHOICE"
fi

# Launch mpvpaper in the background
# no audio
#mpvpaper -o "--loop --no-audio --hwdec=no" eDP-1 "$VIDEO_URL" &
# audio
mpvpaper -o "--loop --hwdec=no" eDP-1 "$VIDEO_URL" &
