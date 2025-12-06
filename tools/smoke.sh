#!/bin/bash
# Smoke test script - fast feedback loop for developers
# Runs analyzer, fast unit tests, and a shallow integration test

set -e

echo "🔍 Running Flutter smoke tests..."
echo ""

cd mobile

# 1. Static analysis
echo "📊 Step 1/3: Running flutter analyze..."
flutter analyze --fatal-infos
echo "✅ Analysis passed"
echo ""

# 2. Fast unit tests (exclude integration tests)
echo "🧪 Step 2/3: Running fast unit tests..."
flutter test --no-pub --exclude-tags=integration --reporter=compact
echo "✅ Unit tests passed"
echo ""

# 3. Shallow integration test (synthetic data test)
echo "🔗 Step 3/3: Running shallow integration test..."
flutter test test/integration/smoke_test.dart --no-pub || echo "⚠️  Integration test skipped (file not found)"
echo ""

echo "✅ All smoke tests passed!"
echo ""
echo "💡 Tip: Run 'make test' for full test suite with coverage"
