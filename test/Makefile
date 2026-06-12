MYVIM ?= vim -es -T dumb --not-a-term --noplugin -n
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test clean $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@

clean:
	find . \( -name '*-errors.txt' -o -name 'error.log' -o -name 'test-output.txt' -o -name 'import-*.txt' \) -delete
