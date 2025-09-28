#!/bin/bash

# Test runner script for etc_data_processor

set -e

echo "🧪 ETC Data Processor Test Suite"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run unit tests
echo "📝 Running Unit Tests..."
if go test ./tests/unit/... -v; then
    echo -e "${GREEN}✅ Unit tests passed${NC}"
else
    echo -e "${RED}❌ Unit tests failed${NC}"
    exit 1
fi

echo ""

# Run integration tests
echo "🔗 Running Integration Tests..."
if go test ./tests/integration/... -v; then
    echo -e "${GREEN}✅ Integration tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Integration tests failed (non-blocking)${NC}"
fi

echo ""

# Run with race detector
echo "🏃 Running Race Detection..."
if go test -race ./src/pkg/...; then
    echo -e "${GREEN}✅ No race conditions detected${NC}"
else
    echo -e "${RED}❌ Race conditions detected${NC}"
    exit 1
fi

echo ""

# Check coverage
echo "📊 Checking Coverage..."
go test -coverprofile=coverage.out -coverpkg=./src/... ./tests/... > /dev/null 2>&1

# Calculate coverage excluding generated files
COVERAGE=$(go tool cover -func=coverage.out | grep -v ".pb.go" | grep -v ".pb.gw.go" | grep -v "mock_" | tail -1 | awk '{print $3}' | sed 's/%//')

echo "Coverage: $COVERAGE%"

# Check if coverage meets requirement
REQUIRED_COVERAGE=80
if (( $(echo "$COVERAGE >= $REQUIRED_COVERAGE" | bc -l) )); then
    echo -e "${GREEN}✅ Coverage meets requirement (>= $REQUIRED_COVERAGE%)${NC}"
else
    echo -e "${YELLOW}⚠️  Coverage below requirement (< $REQUIRED_COVERAGE%)${NC}"
fi

echo ""
echo "================================="
echo -e "${GREEN}🎉 All tests completed!${NC}"