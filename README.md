# scheme-test-runner
A simple scheme script for running compiler tests and comparing generated outputs with expected outputs

## Description
This script was built for the final project for the **[Compiler Principles](http://www.cs.bgu.ac.il/~comp151/Main)** course at Ben-Gurion University
It is very *project specific*, but can easily be adapted for use in other projects if needed - basically it's a input-output comparison script.

OS X users have a little easter egg

## Example output
* Here's an example of what a completely sucessful test suite looks like:

		Test 1 ) and-1.scm : PASSED
		Test 2 ) and-2.scm : PASSED
		Test 3 ) and-3.scm : PASSED
		Test 4 ) and-4.scm : PASSED
		Test 5 ) and-5.scm : PASSED
		==============================
		All Test completed
			5 Passed
			0 Failed
		100.% Success rate (5 out of 5)
	
* Here's an example of a test suite with partial success

		Test 1 ) and-1.scm : PASSED
		Test 2 ) and-2.scm : FAILED
						Expected: (#t)
						Got: (#f)
		Test 3 ) and-3.scm : PASSED
		Test 4 ) and-4.scm : PASSED
		Test 5 ) and-5.scm : PASSED
		==============================
		All Test completed
			4 Passed
			1 Failed
		80.% Success rate (4 out of 5)


## Running tests
To run all your tests simply execute the command

`> ./test-runner.scm`

from the command line from your project directory


## Adding your own tests
To add a new test to the test suite, simple add a new file to the `inputs` directory and add the expected output to a file, matching the same filename, in the `outputs` directory.

For example add `tests/inputs/my-new-test.scm` and  `tests/outputs/my-new-test`.

That's it! The file will be automatically compiled and it's output compared the next time you run `test-runner.scm`



## [Directory Layout](id:layout)
Your project layout should look similar to this (in general)

	| /project
	|   |
	|   -- compiler.scm
	|   -- test-runner.scm
	|   -- tests/
	|   --  |
	|   --  |-- inputs/
	|   --  |--     | -- test-1.scm
	|   --  |--     | -- test-2.scm
	|   --  |-- outputs/
	|   --  |--     | -- test-1
	|   --  |--     | -- test-2
	|   --  |-- results/
	|   --  |-- results-cisc/
	
## Technical Overview
This script uses convention over configuration to run 2 stages that each performs set of instructions as specified below.

The **[first stage](#stage-1)** compiles the files and places the outputs (binary and cisc) in appropriate directories.
the **[seconds stage](#stage-2)** iterates again, this time running the executable and comparing it's output to the **expected output** and outputs the tests results.

Please pay attention to the [Directory Layout](#layout) section on how to setup your project for test-runner to work

### [First stage](id:stage-1)
At first, the script iterates over all test files (.scm extension) in `tests/inputs/` directory and:

1. Call `compile-scheme-file` on the input file, setting output file as `out.c` (temporarily)

2. Call `make` (without arguments) in the root directory to compile `out.c` and create `out` executable

3. Copy the `out.c` file to `tests/results-cisc/` directory (for future inspection by you if nessecary)


4. Copy the `out` executable to `tests/results/` directory

### [Second stage](id:stage-2)
Iterate over all test files in `tests/inputs/` and peform the following for **each file**

1. Run the executable file, and redirect the output to `tests/results/filename.output`

2. Compare output of each `tests/results/filename.output` file with `tests/outputs/filename` (expected output) and print the result (`PASSED` or `FAILED (expected...got...)`)

3. Print summary - number of tests passed out of total tests ran (plus percentage of success)

## Troubleshooting
**Problem:** I get `permission denied: ./test-runner.scm`

**Solution:** Make sure `test-runner.scm` has executable permissions. If it doesn't, then run `chmod +x test-runner.scm` to make it executable
