# USPSA VR Range

A USPSA-style handgun range for VR, built with Godot 4.4 + OpenXR and packaged as a **native aarch64 AppImage**
for the Steam Frame. Everything (guns, targets, ranges, textures, sounds) is generated in code, so there are no
external assets to download.

**Features**
- Indoor and outdoor ranges
- 4 pistols (Glock 17, CZ Shadow 2, S&W M&P9 2.0, 1911 .45) and 4 red dots plus iron sights
- Muzzle devices: compensator, muzzle brake, suppressor
- Draw from a hip or appendix holster, re-holster, brass ejection
- Realistic reloads: drop mag, pull a mag from your belt, seat it, rack or press slide release
  (slide only locks back on an empty mag, a chambered round is remembered)
- Shot timer with USPSA scoring and hit factor
- Target editor with 5 save slots per range: paper, no-shoot, steel (popper, plate, spinner),
  sliding / turning / tumbling / orbiting targets
- Placeable walls and barricades with shooting ports, 8 models x 6 textures
- Teleport and smooth locomotion, snap or smooth turn, full button remapping
- 11 built-in drills and stages with par times and PASS/FAIL (Bill Drill, El Presidente, Failure to Stop,
  Transitions, Steel Plates, Hostage Rescue, Moving Target, Pop-ups, Barricade Stage, Air Targets)
- Run history, personal bests and per-drill stats, saved on the device
- Red dot reticle options (dot or circle-dot, 4 colors, 5 brightness levels), optional malfunctions
- Foveated rendering: off, fixed, or eye-tracked (Steam Frame eye tracking), with a strength setting and FPS readout
- Pop-up targets, floating scoreboard, hit markers, first-run tutorial, belt height, volume and haptics settings

---

## Installing (Steam Frame / any aarch64 Linux with OpenXR)

### Option A: download a build
1. Open this repo's **Releases** page (or the latest **Actions** run -> *Artifacts*) and download
   `USPSA-VR-aarch64.AppImage`.
2. Make it executable:
   ```bash
   chmod +x USPSA-VR-aarch64.AppImage
   ```
3. Add it to Steam so SteamVR / the OpenXR runtime is running when it launches:
   Steam -> *Games* -> *Add a Non-Steam Game to My Library* -> *Browse* -> pick the AppImage.
4. Launch it from Steam while in VR. The AppImage already passes `--xr-mode on`.

If it does not start, run it from a terminal to see the error:
```bash
./USPSA-VR-aarch64.AppImage --xr-mode on
```
(If your system has no FUSE, use `APPIMAGE_EXTRACT_AND_RUN=1 ./USPSA-VR-aarch64.AppImage`.)

### Option B: build it yourself with GitHub Actions
1. Fork or push this repo to your own GitHub account (branch `main`).
2. The workflow `.github/workflows/build.yml` runs on `ubuntu-24.04-arm`. Open the **Actions** tab, run
   *Build aarch64 AppImage* (or just push a commit) and download the `USPSA-VR-aarch64.AppImage` artifact.
3. Pushing a tag such as `v1.0.0` also publishes the AppImage as a GitHub Release.

The workflow downloads Godot 4.4.1 (arm64) and its export templates, generates the default OpenXR action map,
exports with `export_presets.cfg` ("Linux ARM64"), then packages the AppImage with `appimagetool`.

### Where your data lives
Settings, control bindings and saved layouts are stored in Godot's user folder:
```
~/.local/share/godot/app_userdata/USPSA VR Range/
```
(`settings.json`, `history.json`, and `layout_<range>_<slot>.json` for each saved layout.)

---

## Controls (defaults; the gun hand is the right hand unless you change it in the menu)

| Action | Default button |
|---|---|
| Fire (and click menu items) | Gun hand **trigger** |
| Drop magazine | Gun hand **A** (or X if the gun hand is left) |
| Slide release | Gun hand **B** (or Y) |
| Draw / re-holster | Gun hand **grip**, with the hand at your holster |
| Grab a mag from the belt / rack the slide | Off hand **grip** (at the belt pouch / at the rear of the slide) |
| Shot timer | Off hand **X** (or A) |
| Menu | Off hand **Y** (or B), or the controller **menu** button at any time |
| Turn | Gun hand **thumbstick** left/right (snap or smooth) |
| Move | Off hand **thumbstick** (smooth), or push forward to aim the teleport arc and release to go |

