# 7S-03: SOLUTIONS - simple_serial


**Date**: 2026-01-23

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Existing Solutions Evaluated

### 1.1 WEL (Windows Eiffel Library)
- **Pros**: Full Windows support
- **Cons**: Heavy dependency, Windows-only
- **Decision**: Create lightweight alternative

### 1.2 Direct Win32 API
- **Pros**: Full control, no dependencies
- **Cons**: Platform-specific
- **Decision**: Use with platform abstraction

### 1.3 libserialport
- **Pros**: Cross-platform C library
- **Cons**: External dependency
- **Decision**: Inline C for simplicity

## 2. Chosen Approach

### 2.1 Architecture
Multi-class design:
- SIMPLE_SERIAL: Main facade with factory methods
- SERIAL_PORT: Core port operations
- SERIAL_PORT_CONFIG: Configuration object
- SERIAL_PORT_ENUMERATOR: Port discovery

### 2.2 Key Design Decisions

1. **Inline C**: No external C files, all Win32 calls inline
2. **Platform detection**: PLATFORM.is_windows for conditional code
3. **Fluent config**: Chained setters return Current
4. **Factory facade**: SIMPLE_SERIAL provides convenience methods

### 2.3 Trade-offs
- Linux/macOS implementation placeholder (not complete)
- No async I/O (simplicity)
- Port enumeration via brute force (COM1-256)
