# kanata

[kanata](https://github.com/jtroo/kanata) keyboard remapper config for macOS.

`kanata.kbd` is the only tracked file; it's symlinked to
`~/.config/kanata/kanata.kbd` by `link.sh` and loaded by a system LaunchDaemon.

## What the config does

- **Home-row mods** (tap = letter, hold = modifier):
  - left hand: `s`=alt `d`=ctrl `f`=gui
  - right hand: `j`=gui `k`=ctrl `l`=alt
- **Meh on hold** for `m` and `v` (tap = letter, hold = Ctrl+Alt+Shift).
- **Space**: tap = space, hold = shift.
- **F-row** remapped to media/hardware functions:

  | Key | Function        | Key | Function      |
  |-----|-----------------|-----|---------------|
  | F1  | brightness down | F7  | previous track|
  | F2  | brightness up   | F8  | play / pause  |
  | F3–F6 | plain F3–F6   | F9  | next track    |
  | F10 | mute (toggle)   | F11 | volume down   |
  | F12 | volume up       |     |               |

  Note: because the F-row is remapped inside kanata, these are NOT
  fn-sensitive — pressing fn+F11 does not produce a real F11. kanata sees
  the physical key and emits the mapped function unconditionally. (Apple
  keyboards generally don't expose the `fn` key to kanata, so a
  "bare = media, fn = real F-key" split isn't reliably possible here.)

`defsrc` and the `base` deflayer must stay row-aligned — the F-row line was
added to both. If you add/remove keys, keep both blocks in sync.

## Install / setup (macOS)

1. **Install the binary** (also done by `scripts/setup-mac.sh`):
   ```
   brew install kanata
   ```
2. **Link the config** (done by `link.sh`):
   ```
   ~/.config/kanata/kanata.kbd → dotfiles/config/kanata/kanata.kbd
   ```
3. **Run it as a system LaunchDaemon** so it starts on boot and restarts if it
   dies. Create `/Library/LaunchDaemons/dev.kanata.kanata.plist` (root:wheel,
   644) with:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
     <key>Label</key><string>dev.kanata.kanata</string>
     <key>ProgramArguments</key>
     <array>
       <string>/opt/homebrew/Cellar/kanata/<VERSION>/bin/kanata</string>
       <string>--cfg</string>
       <string>/Users/<YOU>/.config/kanata/kanata.kbd</string>
     </array>
     <key>RunAtLoad</key><true/>
     <key>KeepAlive</key><true/>
     <key>StandardOutPath</key><string>/var/log/kanata.log</string>
     <key>StandardErrorPath</key><string>/var/log/kanata.log</string>
   </dict>
   </plist>
   ```
   Then load it:
   ```
   sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.kanata.plist
   ```
   > The `kanata` binary path is version-pinned (`Cellar/kanata/<VERSION>`).
   > After a `brew upgrade kanata`, update the plist path and re-kickstart.

4. **Grant permissions**: macOS will require Input Monitoring (and Accessibility)
   for kanata. Approve in System Settings → Privacy & Security. kanata uses the
   Karabiner VirtualHID driver; the log shows `driver connected: true` when ready.

## Managing the daemon

```
# reload after editing kanata.kbd (needs admin)
sudo launchctl kickstart -k system/dev.kanata.kanata

# stop / start
sudo launchctl bootout   system/dev.kanata.kanata
sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.kanata.plist

# logs (config errors, driver status, keypress info with --debug)
tail -f /var/log/kanata.log
```

A SwiftBar plugin at `~/.config/swiftbar/kanata.5s.sh` shows live status and
menu actions (enable/disable/restart/reload). It is **not currently tracked** in
this repo.

## Validating a config change

After editing `kanata.kbd`, kickstart the daemon and check the log for
`config file is valid`. If invalid, kanata logs the parse error and keeps the
previous config running.

## Emergency exit

Press `lctl` + `spc` + `esc` (physical keys, before remapping) to force-quit
kanata if a config change locks up input.

## Out-of-repo state

The LaunchDaemon plist (`/Library/LaunchDaemons/dev.kanata.kanata.plist`) and
the SwiftBar plugin are NOT tracked here. If reproducibility on a new machine
matters, script them under `scripts/` — currently `setup-mac.sh` only installs
the binary and links the config.
