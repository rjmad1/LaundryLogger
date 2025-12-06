# Laundry Logger - Build & Development Tasks
#
# Quick reference:
#   make fast-debug    - Fast debug build for development
#   make ci-release    - Release build for CI/CD
#   make test          - Run all tests
#   make smoke         - Run smoke tests (fast subset)

.PHONY: help fast-debug ci-release test smoke clean analyze format

# Default target
help:
	@echo "LaundryLogger Build Targets:"
	@echo "  fast-debug    - Fast debug build (hot-restart friendly)"
	@echo "  ci-release    - CI release build with debug info"
	@echo "  test          - Run all tests"
	@echo "  smoke         - Run smoke tests (analyze + fast tests)"
	@echo "  clean         - Clean build artifacts"
	@echo "  analyze       - Run flutter analyze"
	@echo "  format        - Format code"

# Fast debug build optimized for development
fast-debug:
	@echo "Building fast debug..."
	cd mobile && flutter build apk --debug

# CI release build with split debug info
ci-release:
	@echo "Building CI release with debug symbols..."
	cd mobile && flutter build apk --release \
		--split-debug-info=build/debug-info \
		--obfuscate

# Run all tests with coverage
test:
	@echo "Running all tests..."
	cd mobile && flutter test --coverage

# Fast smoke test (analyze + unit tests subset)
smoke:
	@echo "Running smoke tests..."
	@bash tools/smoke.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd mobile && flutter clean
	cd mobile/android && ./gradlew clean || true

# Run static analysis
analyze:
	@echo "Running flutter analyze..."
	cd mobile && flutter analyze

# Format code
format:
	@echo "Formatting code..."
	cd mobile && flutter format lib/ test/

# Get dependencies
deps:
	@echo "Getting dependencies..."
	cd mobile && flutter pub get

# Build for all platforms (local)
build-all: fast-debug
	@echo "Building for Android, iOS, Windows..."
	cd mobile && flutter build apk --debug
	cd mobile && flutter build ios --debug --no-codesign
	cd mobile && flutter build windows --debug
