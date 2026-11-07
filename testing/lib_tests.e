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
