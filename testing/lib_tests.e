note
	description: "Core tests for simple_serial library"
	author: "Larry Rix"
	date: "$Date$"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Configuration Tests

	test_config_default
			-- Test default configuration.
		local
			config: SERIAL_PORT_CONFIG
		do
			create config.make_default
			assert_integers_equal ("default_baud", 9600, config.baud_rate)
			assert_integers_equal ("default_data_bits", 8, config.data_bits)
			assert_integers_equal ("default_stop_bits", config.stop_bits_one, config.stop_bits)
			assert_integers_equal ("default_parity", config.parity_none, config.parity)
			assert_integers_equal ("default_flow", config.flow_control_none, config.flow_control)
		end

	test_config_builder
			-- Test fluent builder pattern.
		local
			config: SERIAL_PORT_CONFIG
		do
			create config.make_default
			config := config.set_baud_rate (115200).set_parity ({SERIAL_PORT_CONFIG}.parity_even)
			assert_integers_equal ("builder_baud", 115200, config.baud_rate)
			assert_integers_equal ("builder_parity", {SERIAL_PORT_CONFIG}.parity_even, config.parity)
		end

	test_config_description
			-- Test configuration description output.
		local
			config: SERIAL_PORT_CONFIG
		do
			create config.make_default
			assert_strings_equal_case_insensitive ("description_format", "9600-8-N-1", config.description)

			create config.make (115200, 8, {SERIAL_PORT_CONFIG}.stop_bits_two, {SERIAL_PORT_CONFIG}.parity_even)
			assert_strings_equal_case_insensitive ("description_custom", "115200-8-E-2", config.description)
		end

feature -- Enumerator Tests

	test_enumerator_creation
			-- Test port enumerator creation.
		local
			enum: SERIAL_PORT_ENUMERATOR
		do
			create enum.make
			assert_attached ("ports_list", enum.available_ports)
			assert_non_negative ("count", enum.count)
		end

