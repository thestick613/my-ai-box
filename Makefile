.PHONY: test lint

BATS := tests/bats/lib/bats-core/bin/bats

test:
	$(BATS) tests/bats/

lint:
	@find . -type f \( -name '*.sh' -o -name '*.bash' \) \
		-not -path './tests/bats/lib/*' \
		-print0 | xargs -0 -r shellcheck -S style
