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

	c_port_listing (a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- Write the COM ports into `a_buffer' as zero-terminated UTF-16 of at
			-- most `a_capacity' units, one port per line: name, description and
			-- hardware id separated by tabs. First the Ports device class from
			-- SetupAPI (friendly name, else device description; first hardware
			-- id), then every port in the SERIALCOMM device map with empty
			-- description and hardware id (the caller keeps the first record of
			-- each name). Opens no port. Returns the units the whole listing
			-- needs, terminator included; a larger value than `a_capacity' means
			-- the listing was cut short.
		external
			"C inline use <windows.h>, <setupapi.h>"
		alias
			"[
				static const GUID l_ports_class = {0x4D36E978, 0xE325, 0x11CE, {0xBF, 0xC1, 0x08, 0x00, 0x2B, 0xE1, 0x03, 0x18}};
				WCHAR *l_out = (WCHAR *) $a_buffer;
				int l_capacity = (int) $a_capacity;
				int l_used = 0;
				int l_phase = 0;
				int l_has_record, l_field;
				DWORD l_index = 0;
				DWORD l_size, l_value_size, l_type;
				HDEVINFO l_set;
				SP_DEVINFO_DATA l_info;
				HKEY l_key;
				HKEY l_map = NULL;
				WCHAR l_name [256];
				WCHAR l_description [512];
				WCHAR l_hardware_id [512];
				WCHAR l_value [256];
				const WCHAR *l_fields [3];
				const WCHAR *l_char;

				l_set = SetupDiGetClassDevsW (&l_ports_class, NULL, NULL, DIGCF_PRESENT);
				if (RegOpenKeyExW (HKEY_LOCAL_MACHINE, L"HARDWARE\\DEVICEMAP\\SERIALCOMM", 0, KEY_READ, &l_map) != ERROR_SUCCESS) {
					l_map = NULL;
				}
				l_info.cbSize = sizeof (l_info);
				while (l_phase < 2) {
					l_has_record = 0;
					memset (l_name, 0, sizeof (l_name));
					memset (l_description, 0, sizeof (l_description));
					memset (l_hardware_id, 0, sizeof (l_hardware_id));
					if (l_phase == 0) {
						if (l_set != INVALID_HANDLE_VALUE && SetupDiEnumDeviceInfo (l_set, l_index, &l_info)) {
							l_key = SetupDiOpenDevRegKey (l_set, &l_info, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_READ);
							if (l_key != INVALID_HANDLE_VALUE) {
								l_size = sizeof (l_name) - sizeof (WCHAR);
								if (RegQueryValueExW (l_key, L"PortName", NULL, &l_type, (LPBYTE) l_name, &l_size) != ERROR_SUCCESS || l_type != REG_SZ) {
									memset (l_name, 0, sizeof (l_name));
								}
								RegCloseKey (l_key);
							}
							if (!SetupDiGetDeviceRegistryPropertyW (l_set, &l_info, SPDRP_FRIENDLYNAME, NULL, (PBYTE) l_description, sizeof (l_description) - sizeof (WCHAR), NULL)) {
								memset (l_description, 0, sizeof (l_description));
								if (!SetupDiGetDeviceRegistryPropertyW (l_set, &l_info, SPDRP_DEVICEDESC, NULL, (PBYTE) l_description, sizeof (l_description) - sizeof (WCHAR), NULL)) {
									memset (l_description, 0, sizeof (l_description));
								}
							}
							if (!SetupDiGetDeviceRegistryPropertyW (l_set, &l_info, SPDRP_HARDWAREID, NULL, (PBYTE) l_hardware_id, sizeof (l_hardware_id) - 2 * sizeof (WCHAR), NULL)) {
								memset (l_hardware_id, 0, sizeof (l_hardware_id));
							}
							l_has_record = _wcsnicmp (l_name, L"COM", 3) == 0;
							l_index++;
						} else {
							l_phase = 1;
							l_index = 0;
						}
					} else {
						l_value_size = sizeof (l_value) / sizeof (WCHAR);
						l_size = sizeof (l_name) - sizeof (WCHAR);
						if (l_map != NULL && RegEnumValueW (l_map, l_index, l_value, &l_value_size, NULL, &l_type, (LPBYTE) l_name, &l_size) == ERROR_SUCCESS) {
							l_has_record = l_type == REG_SZ && l_name [0] != 0;
							l_index++;
						} else {
							l_phase = 2;
						}
					}
					if (l_has_record) {
						l_fields [0] = l_name;
						l_fields [1] = l_description;
						l_fields [2] = l_hardware_id;
						for (l_field = 0; l_field < 3; l_field++) {
							for (l_char = l_fields [l_field]; *l_char != 0; l_char++) {
								if (l_used + 1 < l_capacity) {
									l_out [l_used] = (*l_char == L'\t' || *l_char == L'\n' || *l_char == L'\r') ? L' ' : *l_char;
								}
								l_used++;
							}
							if (l_used + 1 < l_capacity) {
								l_out [l_used] = (l_field < 2) ? L'\t' : L'\n';
							}
							l_used++;
						}
					}
				}
				if (l_set != INVALID_HANDLE_VALUE) {
					SetupDiDestroyDeviceInfoList (l_set);
				}
				if (l_map != NULL) {
					RegCloseKey (l_map);
				}
				if (l_capacity > 0) {
					l_out [(l_used < l_capacity) ? l_used : l_capacity - 1] = 0;
				}
				return (EIF_INTEGER) (l_used + 1);
			]"
		end

end
