# S07: SPEC SUMMARY - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Library Overview

**Name**: simple_serial
**Purpose**: Cross-platform serial port communication
**Status**: Production ready (Windows)

## 2. Quick Reference

### 2.1 Quick Open
```eiffel
serial: SIMPLE_SERIAL
create serial

-- Open with defaults (9600-8-N-1)
if attached serial.open_port ("COM3") as port then
    port.write_string ("Hello")
    response := port.read_string (100)
    port.close
end
```

### 2.2 Custom Configuration
```eiffel
config := serial.default_config.set_baud_rate (115200)
if attached serial.open_port_with_config ("COM3", config) as port then
    ...
end
```

### 2.3 Port Enumeration
```eiffel
across serial.available_ports as p loop
    print (p + "%N")
end

-- Find Bluetooth ports
across serial.bluetooth_ports as bt loop
    print ("Bluetooth: " + bt + "%N")
end
```

### 2.4 Full Configuration
```eiffel
config: SERIAL_PORT_CONFIG
create config.make (115200, 8,
    {SERIAL_PORT_CONFIG}.stop_bits_one,
    {SERIAL_PORT_CONFIG}.parity_none)
config.set_flow_control ({SERIAL_PORT_CONFIG}.flow_control_hardware)
config.set_read_timeout (2000)
```

## 3. Key Specifications

| Aspect | Specification |
|--------|---------------|
| Classes | 4 |
| Platform | Windows (Linux/macOS placeholder) |
| I/O Mode | Synchronous |
| Bluetooth | SPP supported |

## 4. Warnings

1. **Windows only** (currently)
2. **Synchronous I/O** - blocks on read/write
3. **Port enumeration** - may be slow (brute force)
4. **Timeouts** - essential for reliable operation
