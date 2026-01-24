# 7S-02: STANDARDS - simple_serial


**Date**: 2026-01-23

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Applicable Standards

### 1.1 Serial Communication Standards
- RS-232: Standard serial communication
- Common baud rates: 9600, 19200, 38400, 57600, 115200, etc.
- Data formats: 7/8 data bits, 1/1.5/2 stop bits
- Parity: None, Odd, Even, Mark, Space

### 1.2 Flow Control
| Type | Method |
|------|--------|
| None | No flow control |
| Hardware | RTS/CTS handshaking |
| Software | XON/XOFF (0x11/0x13) |

### 1.3 Bluetooth SPP
- Serial Port Profile over Bluetooth
- Appears as virtual COM port
- Same API as wired serial

## 2. Windows API Standards

### 2.1 Win32 Serial API
- CreateFile for port opening
- DCB structure for configuration
- COMMTIMEOUTS for timeouts
- ReadFile/WriteFile for I/O
- EscapeCommFunction for control lines

### 2.2 Port Naming
- COM1-COM9: Standard naming
- COM10+: Requires \\.\COMn prefix

## 3. Eiffel Standards

### 3.1 Design by Contract
- Preconditions on port state
- Open/close state tracking
- Result validation

### 3.2 Inline C Pattern
- Direct Win32 API calls
- No external C files
- Platform detection via PLATFORM
