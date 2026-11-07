note
	description: "[
		Cross-platform serial port communication.

		Provides read/write access to serial ports (COM ports on Windows,
		/dev/tty* on Linux and /dev/cu.* on macOS). SERIAL_PORT_PRIMITIVES holds
		the platform calls, one class per platform.

		Usage:
			port: SERIAL_PORT
			create port.make ("COM3")
			port.open_with_config (create {SERIAL_PORT_CONFIG}.make_default.set_baud_rate (115200))
			if port.is_open then
				port.write_string ("Hello")
				print (port.read_string (100))
				port.close
			end

		Note: Bluetooth SPP devices appear as COM ports after pairing.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SERIAL_PORT

inherit
	SERIAL_PORT_PRIMITIVES

create
	make

feature {NONE} -- Initialization

	make (a_port_name: READABLE_STRING_GENERAL)
			-- Create serial port for `a_port_name' (e.g., "COM3" or "/dev/ttyUSB0").
		require
			name_not_empty: not a_port_name.is_empty
		do
			port_name := a_port_name.to_string_32
			handle := Invalid_handle
			create config.make_default
			last_error := Void
		ensure
			name_set: port_name.same_string_general (a_port_name)
			not_open: not is_open
		end

feature -- Access

	port_name: STRING_32
			-- Name of the serial port (e.g., "COM3", "/dev/ttyUSB0").

	config: SERIAL_PORT_CONFIG
			-- Current configuration.

	last_error: detachable STRING_32
			-- Error message from last failed operation.

	last_read_count: INTEGER
			-- Number of bytes read in last read operation.

	last_write_count: INTEGER
			-- Number of bytes written in last write operation.

feature -- Status

	is_open: BOOLEAN
			-- Is the port currently open?
		do
			Result := handle /= Invalid_handle
		end

feature -- Connection

	open: BOOLEAN
			-- Open the port with default configuration (9600-8-N-1).
		do
			Result := open_with_config (config)
		ensure
			open_implies_result: is_open implies Result
		end

	open_with_config (a_config: SERIAL_PORT_CONFIG): BOOLEAN
			-- Open the port with specified configuration.
		require
			not_open: not is_open
		local
			l_port_c: C_STRING
		do
			config := a_config
			last_error := Void

			create l_port_c.make (platform_port_path (port_name))
			handle := c_open_port (l_port_c.item)
			if handle /= Invalid_handle then
				if c_configure_port (handle, config.baud_rate, config.data_bits,
					config.stop_bits, config.parity, config.flow_control) then
					if c_set_timeouts (handle, config.read_timeout_ms, config.write_timeout_ms) then
						Result := True
					else
						last_error := "Failed to set timeouts"
						c_close_port (handle)
						handle := Invalid_handle
					end
				else
					last_error := "Failed to configure port"
					c_close_port (handle)
					handle := Invalid_handle
				end
			else
				last_error := "Failed to open port: " + port_name
			end
		ensure
			config_updated: config = a_config
		end

	close
			-- Close the port.
		require
			is_open: is_open
		do
			c_close_port (handle)
			handle := Invalid_handle
			last_error := Void
		ensure
			closed: not is_open
		end

feature -- Read Operations

	read_bytes (a_max_count: INTEGER): ARRAY [NATURAL_8]
			-- Read up to `a_max_count' bytes. Check `last_read_count' for actual count.
		require
			is_open: is_open
			positive_count: a_max_count > 0
		local
			l_buffer: MANAGED_POINTER
			i: INTEGER
		do
			create l_buffer.make (a_max_count)
			last_read_count := 0
			last_error := Void

			last_read_count := c_read_port (handle, l_buffer.item, a_max_count)
			if last_read_count < 0 then
				last_error := "Read failed"
				last_read_count := 0
			end

			create Result.make_filled (0, 1, last_read_count.max (0))
			from i := 1 until i > last_read_count loop
				Result [i] := l_buffer.read_natural_8 (i - 1)
				i := i + 1
			end
		ensure
			result_exists: Result /= Void
			valid_count: last_read_count >= 0
		end

	read_string (a_max_length: INTEGER): STRING_8
			-- Read up to `a_max_length' characters as string.
		require
			is_open: is_open
			positive_length: a_max_length > 0
		local
			l_bytes: ARRAY [NATURAL_8]
			i: INTEGER
		do
			l_bytes := read_bytes (a_max_length)
			create Result.make (last_read_count)
			from i := 1 until i > last_read_count loop
				Result.append_character (l_bytes [i].to_character_8)
				i := i + 1
			end
		ensure
			result_exists: Result /= Void
		end

	read_line: STRING_8
			-- Read until newline or timeout.
		require
			is_open: is_open
		local
			l_char: STRING_8
			l_done: BOOLEAN
		do
			create Result.make (80)
			from until l_done loop
				l_char := read_string (1)
				if last_read_count = 0 then
					l_done := True
				elseif l_char [1] = '%N' then
					l_done := True
				elseif l_char [1] /= '%R' then
					Result.append (l_char)
				end
			end
		ensure
			result_exists: Result /= Void
		end

feature -- Write Operations

	write_bytes (a_bytes: ARRAY [NATURAL_8]): BOOLEAN
			-- Write `a_bytes' to port. Returns True on success.
		require
			is_open: is_open
			bytes_not_empty: not a_bytes.is_empty
		local
			l_buffer: MANAGED_POINTER
			i: INTEGER
		do
			create l_buffer.make (a_bytes.count)
			from i := 1 until i > a_bytes.count loop
				l_buffer.put_natural_8 (a_bytes [i], i - 1)
				i := i + 1
			end

			last_write_count := 0
			last_error := Void

			last_write_count := c_write_port (handle, l_buffer.item, a_bytes.count)
			if last_write_count < 0 then
				last_error := "Write failed"
				last_write_count := 0
			else
				Result := last_write_count = a_bytes.count
			end
		ensure
			valid_count: last_write_count >= 0
		end

	write_string (a_string: READABLE_STRING_8): BOOLEAN
			-- Write `a_string' to port. Returns True on success.
		require
			is_open: is_open
			string_not_empty: not a_string.is_empty
		local
			l_bytes: ARRAY [NATURAL_8]
			i: INTEGER
		do
			create l_bytes.make_filled (0, 1, a_string.count)
			from i := 1 until i > a_string.count loop
				l_bytes [i] := a_string [i].code.to_natural_8
				i := i + 1
			end
			Result := write_bytes (l_bytes)
		ensure
			valid_count: last_write_count >= 0
		end

	write_line (a_string: READABLE_STRING_8): BOOLEAN
			-- Write `a_string' followed by newline.
		require
			is_open: is_open
		do
			if a_string.is_empty then
				Result := write_string ("%N")
			else
				Result := write_string (a_string + "%N")
			end
		end

