# 'keyd' on the Steam Deck

## Changelog:

* 2025-06-30 - Fixed some typos and paths, **verified still working on newer SteamOS**
* 2024-07-09 - Initial post


**NOTES:** 

* This is guide is *long* to help people newer to modifying their Steam Deck. Sorry for the folks that just want the nitty gritty, I'd rather just write 1 guide :) And I want to be able to completely redo my procedure if I need to at some random point in the forgetful future. 
* This WILL break whenever SteamOS decides to update or refresh it's install image. This is the pain of immutable distributions (which have many benefits). Whenever it stops working, you'll need to redo the steps starting with 'sudo steamos-readonly disable' through 'sudo steamos-readonly enable' to get it working again.
* This guide is **not** going to be fully plug-and-play, you will need some ability to adapt it to your system. 

***Don't go any farther*** unless you are comfortable with running Linux terminal commands. Running commands like this is gives *you* responsibility for fixing any mistakes. This guide is *meant for people who don't mind tinkering with Linux*.

* *What are we doing?* Installing 'keyd' on a Steam Deck. 
* *Why are we doing that?* So you can remap keys on a physical USB keyboard and have it work *both in Game and Desktop mode*. 

* **The Main Problem?** 'keyd' only comes in source code so you'll need to set up your Steam Deck to compile the program first.

***Warning***: Updating SteamOS will overwrite the compiler packages we need to update to do the compiling. I'm not sure if that will affect the 'keyd' binary or not after an update, **but it probably will**. If so you will *need to repeat this process after SteamOS updates*. 

**I'll try to remember to edit this section after the next SteamOS update to answer whether you'll have to do this,** but I think it is a safe assumption. 

***Why is Game Mode important?*** Simply put ... frames per second. For me World of Warcraft gets 50% more FPS in Game Mode than in Desktop Mode. 

---

And for a bit more background ... this isn't my main gaming rig. But I've been spending extended periods away from home helping with family issues in another state. This process helps me mimic my home rig setup (which has a programmable keyboard and access to Windows configuration software). However, it's proving effective enough that figuring out this process helps me with one of the last hurdles I needed to ditch Windows in the near future. 

---

*Alternatives?* 
   * 'kmonad'
      * Can be installed without needing to write to the readonly portion of SteamOS, so it works through updates without needing to be fixed
      * Only works in Desktop mode (maybe could work in Game mode but not without a lot of finessing)
      * Is harder to configure, at least for me
      * Comes in binary form (good) but required a very old version when I had it running a year ago
      * **NOTE:** I nuked the install that worked with 'kmonad' and forgot to document it so unfortunately (at least for now) I don't have a guide for that

## 0. Prep work for compiling 'keyd' on the Steam Deck

* Go into your Steam Deck's "Desktop" mode and connect a USB keyboard. You're not going to want to do this guide with the virtual keyboard.
* For most of this document you'll be working in a Konsole terminal window. Go ahead and open it now.
* If your Steam Deck doesn't have a root password, set one now via `passwd`
  * if you really really don't want a password later on, you can use `passwd -d` after this document to remove it
  * Since you will likely have to redo this after an update ... well ... just keep your password set.
  * If I find a way to set up 'keyd' locally instead of system wide I will update this document, but as it requires systemd to run in Game mode, that probably won't be the case.
  * ***IMPORTANT NOTE:***
     * ***Write this password down / store it in a way you can't lose.***
     * There are ways to recover your password without resetting your Steam Deck to factory but I'm **not** going to be tech support!
* Set your SteamOS to be writable so that following commands will work (we will go back to read only when 'keyd' is installed):
  `sudo steamos-readonly disable`
