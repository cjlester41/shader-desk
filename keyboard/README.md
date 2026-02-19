[README ru](README_ru.md) | [README en](README.md)
# evdev-pointer-daemon

A daemon for intercepting input device events (mice, touchpads) via evdev and transmitting them through a Unix socket in JSON format.

## Description

The program monitors input devices in `/dev/input/event*`, detects devices with relative (mouse) or absolute (touchpad) coordinates, and forwards movement events in real-time through a UDP Unix socket.

## Features

- Automatic detection of input devices (mice, touchpads)
- Support for both relative (REL) and absolute (ABS) coordinates
- Coordinate normalization for ABS devices
- Data transmission in JSON format over Unix socket
- Automatic device rescanning every 5 seconds
- Proper handling of termination signals (SIGINT, SIGTERM)

## Dependencies

- CMake ≥ 3.10
- C++17 compiler
- libevdev
- Linux with input subsystem support

## Building

```bash
mkdir build && cd build
cmake ..
make
```

## Permissions

To work with input devices without root privileges, add your user to the `input` group:

```bash
sudo usermod -a -G input $USER
```

After this, you need to re-login or reboot the system.

## Usage

### Starting the daemon

```bash
./evdev-pointer-daemon [--socket PATH]
```

Arguments:
- `--socket PATH` - path to Unix socket
  (default: `$XDG_RUNTIME_DIR/evdev-pointer.sock`
  or `/tmp/evdev-pointer-UID.sock`)
- `-h, --help` - show help message

### Example client for reading events

```python
#!/usr/bin/env python3
import socket
import json
import os

socket_path = os.getenv('XDG_RUNTIME_DIR', '/tmp') + '/evdev-pointer.sock'

sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
sock.bind(socket_path)

print(f"Listening on {socket_path}")

while True:
    data, addr = sock.recvfrom(1024)
    event = json.loads(data.decode())
    print(f"Device: {event['name']} | dX: {event['dx']:.4f} | dY: {event['dy']:.4f} | Type: {event['type']}")
```

## Data Format

Events are transmitted in JSON format:

```json
{
  "device": "/dev/input/event2",
  "name": "USB Optical Mouse",
  "type": "rel",
  "normalized": false,
  "dx": 5.0,
  "dy": -3.0,
  "vx": 0.0,
  "vy": 0.0,
  "dt": 0.0,
  "ts": 1712345678901
}
```

Fields:
- `device` - path to device in `/dev/input`
- `name` - device name
- `type` - device type (`"rel"` for mouse, `"abs"` for touchpad)
- `normalized` - whether coordinates are normalized (true for ABS devices)
- `dx`, `dy` - coordinate changes
- `vx`, `vy` - velocity (reserved for future use)
- `dt` - time since previous event (reserved)
- `ts` - timestamp in milliseconds
