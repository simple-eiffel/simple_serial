note
	description: "[
		termios calls behind SERIAL_PORT and SERIAL_PORT_ENUMERATOR (macOS and
		Linux). Clib/simple_serial_posix.h holds the C.

		The ECF selects this class off Windows and its namesake in
		platform/windows there.
	]"
	author: "Larry Rix"

class
	SERIAL_PORT_PRIMITIVES

feature {NONE} -- Platform

	platform_port_path (a_port_name: STRING_32): STRING_32
			-- The device path: on POSIX the port name already is one.
		do
			Result := a_port_name
		end

	read_timeout: INTEGER
			-- From the last `c_set_timeouts', in milliseconds.

	write_timeout: INTEGER
			-- From the last `c_set_timeouts', in milliseconds.

feature {NONE} -- POSIX operations

	c_invalid_handle: POINTER
			-- The handle meaning no port.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"return (EIF_POINTER) (intptr_t) -1;"
		end

	c_open_port (a_port: POINTER): POINTER
			-- Open serial port, return handle or `c_invalid_handle'.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"return (EIF_POINTER) ssp_open ((const char *) $a_port);"
		end

	c_close_port (a_handle: POINTER)
			-- Close the port handle.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"close (ssp_fd ((void *) $a_handle));"
		end

	c_configure_port (a_handle: POINTER; a_baud, a_data_bits, a_stop_bits, a_parity, a_flow: INTEGER): BOOLEAN
			-- Configure serial port settings.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"return ssp_configure ((void *) $a_handle, (int) $a_baud, (int) $a_data_bits, (int) $a_stop_bits, (int) $a_parity, (int) $a_flow) ? EIF_TRUE : EIF_FALSE;"
		end

	c_set_timeouts (a_handle: POINTER; a_read_ms, a_write_ms: INTEGER): BOOLEAN
			-- Remember the timeouts: each read and write waits by them.
		do
			read_timeout := a_read_ms
			write_timeout := a_write_ms
			Result := True
		end

	c_read_port (a_handle, a_buffer: POINTER; a_max_count: INTEGER): INTEGER
			-- Read from port, return bytes read or -1 on error.
		do
			Result := c_read (a_handle, a_buffer, a_max_count, read_timeout)
		end

	c_write_port (a_handle, a_buffer: POINTER; a_count: INTEGER): INTEGER
			-- Write to port, return bytes written or -1 on error.
		do
			Result := c_write (a_handle, a_buffer, a_count, write_timeout)
		end

	c_read (a_handle, a_buffer: POINTER; a_max_count, a_timeout_ms: INTEGER): INTEGER
			-- Marked `blocking': it waits. `a_buffer' is a MANAGED_POINTER on the C heap.
		external
			"C blocking inline use %"simple_serial_posix.h%""
		alias
			"return ssp_read ((void *) $a_handle, (void *) $a_buffer, (int) $a_max_count, (int) $a_timeout_ms);"
		end

	c_write (a_handle, a_buffer: POINTER; a_count, a_timeout_ms: INTEGER): INTEGER
			-- Marked `blocking': it waits. `a_buffer' is a MANAGED_POINTER on the C heap.
		external
			"C blocking inline use %"simple_serial_posix.h%""
		alias
			"return ssp_write ((void *) $a_handle, (const void *) $a_buffer, (int) $a_count, (int) $a_timeout_ms);"
		end

	c_bytes_available (a_handle: POINTER): INTEGER
			-- Return number of bytes available to read.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"return ssp_bytes_available ((void *) $a_handle);"
		end

	c_set_dtr (a_handle: POINTER; a_state: BOOLEAN)
			-- Set DTR line state.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"ssp_set_dtr ((void *) $a_handle, (int) $a_state);"
		end

	c_set_rts (a_handle: POINTER; a_state: BOOLEAN)
			-- Set RTS line state.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"ssp_set_rts ((void *) $a_handle, (int) $a_state);"
		end

	c_flush (a_handle: POINTER)
			-- Wait until all output is sent. Marked `blocking': it waits.
		external
			"C blocking inline use %"simple_serial_posix.h%""
		alias
			"tcdrain (ssp_fd ((void *) $a_handle));"
		end

	c_purge_input (a_handle: POINTER)
			-- Purge input buffer.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"tcflush (ssp_fd ((void *) $a_handle), TCIFLUSH);"
		end

	c_purge_output (a_handle: POINTER)
			-- Purge output buffer.
		external
			"C inline use %"simple_serial_posix.h%""
		alias
			"tcflush (ssp_fd ((void *) $a_handle), TCOFLUSH);"
		end

	c_port_exists (a_port: POINTER): BOOLEAN
			-- Only the Windows scan asks this.
		do
			Result := False
		end

end
