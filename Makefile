SHELL := /bin/zsh
ROOT_DIR := $(CURDIR)
BUILD_PATH := /tmp/dh_charlist-build

.PHONY: fmt lint typecheck test ci

fmt:
	@echo "No repository formatter is configured; fmt is a documented no-op fallback for this repo."

lint:
	@echo "No repository linter is configured; lint is a documented no-op fallback for this repo."

typecheck:
	swift build --disable-sandbox --package-path $(ROOT_DIR) --build-path $(BUILD_PATH)

test:
	swift test --disable-sandbox --package-path $(ROOT_DIR) --build-path $(BUILD_PATH)

ci: fmt lint typecheck test
	xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build
	bash ./scripts/run_xcode_coverage.sh
	bash ./scripts/check_coverage_policy.sh
