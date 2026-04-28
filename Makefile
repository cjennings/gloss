# Makefile for gloss
# Run `make help' for available targets.

EMACS ?= emacs
EMACSFLAGS = --batch -Q
LOADPATH = -L . -L tests

PACKAGE_FILES = $(filter-out gloss-pkg.el,$(wildcard gloss*.el))
TEST_FILES = $(wildcard tests/test-*.el)
UNIT_TESTS = $(filter-out tests/test-integration-%.el,$(TEST_FILES))
INTEGRATION_TESTS = $(wildcard tests/test-integration-*.el)

.PHONY: help test test-unit test-integration test-file test-name validate-parens compile lint clean

help:
	@echo "Targets:"
	@echo "  make test                     Run all tests"
	@echo "  make test-unit                Unit tests only"
	@echo "  make test-integration         Integration tests only"
	@echo "  make test-file FILE=path/to/test-foo.el   Run one test file"
	@echo "  make test-name TEST=pattern   Run tests whose name matches PATTERN"
	@echo "  make validate-parens          check-parens on every .el"
	@echo "  make compile                  Byte-compile package files"
	@echo "  make lint                     elisp-lint pass"
	@echo "  make clean                    Remove .elc"

test:
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l ert $(addprefix -l ,$(TEST_FILES)) -f ert-run-tests-batch-and-exit

test-unit:
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l ert $(addprefix -l ,$(UNIT_TESTS)) -f ert-run-tests-batch-and-exit

test-integration:
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l ert $(addprefix -l ,$(INTEGRATION_TESTS)) -f ert-run-tests-batch-and-exit

test-file:
	@if [ -z "$(FILE)" ]; then echo "Usage: make test-file FILE=tests/test-NAME.el"; exit 1; fi
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l ert -l "$(FILE)" -f ert-run-tests-batch-and-exit

test-name:
	@if [ -z "$(TEST)" ]; then echo "Usage: make test-name TEST=pattern"; exit 1; fi
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l ert $(addprefix -l ,$(TEST_FILES)) --eval "(ert-run-tests-batch-and-exit \"$(TEST)\")"

validate-parens:
	@for f in $(PACKAGE_FILES) $(TEST_FILES); do \
		echo "  check-parens: $$f"; \
		$(EMACS) --batch --eval "(progn (find-file \"$$f\") (check-parens))" 2>&1 | grep -v '^Loading' || true; \
	done

compile:
	@for f in $(PACKAGE_FILES); do \
		echo "  byte-compile: $$f"; \
		$(EMACS) $(EMACSFLAGS) $(LOADPATH) --eval "(byte-compile-file \"$$f\")"; \
	done

lint:
	@$(EMACS) $(EMACSFLAGS) $(LOADPATH) -l elisp-lint --funcall elisp-lint-files-batch $(PACKAGE_FILES)

clean:
	@rm -f *.elc tests/*.elc