### Shooting and reloading
1. Put your gun hand at your hip (or belt line in front, for Appendix) and squeeze the grip to draw.
   Squeeze the grip again with the hand at the holster to re-holster.
2. Off hand grip at your belt pouch pulls a full magazine. Bring it up into the bottom of the grip to seat it.
3. Rack: off hand grip at the rear of the slide, pull back, let go. Or press slide release.
4. Drop the empty mag with the mag release. When the slide locks back on an empty mag, seat a new mag and
   press slide release (or rack). A round already in the chamber stays chambered when you swap mags.
5. Press the timer button: *standby*, then a random 2-4 s delay, then the beep. Press it again to stop and see
   time, points, zone counts, hit factor, draw time and splits on your off-hand wrist display.

Scoring: A=5, C=3, D=1 (best 2 hits per paper target), steel=5, each miss or no-shoot hit = -10,
hit factor = points / time (time ends on your last shot).

### Target and barricade editor
Menu -> **Target editor: ON** (the menu is pointed at with the gun hand laser; trigger clicks).
- Aim at the floor: **trigger** places the selected item
- **B/Y** cycles the item type, **off hand X/A** cycles the barricade texture
- **Gun hand stick up/down** sets the height for floating (air) targets
- **Grip + stick left/right** rotates
- Aim at an existing item and **pull the trigger** to pick it up, trigger again to drop it. **A/X** deletes it
- Menu -> **Layout slot 1-5**, **Save layout**, **Load layout**, **Clear targets** (saved per range)

Items: USPSA, Mini USPSA, No-Shoot, Popper, Plate, Spinner, Sliding USPSA / Plate / Popper / Spinner,
Turning USPSA, Pop-up USPSA, Tumbling Plate, Orbiting Plate / USPSA / Spinner, and walls: Window, Port Slit, Double Port,
Low, Tall, Doorway, Slat Fence, Barrel Stack. Textures: Plywood, Brick, Concrete, Metal, Camo, Sandbags.

### Drills, stats and ease of use
- **Menu -> Drills / stages...** loads a drill: it replaces the targets, sets the par time and shows the goal on
  your wrist. Press the timer button to start. The run ends automatically at par with a second beep.
  PASS needs the A-zone and steel goals, no no-shoot hits, inside par. *Free Practice* returns to your own layout.
- **Par timer** (Settings) adds an automatic par end to Free Practice too.
- **Stats / history** shows runs, best and average hit factor and your last 6 runs for the selected drill.
  A new best hit factor shows "NEW PERSONAL BEST!". History is stored in `history.json` (last 200 runs).
- **Scoreboard**: a large board appears in front of you when you start the timer (time, shots, then the result).
  **Hit markers** pop up A/C/D/NS/steel where each shot lands. Both can be turned off in Settings.
- **Tutorial**: shown on first launch, any button closes it. Menu -> *Show tutorial* shows it again.
- **Recenter to start** puts you back on the start line. **Belt height** moves the holster and mag pouch to
  match your height. **Volume** and **Haptics** are in Settings.
- **Reticle** (Menu -> Gun): dot or circle-dot (circle-dot on the Holosun 507C only), red/green/yellow/cyan,
  20-100% brightness.
- **Malfunctions** (Menu -> Gun): Off / Rare / Common. A jam leaves the slide partly open with a click on the
  trigger. Rack the slide to clear it.