* Initialize 'pacman' via: 
```
sudo pacman-key --init
sudo pacman-key --populate archlinux
```
* Tell pacman to trust ALL sources (temporary, we'll switch it back after). 
   * This comes from a hint on [this issue](https://github.com/malordin/steamdeck-samba-server/issues/4) where it appears that SteamOS does not ship with complete packages for headers/glibc/base-devel.
   * Edit '/etc/pacman.conf'
      * Use whatever editor you like, example: `sudo nano /etc/pacman.conf` (all of my commands will be for nano, swap if you want)
      * Originally:
        
         > SigLevel    = Required DatabaseOptional
         
      * *Change that to this:*
         ```
         #SigLevel    = Required DatabaseOptional
         SigLevel = TrustAll
         ```
      * Save the file
* Install/repair the compiler/headers needed to compile 'keyd':
  
   `sudo pacman --sync --noconfirm base-devel glibc linux-api-headers`

* **IF** the above command executed properly, do this step. *If you saw errors and nothing was installed, pause this guide now to try and figure out what happened until the step above executes properly*. 
   * Remove the 'TrustAll' so that pacman requires trust again:
 
     `sudo nano /etc/pacman.conf`
     
      * Currently:
         ```
         #SigLevel    = Required DatabaseOptional
         SigLevel = TrustAll
         ```
      * *Change that to this:*
         ```
         SigLevel    = Required DatabaseOptional
         #SigLevel = TrustAll
         ```
      * Save the file

## 2. Download, make and install 'keyd'

These instructions are taken from [the keyd github README](https://github.com/rvaiya/keyd?tab=readme-ov-file#installation). I'm repeating them here with some tweaks (but go read that link to learn about keyd). 

* First, decide where you want to store the source code. I made a directory named '~home/Documents/source'.

  If you want the same directory, do the following. Otherwise adapt the command to your chosen directory:
  
  `mkdir ~/Documents/source; cd ~/Documents/source`

* Now clone, build and install 'keyd':

```
git clone https://github.com/rvaiya/keyd
cd keyd
make && sudo make install
sudo systemctl enable keyd && sudo systemctl start keyd
```

## 3. Set your Deck back to 'readonly'

'readonly' can't be on before this point because the 'make install' above needs to write for the last step above. Now that that is done, set it back to readonly: 

`sudo steamos-readonly enable`

## 4. Start remapping keys

Much of the following is also taken directly from [GitHub - rvaiya/keyd: A key remapping daemon for linux.](https://github.com/rvaiya/keyd?tab=readme-ov-file#installation)

* Create the file '/etc/keyd/default.conf'

  `sudo nano /etc/keyd/default.conf`

  and paste in these Contents:
  
  ```
  [ids]
  
  *
  
  [main]
  
  # Maps capslock to escape when pressed and control when held.
  capslock = overload(control, esc)
  
  # Remaps the escape key to capslock
  esc = capslock
  ```

  * This is the default example from the keyd github. We'll be customizing it later for the Deck. 
  * This config will remap your 'escape' key to be 'capslock'. Your capslock key becomes 'escape' when quickly pressed or 'control' if held down. 
* **'keyd' won't do this remapping until you reload it**. If you are ready to swap your escape and capslock keys for testing, do this:

  `sudo keyd reload`

* To revert back to your normal keyboard layout:
  
  `sudo nano /etc/keyd/default.conf`
  
  then comment out the "capslock" and "esc" lines (add a # at the beginning of those lines), save the file, and then:
  
  `sudo keyd reload`

* Your keyboard should be back to normal operation but you have a skeleton file ready for remapping. 
* **If you ever create a bad mapping that prevents you from using your keyboard:** 

   * hold *'backspace' + 'enter' + 'escape'* at the same time to kill the keyd process.
   * Edit your conf file again to fix whatever happened and run keyd again:

     `sudo systemctl start keyd`.

* If you aren't sure what the name of the key you need to remap is, you can watch key events via `sudo keyd monitor`. If you want time stamps, use `sudo keyd monitor -t`.
  * **If keyd daemon is running**, the output of 'monitor' will show the **remapped** keys.
  * To see the keys without remapping just stop keyd (`sudo systemctl stop keyd` or hold 'backspace+enter+escape`) and run
    
    `sudo keyd monitor`

* For more information on using the 'keyd' main program:
   * `keyd --help` or
   * `man keyd` for more details

## 5. Basic Steam Deck configuration

The volume and power buttons on the Steam Deck are handled through a keyboard device. *We don't want keyd to bind to those buttons*, so we're going to blacklist that device from keyd. 

* If you don't do this, the buttons can give different behaviors compared to a stock Steam Deck
* **Example:** *in Game mode you won't be able to hold down the "Power" button to bring up the menu that allows you to switch to Desktop mode* (you can still get there via the Steam Button > Power, but, let's keep things normal)

* **TLDR;** (just fix it)
  * edit '/etc/keyd/default.conf'
  
    `sudo nano /etc/keyd/default.conf`
  
  * Contents: Change the [ids] section to match this (replace the section between [ids] and [main], don't change [main] yet):
```
[ids]
# This section determines which devices 'keyd' will be able to remap.
# First line "*" tells 'keyd' to bind to ALL devices EXCEPT:
#   * Devices blacklisted via "-" lines in this config file
#   * Devices specifically bound in separate config files
*
# Place devices you DON'T want keyd to remap below.
#   * format example: -<vendor id>:<product id>
#   * "-" at the beginning blacklists the device from keyd
#   * see `man keyd` section on [ids] for more info
# Device: Steam Deck 'AT Translated Set 2 keyboard' - volume and power buttons
-0001:0001
```

   (read the comments in the section above to understand what is going on)

  * stop keyd so you can use 'keyd monitor' to see the base devices instead of the remapped keyd device:
    
    `sudo systemctl`
  
  * `keyd monitor`
     * While this command is running, press your "volume up" button.
     * You should see:
       
        > AT Translated Set 2 keyboard    0001:0001:a38e6885      volumeup down
     
        > AT Translated Set 2 keyboard    0001:0001:a38e6885      volumeup up

      * Read this as:
        
         > [device name]   [vendor id]:[product id]:[? not needed ?]   [key name]   [up or down]
         
      * If 'keyd' were running **AND** you had ***not*** *blacklisted the Steam Deck keypad buttons in [ids] above*, you would instead see:
   
        > keyd virtual keyboard   0fac:0ade:efba1ddf      volumeup down
        
        > keyd virtual keyboard   0fac:0ade:efba1ddf      volumeup up

* At this point you have a config file you can use to remap keys without affecting your Steam Deck volume/power buttons and an example of how to remap Escape and Control.
* If you only have 1 USB device (or multiple but without the same keys on each) you can just modify the existing 'default.conf' rather than using the rest of my configs below.
* *If you have a 'default.conf' (bound to "*" all devices)* **BUT** *also have other configs (like I do below) that bind to individual devices*, ***those individual devices won't be affected by 'default.conf'***
   * Just be aware of this.
   * My recommendation is to keep the 'default.conf' for future flexibility, but make very specific mappings go in to separate conf files as shown in the next section.
   * *Example:*
      * 'default.conf' binds to * and changes "Escape" to be "CapsLock"
      * 'keyboard.conf' binds specifically to a keyboard "1001:2002"
      * *No mappings in 'default.conf' will apply to the keyboard "1001:2002"*, **but** ***WILL*** apply to any other keyboard that is connected (unless it also is bound in a different config file). 

* *If you have multiple devices with the same keys and want to map them separately*, keep reading the next section.  
* For more information on remapping:
   *  [GitHub - rvaiya/keyd: A key remapping daemon for linux.](https://github.com/rvaiya/keyd?tab=readme-ov-file)
   *  `man keyd`

## 6. My Steam Deck configuration

* The goal for my keyboard remapping is, well, unusual.
   * I use a numpad on the *left* side of my keyboard for playing World of Warcraft and use it for all class abilities
   * To make it more useful I need to remap some of the numpad keys (like numpadEnter and numLock) so that I can use them for actions in WoW.
   * My numpad ALSO has a row of keyboard keys (Escape, Tab, Backspace) that I want to remap without affecting the TKL keyboard
   * To accomplish all of this I use multiple conf files, with examples of how to create them below
* Get a list of all plugged in USB device IDs. Since this will be different for other models of keyboards/numpads (ie, you can't just use my config unless you own the same devices) I'll detail that process:
   * `sudo systemctl stop keyd` # so we see the raw device IDs with monitor
   * `sudo keyd monitor` # see what devices are being pressed
   * Press a key on each device we want to configure. Examples below for my 3 devices:
      * Phantom RGB USB Keyboard:
         > SONIX USB DEVICE        320f:5064:dfa388ad      d up
      * Damoshark USB Numpad:
         > Gaming Keyboard 0416:c345:475be355      numlock down
      * Roccat Kone Aimo USB Mouse:
         > ROCCAT ROCCAT Kone Aimo 16K Mouse       1e7d:2e2c:f891b7cd      leftmouse down
* Create a config file for each device separately.
   * These configs are stored in '/etc/keyd/`
      * There is no need to remove '/etc/keyd/default.conf'
      * if you wanted you could also use that for global key remaps that affect all devices (except the Steam Deck buttons that we blacklisted)
      * Files in '/etc/keyd' should all be loaded when 'keyd' starts
   * In the following commands I'm using generic device types for the file names, feel free to edit the names.
     ```
     sudo touch /etc/keyd/keyboard.conf
     sudo touch /etc/keyd/numpad.conf
     sudo touch /etc/keyd/mouse.conf
     ```
* Add initial contents for each of the conf files next.
   * **You need to change your [vendor id]:[product id] here using what you found via `sudo keyd monitor` above.** The examples below match *my* devices.
   * For now the [main] sections remain empty, so nothing is remapped in this step
   * Keyboard:

     `sudo nano /etc/keyd/keyboard.conf`

     * Contents:
        ```
        [ids]
        # Device:
        #    * Product: Phantom RGB Keyboard
        #    * `keyd monitor` name: SONIX USB DEVICE
        320f:5064
        
        # NOTES:
        #    * This will prevent 'default.conf' from applying mappings to this device
        #    * Don't use "-" at the beginning of this line as "-" _prevents_ binding
        
        [main] 
        ```
   * Numpad:

     `sudo nano /etc/keyd/numpad.conf`

     * Contents:
        ```
        [ids]
        # Device:
        #    * Product: Damoshark USB Numpad
        #    * `keyd monitor` name: Gaming Keyboard
        0416:c345
        
        # NOTES:
        #    * This will prevent 'default.conf' from applying mappings to this device
        #    * Don't use "-" at the beginning of this line as "-" _prevents_ binding
        
        [main] 
        ```
   * Mouse:

     `sudo nano /etc/keyd/mouse.conf`

     * Contents:
        ```
        [ids]
        # Device:
        #    * Product: Roccat Kone Aimo mouse
        #    * `keyd monitor` name: ROCCAT ROCCAT Kone Aimo 16K Mouse
        1e7d:2e2c
        
        # NOTES:
        #    * This will prevent 'default.conf' from applying mappings to this device
        #    * Don't use "-" at the beginning of this line as "-" _prevents_ binding
        
        [main] 
        ```
* This is where the configuration gets *very specific* to my needs.
   * **You can stop here** to create your own configurations, all the breadcrumbs are in place
   * Just consider this an advanced *example* and modify to suit you.
* Specifically I want this to happen when I press **Numpad** (not Keyboard) keys:

   | Numpad Key Pressed  | Key Sent | Notes |
   | ------------------- | -------- | -------- |
   | Escape | \ | (top extra row) |
   | Tab | [ | (top extra row) |
   | Backspace | ] | (top extra row) |
   | | |
   | numLock | ; | (locked ON, state shouldn't toggle) |
   | / | / | (*no change*) |
   | * | * | (*no change*) |
   | - | - | (*no change*) |
   | | |
   | numpad 7/Home | numpad 7 | (**always send as NumLock ON**) |
   | numpad 8/ArrowUp | numpad 8 | (**always send as NumLock ON**) |
   | numpad 9/PgUp | numpad 9 | (**always send as NumLock ON**) |
   | numpad + | numpad + | (*no change*) |
   | | |
   | numpad 4/ArrowLeft | numpad 7 | (**always send as NumLock ON**) |
   | numpad 5 | numpad 5 | (*no change*) |
   | numpad 6/ArrowRight | numpad 6 | (**always send as NumLock ON**) |
   | numpad Enter | ' | (Enter by default opens chat, bad) |
   | | |
   | numpad 0/Ins | numpad 0 | (**always send as NumLock ON**) |
   | numpad ./Del | numpad . | (**always send as NumLock ON**) |

* With the above properly mapped I can bind those keys in WoW to work like a macro pad with action bars
* That does mean when I press these keys ( *\*, *[*, *]*, *;*, *'* ) on the keyboard they will activate WoW actions, but that's not something that bothers me
* Like I said, this configuration is *very specific to my uses* :)
* The [main] section in makes things work like mapped above, all put together this is my complete 'numpad.conf':

  `sudo nano /etc/keyd/numpad.conf`

  Contents:
  
   ```
   [ids]
   # Device:
   #    * Product: Damoshark USB Numpad
   #    * `keyd monitor` name: Gaming Keyboard
   0416:c345
   
   # NOTES:
   #    * This will prevent 'default.conf' from applying mappings to this device
   #    * Don't use "-" at the beginning of this line as "-" _prevents_ binding
   #    * You can have multiple Devices configured in a file, but if there were
   #    * 2 keyboard devices here (like to use the keyboard "Pause" key to switch layers)
   #    * other remappings would apply to BOTH devices. In my WoW case this is bad.
   
   [main]
   
   # numpad "backspace" when MACROPAD is NOT active will activate it and turn on numlock
   # will remain as MACROPAD until backspace is HELD for 2 seconds
   #    * this configuration is specific to a numpad with a backspace key ... modify the procedure
   #      for a traditional numpad. 
   #    * Switching to numlock might work but in WoW I use that key for
   #      long cooldowns and don't want to risk a misfire :)
   backspace = togglem(MACROPAD,numlock)
   
   [MACROPAD]
   
   # numpad "backspace" when MACROPAD IS active will deactivate MACROPAD and numlock
   # when HELD for more than 2 seconds 
   #    * Allows use of the numpad normally except for "backspace" key, which I never use
   #    * see note in [main] on switching the key if using a different
   #      numpad that does not have a "backspace" key.
   backspace = timeout(], 2000, togglem(MACROPAD,numlock))
   
   # other keys to remap for WoW binding
   esc = \
   tab = [
   numlock = ;
   kpenter = '
   
   # The rest of the numpad is not remapped, BUT ... 
   # NOTE: numlock needs to be ON for my WoW bindings to work
   #    * ideally we'd set numlock ON by default at boot but Game mode has a problem there
   #    * follow https://github.com/rvaiya/keyd/issues/790 to see if any responses
   ```
* **EXTRA** ... modify "capslock" on the **keyboard** to fire a macro
   * I'm not going to go too far into explaining why I might do this in WoW, you'll get the idea
   * You can extend this to press MANY keys in succession

   `sudo nano /etc/keyd/keyboard.conf`
   * Contents:
      ```
      [ids]
      # Device:
      #    * Product: Phantom RGB Keyboard
      #    * `keyd monitor` name: SONIX USB DEVICE
      # NOTE: This will prevent 'default.conf' from applying mappings to this device
      320f:5064
      
      [main]
      
      # * keyboard "pause" when WOWMACRO is NOT active will activate it
      # * will remain as WOWMACRO until pause is HELD for 2 seconds
      # * does not actually use the numpad, just emulates
      # * numlock is set ON through when turning on the numpad macro
      #   (in other conf file) and is a shared state so don't set it here
      # pause = togglem(WOWMACRO,numlock)
      #   ... instead do this:
      pause = toggle(WOWMACRO)

      # OPTIONAL, uncomment if you also hate "capslock" in daily life:
      #capslock = noop
      
      [WOWMACRO]
      
      # * Pressing pause will work normally
      # * HOLDing pause for 2 seconds will turn off the capslock macro
      # * numlock is set ON through when turning on the numpad macro
      #   (in other conf file) and is a shared state so don't set it here
      #pause = timeout(pause, 2000, togglem(WOWMACRO,numlock))
      #   ... instead do this:
      pause = timeout(pause, 2000, toggle(WOWMACRO))
      
      # "capslock" will fire multiple numpad key equivalents
      capslock = macro(kp7 kp8 kp9 kp4 kp5 kp6)
      
      ```
     * At this point (after `sudo keyd reload` of course) I press numpad "backspace" and keyboard "pause" to activate my WoW Macro setup
     * Holding numpad "backspace" and keyboard "pause" for 2 seconds each returns to normal keyboard configuration
     * **NOTE**: Ideally I would activate/deactivate the macro on keyboard "capslock" with the same "backspace" on the numpad that activates the WoW macros there.
        * I didn't find a good way to do that without having the NUMPADMACRO remappings also affect the keyboard
        * This choice means when I'm playing WoW I press numpad "backspace" and keyboard "pause" once to activate the macros
        * When I am done with WoW I **hold** numpad "backspace" and keyboard "pause" to deactivate the macros
        * Don't forget the keyboard "backspace + enter + escape" sequence will terminate 'keyd' even in Game mode if you get into a weird situation
* That's it (almost)

## 7. Additional Tweaks

These are NOT needed to make things work. 

However they *may* make it easier to recreate your 'keyd' install if a SteamOS update breaks it. 

Please read the notes before deciding to do these yourself. 

* Moving the config files to the 'deck' user directory
   * I did this to try and retain my config files even if SteamOS resets the '/etc' directory
   * This may not have been necessary and won't affect the stuff before working
   * **This may seem like a BAD IDEA.** 
      * When 'keyd' runs it is run as ***root***.
         * This tweak moves conf files user accessible directory that should not be affected by SteamOS updates
         * If a user manages to get access to the files, they could force arbitrary commands to run as root since keyd has a 'command' binding option
      * *However* we're not changing the *ownership* to the user, they remain as root, *and still require 'sudo' to edit*
      ```
      sudo mv /etc/keyd ~/.config
      sudo ln -s ~/.config/keyd /etc
      ls -aFl ~/.config/keyd
      ```
     * **Make sure** '~home/.config/keyd' (the directory) **and** all files in it remain owned by user:group *root:root*.
* There is no need to relocate the 'keyd' binaries, docs, man files as they still exist in '~/Documents/source/keyd' (or wherever you compiled it)
* ~~(***NOT tested yet***) Cheatsheet to reinstall 'keyd' after if a SteamOS update breaks 'keyd', assuming you used the same paths and file names:~~ 
   ```
   cd ~/Documents/source/keyd
   sudo steamos-readonly disable
   sudo make install                   # re-run the install to copy the previously compiled files
   ```
   Tested this on the Oct 2 2025 SteamOS image after an update. It doesn't "just work" as you still need to do the pacman-key and /etc/pacman.conf stuff at the top of this page to get 'make' installed. So just redo the initial instructions to trustall on the keys if you don't have a working 'make' command. But you shouldn't need to rebuild the keyd binary unless you want to look for a newer version. I'll clean this up again someday. 

   ```
   sudo steamos-readonly enable
   ln -s ~/.config/keyd /etc      # link your customized configs in to /etc
   sudo systemctl enable keyd
   sudo systemctl start keyd
   ```

   If one of those steps fails (make commands seem the most likely fail), you may need to start the process from the beginning of the guide. But that should work for most updates. 

## 8. Future Plans

* I would like to make a configurations that only remaps those keys *while playing WoW* (so I can have other configs for other situations), **however:**
   * [This issue](https://github.com/rvaiya/keyd/issues/525) means that the unpatched 'keyd' can't really do this on the Steam Deck
   * There is a patch that supposedly fixes it [in this issue](https://github.com/rvaiya/keyd/pull/545) that requires additional patching instructions
   * I'm also unsure if the application method would work for Proton games on the Steam Deck (need to test)



