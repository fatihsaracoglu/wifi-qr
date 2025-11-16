# WiFi QR Code Generator

A simple and portable Bash tool for generating Wi-Fi QR codes.
Scan the generated QR code with any iOS or Android device to instantly connect to the Wi-Fi network.

## Features

✔ Standards-compliant Wi-Fi QR format
✔ Supports WPA, WEP, and open networks
✔ Generates PNG QR codes ready to share or print

---

## Usage

```sh
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
```

### Example

```sh
./wifi-qr.sh -s "MyWiFi" -e WPA -p "secret123"
```



