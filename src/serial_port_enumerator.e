note
	description: "[
		Enumerate available serial ports on the system.

		Provides discovery of COM ports (Windows) or /dev/tty* devices (Unix).
		Can filter by device type (e.g., Bluetooth, USB).

		On Windows each port carries its SetupAPI friendly name (such as
		"Standard Serial over Bluetooth link (COM5)") and its hardware id (such
		as "BTHENUM\{00001101-...}"); SERIAL_PORT_CLASSIFIER judges the kind
		from both. `make_empty' with `put_port' or `put_listing' loads fixed
		ports without scanning, for tests.

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

	SERIAL_PORT_CLASSIFIER
		export
			{NONE} all
		end

create
	make,
	make_empty

feature {NONE} -- Initialization

	make
			-- Create enumerator and scan for ports.
		do
			make_empty
			refresh
		end

	make_empty
			-- Create enumerator with no ports and no scan.
		do
			create available_ports.make (10)
			create port_descriptions.make (10)
			create port_hardware_ids.make (10)
		ensure
			no_ports: not has_ports
		end

feature -- Access

	available_ports: ARRAYED_LIST [STRING_32]
			-- List of available port names (e.g., "COM3", "/dev/ttyUSB0").

	port_descriptions: HASH_TABLE [STRING_32, STRING_32]
			-- Descriptions keyed by port name (e.g., "COM3" -> "USB Serial Device (COM3)").

	port_hardware_ids: HASH_TABLE [STRING_32, STRING_32]
			-- Hardware ids keyed by port name (e.g., "COM5" -> "BTHENUM\{00001101-...}").
			-- Only ports whose hardware id is known appear; Windows knows them.

	description_for (a_port: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get description for port, or Void if unknown.
		do
			if port_descriptions.has (a_port.to_string_32) then
				Result := port_descriptions.item (a_port.to_string_32)
			end
		end

	hardware_id_for (a_port: READABLE_STRING_GENERAL): detachable STRING_32
			-- Hardware id of `a_port', or Void if unknown.
		do
			if port_hardware_ids.has (a_port.to_string_32) then
				Result := port_hardware_ids.item (a_port.to_string_32)
			end
		end

	default_description: STRING_32
			-- Description of a port nothing better is known about.
		once
			Result := {STRING_32} "Serial Port"
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
				if is_bluetooth_port (description_or_empty (p), hardware_id_or_empty (p)) then
					Result.extend (p.twin)
				end
			end
		end

	usb_ports: ARRAYED_LIST [STRING_32]
			-- Ports that appear to be USB serial devices.
		do
			create Result.make (5)
			across available_ports as p loop
				if is_usb_port (description_or_empty (p), hardware_id_or_empty (p)) then
					Result.extend (p.twin)
				end
			end
		end

feature -- Operations

	refresh
			-- Rescan for available ports.
		do
			available_ports.wipe_out
			port_descriptions.wipe_out
			port_hardware_ids.wipe_out

			if {PLATFORM}.is_windows then
				scan_windows_ports
			else
				scan_unix_ports
			end
		end

	put_port (a_name, a_description, a_hardware_id: READABLE_STRING_GENERAL)
			-- Record port `a_name' with `a_description' and `a_hardware_id'.
			-- An empty description becomes `default_description'; an empty
			-- hardware id means unknown.
		require
			name_not_empty: not a_name.is_empty
			new_port: not has_port (a_name)
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32
			available_ports.extend (l_name)
			if a_description.is_empty then
				port_descriptions.force (default_description.twin, l_name)
			else
				port_descriptions.force (a_description.to_string_32, l_name)
			end
			if not a_hardware_id.is_empty then
				port_hardware_ids.force (a_hardware_id.to_string_32, l_name)
			end
		ensure
			added: has_port (a_name)
			one_more: count = old count + 1
			described: attached description_for (a_name) as l_description and then
				(a_description.is_empty or else l_description.same_string_general (a_description))
			identified: a_hardware_id.is_empty or else
				(attached hardware_id_for (a_name) as l_hardware_id and then l_hardware_id.same_string_general (a_hardware_id))
		end

	put_listing (a_listing: READABLE_STRING_GENERAL)
			-- Record each port `a_listing' names that is not already known.
			-- One port per line: name, description and hardware id, separated
			-- by tabs, the form the Windows scan reads. A line without a name
			-- is skipped; missing fields are empty.
		local
			l_fields: LIST [STRING_32]
			l_name, l_description, l_hardware_id: STRING_32
		do
			across a_listing.to_string_32.split ('%N') as ic_line loop
				l_fields := ic_line.split ('%T')
				l_name := l_fields.first
				create l_description.make_empty
				create l_hardware_id.make_empty
				if l_fields.count >= 2 then
					l_description := l_fields.i_th (2)
				end
				if l_fields.count >= 3 then
					l_hardware_id := l_fields.i_th (3)
				end
				if not l_name.is_empty and then not has_port (l_name) then
					put_port (l_name, l_description, l_hardware_id)
				end
			end
		ensure
			none_lost: count >= old count
		end

feature {NONE} -- Classification support

	description_or_empty (a_port: READABLE_STRING_GENERAL): STRING_32
			-- Description of `a_port', or empty if unknown.
		do
			if attached description_for (a_port) as l_description then
				Result := l_description
			else
				create Result.make_empty
			end
		end

	hardware_id_or_empty (a_port: READABLE_STRING_GENERAL): STRING_32
			-- Hardware id of `a_port', or empty if unknown.
		do
			if attached hardware_id_for (a_port) as l_hardware_id then
				Result := l_hardware_id
			else
				create Result.make_empty
			end
		end

feature {NONE} -- Windows Implementation

	scan_windows_ports
			-- Record the COM ports SetupAPI lists under the Ports device class,
			-- each with its friendly name and hardware id, then any other port
			-- the SERIALCOMM device map lists (such as a virtual port outside that
			-- class). No port is opened: opening one toggles DTR, which resets
			-- some boards.
		local
			l_buffer: MANAGED_POINTER
			l_needed, l_tries: INTEGER
		do
			create l_buffer.make (16384)
			from
				l_needed := c_port_listing (l_buffer.item, l_buffer.count // 2)
				l_tries := 1
			until
				l_needed <= l_buffer.count // 2 or l_tries >= 3
			loop
				l_buffer.resize (l_needed * 2 + 1024)
				l_needed := c_port_listing (l_buffer.item, l_buffer.count // 2)
				l_tries := l_tries + 1
			end
			if l_needed <= l_buffer.count // 2 then
				put_listing ({UTF_CONVERTER}.utf_16_0_pointer_to_string_32 (l_buffer))
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
					if is_serial_device (l_name) and then not has_port ({STRING_32} "/dev/" + l_name) then
						put_port ({STRING_32} "/dev/" + l_name, device_description (l_name), {STRING_32} "")
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
				Result := default_description.twin
			end
		end

invariant
	every_port_described: port_descriptions.count = available_ports.count
	no_stray_hardware_id: port_hardware_ids.count <= available_ports.count

end
