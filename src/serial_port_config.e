note
	description: "[
		Serial port configuration parameters.

		Holds baud rate, data bits, stop bits, parity, and flow control settings.
		Used by SERIAL_PORT to configure the connection.

		Defaults:
			- 9600 baud
			- 8 data bits
			- 1 stop bit
			- No parity
			- No flow control

		Usage:
			config: SERIAL_PORT_CONFIG
			create config.make_default
			config.set_baud_rate (115200)
			config.set_parity (config.parity_even)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SERIAL_PORT_CONFIG

create
	make_default,
	make

feature {NONE} -- Initialization

	make_default
			-- Create with default settings (9600-8-N-1, no flow control).
		do
			baud_rate := 9600
			data_bits := 8
			stop_bits := Stop_bits_one
			parity := Parity_none
			flow_control := Flow_control_none
			read_timeout_ms := 1000
			write_timeout_ms := 1000
		ensure
			default_baud: baud_rate = 9600
			default_data_bits: data_bits = 8
			default_stop_bits: stop_bits = Stop_bits_one
			default_parity: parity = Parity_none
			default_flow: flow_control = Flow_control_none
		end

	make (a_baud: INTEGER; a_data_bits: INTEGER; a_stop_bits: INTEGER; a_parity: INTEGER)
			-- Create with specified settings.
		require
			valid_baud: is_valid_baud_rate (a_baud)
			valid_data_bits: a_data_bits = 7 or a_data_bits = 8
			valid_stop_bits: a_stop_bits >= Stop_bits_one and a_stop_bits <= Stop_bits_two
			valid_parity: a_parity >= Parity_none and a_parity <= Parity_space
		do
			baud_rate := a_baud
			data_bits := a_data_bits
			stop_bits := a_stop_bits
			parity := a_parity
			flow_control := Flow_control_none
			read_timeout_ms := 1000
			write_timeout_ms := 1000
		ensure
			baud_set: baud_rate = a_baud
			data_bits_set: data_bits = a_data_bits
			stop_bits_set: stop_bits = a_stop_bits
			parity_set: parity = a_parity
		end

feature -- Access

	baud_rate: INTEGER
			-- Communication speed in bits per second.
			-- Common values: 9600, 19200, 38400, 57600, 115200

	data_bits: INTEGER
			-- Number of data bits per byte (7 or 8).

	stop_bits: INTEGER
			-- Number of stop bits (use Stop_bits_* constants).

	parity: INTEGER
			-- Parity checking mode (use Parity_* constants).

	flow_control: INTEGER
			-- Flow control mode (use Flow_control_* constants).

	read_timeout_ms: INTEGER
			-- Read operation timeout in milliseconds.

	write_timeout_ms: INTEGER
			-- Write operation timeout in milliseconds.

feature -- Settings

	set_baud_rate (a_rate: INTEGER): like Current
			-- Set baud rate. Returns Current for chaining.
		require
			valid_rate: is_valid_baud_rate (a_rate)
		do
			baud_rate := a_rate
			Result := Current
		ensure
			rate_set: baud_rate = a_rate
			chained: Result = Current
		end

	set_data_bits (a_bits: INTEGER): like Current
			-- Set data bits (7 or 8). Returns Current for chaining.
		require
			valid_bits: a_bits = 7 or a_bits = 8
		do
			data_bits := a_bits
			Result := Current
		ensure
			bits_set: data_bits = a_bits
			chained: Result = Current
		end

	set_stop_bits (a_stop: INTEGER): like Current
			-- Set stop bits. Returns Current for chaining.
		require
			valid_stop: a_stop >= Stop_bits_one and a_stop <= Stop_bits_two
		do
			stop_bits := a_stop
			Result := Current
		ensure
			stop_set: stop_bits = a_stop
			chained: Result = Current
		end

	set_parity (a_parity: INTEGER): like Current
			-- Set parity mode. Returns Current for chaining.
		require
			valid_parity: a_parity >= Parity_none and a_parity <= Parity_space
		do
			parity := a_parity
			Result := Current
		ensure
			parity_set: parity = a_parity
			chained: Result = Current
		end

	set_flow_control (a_flow: INTEGER): like Current
			-- Set flow control mode. Returns Current for chaining.
		require
			valid_flow: a_flow >= Flow_control_none and a_flow <= Flow_control_xon_xoff
		do
			flow_control := a_flow
			Result := Current
		ensure
			flow_set: flow_control = a_flow
			chained: Result = Current
		end

	set_read_timeout (a_ms: INTEGER): like Current
			-- Set read timeout in milliseconds. Returns Current for chaining.
		require
			non_negative: a_ms >= 0
		do
			read_timeout_ms := a_ms
			Result := Current
		ensure
			timeout_set: read_timeout_ms = a_ms
			chained: Result = Current
		end

	set_write_timeout (a_ms: INTEGER): like Current
			-- Set write timeout in milliseconds. Returns Current for chaining.
		require
			non_negative: a_ms >= 0
		do
			write_timeout_ms := a_ms
			Result := Current
		ensure
			timeout_set: write_timeout_ms = a_ms
			chained: Result = Current
		end

