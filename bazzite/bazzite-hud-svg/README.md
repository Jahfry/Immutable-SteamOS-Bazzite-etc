# Bazzite OSTree Status HUD - Installation Guide

This package installs a desktop HUD for Bazzite (KDE Plasma) that displays the currently booted OSTree version, kernel info, and layered packages. It updates automatically on boot, on a timer, and instantly whenever a system update occurs.

I didn't make this a full archive with installer, I'm just publishing something I used on my system with instructions on how to get it working. 

## File Manifest

Ensure you have the following files available:
*   [bazzite-hud-svg.sh](./bazzite-hud-svg.sh)
*   [bazzite-hud.service](./bazzite-hud.service)
*   [bazzite-hud.timer](./bazzite-hud.timer)
*   [bazzite-hud.path](./bazzite-hud.path)
*   [bazzite-hud-trigger.service](./bazzite-hud-trigger.service)
*   [bazzite-hud-trigger.path](./bazzite-hud-trigger.path)
*   [this README](./README.md)

NOTE: This will automatically update the display when the system detects a new upgrade has been staged / rebased, etc. However it will not update automatically when a metadata change has happened like pinning an ostree. It will be changed on the next reboot, after you manually run `bazzite-hud-svg.sh`, or after the 5 hour timer is up (you could always make the timer shorter, too).

---

Example image:

![bazzite-status.svg](https://github.com/Jahfry/Immutable-Linux-aka-SteamOS-Bazzite-etc/blob/main/bazzite-hud-svg/bazzite-status.svg)

---

## Step 1: User-Level Setup
*These steps do not require sudo.*

1.  **Install the Script**
    Copy `bazzite-hud-svg.sh` to your local bin directory and make it executable:
    ```bash
    mkdir -p ~/.local/bin
    cp bazzite-hud-svg.sh ~/.local/bin/
    chmod +x ~/.local/bin/bazzite-hud-svg.sh
    ```

2.  **Install User Systemd Units**
    Copy the three user-level units to the systemd config folder:
    ```bash
    mkdir -p ~/.config/systemd/user
    cp bazzite-hud.service ~/.config/systemd/user/
    cp bazzite-hud.timer ~/.config/systemd/user/
    cp bazzite-hud.path ~/.config/systemd/user/
    ```

3.  **Initialize the Relay File**
    Create the dummy file used to signal updates between the system and your user session. This ensures permissions are correctly set to your user:
    ```bash
    touch ~/.cache/bazzite-ostree-trigger
    ```

---

## Step 2: System-Level Setup
*These steps require sudo privileges to watch the boot partition.*

1.  **Install System Systemd Units**
    Copy the trigger units to the system directory:
    ```bash
    sudo cp bazzite-hud-trigger.service /etc/systemd/system/
    sudo cp bazzite-hud-trigger.path /etc/systemd/system/
    ```

---

## Step 3: Activation

1.  **Reload Systemd Daemons**
    Refresh both systemd instances to recognize the new files:
    ```bash
    systemctl --user daemon-reload
    sudo systemctl daemon-reload
    ```

2.  **Enable and Start User Units**
    This sets up the script to run on boot, on a timer, and when the relay file is touched:
    ```bash
    systemctl --user enable --now bazzite-hud.timer
    systemctl --user enable --now bazzite-hud.path
    ```

3.  **Enable and Start System Watcher**
    This sets up the root-level watcher to detect OS updates and touch the relay file:
    ```bash
    sudo systemctl enable --now bazzite-hud-trigger.path
    ```

4.  **Generate Initial Image**
    Run the script manually once to generate the first SVG file:
    ```bash
    ~/.local/bin/bazzite-hud-svg.sh
    ```

---

## Step 4: KDE Widget Setup

1.  Right-click the Desktop -> **Enter Edit Mode**.
2.  Add a **"Media Frame"** (or Picture Frame) widget to the desktop.
3.  **Configure the Widget:**
    *   **Path:** Browse to `~/Pictures/bazzite-status.svg`.
    *   **Refresh:** Set to a reasonable interval (e.g., 10 seconds) or leave default (it usually detects file changes automatically).
4.  **Appearance:**
    *   Attempt to set **Frame Style** or **Background** to "None" or "No Frame" to enable transparency.
    *   Resize the widget to be tall enough to display the full list.

---

## Verification

To verify the automation works, simulate a system update by creating a dummy file in the boot loader directory.

**Run this test command:**
```bash
sudo touch /boot/loader/entries/test-trigger.conf
```

Result:
Within a few seconds, the Last checked timestamp on your desktop widget should update to the current time.

Cleanup:

```
sudo rm /boot/loader/entries/test-trigger.conf
```
