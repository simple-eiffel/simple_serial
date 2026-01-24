# S04: FEATURE SPECS - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. SIMPLE_SERIAL Features

### 1.1 Factory Methods
| Feature | Signature | Description |
|---------|-----------|-------------|
| open_port | `(a_name): detachable SERIAL_PORT` | Open with defaults |
| open_port_with_config | `(a_name, a_config): detachable SERIAL_PORT` | Open with config |
| create_port | `(a_name): SERIAL_PORT` | Create unopened |

### 1.2 Configuration
| Feature | Signature | Description |
|---------|-----------|-------------|
| default_config | `: SERIAL_PORT_CONFIG` | 9600-8-N-1 |
| config_9600 | `: SERIAL_PORT_CONFIG` | 9600-8-N-1 |
| config_115200 | `: SERIAL_PORT_CONFIG` | 115200-8-N-1 |

### 1.3 Enumeration
| Feature | Signature | Description |
|---------|-----------|-------------|
| available_ports | `: ARRAYED_LIST [STRING_32]` | All ports |
| bluetooth_ports | `: ARRAYED_LIST [STRING_32]` | BT SPP ports |
| usb_ports | `: ARRAYED_LIST [STRING_32]` | USB serial |
| port_exists | `(a_name): BOOLEAN` | Check existence |

## 2. SERIAL_PORT Features

### 2.1 Connection
| Feature | Description |
|---------|-------------|
| make | Create with port name |
| open | Open with default config |
| open_with_config | Open with custom config |
| close | Close port |
| is_open | Check open status |

### 2.2 Read Operations
| Feature | Description |
|---------|-------------|
| read_bytes | Read up to N bytes |
| read_string | Read as string |
| read_line | Read until newline |
| bytes_available | Bytes ready to read |
| has_data | Any data available? |

### 2.3 Write Operations
| Feature | Description |
|---------|-------------|
| write_bytes | Write byte array |
| write_string | Write string |
| write_line | Write with newline |

### 2.4 Flow Control
| Feature | Description |
|---------|-------------|
| set_dtr | Set DTR line |
| set_rts | Set RTS line |
| flush | Wait for output complete |
| purge_input | Discard input buffer |
| purge_output | Discard output buffer |

## 3. SERIAL_PORT_CONFIG Features

### 3.1 Properties
| Feature | Type | Default |
|---------|------|---------|
| baud_rate | INTEGER | 9600 |
| data_bits | INTEGER | 8 |
| stop_bits | INTEGER | 0 (one) |
| parity | INTEGER | 0 (none) |
| flow_control | INTEGER | 0 (none) |
| read_timeout_ms | INTEGER | 1000 |
| write_timeout_ms | INTEGER | 1000 |

### 3.2 Fluent Setters
All return `like Current` for chaining:
- set_baud_rate, set_data_bits, set_stop_bits
- set_parity, set_flow_control
- set_read_timeout, set_write_timeout

### 3.3 Constants
| Category | Constants |
|----------|-----------|
| Stop bits | Stop_bits_one (0), Stop_bits_one_five (1), Stop_bits_two (2) |
| Parity | Parity_none (0), Parity_odd (1), Parity_even (2), Parity_mark (3), Parity_space (4) |
| Flow | Flow_control_none (0), Flow_control_hardware (1), Flow_control_xon_xoff (2) |

## 4. SERIAL_PORT_ENUMERATOR Features

| Feature | Description |
|---------|-------------|
| make | Create and scan |
| refresh | Rescan ports |
| available_ports | Port names |
| port_descriptions | Descriptions hash |
| description_for | Get description |
| count, has_ports, has_port | Query methods |
| bluetooth_ports | Filter BT ports |
| usb_ports | Filter USB ports |
