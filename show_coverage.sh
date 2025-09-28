#!/bin/bash

# Enable color output
export FORCE_COLOR=1

echo "📊 テストカバレッジレポート (Generated Codeを除く)"
echo "================================================"
echo ""

# Run tests and generate coverage
echo "🔄 Running tests with coverage..."
go test -coverprofile=coverage.out -coverpkg=./src/... ./tests/... > test_output.txt 2>&1

if [ $? -ne 0 ]; then
    echo "⚠️  Some tests failed. Showing test output:"
    cat test_output.txt
    echo ""
fi

# Process coverage data and create summary
echo "📋 Coverage Summary (excluding auto-generated files):"
echo "---------------------------------------------------"

# Count different coverage levels and display with simple icons
coverage_data=$(go tool cover -func=coverage.out | grep -v "\.pb\.go" | grep -v "\.pb\.gw\.go" | grep -v "_grpc\.pb\.go" | grep -v "mock_" | grep -v "generated" | grep -v "_gen\.go")

# Count coverage levels using separate commands to avoid subshell issues
total_covered=$(echo "$coverage_data" | grep -v "^total:" | grep -c "100\.0%$")
total_untested=$(echo "$coverage_data" | grep -v "^total:" | grep -E "[ \t]0\.0%$" | wc -l)
total_partial=$(echo "$coverage_data" | grep -v "100\.0%$" | grep -v "^total:" | grep -c "\.go:[0-9]*:")
total_partial=$((total_partial - total_untested))

# Display each function with appropriate icon
while read -r line; do
    if [[ "$line" =~ ^total: ]]; then
        # Skip the total line here - we'll calculate our own
        continue
    fi

    if [[ "$line" =~ \.go:[0-9]+: ]]; then
        pct=$(echo "$line" | awk '{print $NF}')
        val=$(echo "$pct" | sed 's/%//' | awk '{print $1 + 0}')

        # Choose icon based on coverage
        if [[ "$pct" == "100.0%" ]]; then
            icon="✅"
        elif [[ "$val" -ge 80 ]]; then
            icon="🔶"
        elif [[ "$val" -ge 50 ]]; then
            icon="🔷"
        elif [[ "$val" -gt 0 ]]; then
            icon="⚠️"
        else
            icon="⏹️"
        fi

        # Clean up file path - keep only filename
        func_info=$(echo "$line" | sed 's|.*/||' | awk '{$NF=""; print $0}' | sed 's/ $//')

        echo "$icon $func_info $pct"
    fi
done <<< "$coverage_data"

# Calculate correct coverage percentage for non-generated files only
total_funcs=$(echo "$coverage_data" | grep -v "^total:" | grep -c "\.go:[0-9]*:")

# Calculate actual coverage percentage based on our filtered data
if [ $total_funcs -gt 0 ]; then
    actual_coverage=$(awk "BEGIN {printf \"%.1f\", $total_covered * 100 / $total_funcs}")
    actual_coverage="${actual_coverage}%"
else
    actual_coverage="0.0%"
fi

# Get original total (including generated files) for reference
original_total=$(go tool cover -func=coverage.out | grep "^total:" | awk '{print $NF}')

echo ""
echo "📊 Summary:"
echo "   ✅ Fully covered:     $total_covered functions"
echo "   🔶 Partially covered: $total_partial functions"
echo "   ⚠️ Untested:          $total_untested functions"
echo "   📦 Total functions:   $total_funcs"
echo "   📈 Coverage:          $actual_coverage"

# Generate HTML report
echo ""
echo "🌐 Generating HTML coverage report..."
go tool cover -html=coverage.out -o coverage.html
echo "✅ HTML report generated: coverage.html"

# Show functions that need attention
echo ""
echo "🎯 Functions needing attention (< 100% coverage):"
echo "------------------------------------------------"

uncovered_functions=$(go tool cover -func=coverage.out | grep -v "\.pb\.go" | grep -v "\.pb\.gw\.go" | grep -v "_grpc\.pb\.go" | grep -v "mock_" | grep -v "generated" | grep -v "_gen\.go" | grep -v "100.0%" | grep -v "total:")

if [ -z "$uncovered_functions" ]; then
    echo "🎉 All functions have 100% coverage! Great job!"
else
    echo "$uncovered_functions" | while read line; do
        if [[ "$line" =~ \.go:[0-9]+: ]]; then
            pct=$(echo "$line" | awk '{print $NF}')
            val=$(echo "$pct" | sed 's/%//' | awk '{print $1 + 0}')

            # Choose icon based on coverage
            if [[ "$val" -ge 80 ]]; then
                icon="🔶"
            elif [[ "$val" -ge 50 ]]; then
                icon="🔷"
            elif [[ "$val" -gt 0 ]]; then
                icon="⚠️"
            else
                icon="⏹️"
            fi

            # Clean up file path - keep only filename
            func_info=$(echo "$line" | sed 's|.*/||' | awk '{$NF=""; print $0}' | sed 's/ $//')

            echo "$icon $func_info $pct"
        fi
    done
fi

# Cleanup
rm -f test_output.txt

echo ""
echo "📊 Legend:"
echo "✅ 100% coverage  🔶 80-99%  🔷 50-79%  ⚠️ <50%  ⏹️ 0%"
echo ""
echo "================================================"
echo "🎯 Report complete! Open coverage.html for details"