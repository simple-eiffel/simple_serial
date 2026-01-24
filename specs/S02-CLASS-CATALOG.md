# S02: CLASS CATALOG - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Class Overview

| Class | Type | Purpose |
|-------|------|---------|
| SIMPLE_SERIAL | Effective | Facade and factories |
| SERIAL_PORT | Effective | Core port operations |
| SERIAL_PORT_CONFIG | Effective | Port configuration |
| SERIAL_PORT_ENUMERATOR | Effective | Port discovery |

## 2. Class Details

### 2.1 SIMPLE_SERIAL
**Purpose**: Main entry point with convenience methods.

Features:
- Factory: open_port, open_port_with_config, create_port
- Configuration: default_config, config_9600, config_115200
- Enumeration: available_ports, bluetooth_ports, usb_ports, port_exists
- Anchors: port_anchor, config_anchor, enumerator_anchor

### 2.2 SERIAL_PORT
**Purpose**: Core serial port operations.

Features:
- Connection: open, open_with_config, close
- Read: read_bytes, read_string, read_line
- Write: write_bytes, write_string, write_line
- Status: is_open, bytes_available, has_data
- Flow control: set_dtr, set_rts, flush, purge_input, purge_output
- Attributes: port_name, config, last_error, last_read_count, last_write_count

### 2.3 SERIAL_PORT_CONFIG
**Purpose**: Configuration parameters.

Settings:
- baud_rate, data_bits, stop_bits, parity
- flow_control
- read_timeout_ms, write_timeout_ms

Constants:
- Stop_bits_one/one_five/two
- Parity_none/odd/even/mark/space
- Flow_control_none/hardware/xon_xoff

### 2.4 SERIAL_PORT_ENUMERATOR
**Purpose**: Discover available ports.

Features:
- available_ports, port_descriptions
- has_ports, has_port, count
- bluetooth_ports, usb_ports
- refresh, description_for
