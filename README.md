RNNoise PipeWire Setup Auto Default Mic Switching

Setup creates virtual microphone named RNNoise Mic that
- applies RNNoise noise suppression
- follows whatever microphone PipeWire marks default

Files

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
- `build-release.sh`
  Release packager creating versioned tar gz archives in `dist`

Dependencies

Install PipeWire RNNoise LADSPA plugin before setup

Arch
```bash
sudo pacman -S noise-suppression-for-voice
```

Debian Ubuntu
```bash
sudo apt install lsp-plugins-ladspa
```

If plugin installs library outside `/usr/lib/ladspa/librnnoise_ladspa.so` update path inside `99-rnnoise-source.conf`.

Setup

Run installer from repository root

```bash
chmod +x install.sh
./install.sh
```

Create release archive

```bash
chmod +x build-release.sh
./build-release.sh
```

Optional explicit version

```bash
./build-release.sh v1.0.0
```

Archive will be written to `dist/` and contains the config script service installer uninstaller README and license.

Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Manual setup if preferred

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.local/bin ~/.config/systemd/user
install -m 0644 99-rnnoise-source.conf ~/.config/pipewire/pipewire.conf.d/99-rnnoise-source.conf
install -m 0755 rnnoise-watch-default.sh ~/.local/bin/rnnoise-watch-default.sh
install -m 0644 rnnoise-watch-default.service ~/.config/systemd/user/rnnoise-watch-default.service
systemctl --user daemon-reload
systemctl --user enable --now rnnoise-watch-default.service
systemctl --user restart pipewire pipewire-pulse wireplumber
```

Usage

Set OBS Discord VRChat and similar apps input device to `RNNoise Mic`.

Watcher will
- detect current default raw microphone
- link that source into RNNoise filter
- switch automatically when default microphone changes
- remove stale mic links after service restarts or device changes so only one input feeds RNNoise

Troubleshooting

Check service
```bash
systemctl --user status rnnoise-watch-default.service
journalctl --user -u rnnoise-watch-default.service -f
```

Check current links
```bash
pw-link -l | grep rnnoise
```

Correct routing should show one raw mic feeding `capture.rnnoise_mic:playback_MONO` and apps reading from `rnnoise_mic:capture_MONO`.

Check default source
```bash
wpctl status
wpctl inspect @DEFAULT_AUDIO_SOURCE@
```

Notes

- no EasyEffects required
- service path uses `%h` so config works across usernames
- watcher no longer hardcodes microphone names
- watcher parses current WirePlumber `wpctl inspect` output format
- stale RNNoise input links are cleaned up by PipeWire link id
