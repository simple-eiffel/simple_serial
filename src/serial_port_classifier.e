note
	description: "[
		What kind of device a serial port is, judged from its description and
		its hardware id.

		Pure: it scans nothing, so tests can hand it fixed names. On Windows the
		description is the SetupAPI friendly name, such as
		"Standard Serial over Bluetooth link (COM5)", and the hardware id is the
		first SetupAPI hardware id, such as "BTHENUM\{00001101-...}" or
		"USB\VID_2341&PID_0043". On Linux and macOS the description comes from
		the /dev name and there is no hardware id (an empty string).

		Bluetooth wins over USB: a port carried over a Bluetooth link is a
		Bluetooth port even when the Bluetooth adapter sits on USB.
	]"
	author: "Larry Rix"

class
	SERIAL_PORT_CLASSIFIER

feature -- Classification

	is_bluetooth_port (a_description, a_hardware_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Do `a_description' or `a_hardware_id' (empty when unknown) name a Bluetooth link?
		local
			l_description, l_hardware_id: STRING_32
		do
			l_description := a_description.to_string_32.as_lower
			l_hardware_id := a_hardware_id.to_string_32.as_lower
			Result := l_description.has_substring ({STRING_32} "bluetooth")
				or l_description.has_substring ({STRING_32} "bth")
				or l_description.has_substring ({STRING_32} "rfcomm")
				or l_hardware_id.starts_with ({STRING_32} "bth")
				or l_hardware_id.has_substring ({STRING_32} "rfcomm")
		end

	is_usb_port (a_description, a_hardware_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Do `a_description' or `a_hardware_id' (empty when unknown) name a USB serial
			-- device that is not a Bluetooth link?
		local
			l_description, l_hardware_id: STRING_32
		do
			if not is_bluetooth_port (a_description, a_hardware_id) then
				l_description := a_description.to_string_32.as_lower
				l_hardware_id := a_hardware_id.to_string_32.as_lower
				Result := l_description.has_substring ({STRING_32} "usb")
					or l_description.has_substring ({STRING_32} "ch340")
					or l_description.has_substring ({STRING_32} "cp210")
					or l_description.has_substring ({STRING_32} "ftdi")
					or l_description.has_substring ({STRING_32} "pl2303")
					or l_hardware_id.starts_with ({STRING_32} "usb\")
					or l_hardware_id.starts_with ({STRING_32} "ftdibus\")
					or l_hardware_id.has_substring ({STRING_32} "vid_")
			end
		ensure
			bluetooth_excluded: Result implies not is_bluetooth_port (a_description, a_hardware_id)
		end

end
