MYVIM ?= vim -es -T dumb --not-a-term --noplugin -n
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@
