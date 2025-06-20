#!/bin/bash

# Makefile Cleanup Script
# ========================
# Optional script to help identify and remove obsolete or unused commands

echo "🧹 MAKEFILE CLEANUP ANALYSIS"
echo "============================"
echo ""

# Count lines in current vs original
CURRENT_LINES=$(wc -l Makefile | cut -d' ' -f1)
ORIGINAL_LINES=$(wc -l Makefile.backup | cut -d' ' -f1)
MODULE_LINES=$(wc -l make/*.mk | tail -1 | cut -d' ' -f1)
TOTAL_CURRENT=$((CURRENT_LINES + MODULE_LINES))

echo "📊 SIZE COMPARISON:"
echo "   Original Makefile: $ORIGINAL_LINES lines"
echo "   New Makefile: $CURRENT_LINES lines"
echo "   All modules: $MODULE_LINES lines"
echo "   Total current: $TOTAL_CURRENT lines"
echo "   Reduction: $((ORIGINAL_LINES - TOTAL_CURRENT)) lines ($(((ORIGINAL_LINES - TOTAL_CURRENT) * 100 / ORIGINAL_LINES))%)"
echo ""

# Check for any remaining long commands
echo "🔍 CHECKING FOR OPTIMIZATION OPPORTUNITIES:"
echo ""

# Find long lines in modules
echo "Lines with >100 characters:"
find make/ -name "*.mk" -exec wc -L {} \; | sort -nr | head -5

echo ""

# Check for duplicate patterns
echo "🔄 CHECKING FOR DUPLICATE PATTERNS:"
echo ""

# Look for repeated forge script calls
echo "Most common forge script patterns:"
grep -h "forge script" make/*.mk | sort | uniq -c | sort -nr | head -5

echo ""

echo "✅ CLEANUP ANALYSIS COMPLETE"
echo ""
echo "📋 RECOMMENDATIONS:"
echo "   1. All commands organized into logical modules"
echo "   2. Achieved $(((ORIGINAL_LINES - TOTAL_CURRENT) * 100 / ORIGINAL_LINES))% reduction in total size"
echo "   3. Main Makefile now only $CURRENT_LINES lines (vs $ORIGINAL_LINES)"
echo "   4. Easy to maintain and extend"
echo ""
echo "🎯 NEXT STEPS:"
echo "   - Test all essential commands: make help"
echo "   - Use modular help: make help-core, help-automation, etc."
echo "   - Add new commands to appropriate modules"
echo "   - Original backup available at: Makefile.backup"
echo "" 