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

end
