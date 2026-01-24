# S01: PROJECT INVENTORY - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Project Structure

```
simple_serial/
  src/
    simple_serial.e              # Facade class
    serial_port.e                # Core port operations
    serial_port_config.e         # Configuration object
    serial_port_enumerator.e     # Port discovery
  testing/
    lib_tests.e                  # Test suite
    test_app.e                   # Test runner
  research/
  specs/
  simple_serial.ecf
```

## 2. Source Files

| File | Purpose | Lines |
|------|---------|-------|
| simple_serial.e | Facade and factories | ~145 |
| serial_port.e | Core operations | ~555 |
| serial_port_config.e | Configuration | ~270 |
| serial_port_enumerator.e | Port discovery | ~175 |

## 3. Test Files

| File | Purpose |
|------|---------|
| lib_tests.e | Test suite |
| test_app.e | Test runner |

## 4. Dependencies

### 4.1 External Libraries
| Library | Purpose |
|---------|---------|
| Windows SDK | windows.h for Win32 API |

### 4.2 EiffelBase Dependencies
- C_STRING: String marshalling
- MANAGED_POINTER: Buffer management
- PLATFORM: Platform detection
- ARRAYED_LIST: Port lists
