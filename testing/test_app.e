note
	description: "Test application for simple_serial"
	author: "Larry Rix"
	date: "$Date$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running simple_serial tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature -- Test Runners

	run_lib_tests
			-- Run core library tests.
		local
			tests: LIB_TESTS
		do
			create tests
			run_test (agent tests.test_config_default, "test_config_default")
			run_test (agent tests.test_config_builder, "test_config_builder")
			run_test (agent tests.test_config_description, "test_config_description")
			run_test (agent tests.test_enumerator_creation, "test_enumerator_creation")
			run_test (agent tests.test_facade_creation, "test_facade_creation")
			run_test (agent tests.test_port_creation, "test_port_creation")
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and track results.
		do
			print ("  " + a_name + "...")
			a_test.call (Void)
			passed := passed + 1
			print ("OK%N")
		rescue
			failed := failed + 1
			print ("FAILED%N")
		end

end
