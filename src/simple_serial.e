note
	description: "[
		SIMPLE_SERIAL - Serial Port Communication Facade

		Main entry point for serial port communication in Eiffel.
		Provides type aliases and convenience factory methods.

		Usage:
			-- Quick open with defaults (9600-8-N-1)
			port := (create {SIMPLE_SERIAL}).open_port ("COM3")
			if attached port as p then
				p.write_string ("Hello")
				print (p.read_string (100))
				p.close
			end

			-- With custom configuration
			config := (create {SIMPLE_SERIAL}).default_config.set_baud_rate (115200)
			port := (create {SIMPLE_SERIAL}).open_port_with_config ("COM3", config)

			-- List available ports
			across (create {SIMPLE_SERIAL}).available_ports as p loop
				print (p + "%N")
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SERIAL

feature -- Factory

	open_port (a_name: READABLE_STRING_GENERAL): detachable SERIAL_PORT
			-- Open port with default config. Returns Void on failure.
		require
			name_not_empty: not a_name.is_empty
		local
			l_port: SERIAL_PORT
		do
			create l_port.make (a_name)
			if l_port.open then
				Result := l_port
			end
		ensure
			open_if_success: attached Result implies Result.is_open
		end

	open_port_with_config (a_name: READABLE_STRING_GENERAL; a_config: SERIAL_PORT_CONFIG): detachable SERIAL_PORT
			-- Open port with specified config. Returns Void on failure.
		require
			name_not_empty: not a_name.is_empty
		local
			l_port: SERIAL_PORT
		do
			create l_port.make (a_name)
			if l_port.open_with_config (a_config) then
				Result := l_port
			end
		ensure
			open_if_success: attached Result implies Result.is_open
		end

	create_port (a_name: READABLE_STRING_GENERAL): SERIAL_PORT
			-- Create port object (not opened). Use `open' to connect.
		require
			name_not_empty: not a_name.is_empty
		do
			create Result.make (a_name)
		ensure
			not_open: not Result.is_open
		end

feature -- Configuration

	default_config: SERIAL_PORT_CONFIG
			-- Create default configuration (9600-8-N-1).
		do
			create Result.make_default
		end

	config_9600: SERIAL_PORT_CONFIG
			-- Common config: 9600-8-N-1.
		do
			create Result.make (9600, 8, {SERIAL_PORT_CONFIG}.stop_bits_one, {SERIAL_PORT_CONFIG}.parity_none)
		end

	config_115200: SERIAL_PORT_CONFIG
			-- Common config: 115200-8-N-1.
		do
			create Result.make (115200, 8, {SERIAL_PORT_CONFIG}.stop_bits_one, {SERIAL_PORT_CONFIG}.parity_none)
		end

feature -- Enumeration

	available_ports: ARRAYED_LIST [STRING_32]
			-- List of available port names.
		local
			l_enum: SERIAL_PORT_ENUMERATOR
		do
			create l_enum.make
			Result := l_enum.available_ports
		end

	bluetooth_ports: ARRAYED_LIST [STRING_32]
			-- List of ports that appear to be Bluetooth SPP.
		local
			l_enum: SERIAL_PORT_ENUMERATOR
		do
			create l_enum.make
			Result := l_enum.bluetooth_ports
		end

	usb_ports: ARRAYED_LIST [STRING_32]
			-- List of ports that appear to be USB serial.
		local
			l_enum: SERIAL_PORT_ENUMERATOR
		do
			create l_enum.make
			Result := l_enum.usb_ports
		end

	port_exists (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does port `a_name' exist?
		local
			l_enum: SERIAL_PORT_ENUMERATOR
		do
			create l_enum.make
			Result := l_enum.has_port (a_name)
		end

feature -- Type References (for anchored types)

	port_anchor: detachable SERIAL_PORT
			-- Anchor for SERIAL_PORT type.

	config_anchor: detachable SERIAL_PORT_CONFIG
			-- Anchor for SERIAL_PORT_CONFIG type.

	enumerator_anchor: detachable SERIAL_PORT_ENUMERATOR
			-- Anchor for SERIAL_PORT_ENUMERATOR type.

end
