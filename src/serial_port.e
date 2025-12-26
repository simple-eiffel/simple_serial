note
	description: "[
		Cross-platform serial port communication.

		Provides read/write access to serial ports (COM ports on Windows,
		/dev/tty* on Linux/macOS). Uses inline C for platform-specific APIs.

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

			if {PLATFORM}.is_windows then
				create l_port_c.make (windows_port_path)
				handle := c_open_port_windows (l_port_c.item)
				if handle /= Invalid_handle then
					if c_configure_port_windows (handle, config.baud_rate, config.data_bits,
						config.stop_bits, config.parity, config.flow_control) then
						if c_set_timeouts_windows (handle, config.read_timeout_ms, config.write_timeout_ms) then
							Result := True
						else
							last_error := "Failed to set timeouts"
							c_close_port_windows (handle)
							handle := Invalid_handle
						end
					else
						last_error := "Failed to configure port"
						c_close_port_windows (handle)
						handle := Invalid_handle
					end
				else
					last_error := "Failed to open port: " + port_name
				end
			else
				-- Linux/macOS implementation would go here
				last_error := "Platform not yet supported"
			end
		ensure
			config_updated: config = a_config
		end

	close
			-- Close the port.
		require
			is_open: is_open
		do
			if {PLATFORM}.is_windows then
				c_close_port_windows (handle)
			end
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

			if {PLATFORM}.is_windows then
				last_read_count := c_read_port_windows (handle, l_buffer.item, a_max_count)
				if last_read_count < 0 then
					last_error := "Read failed"
					last_read_count := 0
				end
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

			if {PLATFORM}.is_windows then
				last_write_count := c_write_port_windows (handle, l_buffer.item, a_bytes.count)
				if last_write_count < 0 then
					last_error := "Write failed"
					last_write_count := 0
				else
					Result := last_write_count = a_bytes.count
				end
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
			if {PLATFORM}.is_windows then
				Result := c_bytes_available_windows (handle)
				if Result < 0 then
					Result := 0
				end
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
			if {PLATFORM}.is_windows then
				c_set_dtr_windows (handle, a_state)
			end
		end

	set_rts (a_state: BOOLEAN)
			-- Set RTS (Request To Send) line state.
		require
			is_open: is_open
		do
			if {PLATFORM}.is_windows then
				c_set_rts_windows (handle, a_state)
			end
		end

	flush
			-- Flush output buffer (wait for all data to be sent).
		require
			is_open: is_open
		do
			if {PLATFORM}.is_windows then
				c_flush_windows (handle)
			end
		end

	purge_input
			-- Discard any data in input buffer.
		require
			is_open: is_open
		do
			if {PLATFORM}.is_windows then
				c_purge_input_windows (handle)
			end
		end

	purge_output
			-- Discard any data in output buffer.
		require
			is_open: is_open
		do
			if {PLATFORM}.is_windows then
				c_purge_output_windows (handle)
			end
		end

