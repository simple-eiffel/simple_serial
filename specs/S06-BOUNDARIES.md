# S06: BOUNDARIES - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. API Boundaries

### 1.1 Public Interface
All classes provide public access to their features:
- SIMPLE_SERIAL: Facade methods
- SERIAL_PORT: All operations
- SERIAL_PORT_CONFIG: All settings and constants
- SERIAL_PORT_ENUMERATOR: All discovery features

### 1.2 Private Features (SERIAL_PORT)
| Feature | Purpose |
|---------|---------|
| handle | Windows HANDLE |
| Invalid_handle | Sentinel value |
| windows_port_path | Path conversion |
| c_* | Win32 inline C externals |

### 1.3 Private Features (SERIAL_PORT_ENUMERATOR)
| Feature | Purpose |
|---------|---------|
| scan_windows_ports | Windows scanning |
| scan_unix_ports | Unix scanning (placeholder) |
| c_port_exists_windows | Port check |

## 2. Input Boundaries

### 2.1 Port Names
| Constraint | Validation |
|------------|------------|
| Not empty | Precondition |
| Valid format | OS validates |

### 2.2 Configuration
| Parameter | Valid Range |
|-----------|-------------|
| baud_rate | Enumerated values |
| data_bits | 7, 8 |
| stop_bits | 0, 1, 2 |
| parity | 0-4 |
| flow_control | 0-2 |
| timeouts | >= 0 |

### 2.3 I/O Operations
| Parameter | Constraint |
|-----------|------------|
| max_count | > 0 |
| bytes array | Not empty |
| string | Not empty |

## 3. Output Boundaries

### 3.1 Read Results
| Operation | Result |
|-----------|--------|
| read_bytes | ARRAY [NATURAL_8], may be smaller than requested |
| read_string | STRING_8, may be shorter than max |
| read_line | STRING_8, up to newline or timeout |

### 3.2 Status
| Attribute | Type |
|-----------|------|
| last_read_count | >= 0 |
| last_write_count | >= 0 |
| last_error | STRING_32 or Void |
| bytes_available | >= 0 |

## 4. State Boundaries

### 4.1 Port States
| State | Allowed Operations |
|-------|-------------------|
| Closed | open, open_with_config |
| Open | read, write, close, control |
