    
#!/bin/bash

# ostree desktop message ... displayed in KDE "Media Frame" widget
# files:
# ~/.local/bin/bazzite-hud-svg.sh
#
# User Units (Execution & Listening):
# ~/.config/systemd/user/bazzite-hud.service
# ~/.config/systemd/user/bazzite-hud.timer
# ~/.config/systemd/user/bazzite-hud.path
# ~/.cache/bazzite-ostree-trigger  (Relay file)
#
# System Units (Detection & Signaling):
# /etc/systemd/system/bazzite-hud-trigger.path
# /etc/systemd/system/bazzite-hud-trigger.service
#
# Output:
# ~/Pictures/bazzite-status.svg

# --- CONFIGURATION ---
OUTPUT_FILE="$HOME/Pictures/bazzite-status.svg"

# Colors
C_TITLE="#ffffff"
C_SUBTITLE="#aaaaaa"
C_INFO="#ffcc00"      # Yellow
C_BOOTED="#55ff55"    # Green
C_PENDING="#ff5555"   # Red
C_OTHER="#999999"     # Grey
C_LAYERS="#ffcc00"    # Yellow
C_PINNED="#ffffff"    # White (For the pinned indicator)

# --- SYSTEM DATA ---
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# --- SVG INIT ---
# Canvas width 600 (Constrained) vs Height 950 (Tall)
SVG_CONTENT=""
Y_POS=190 
LINE_HEIGHT=36  # Spacing for larger text
GAP_HEIGHT=45   # Spacing between entries

# --- PARSING FUNCTION ---
RAW_STATUS=$(rpm-ostree status)

# Variables to hold current block data
CURRENT_TYPE=""
CURRENT_VER=""
CURRENT_DATE=""
CURRENT_LAYERS=""
CURRENT_PINNED=0
IS_FIRST=1

# Helper function to flush a block to SVG text
flush_block() {
    if [ -z "$CURRENT_VER" ]; then return; fi

    # Determine Color and Label based on type
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

    # 1. Version Line (Font 22 - Large relative to canvas)
    SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='22' font-weight='bold' fill='${COLOR}' xml:space='preserve'>${LABEL} ${CURRENT_VER}</text>"
    Y_POS=$((Y_POS + LINE_HEIGHT))

    # 2. Date Line (Font 18)
    SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_SUBTITLE}' xml:space='preserve'>  Date:   ${CURRENT_DATE}</text>"
    Y_POS=$((Y_POS + LINE_HEIGHT))

    # 3. Layers (Font 18)
    if [ -n "$CURRENT_LAYERS" ]; then
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_LAYERS}' xml:space='preserve'>  Layers: ${CURRENT_LAYERS}</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    else
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='#555555' xml:space='preserve'>  Layers: (None)</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    fi

    # 4. Pinned Status (Font 18, only appears if pinned)
    if [ "$CURRENT_PINNED" -eq 1 ]; then
        SVG_CONTENT="${SVG_CONTENT}<text x='15' y='${Y_POS}' font-family='monospace' font-size='18' fill='${C_PINNED}' xml:space='preserve'>  ● pinned</text>"
        Y_POS=$((Y_POS + LINE_HEIGHT))
    fi

    # 5. Spacer
    Y_POS=$((Y_POS + GAP_HEIGHT))
}

# --- MAIN LOOP ---
while IFS= read -r line; do
    clean_line=$(echo "$line" | xargs)

    # DETECT NEW BLOCK
    if [[ "$line" == *"ostree-image"* ]]; then
        flush_block
        CURRENT_VER=""
        CURRENT_DATE=""
        CURRENT_LAYERS=""
        CURRENT_PINNED=0
        
        if [[ "$line" == *"●"* ]]; then
            CURRENT_TYPE="BOOTED"
            IS_FIRST=0
        elif [ $IS_FIRST -eq 1 ]; then
            CURRENT_TYPE="STAGED"
            IS_FIRST=0
        else
            CURRENT_TYPE="ROLLBACK"
        fi
    fi

    # PARSE VERSION
    if [[ "$clean_line" == Version:* ]]; then
        CURRENT_VER=$(echo "$clean_line" | awk '{print $2}')
        CURRENT_DATE=$(echo "$clean_line" | cut -d'(' -f2 | cut -d')' -f1 | cut -d'T' -f1)
    fi

    # PARSE LAYERS
    if [[ "$clean_line" == LayeredPackages:* ]]; then
        CURRENT_LAYERS=$(echo "$clean_line" | sed 's/LayeredPackages: //')
    fi

    # PARSE PINNED STATUS
    if [[ "$clean_line" == "Pinned: yes" ]]; then
        CURRENT_PINNED=1
    fi

done <<< "$RAW_STATUS"

# Flush final block
flush_block

# --- WRITE SVG FILE ---
cat > "$OUTPUT_FILE" <<EOF
<svg width="600" height="950" xmlns="http://www.w3.org/2000/svg">

  <!--
ostree desktop message ... displayed in KDE "Media Frame" widget
files:
~/.local/bin/bazzite-hud-svg.sh

User Units (Execution & Listening):
~/.config/systemd/user/bazzite-hud.service
~/.config/systemd/user/bazzite-hud.timer
~/.config/systemd/user/bazzite-hud.path
~/.cache/bazzite-ostree-trigger  (Relay file)

System Units (Detection & Signaling):
/etc/systemd/system/bazzite-hud-trigger.path
/etc/systemd/system/bazzite-hud-trigger.service

Output:
~/Pictures/bazzite-status.svg
    -->

  <!-- Header Section -->
  <text x="15" y="50" font-family="monospace" font-weight="bold" font-size="32" fill="${C_TITLE}">ostree status</text>
  <text x="15" y="80" font-family="monospace" font-size="16" fill="${C_SUBTITLE}">last checked: ${TIMESTAMP}</text>
 
  <!-- Separator 1 -->
  <line x1="15" y1="95" x2="585" y2="95" stroke="${C_SUBTITLE}" stroke-width="1" />
 
  <!-- Info Row (Host + Kernel combined) -->
  <!-- We use xml:space='preserve' so the 4 spaces are respected -->
  <text x="15" y="125" font-family="monospace" font-size="18" fill="${C_INFO}" xml:space='preserve'>Host: ${HOSTNAME}    Kernel: ${KERNEL}</text>

  <!-- Separator 2 -->
  <line x1="15" y1="145" x2="585" y2="145" stroke="${C_SUBTITLE}" stroke-width="1" />

  <!-- Deployment List -->
  ${SVG_CONTENT}

</svg>
EOF

  
