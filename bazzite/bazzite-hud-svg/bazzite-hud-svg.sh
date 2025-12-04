#!/bin/bash

# ==============================================================================
# Bazzite HUD SVG Generator
# Generates an SVG displaying rpm-ostree status for desktop widgets.
# Source: https://github.com/Jahfry/Immutable-SteamOS-Bazzite-etc/tree/main/bazzite/bazzite-hud-svg
# ==============================================================================

# --- CONFIGURATION ---
HUD_DIR="$HOME/Pictures/Wallpapers/bazzite-hud"
mkdir -p "$HUD_DIR"
OUTPUT_FILE="${HUD_DIR}/status.svg"

# Colors
C_TITLE="#ffffff"     # White
C_SUBTITLE="#aaaaaa"  # Light Grey
C_INFO="#ffcc00"      # Yellow
C_BOOTED="#55ff55"    # Green
C_PENDING="#ff5555"   # Red
C_OTHER="#999999"     # Grey
C_LAYERS="#ffcc00"    # Yellow
C_PINNED="#ffffff"    # White

# --- SYSTEM DATA ---
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# --- PARSING LOGIC ---
RAW_STATUS=$(/usr/bin/rpm-ostree status)

SVG_CONTENT=""
Y_POS=190 
LINE_HEIGHT=36
GAP_HEIGHT=45

CURRENT_TYPE=""
CURRENT_VER=""
CURRENT_DATE=""
CURRENT_LAYERS=""
CURRENT_PINNED=0
IS_FIRST=1

flush_block() {
    if [ -z "$CURRENT_VER" ]; then return; fi
    if [[ "$CURRENT_TYPE" == "BOOTED" ]]; then
        COLOR="$C_BOOTED"
        LABEL="➤ BOOTED:"
    elif [[ "$CURRENT_TYPE" == "STAGED" ]]; then
        COLOR="$C_PENDING"
        LABEL="⚠️ STAGED:"
    else
        COLOR="$C_OTHER"
        LABEL="  BACKUP:"
    fi
    SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='22' font-weight='bold' fill='${COLOR}' xml:space='preserve'>${LABEL} ${CURRENT_VER}</text>"
    Y_POS=$((Y_POS + LINE_HEIGHT))
    SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_SUBTITLE}' xml:space='preserve'>  Date:   ${CURRENT_DATE}</text>"
    Y_POS=$((Y_POS + LINE_HEIGHT))
    if [ -n "$CURRENT_LAYERS" ]; then
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_LAYERS}' xml:space='preserve'>  Layers: ${CURRENT_LAYERS}</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    else
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='#555555' xml:space='preserve'>  Layers: (None)</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    fi
    if [ "$CURRENT_PINNED" -eq 1 ]; then
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_PINNED}' xml:space='preserve'>  ● pinned</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    fi
    Y_POS=$((Y_POS + GAP_HEIGHT))
}

while IFS= read -r line; do
    clean_line=$(echo "$line" | xargs)
    if [[ "$line" == *"ostree-image"* ]]; then
        flush_block
        CURRENT_VER=""
        CURRENT_DATE=""
        CURRENT_LAYERS=""
        CURRENT_PINNED=0
        if [[ "$line" == *"●"* ]]; then CURRENT_TYPE="BOOTED"; IS_FIRST=0
        elif [ $IS_FIRST -eq 1 ]; then CURRENT_TYPE="STAGED"; IS_FIRST=0
        else CURRENT_TYPE="ROLLBACK"; fi
    fi
    if [[ "$clean_line" == Version:* ]]; then
        CURRENT_VER=$(echo "$clean_line" | awk '{print $2}')
        CURRENT_DATE=$(echo "$clean_line" | cut -d'(' -f2 | cut -d')' -f1 | cut -d'T' -f1)
    fi
    if [[ "$clean_line" == LayeredPackages:* ]]; then
        CURRENT_LAYERS=$(echo "$clean_line" | sed 's/LayeredPackages: //')
    fi
    if [[ "$clean_line" == "Pinned: yes" ]]; then CURRENT_PINNED=1; fi
done <<< "$RAW_STATUS"
flush_block

# --- DIRECT WRITE ---
cat > "$OUTPUT_FILE" <<EOF
<svg width="600" height="950" xmlns="http://www.w3.org/2000/svg">
<!-- 
  Bazzite HUD SVG Generator
  Source: https://github.com/Jahfry/Immutable-SteamOS-Bazzite-etc/tree/main/bazzite/bazzite-hud-svg
-->
  <text x="15" y="50" font-family="monospace" font-weight="bold" font-size="32" fill="${C_TITLE}">ostree status</text>
  <text x="15" y="80" font-family="monospace" font-size="16" fill="${C_SUBTITLE}">last checked: ${TIMESTAMP}</text>
  <line x1="15" y1="95" x2="585" y2="95" stroke="${C_SUBTITLE}" stroke-width="1" />
  <text x="15" y="125" font-family="monospace" font-size="18" fill="${C_INFO}" xml:space='preserve'>Host: ${HOSTNAME}    Kernel: ${KERNEL}</text>
  <line x1="15" y1="145" x2="585" y2="145" stroke="${C_SUBTITLE}" stroke-width="1" />
  ${SVG_CONTENT}
</svg>
EOF

# --- CLEANUP ---
# Remove any leftover rotation files
find "$HUD_DIR" -name "status-*.svg" -type f -not -name "status.svg" -delete

# --- FEEDBACK ---
echo "===================================================="
echo "Bazzite HUD Generation Complete"
echo "----------------------------------------------------"
echo "Output: $OUTPUT_FILE"
echo "Status: Updated on disk."
echo "Widget: Will refresh on next poll."
echo "===================================================="
