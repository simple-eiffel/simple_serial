note
	description: "[
		Win32 calls behind SERIAL_PORT and SERIAL_PORT_ENUMERATOR (Windows).

		The ECF selects this class on Windows and its namesake in
		platform/posix elsewhere.
	]"
	author: "Larry Rix"

class
	SERIAL_PORT_PRIMITIVES

feature {NONE} -- Platform

	platform_port_path (a_port_name: STRING_32): STRING_32
			-- Convert port name to Windows path format.
		do
			create Result.make (20)
			if a_port_name.count > 4 and then a_port_name.substring (1, 4).is_case_insensitive_equal ("COM") then
				-- COM10 and above need \\.\COM prefix
				Result.append ("\\.\")
			end
			Result.append (a_port_name)
		end

feature {NONE} -- Windows C externals

	c_invalid_handle: POINTER
			-- Return INVALID_HANDLE_VALUE.
		external
			"C inline use <windows.h>"
		alias
			"return INVALID_HANDLE_VALUE;"
		end

	c_open_port (a_port: POINTER): POINTER
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

	c_close_port (a_handle: POINTER)
			-- Close the port handle.
		external
			"C inline use <windows.h>"
		alias
			"CloseHandle((HANDLE)$a_handle);"
		end

	c_configure_port (a_handle: POINTER; a_baud, a_data_bits, a_stop_bits, a_parity, a_flow: INTEGER): BOOLEAN
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

	c_set_timeouts (a_handle: POINTER; a_read_ms, a_write_ms: INTEGER): BOOLEAN
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

	c_read_port (a_handle, a_buffer: POINTER; a_max_count: INTEGER): INTEGER
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

	c_write_port (a_handle, a_buffer: POINTER; a_count: INTEGER): INTEGER
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

	c_bytes_available (a_handle: POINTER): INTEGER
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

	c_set_dtr (a_handle: POINTER; a_state: BOOLEAN)
			-- Set DTR line state.
		external
			"C inline use <windows.h>"
		alias
			"EscapeCommFunction((HANDLE)$a_handle, $a_state ? SETDTR : CLRDTR);"
		end

	c_set_rts (a_handle: POINTER; a_state: BOOLEAN)
			-- Set RTS line state.
		external
			"C inline use <windows.h>"
		alias
			"EscapeCommFunction((HANDLE)$a_handle, $a_state ? SETRTS : CLRRTS);"
		end

	c_flush (a_handle: POINTER)
			-- Flush output buffer.
		external
			"C inline use <windows.h>"
		alias
			"FlushFileBuffers((HANDLE)$a_handle);"
		end

	c_purge_input (a_handle: POINTER)
			-- Purge input buffer.
		external
			"C inline use <windows.h>"
		alias
			"PurgeComm((HANDLE)$a_handle, PURGE_RXCLEAR);"
		end

	c_purge_output (a_handle: POINTER)
			-- Purge output buffer.
		external
			"C inline use <windows.h>"
		alias
			"PurgeComm((HANDLE)$a_handle, PURGE_TXCLEAR);"
		end

	c_port_exists (a_port: POINTER): BOOLEAN
			-- Check if COM port exists by trying to open it.
		external
			"C inline use <windows.h>"
		alias
			"[
				HANDLE h = CreateFileA(
					(LPCSTR)$a_port,
					GENERIC_READ | GENERIC_WRITE,
					0,
					NULL,
					OPEN_EXISTING,
					0,
					NULL
				);
				if (h != INVALID_HANDLE_VALUE) {
					CloseHandle(h);
					return EIF_TRUE;
				}
				// ERROR_ACCESS_DENIED means port exists but is in use
				return (GetLastError() == ERROR_ACCESS_DENIED) ? EIF_TRUE : EIF_FALSE;
			]"
		end

end