### Foveated rendering (performance)
Menu -> Settings has three options:
- **Foveation**: *Off*, *Fixed* (the sharp area stays centered, done by the runtime) or *Eye-tracked*
  (the sharp area follows your gaze using the Frame's eye cameras).
- **Fov strength**: Low / Medium / High. Higher means a smaller sharp area and more savings.
- **Show FPS**: adds the frame rate and the current foveation state to your wrist display, so you can compare modes.

How eye-tracked mode works: the app enables the OpenXR eye gaze extension (`XR_EXT_eye_gaze_interaction`), reads your
gaze about 20 times a second, and builds a variable-rate-shading map with full detail around the gaze point,
half detail around it and quarter detail in the periphery. If no gaze data arrives for 3 seconds it falls back to
Fixed until the data comes back. The wrist status shows `FOV eye` when gaze is live and `FOV eye: no gaze, fixed`
when it is not.

Eye-tracked mode is experimental. It needs SteamVR to expose eye gaze and the GPU/driver to accept a custom
shading-rate map. If you see the periphery shimmering or doubling, switch to *Fixed* or *Off*. Valve's Godot
guide describes the officially supported route as the OpenXR Vendors plugin, which this project does not use.
Eye tracking may also need to be allowed in your Steam Frame / SteamVR settings.

### Remapping controls
1. Open the menu and choose **Controls / remap...**
2. Click an action (for example *Slide rel*), the label changes to *press...*, then press the button you want.
3. Rules: weapon actions are locked to their hand (fire, drop mag, slide release and draw are gun hand;
   mag and rack are off hand). **Timer** and **Menu** can go on either hand. If the new button is already used,
   the two actions swap, or the change is refused with a message if that would break a hand rule.
   The controller **menu** button always opens the menu, and pressing it while listening cancels the remap.
4. **Swap sticks** puts movement on the gun hand and turning on the off hand.
   **Reset controls** restores every default. Bindings are saved automatically.
5. Changing the **Gun hand** (left/right) in the main menu mirrors everything for left-handed use.

Bindable buttons: trigger, grip, A/X, B/Y, thumbstick click.

### Other menu options
The menu is split into pages: **Main** (range, drills, gun, layout, settings, controls, stats, tutorial,
recenter), **Gun / optic** (gun, optic, reticle, muzzle, grip angle, holster, belt, malfunctions, gun hand),
**Target layout** (editor, slots, save/load/clear) and **Settings** (move and turn mode, quality, ammo display,
volume, haptics, hit markers, scoreboard, par timer).

---

## Troubleshooting
- **Buttons do nothing:** the OpenXR action map may be missing from the build. Open the project once in the
  Godot editor (*Project -> Project Settings -> XR -> OpenXR -> Action Map*), let it create
  `openxr_action_map.tres`, and commit that file.
- **The gun points too high or low:** Menu -> *Grip angle*.
- **Low frame rate:** Menu -> *Quality: Low*.
- **Teleport arc comes from the wrong place:** it uses the controller aim pose of the movement hand.

---

## Uninstalling
1. Remove the Non-Steam shortcut: Steam library -> right click *USPSA-VR-aarch64.AppImage* -> *Manage* ->
   *Remove non-Steam game from your library*.
2. Delete the AppImage file you downloaded:
   ```bash
   rm USPSA-VR-aarch64.AppImage
   ```
3. Optional, remove saved settings, bindings and layouts:
   ```bash
   rm -rf "$HOME/.local/share/godot/app_userdata/USPSA VR Range"
   ```
4. Optional, if you integrated it with a launcher (AppImageLauncher or similar), remove the entry from that
   launcher. Nothing else is installed system-wide.

---

## Project layout
```
project.godot, export_presets.cfg, main.tscn
scripts/main.gd          rig, input, menu, remapping, editor, timer, scoring
scripts/gun.gd           pistol, slide, mags, red dot, brass, muzzle devices
scripts/mag.gd           magazines
scripts/target.gd        paper and steel targets, motion
scripts/barricade.gd     walls and barricades with ports
scripts/defs.gd          gun/optic/muzzle data, textures, sounds
scripts/drills.gd        drill and stage definitions
scripts/range_builder.gd indoor and outdoor ranges
tools/gen_action_map.gd  CI helper that generates the OpenXR action map
.github/workflows/build.yml  aarch64 AppImage build
```

## License
Choose a license before publishing (for example MIT) and add a `LICENSE` file.
