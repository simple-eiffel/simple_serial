note
	description: "[
		Enumerate available serial ports on the system.

		Provides discovery of COM ports (Windows) or /dev/tty* devices (Unix).
		Can filter by device type (e.g., Bluetooth, USB).

		Usage:
			ports: SERIAL_PORT_ENUMERATOR
			create ports.make
			ports.refresh
			across ports.available_ports as p loop
				print (p + "%N")
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SERIAL_PORT_ENUMERATOR

inherit
	SERIAL_PORT_PRIMITIVES

create
	make

feature {NONE} -- Initialization

	make
			-- Create enumerator and scan for ports.
		do
			create available_ports.make (10)
			create port_descriptions.make (10)
			refresh
		end

feature -- Access

	available_ports: ARRAYED_LIST [STRING_32]
			-- List of available port names (e.g., "COM3", "/dev/ttyUSB0").

	port_descriptions: HASH_TABLE [STRING_32, STRING_32]
			-- Descriptions keyed by port name (e.g., "COM3" -> "USB Serial Port").

	description_for (a_port: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get description for port, or Void if unknown.
		do
			if port_descriptions.has (a_port.to_string_32) then
				Result := port_descriptions.item (a_port.to_string_32)
			end
		end

feature -- Status

	count: INTEGER
			-- Number of available ports.
		do
			Result := available_ports.count
		end

	has_ports: BOOLEAN
			-- Are any ports available?
		do
			Result := not available_ports.is_empty
		end

	has_port (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_name' an available port?
		do
			Result := across available_ports as p some p.same_string_general (a_name) end
		end

feature -- Query

	bluetooth_ports: ARRAYED_LIST [STRING_32]
			-- Ports that appear to be Bluetooth SPP devices.
		do
			create Result.make (5)
			across available_ports as p loop
				if attached description_for (p) as desc then
					if desc.as_lower.has_substring ("bluetooth") or
						desc.as_lower.has_substring ("bth") or
						desc.as_lower.has_substring ("rfcomm") then
						Result.extend (p.twin)
					end
				end
			end
		end

	usb_ports: ARRAYED_LIST [STRING_32]
			-- Ports that appear to be USB serial devices.
		do
			create Result.make (5)
			across available_ports as p loop
				if attached description_for (p) as desc then
					if desc.as_lower.has_substring ("usb") or
						desc.as_lower.has_substring ("ch340") or
						desc.as_lower.has_substring ("cp210") or
						desc.as_lower.has_substring ("ftdi") or
						desc.as_lower.has_substring ("pl2303") then
						Result.extend (p.twin)
					end
				end
			end
		end

feature -- Operations

	refresh
			-- Rescan for available ports.
		do
			available_ports.wipe_out
			port_descriptions.wipe_out

			if {PLATFORM}.is_windows then
				scan_windows_ports
			else
				scan_unix_ports
			end
		end

feature {NONE} -- Windows Implementation

	scan_windows_ports
			-- Scan for COM ports on Windows.
		local
			i: INTEGER
			l_port_name: STRING_32
			l_path: C_STRING
		do
			-- Simple approach: try COM1 through COM256
			from i := 1 until i > 256 loop
				l_port_name := "COM" + i.out
				create l_path.make ("\\.\COM" + i.out)
				if c_port_exists (l_path.item) then
					available_ports.extend (l_port_name)
					port_descriptions.force ("Serial Port", l_port_name)
				end
				i := i + 1
			end
		end

feature {NONE} -- Unix Implementation

	scan_unix_ports
			-- Scan /dev: cu.* on macOS, and USB, ACM and rfcomm devices on Linux.
		local
			l_folder: DIRECTORY
			l_name: STRING_32
		do
			create l_folder.make ("/dev")
			if l_folder.exists and then l_folder.is_readable then
				across l_folder.entries as ic loop
					l_name := ic.name
					if is_serial_device (l_name) then
						available_ports.extend ({STRING_32} "/dev/" + l_name)
						port_descriptions.force (device_description (l_name), {STRING_32} "/dev/" + l_name)
					end
				end
			end
		end

	is_serial_device (a_name: READABLE_STRING_32): BOOLEAN
			-- Does `a_name' in /dev look like a serial port?
		do
			Result := a_name.starts_with ({STRING_32} "cu.") or a_name.starts_with ({STRING_32} "ttyUSB")
				or a_name.starts_with ({STRING_32} "ttyACM") or a_name.starts_with ({STRING_32} "rfcomm")
		end

	device_description (a_name: READABLE_STRING_32): STRING_32
			-- What `a_name' suggests the device is.
		local
			l_lower: STRING_32
		do
			l_lower := a_name.as_lower
			if l_lower.has_substring ({STRING_32} "bluetooth") or l_lower.has_substring ({STRING_32} "rfcomm") then
				Result := {STRING_32} "Bluetooth Serial Port"
			elseif l_lower.has_substring ({STRING_32} "usb") or l_lower.has_substring ({STRING_32} "acm") then
				Result := {STRING_32} "USB Serial Port"
			else
				Result := {STRING_32} "Serial Port"
			end
		end

end
