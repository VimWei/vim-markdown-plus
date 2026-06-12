MYVIM ?= vim -es -T dumb --not-a-term --noplugin -n

tests := $(wildcard test-*.vim)

.PHONY: test $(tests)

test: $(tests)

$(tests):
	@$(MYVIM) -u $@ +qall
