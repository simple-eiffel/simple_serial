# S03: CONTRACTS - simple_serial

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. SIMPLE_SERIAL Contracts

```eiffel
-- open_port
require
    name_not_empty: not a_name.is_empty
ensure
    open_if_success: attached Result implies Result.is_open

-- open_port_with_config
require
    name_not_empty: not a_name.is_empty
ensure
    open_if_success: attached Result implies Result.is_open

-- create_port
require
    name_not_empty: not a_name.is_empty
ensure
    not_open: not Result.is_open
```

## 2. SERIAL_PORT Contracts

```eiffel
-- make
require
    name_not_empty: not a_port_name.is_empty
ensure
    name_set: port_name.same_string_general (a_port_name)
    not_open: not is_open

-- open_with_config
require
    not_open: not is_open
ensure
    config_updated: config = a_config

-- close
require
    is_open: is_open
ensure
    closed: not is_open

-- read_bytes, read_string
require
    is_open: is_open
    positive_count: a_max_count > 0
ensure
    result_exists: Result /= Void
    valid_count: last_read_count >= 0

-- read_line
require
    is_open: is_open
ensure
    result_exists: Result /= Void

-- write_bytes
require
    is_open: is_open
    bytes_not_empty: not a_bytes.is_empty
ensure
    valid_count: last_write_count >= 0

-- write_string
require
    is_open: is_open
    string_not_empty: not a_string.is_empty
ensure
    valid_count: last_write_count >= 0

-- bytes_available, has_data
require
    is_open: is_open
ensure (bytes_available)
    non_negative: Result >= 0

-- set_dtr, set_rts, flush, purge_*
require
    is_open: is_open

invariant
    name_not_empty: not port_name.is_empty
```

## 3. SERIAL_PORT_CONFIG Contracts

```eiffel
-- make
require
    valid_baud: is_valid_baud_rate (a_baud)
    valid_data_bits: a_data_bits = 7 or a_data_bits = 8
    valid_stop_bits: a_stop_bits >= Stop_bits_one and a_stop_bits <= Stop_bits_two
    valid_parity: a_parity >= Parity_none and a_parity <= Parity_space
ensure
    baud_set: baud_rate = a_baud
    data_bits_set: data_bits = a_data_bits
    stop_bits_set: stop_bits = a_stop_bits
    parity_set: parity = a_parity

-- set_* (all return like Current for chaining)
ensure
    value_set: attribute = a_value
    chained: Result = Current

invariant
    valid_data_bits: data_bits = 7 or data_bits = 8
    valid_stop_bits: stop_bits >= Stop_bits_one and stop_bits <= Stop_bits_two
    valid_parity: parity >= Parity_none and parity <= Parity_space
    valid_flow_control: flow_control >= Flow_control_none and flow_control <= Flow_control_xon_xoff
    non_negative_read_timeout: read_timeout_ms >= 0
    non_negative_write_timeout: write_timeout_ms >= 0
```
