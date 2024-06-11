.PHONY: all
all: build test

.PHONY: build
build:
	@cabal build

.PHONY: test
test: test-options test-chars test-text test-stdin test-multi

.PHONY: test-options
test-options:
	@./tests/test.sh --options

.PHONY: create-test-chars
create-test-chars:
	@echo Generating random characters ...
	@cd tests && rm -rf test_chars.txt && ./create_random_chars.perl 2>/dev/null
	@echo Done

.PHONY: test-chars
test-chars: create-test-chars
	@./tests/test.sh --chars

.PHONY: create-test-text
create-test-text:
	@echo Generating random text ...
	@cd tests && rm -rf test_text.txt && ./create_random_text.perl 100000 test_text.txt 2>/dev/null
	@echo Done

.PHONY: test-text
test-text: create-test-text
	@./tests/test.sh --text

.PHONY: create-test-stdin
create-test-stdin:
	@echo Generating random text for stdin tests...
	@cd tests && rm -rf test_text.txt && ./create_random_text.perl 100000 test_stdin.txt 2>/dev/null
	@echo Done

.PHONY: test-stdin
test-stdin: create-test-stdin
	@./tests/test.sh --stdin

.PHONY: test-multi
test-multi:
	@./tests/test.sh --multi
