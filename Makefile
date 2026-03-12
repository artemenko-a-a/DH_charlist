SHELL := /bin/zsh

.PHONY: fmt lint typecheck test ci

fmt:
	@echo "No repository formatter is configured; fmt is a documented no-op fallback for this repo."

lint:
	@echo "No repository linter is configured; lint is a documented no-op fallback for this repo."

typecheck:
	swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build

test:
	swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build

ci: fmt lint typecheck test
	xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build
	bash ./scripts/run_xcode_coverage.sh
	bash ./scripts/check_coverage_policy.sh
