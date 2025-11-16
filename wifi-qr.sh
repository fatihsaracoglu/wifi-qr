#!/usr/bin/env bash

set -euo pipefail

log()        { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn()       { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

install_qrencode() {
    warn "qrencode not found, attempting auto install..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            log "Installing qrencode via Homebrew..."
            brew install qrencode || error_exit "qrencode installation failed."
        else
            error_exit "Cannot install qrencode. Install it manually."
        fi
        return
    fi

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID=${ID,,}
        log "Detected Linux distribution: $DISTRO_ID"
    else
        error_exit "Cannot detect OS. Install qrencode manually."
    fi

    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update && sudo apt install -y qrencode || error_exit "apt install failed"
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -S --noconfirm qrencode || error_exit "pacman install failed"
            ;;
        fedora)
            sudo dnf install -y qrencode || error_exit "dnf install failed"
            ;;
        rhel|centos|rocky|almalinux)
            sudo yum install -y qrencode || sudo dnf install -y qrencode || error_exit "yum/dnf install failed"
            ;;
        alpine)
            sudo apk add qrencode || error_exit "apk install failed"
            ;;
        opensuse*)
            sudo zypper install -y qrencode || error_exit "zypper install failed"
            ;;
        *)
            error_exit "Unsupported Linux distribution: $DISTRO_ID"
            ;;
    esac
}

if ! command -v qrencode >/dev/null 2>&1; then
    install_qrencode
fi

usage() {
    cat <<EOF
Usage: ./wifi-qr.sh [options]

Options:
  -s SSID         Wi-Fi network name (required)
  -p PASSWORD     Password
  -e ENCRYPTION   WPA | WEP | nopass (default: WPA)
  -h              Hidden SSID
  -o OUTPUT       Output PNG (default: wifi.png)
  -t TYPE         png | ansi (default: png)
  -q              Quiet mode
  --help          Show help
EOF
    exit 1
}

ENCRYPTION="WPA"
OUTPUT="wifi.png"
OUTTYPE="png"
HIDDEN=false
QUIET=false
SSID=""
PASSWORD=""

quiet_log() { [[ "$QUIET" = true ]] || log "$@"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s) SSID="$2"; shift 2 ;;
    -p) PASSWORD="$2"; shift 2 ;;
    -e) ENCRYPTION="${2^^}"; shift 2 ;;
    -o) OUTPUT="$2"; shift 2 ;;
    -t) OUTTYPE="${2,,}"; shift 2 ;;
    -h) HIDDEN=true; shift ;;
    -q) QUIET=true; shift ;;
    --help) usage ;;
    *) error_exit "Unknown argument: $1" ;;
  esac
done

[[ -z "$SSID" ]] && error_exit "SSID is required."

case "$ENCRYPTION" in
    WPA|WPA2|WPA3) ENCRYPTION="WPA" ;;
    WEP) ;;
    NOPASS|nopass) ENCRYPTION="nopass"; PASSWORD="" ;;
    *) error_exit "Unknown encryption type: $ENCRYPTION" ;;
esac

if [[ "$ENCRYPTION" != "nopass" && -z "$PASSWORD" ]]; then
    error_exit "Encryption $ENCRYPTION requires a password."
fi

escape() {
    local input="$1"

    input="${input//\\/\\\\}"
    input="${input//;/\\;}"
    input="${input//,/\\,}"
    input="${input//:/\\:}"
    input="${input//\"/\\\"}"

    printf "%s" "$input"
}

esc_ssid="$(escape "$SSID")"
esc_pass="$(escape "$PASSWORD")"

payload="WIFI:T:$ENCRYPTION;S:$esc_ssid;"
[[ -n "$esc_pass" ]] && payload+="P:$esc_pass;"
$HIDDEN && payload+="H:true;"
payload+=";"

quiet_log "Generated payload: $payload"

if [[ "$OUTTYPE" = "ansi" ]]; then
    quiet_log "Generating ANSI QR..."
    qrencode -t ANSIUTF8 -o - -s 2 "$payload"
    exit 0
fi

PIXEL=8
MARGIN=2
quiet_log "Generating PNG -> $OUTPUT"
qrencode -o "$OUTPUT" -s "$PIXEL" -m "$MARGIN" "$payload" || error_exit "Failed to generate QR PNG"

quiet_log "Done."