feature {NONE} -- Implementation

	handle: POINTER
			-- Platform-specific handle (HANDLE on Windows, fd on Unix).

	Invalid_handle: POINTER
			-- Invalid handle value.
		once
			Result := c_invalid_handle
		end

	windows_port_path: STRING_32
			-- Convert port name to Windows path format.
		do
			create Result.make (20)
			if port_name.count > 4 and then port_name.substring (1, 4).is_case_insensitive_equal ("COM") then
				-- COM10 and above need \\.\COM prefix
				Result.append ("\\.\")
			end
			Result.append (port_name)
		end

feature {NONE} -- Windows C externals

	c_invalid_handle: POINTER
			-- Return INVALID_HANDLE_VALUE.
		external
			"C inline use <windows.h>"
		alias
			"return INVALID_HANDLE_VALUE;"
		end

	c_open_port_windows (a_port: POINTER): POINTER
			-- Open serial port, return handle or INVALID_HANDLE_VALUE.
		external
			"C inline use <windows.h>"
		alias
			"[
				return CreateFileA(
					(LPCSTR)$a_port,
					GENERIC_READ | GENERIC_WRITE,
					0,
					NULL,
					OPEN_EXISTING,
					0,
					NULL
				);
			]"
		end

	c_close_port_windows (a_handle: POINTER)
			-- Close the port handle.
		external
			"C inline use <windows.h>"
		alias
			"CloseHandle((HANDLE)$a_handle);"
		end

	c_configure_port_windows (a_handle: POINTER; a_baud, a_data_bits, a_stop_bits, a_parity, a_flow: INTEGER): BOOLEAN
			-- Configure serial port settings.
		external
			"C inline use <windows.h>"
		alias
			"[
				DCB dcb;
				memset(&dcb, 0, sizeof(dcb));
				dcb.DCBlength = sizeof(dcb);

				if (!GetCommState((HANDLE)$a_handle, &dcb)) {
					return EIF_FALSE;
				}

				dcb.BaudRate = (DWORD)$a_baud;
				dcb.ByteSize = (BYTE)$a_data_bits;
				dcb.StopBits = (BYTE)$a_stop_bits;
				dcb.Parity = (BYTE)$a_parity;

				// Flow control
				if ($a_flow == 1) {
					// Hardware flow control
					dcb.fOutxCtsFlow = TRUE;
					dcb.fRtsControl = RTS_CONTROL_HANDSHAKE;
				} else if ($a_flow == 2) {
					// Software flow control
					dcb.fInX = TRUE;
					dcb.fOutX = TRUE;
					dcb.XonChar = 0x11;
					dcb.XoffChar = 0x13;
				} else {
					dcb.fOutxCtsFlow = FALSE;
					dcb.fRtsControl = RTS_CONTROL_DISABLE;
					dcb.fInX = FALSE;
					dcb.fOutX = FALSE;
				}

				dcb.fBinary = TRUE;
				dcb.fDtrControl = DTR_CONTROL_ENABLE;

				return SetCommState((HANDLE)$a_handle, &dcb) ? EIF_TRUE : EIF_FALSE;
			]"
		end

	c_set_timeouts_windows (a_handle: POINTER; a_read_ms, a_write_ms: INTEGER): BOOLEAN
			-- Set read/write timeouts.
		external
			"C inline use <windows.h>"
		alias
			"[
				COMMTIMEOUTS timeouts;
				timeouts.ReadIntervalTimeout = 50;
				timeouts.ReadTotalTimeoutMultiplier = 10;
				timeouts.ReadTotalTimeoutConstant = (DWORD)$a_read_ms;
				timeouts.WriteTotalTimeoutMultiplier = 10;
				timeouts.WriteTotalTimeoutConstant = (DWORD)$a_write_ms;
				return SetCommTimeouts((HANDLE)$a_handle, &timeouts) ? EIF_TRUE : EIF_FALSE;
			]"
		end

	c_read_port_windows (a_handle, a_buffer: POINTER; a_max_count: INTEGER): INTEGER
			-- Read from port, return bytes read or -1 on error.
		external
			"C inline use <windows.h>"
		alias
			"[
				DWORD bytes_read = 0;
				if (ReadFile((HANDLE)$a_handle, $a_buffer, (DWORD)$a_max_count, &bytes_read, NULL)) {
					return (EIF_INTEGER)bytes_read;
				}
				return -1;
			]"
		end

	c_write_port_windows (a_handle, a_buffer: POINTER; a_count: INTEGER): INTEGER
			-- Write to port, return bytes written or -1 on error.
		external
			"C inline use <windows.h>"
		alias
			"[
				DWORD bytes_written = 0;
				if (WriteFile((HANDLE)$a_handle, $a_buffer, (DWORD)$a_count, &bytes_written, NULL)) {
					return (EIF_INTEGER)bytes_written;
				}
				return -1;
			]"
		end

	c_bytes_available_windows (a_handle: POINTER): INTEGER
			-- Return number of bytes available to read.
		external
			"C inline use <windows.h>"
		alias
			"[
				COMSTAT stat;
				DWORD errors;
				if (ClearCommError((HANDLE)$a_handle, &errors, &stat)) {
					return (EIF_INTEGER)stat.cbInQue;
				}
				return -1;
			]"
		end

	c_set_dtr_windows (a_handle: POINTER; a_state: BOOLEAN)
			-- Set DTR line state.
		external
			"C inline use <windows.h>"
		alias
			"EscapeCommFunction((HANDLE)$a_handle, $a_state ? SETDTR : CLRDTR);"
		end

	c_set_rts_windows (a_handle: POINTER; a_state: BOOLEAN)
			-- Set RTS line state.
		external
			"C inline use <windows.h>"
		alias
			"EscapeCommFunction((HANDLE)$a_handle, $a_state ? SETRTS : CLRRTS);"
		end

	c_flush_windows (a_handle: POINTER)
			-- Flush output buffer.
		external
			"C inline use <windows.h>"
		alias
			"FlushFileBuffers((HANDLE)$a_handle);"
		end

	c_purge_input_windows (a_handle: POINTER)
			-- Purge input buffer.
		external
			"C inline use <windows.h>"
		alias
			"PurgeComm((HANDLE)$a_handle, PURGE_RXCLEAR);"
		end

	c_purge_output_windows (a_handle: POINTER)
			-- Purge output buffer.
		external
			"C inline use <windows.h>"
		alias
			"PurgeComm((HANDLE)$a_handle, PURGE_TXCLEAR);"
		end

invariant
	name_not_empty: not port_name.is_empty

end
