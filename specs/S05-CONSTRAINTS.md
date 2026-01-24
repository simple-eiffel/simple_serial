# S05: CONSTRAINTS - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Platform Constraints

### 1.1 Windows
- Fully implemented
- Uses CreateFile, ReadFile, WriteFile
- COM1-COM9 direct, COM10+ with \\.\prefix

### 1.2 Linux/macOS
- Structure in place
- Implementation placeholder
- Would use /dev/tty* and /dev/cu.*

## 2. Configuration Constraints

### 2.1 Baud Rates
Valid values: 110, 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 57600, 115200, 128000, 256000, 460800, 921600

### 2.2 Data Bits
- 7 or 8 only

### 2.3 Stop Bits
- One (0)
- One and half (1) - rarely used
- Two (2)

### 2.4 Parity
- None (0)
- Odd (1)
- Even (2)
- Mark (3)
- Space (4)

## 3. I/O Constraints

### 3.1 Synchronous Only
- All reads/writes are blocking
- Timeout-based control
- No overlapped/async operations

### 3.2 Timeout Behavior
- read_timeout_ms: Max time for read
- write_timeout_ms: Max time for write
- 0 = immediate return (non-blocking simulation)

## 4. Enumeration Constraints

### 4.1 Windows Enumeration
- Brute-force: tries COM1-COM256
- Checks if port can be opened
- ACCESS_DENIED means port exists (in use)

### 4.2 Description Limitations
- Fixed "Serial Port" description
- No registry-based device names (Phase 2)

## 5. String Constraints

### 5.1 Port Names
- Not empty (precondition)
- Windows: "COM1", "COM3", etc.
- Linux: "/dev/ttyUSB0", etc.

### 5.2 Data Encoding
- Read/write as STRING_8
- Binary via ARRAY [NATURAL_8]
