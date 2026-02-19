
[README ru](README_ru.md) | [README en](README.md)
# evdev-pointer-daemon

Демон для перехвата событий устройств ввода (мыши, тачпады) через evdev и передачи их через Unix socket в формате JSON.

## Описание

Программа мониторит устройства ввода в `/dev/input/event*`, обнаруживает устройства с относительными (мышь) или абсолютными (тачпад) координатами, и пересылает события движения в реальном времени через UDP Unix socket.

## Особенности

- Автоматическое обнаружение устройств ввода (мыши, тачпады)
- Поддержка как относительных (REL), так и абсолютных (ABS) координат
- Нормализация координат для ABS-устройств
- Передача данных в формате JSON через Unix socket
- Автоматический ресканирование устройств каждые 5 секунд
- Корректная обработка сигналов завершения (SIGINT, SIGTERM)

## Зависимости

- CMake ≥ 3.10
- C++17 компилятор
- libevdev
- Linux с поддержкой input subsystem

## Сборка

```bash
mkdir build && cd build
cmake ..
make
```

## Права доступа

Для работы с устройствами ввода без прав root, добавьте пользователя в группу `input`:

```bash
sudo usermod -a -G input $USER
```

После этого необходимо перелогиниться или перезагрузить систему.

## Использование

### Запуск демона

```bash
./evdev-pointer-daemon [--socket PATH]
```

Аргументы:
- `--socket PATH` - путь к Unix socket
  (по умолчанию: `$XDG_RUNTIME_DIR/evdev-pointer.sock`
  или `/tmp/evdev-pointer-UID.sock`)
- `-h, --help` - показать справку

### Пример клиента для чтения событий

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

## Формат данных

События передаются в формате JSON:

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

Поля:
- `device` - путь к устройству в `/dev/input`
- `name` - имя устройства
- `type` - тип устройства (`"rel"` для мыши, `"abs"` для тачпада)
- `normalized` - нормализованы ли координаты (true для ABS устройств)
- `dx`, `dy` - изменения координат
- `vx`, `vy` - скорость (зарезервировано для будущего использования)
- `dt` - время с предыдущего события (зарезервировано)
- `ts` - временная метка в миллисекундах
