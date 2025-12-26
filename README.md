# simple_serial

Serial port communication library for Eiffel.

## Features

- **Cross-platform serial port access** (Windows now, Linux planned)
- **Configurable settings**: baud rate, data bits, stop bits, parity, flow control
- **Fluent API**: chain configuration calls for clean code
- **Port enumeration**: discover available COM ports
- **Bluetooth-aware**: identify Bluetooth SPP and USB serial devices
- **Design by Contract**: proper preconditions/postconditions

## Installation

Set environment variable:
```
SIMPLE_SERIAL=D:\prod\simple_serial
```

Add to your ECF:
```xml
<library name="simple_serial" location="$SIMPLE_SERIAL\simple_serial.ecf"/>
```

## Quick Start

```eiffel
-- Open a serial port with default settings (9600-8-N-1)
serial: SIMPLE_SERIAL
port: detachable SERIAL_PORT

create serial
port := serial.open_port ("COM3")

if attached port as p then
    p.write_string ("Hello device!")
    print (p.read_string (100))
    p.close
end
```

## Configuration

```eiffel
-- Custom configuration with fluent API
config: SERIAL_PORT_CONFIG

create config.make_default
config := config
    .set_baud_rate (115200)
    .set_data_bits (8)
    .set_parity ({SERIAL_PORT_CONFIG}.parity_none)
    .set_stop_bits ({SERIAL_PORT_CONFIG}.stop_bits_one)
    .set_flow_control ({SERIAL_PORT_CONFIG}.flow_control_hardware)

port := serial.open_port_with_config ("COM3", config)
```

## Port Discovery

```eiffel
-- List available ports
serial: SIMPLE_SERIAL
create serial

across serial.available_ports as p loop
    print (p + "%N")
end

-- Find Bluetooth devices (paired via OS)
across serial.bluetooth_ports as p loop
    print ("Bluetooth: " + p + "%N")
end

-- Find USB serial adapters
across serial.usb_ports as p loop
    print ("USB: " + p + "%N")
end
```

## Classes

| Class | Description |
|-------|-------------|
| `SIMPLE_SERIAL` | Main facade with factory methods |
| `SERIAL_PORT` | Port handle for read/write operations |
| `SERIAL_PORT_CONFIG` | Configuration (baud, parity, etc.) |
| `SERIAL_PORT_ENUMERATOR` | Discover available ports |

## Requirements

- EiffelStudio 25.02+
- Windows 10+ (Linux support planned)

## Bluetooth Notes

Bluetooth SPP (Serial Port Profile) devices appear as COM ports after pairing:
1. Pair device via Windows Bluetooth settings
2. Device appears as "COMx" in Device Manager
3. Use `simple_serial` to communicate

This library provides the foundation for `simple_bluetooth`.

## License

MIT