feature -- Status

	bytes_available: INTEGER
			-- Number of bytes available to read (0 if unknown or error).
		require
			is_open: is_open
		do
			Result := c_bytes_available (handle)
			if Result < 0 then
				Result := 0
			end
		ensure
			non_negative: Result >= 0
		end

	has_data: BOOLEAN
			-- Is data available to read?
		require
			is_open: is_open
		do
			Result := bytes_available > 0
		end

feature -- Flow Control

	set_dtr (a_state: BOOLEAN)
			-- Set DTR (Data Terminal Ready) line state.
		require
			is_open: is_open
		do
			c_set_dtr (handle, a_state)
		end

	set_rts (a_state: BOOLEAN)
			-- Set RTS (Request To Send) line state.
		require
			is_open: is_open
		do
			c_set_rts (handle, a_state)
		end

	flush
			-- Flush output buffer (wait for all data to be sent).
		require
			is_open: is_open
		do
			c_flush (handle)
		end

	purge_input
			-- Discard any data in input buffer.
		require
			is_open: is_open
		do
			c_purge_input (handle)
		end

	purge_output
			-- Discard any data in output buffer.
		require
			is_open: is_open
		do
			c_purge_output (handle)
		end

feature {NONE} -- Implementation

	handle: POINTER
			-- Platform-specific handle (HANDLE on Windows, descriptor elsewhere).

	Invalid_handle: POINTER
			-- Invalid handle value.
		once
			Result := c_invalid_handle
		end


invariant
	name_not_empty: not port_name.is_empty

end
