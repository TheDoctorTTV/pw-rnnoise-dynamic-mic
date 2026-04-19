RNNoise PipeWire Setup (Auto Default Mic Switching)

This setup creates a virtual microphone ("RNNoise Mic") that:
- Applies RNNoise noise suppression
- Automatically follows whatever mic is set as the system default

--------------------------------------------------

FILES

99-rnnoise-source.conf
→ PipeWire filter-chain config that creates the RNNoise virtual mic

rnnoise-watch-default.fish
→ Script that monitors the default mic and relinks it into RNNoise

rnnoise-watch-default.service
→ Systemd user service that runs the watcher automatically

--------------------------------------------------

DEPENDENCIES

Install required plugin:
    sudo pacman -S noise-suppression-for-voice

--------------------------------------------------

SETUP

1. Copy config:
    mkdir -p ~/.config/pipewire/pipewire.conf.d
    cp 99-rnnoise-source.conf ~/.config/pipewire/pipewire.conf.d/

2. Copy script:
    mkdir -p ~/.local/bin
    cp rnnoise-watch-default.fish ~/.local/bin/
    chmod +x ~/.local/bin/rnnoise-watch-default.fish

3. Copy service:
    mkdir -p ~/.config/systemd/user
    cp rnnoise-watch-default.service ~/.config/systemd/user/

4. Enable service:
    systemctl --user daemon-reload
    systemctl --user enable --now rnnoise-watch-default.service

5. Restart PipeWire:
    systemctl --user restart pipewire pipewire-pulse wireplumber

--------------------------------------------------

USAGE

- Set apps (OBS, Discord, etc) to use:
    "RNNoise Mic"

- The script will automatically:
    - Detect your default mic (desktop, VR, etc)
    - Route it through RNNoise

--------------------------------------------------

TROUBLESHOOTING

Check links:
    pw-link -l | grep rnnoise

Check default mic:
    wpctl status

Manually set default:
    wpctl set-default <ID>

Restart service:
    systemctl --user restart rnnoise-watch-default.service

--------------------------------------------------

NOTES

- Uses PipeWire filter-chain (no EasyEffects required)
- Supports multiple microphones dynamically
- Designed for streaming setups (OBS, Discord, VRChat, etc)

--------------------------------------------------
