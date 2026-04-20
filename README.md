# RNNoise PipeWire Setup Auto Default Mic Switching

Setup creates virtual microphone named RNNoise Mic that
- applies RNNoise noise suppression
- follows whatever microphone PipeWire marks default

## Files

- `99-rnnoise-source.conf`
  PipeWire filter chain config creating RNNoise virtual mic
- `rnnoise-watch-default.sh`
  Watcher script reading current default source then linking only that source into RNNoise
- `rnnoise-watch-default.service`
  User systemd service running watcher automatically
- `install.sh`
  One step installer copying files into user config then enabling service
- `uninstall.sh`
  One step uninstaller removing installed user files then disabling service

## Dependencies

Install PipeWire RNNoise LADSPA plugin before setup

### Arch
```bash
sudo pacman -S noise-suppression-for-voice
```

### Debian Ubuntu
```bash
sudo apt install lsp-plugins-ladspa
```

Installer will try to detect `librnnoise_ladspa.so` automatically.
If autodetection fails rerun with `RNNOISE_PLUGIN_PATH=/full/path/to/librnnoise_ladspa.so ./install.sh`.

## Setup

Clone repo then run installer from repository root

```bash
git clone https://github.com/TheDoctorTTV/rnnoise-autoswitch-defaultmic.git
cd rnnoise-autoswitch-defaultmic
chmod +x install.sh
./install.sh
```

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Manual Setup

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.local/bin ~/.config/systemd/user
sed "s|@RNNOISE_PLUGIN_PATH@|/full/path/to/librnnoise_ladspa.so|g" 99-rnnoise-source.conf > ~/.config/pipewire/pipewire.conf.d/99-rnnoise-source.conf
install -m 0755 rnnoise-watch-default.sh ~/.local/bin/rnnoise-watch-default.sh
install -m 0644 rnnoise-watch-default.service ~/.config/systemd/user/rnnoise-watch-default.service
systemctl --user daemon-reload
systemctl --user enable --now rnnoise-watch-default.service
systemctl --user restart pipewire pipewire-pulse wireplumber
```

If PipeWire still acts up after setup, log out of your current session and log back in to fully restart PipeWire and avoid audio issues.

## Usage

Set OBS, Discord, VRChat and similar apps input device to `RNNoise Mic`.

Watcher will
- detect current default raw microphone
- link that source into RNNoise filter
- switch automatically when default microphone changes
- remove stale mic links after service restarts or device changes so only one input feeds RNNoise

## Troubleshooting

### Check Service
```bash
systemctl --user status rnnoise-watch-default.service
journalctl --user -u rnnoise-watch-default.service -f
```

### Check Current Links
```bash
pw-link -l | grep rnnoise
```

Correct routing should show one raw mic feeding `capture.rnnoise_mic:playback_MONO` and apps reading from `rnnoise_mic:capture_MONO`.

### Check Default Source
```bash
wpctl status
wpctl inspect @DEFAULT_AUDIO_SOURCE@
```

## Notes

- no EasyEffects required
- service path uses `%h` so config works across usernames
- installer autodetects common RNNoise LADSPA library locations
- watcher autodetects the RNNoise target input port and common source capture ports
- watcher can be overridden with `RNNOISE_CAPTURE_NODE_NAME` `RNNOISE_SOURCE_NODE_NAME` `RNNOISE_TARGET_PORT` `IGNORE_SOURCE_NODE_NAMES` and `POLL_INTERVAL_SECONDS`
- watcher parses current WirePlumber `wpctl inspect` output format
- stale RNNoise input links are cleaned up by PipeWire link id
