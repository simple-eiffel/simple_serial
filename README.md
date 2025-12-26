<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_serial

**[Documentation](https://simple-eiffel.github.io/simple_serial/)** | **[GitHub](https://github.com/simple-eiffel/simple_serial)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Cross-platform serial port communication library for Eiffel.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Phase 1** - 6 tests passing, Windows implementation complete

## Overview

SIMPLE_SERIAL provides serial port (COM port) communication for Eiffel applications. It uses inline C externals for Win32 API calls (CreateFile, SetCommState, ReadFile, WriteFile) following the Eric Bezault pattern. Supports configurable baud rates, parity, stop bits, and flow control with a fluent builder API.

## Quick Start

```eiffel
local
    serial: SIMPLE_SERIAL
    port: detachable SERIAL_PORT
do
    create serial
    port := serial.open_port ("COM3")

    if attached port as p then
        if p.write_string ("Hello device!") then
            print (p.read_string (100))
        end
        p.close
    end
end
```

## Configuration

```eiffel
local
    config: SERIAL_PORT_CONFIG
do
    create config.make_default
    config := config
        .set_baud_rate (115200)
        .set_data_bits (8)
        .set_parity ({SERIAL_PORT_CONFIG}.parity_none)
        .set_stop_bits ({SERIAL_PORT_CONFIG}.stop_bits_one)
        .set_flow_control ({SERIAL_PORT_CONFIG}.flow_control_hardware)

    port := serial.open_port_with_config ("COM3", config)
end
```

## Port Discovery

```eiffel
-- List available ports
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

## Features

- **Cross-platform API** - Windows now, Linux/macOS planned
- **Configurable settings** - Baud rate, data bits, stop bits, parity, flow control
- **Fluent builder** - Chain configuration calls for clean code
- **Port enumeration** - Discover available COM ports
- **Bluetooth-aware** - Identify Bluetooth SPP and USB serial devices
- **Design by Contract** - Full preconditions/postconditions
- **SCOOP compatible** - Concurrency-ready design

## Classes

| Class | Description |
|-------|-------------|
| `SIMPLE_SERIAL` | Main facade with factory methods |
| `SERIAL_PORT` | Port handle for read/write operations |
| `SERIAL_PORT_CONFIG` | Configuration (baud, parity, etc.) |
| `SERIAL_PORT_ENUMERATOR` | Discover available ports |

## Installation

1. Set the ecosystem environment variable (one-time setup for all simple_* libraries):
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_serial" location="$SIMPLE_EIFFEL/simple_serial/simple_serial.ecf"/>
```

## Dependencies

None (uses only ISE standard libraries: base, time)

## Requirements

- EiffelStudio 25.02+
- Windows 10+ (Linux support planned)

## License

MIT License