feature -- Validation

	is_valid_baud_rate (a_rate: INTEGER): BOOLEAN
			-- Is `a_rate' a valid baud rate?
		do
			Result := a_rate = 110 or a_rate = 300 or a_rate = 600 or
				a_rate = 1200 or a_rate = 2400 or a_rate = 4800 or
				a_rate = 9600 or a_rate = 14400 or a_rate = 19200 or
				a_rate = 38400 or a_rate = 57600 or a_rate = 115200 or
				a_rate = 128000 or a_rate = 256000 or a_rate = 460800 or
				a_rate = 921600
		end

feature -- Constants: Stop Bits

	Stop_bits_one: INTEGER = 0
			-- One stop bit.

	Stop_bits_one_five: INTEGER = 1
			-- 1.5 stop bits (rarely used).

	Stop_bits_two: INTEGER = 2
			-- Two stop bits.

feature -- Constants: Parity

	Parity_none: INTEGER = 0
			-- No parity.

	Parity_odd: INTEGER = 1
			-- Odd parity.

	Parity_even: INTEGER = 2
			-- Even parity.

	Parity_mark: INTEGER = 3
			-- Mark parity (always 1).

	Parity_space: INTEGER = 4
			-- Space parity (always 0).

feature -- Constants: Flow Control

	Flow_control_none: INTEGER = 0
			-- No flow control.

	Flow_control_hardware: INTEGER = 1
			-- Hardware flow control (RTS/CTS).

	Flow_control_xon_xoff: INTEGER = 2
			-- Software flow control (XON/XOFF).

feature -- Output

	description: STRING_32
			-- Human-readable configuration description.
		do
			create Result.make (50)
			Result.append_integer (baud_rate)
			Result.append_character ('-')
			Result.append_integer (data_bits)
			Result.append_character ('-')
			inspect parity
			when Parity_none then Result.append_character ('N')
			when Parity_odd then Result.append_character ('O')
			when Parity_even then Result.append_character ('E')
			when Parity_mark then Result.append_character ('M')
			when Parity_space then Result.append_character ('S')
			end
			Result.append_character ('-')
			inspect stop_bits
			when Stop_bits_one then Result.append_character ('1')
			when Stop_bits_one_five then Result.append ("1.5")
			when Stop_bits_two then Result.append_character ('2')
			end
		end

invariant
	valid_data_bits: data_bits = 7 or data_bits = 8
	valid_stop_bits: stop_bits >= Stop_bits_one and stop_bits <= Stop_bits_two
	valid_parity: parity >= Parity_none and parity <= Parity_space
	valid_flow_control: flow_control >= Flow_control_none and flow_control <= Flow_control_xon_xoff
	non_negative_read_timeout: read_timeout_ms >= 0
	non_negative_write_timeout: write_timeout_ms >= 0

end
