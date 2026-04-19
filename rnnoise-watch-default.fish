#!/usr/bin/env fish

set -l target "capture.rnnoise_mic:playback_MONO"
set -l dcmt "alsa_input.usb-DCMT_Technology_USB_Condenser_Microphone_214b206000000178-00.mono-fallback"
set -l antlion "alsa_input.usb-Antlion_Audio_Antlion_Wireless_Microphone-00.mono-fallback"

function current_default
    wpctl inspect @DEFAULT_AUDIO_SOURCE@ | string match -r 'node.name = ".*"' | string replace 'node.name = "' '' | string replace '"' ''
end

while true
    set -l cur (current_default)

    pw-link -d "$dcmt:capture_MONO" "$target" >/dev/null 2>&1
    pw-link -d "$antlion:capture_MONO" "$target" >/dev/null 2>&1
    pw-link -d "$dcmt:capture_FL" "$target" >/dev/null 2>&1
    pw-link -d "$antlion:capture_FL" "$target" >/dev/null 2>&1

    if test "$cur" = "$dcmt"
        pw-link "$dcmt:capture_MONO" "$target" >/dev/null 2>&1
        or pw-link "$dcmt:capture_FL" "$target" >/dev/null 2>&1
    else if test "$cur" = "$antlion"
        pw-link "$antlion:capture_MONO" "$target" >/dev/null 2>&1
        or pw-link "$antlion:capture_FL" "$target" >/dev/null 2>&1
    end

    sleep 2
end
