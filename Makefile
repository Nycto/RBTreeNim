#
# Build instructions
#


# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail


# A list of all test names
TESTS ?= $(notdir $(basename $(wildcard test/*_test.nim)))


# Run all tests
.PHONY: test
test: $(TESTS)


# Compiles a nim file
define COMPILE
nimble c $(FLAGS) \
		--path:. --nimcache:./build/nimcache \
		--out:../build/$(notdir $(basename $1)) \
		$1 \
	| grep -v \
		-e "^Hint: " \
		-e "^CC: " \
		-e "Hint: 'AbortOnError'"
endef


# A template for defining targets for a test
define DEFINE_TEST

build/$1: test/$1.nim $(shell find -name $(patsubst %_test,%,$1).nim)

	$(call COMPILE,test/$1.nim)
	build/$1 || mv build/$1 build/$1_failing

.PHONY: $1
$1: build/$1

endef

# Define a target for each test
$(foreach test,$(TESTS),$(eval $(call DEFINE_TEST,$(test))))


# Watches for changes and reruns
.PHONY: watch
watch:
	$(eval MAKEFLAGS += " -s ")
	@while true; do \
		make TESTS="$(TESTS)"; \
		inotifywait -qre close_write `find . -name "*.nim"` > /dev/null; \
		echo "Change detected, re-running..."; \
	done


# Executes the compiler with profiling enabled
.PHONY: profile
profile:
	make FLAGS="--profiler:on --stackTrace:on"


# Remove all build artifacts
.PHONY: clean
clean:
	rm -rf build