feature -- Classification Tests

	test_classify_bluetooth
			-- A Windows Bluetooth friendly name, a Bluetooth hardware id alone,
			-- and the Linux rfcomm description are all Bluetooth, never USB.
		local
			l_classifier: SERIAL_PORT_CLASSIFIER
		do
			create l_classifier
			assert_true ("friendly name", l_classifier.is_bluetooth_port ("Standard Serial over Bluetooth link (COM5)", Bluetooth_hardware_id))
			assert_false ("friendly name not usb", l_classifier.is_usb_port ("Standard Serial over Bluetooth link (COM5)", Bluetooth_hardware_id))
			assert_true ("hardware id alone", l_classifier.is_bluetooth_port ("Serial Port (COM9)", Bluetooth_hardware_id))
			assert_true ("linux rfcomm", l_classifier.is_bluetooth_port ("Bluetooth Serial Port", ""))
		end

	test_classify_usb
			-- A Windows USB friendly name with a USB hardware id, a USB hardware
			-- id alone, an FTDI bus id, and the Linux description are USB.
		local
			l_classifier: SERIAL_PORT_CLASSIFIER
		do
			create l_classifier
			assert_true ("friendly name", l_classifier.is_usb_port ("USB Serial Device (COM3)", Usb_hardware_id))
			assert_false ("friendly name not bluetooth", l_classifier.is_bluetooth_port ("USB Serial Device (COM3)", Usb_hardware_id))
			assert_true ("hardware id alone", l_classifier.is_usb_port ("Arduino Uno (COM4)", Usb_hardware_id))
			assert_true ("ftdi bus", l_classifier.is_usb_port ("Serial Converter (COM7)", "FTDIBUS\VID_0403+PID_6001+A50285BIA\0000"))
			assert_true ("ch340", l_classifier.is_usb_port ("USB-SERIAL CH340 (COM8)", ""))
			assert_true ("linux usb", l_classifier.is_usb_port ("USB Serial Port", ""))
		end

	test_classify_plain
			-- A motherboard port and an undescribed port are neither kind.
		local
			l_classifier: SERIAL_PORT_CLASSIFIER
		do
			create l_classifier
			assert_false ("com1 not bluetooth", l_classifier.is_bluetooth_port ("Communications Port (COM1)", "ACPI\PNP0501"))
			assert_false ("com1 not usb", l_classifier.is_usb_port ("Communications Port (COM1)", "ACPI\PNP0501"))
			assert_false ("bare not bluetooth", l_classifier.is_bluetooth_port ("Serial Port", ""))
			assert_false ("bare not usb", l_classifier.is_usb_port ("Serial Port", ""))
		end

	test_enumerator_filters_listing
			-- The listing the Windows scan reads, loaded without scanning: each
			-- port lands in the right filter, a device map duplicate is dropped,
			-- and a device-map-only port gets the default description.
		local
			l_enumerator: SERIAL_PORT_ENUMERATOR
			l_listing: STRING_32
		do
			create l_enumerator.make_empty
			create l_listing.make (300)
			l_listing.append ({STRING_32} "COM5%TStandard Serial over Bluetooth link (COM5)%T")
			l_listing.append (Bluetooth_hardware_id)
			l_listing.append ({STRING_32} "%NCOM3%TUSB Serial Device (COM3)%T")
			l_listing.append (Usb_hardware_id)
			l_listing.append ({STRING_32} "%N")
			l_listing.append ({STRING_32} "COM1%TCommunications Port (COM1)%TACPI\PNP0501%N")
			l_listing.append ({STRING_32} "COM5%T%T%N")
			l_listing.append ({STRING_32} "COM9%T%T%N")
			l_enumerator.put_listing (l_listing)

			assert_integers_equal ("four ports", 4, l_enumerator.count)
			assert_integers_equal ("one bluetooth", 1, l_enumerator.bluetooth_ports.count)
			assert_true ("bluetooth is com5", l_enumerator.bluetooth_ports.first.same_string ("COM5"))
			assert_integers_equal ("one usb", 1, l_enumerator.usb_ports.count)
			assert_true ("usb is com3", l_enumerator.usb_ports.first.same_string ("COM3"))
			assert_true ("com5 keeps its friendly name", attached l_enumerator.description_for ("COM5") as l_description
				and then l_description.same_string ("Standard Serial over Bluetooth link (COM5)"))
			assert_true ("com3 hardware id", attached l_enumerator.hardware_id_for ("COM3") as l_hardware_id
				and then l_hardware_id.same_string (Usb_hardware_id))
			assert_true ("com9 default description", attached l_enumerator.description_for ("COM9") as l_description
				and then l_description.same_string (l_enumerator.default_description))
			assert_void ("com9 no hardware id", l_enumerator.hardware_id_for ("COM9"))
		end

	test_scan_this_machine
			-- `refresh' on the real machine returns, every port it finds is
			-- described and named for the platform, and the Bluetooth and USB
			-- filters pick disjoint subsets. Holds with no ports at all.
		local
			l_enumerator: SERIAL_PORT_ENUMERATOR
			l_bluetooth, l_usb: ARRAYED_LIST [STRING_32]
			l_line: STRING_32
		do
			create l_enumerator.make
			l_enumerator.refresh
			l_bluetooth := l_enumerator.bluetooth_ports
			l_usb := l_enumerator.usb_ports
			print ("%N    ports found: " + l_enumerator.count.out + "%N")
			across l_enumerator.available_ports as ic_port loop
				create l_line.make_from_string ({STRING_32} "      ")
				l_line.append (ic_port)
				if attached l_enumerator.description_for (ic_port) as l_description then
					l_line.append ({STRING_32} " | ")
					l_line.append (l_description)
				end
				if attached l_enumerator.hardware_id_for (ic_port) as l_hardware_id then
					l_line.append ({STRING_32} " | ")
					l_line.append (l_hardware_id)
				end
				print ({UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_line) + "%N")
				assert_attached ("described", l_enumerator.description_for (ic_port))
				if {PLATFORM}.is_windows then
					assert_true ("windows name", ic_port.starts_with ({STRING_32} "COM"))
				else
					assert_true ("posix name", ic_port.starts_with ({STRING_32} "/dev/"))
				end
			end
			across l_bluetooth as ic_port loop
				assert_true ("bluetooth port is listed", l_enumerator.has_port (ic_port))
				assert_false ("bluetooth port is not usb", across l_usb as ic_other some ic_other.same_string (ic_port) end)
			end
			across l_usb as ic_port loop
				assert_true ("usb port is listed", l_enumerator.has_port (ic_port))
			end
			print ("    bluetooth: " + l_bluetooth.count.out + ", usb: " + l_usb.count.out + "%N    ")
		end

feature {NONE} -- Sample hardware ids

	Bluetooth_hardware_id: STRING_32 = "BTHENUM\{00001101-0000-1000-8000-00805F9B34FB}_LOCALMFG&0002"
			-- Hardware id Windows gives an outgoing Bluetooth serial link.

	Usb_hardware_id: STRING_32 = "USB\VID_2341&PID_0043&REV_0001"
			-- Hardware id of an Arduino Uno.

feature -- Facade Tests

	test_facade_creation
			-- Test facade factory methods.
		local
			facade: SIMPLE_SERIAL
		do
			create facade
			assert_attached ("default_config", facade.default_config)
			assert_integers_equal ("config_9600_baud", 9600, facade.config_9600.baud_rate)
			assert_integers_equal ("config_115200_baud", 115200, facade.config_115200.baud_rate)
			assert_attached ("available_ports", facade.available_ports)
		end

feature -- Port Tests

	test_port_creation
			-- Test port object creation (without opening).
		local
			port: SERIAL_PORT
		do
			create port.make ("COM99")
			assert_string_contains ("port_name", port.port_name, "COM99")
			assert_false ("not_open", port.is_open)
			assert_void ("no_error", port.last_error)
		end

feature -- Test: a real line

	test_round_trip_over_pty
			-- Bytes both ways through a pseudo-terminal pair, which stands in for a
			-- serial line. Off Windows only: Windows has no such pair.
		local
			l_master, l_count: INTEGER
			l_name: C_STRING
			l_port, l_second: SERIAL_PORT
			l_buffer: MANAGED_POINTER
			l_line: C_STRING
		do
			if not {PLATFORM}.is_windows then
				l_master := c_open_master
				assert_true ("pair opened", l_master >= 0)
				create l_name.make_by_pointer (c_slave_name (l_master))
				create l_port.make (l_name.string)
				assert_true ("port opened", l_port.open)
				create l_second.make (l_name.string)
				assert_false ("second open refused", l_second.open)
				assert_attached ("reason given", l_second.last_error)

				assert_true ("wrote", l_port.write_string ("hello"))
				create l_buffer.make (64)
				l_count := c_master_read (l_master, l_buffer.item, 64, 2000)
				assert_integers_equal ("line carried five bytes", 5, l_count)
				assert_integers_equal ("first byte", 0x68, l_buffer.read_natural_8 (0).to_integer_32)

				create l_line.make ("world%N")
				assert_integers_equal ("sent", 6, c_master_write (l_master, l_line.item, 6))
				assert_true ("read the line", l_port.read_line.same_string ("world"))
				l_port.close
				assert_false ("closed", l_port.is_open)
				c_master_close (l_master)
			end
		end

feature {NONE} -- Pseudo-terminal externals

	c_open_master: INTEGER
		external "C inline use %"serial_test_support.h%""
		alias "return sts_open_master ();"
		end

	c_slave_name (a_fd: INTEGER): POINTER
		external "C inline use %"serial_test_support.h%""
		alias "return (EIF_POINTER) sts_slave_name ((int) $a_fd);"
		end

	c_master_write (a_fd: INTEGER; a_data: POINTER; a_count: INTEGER): INTEGER
		external "C inline use %"serial_test_support.h%""
		alias "return sts_write ((int) $a_fd, (const char *) $a_data, (int) $a_count);"
		end

	c_master_read (a_fd: INTEGER; a_buffer: POINTER; a_max, a_timeout_ms: INTEGER): INTEGER
		external "C blocking inline use %"serial_test_support.h%""
		alias "return sts_read ((int) $a_fd, (char *) $a_buffer, (int) $a_max, (int) $a_timeout_ms);"
		end

	c_master_close (a_fd: INTEGER)
		external "C inline use %"serial_test_support.h%""
		alias "sts_close ((int) $a_fd);"
		end

end
