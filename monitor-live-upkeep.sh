#!/bin/bash

# 📡 CHAINLINK UPKEEP LIVE MONITORING SCRIPT
# ==========================================
# Monitors your registered Chainlink Automation upkeep in real-time
# Shows LINK consumption, execution history, and performance metrics

echo "📡 CHAINLINK AUTOMATION LIVE MONITORING"
echo "========================================"
echo ""

# Check if CHAINLINK_UPKEEP_ID is set
if [ -z "$CHAINLINK_UPKEEP_ID" ]; then
    echo "❌ CHAINLINK_UPKEEP_ID environment variable not set!"
    echo ""
    echo "To get your Upkeep ID:"
    echo "  1. Go to https://automation.chain.link/base-sepolia"
    echo "  2. Find your upkeep in 'My Upkeeps'"
    echo "  3. Copy the ID number"
    echo ""
    echo "Then set it:"
    echo "  export CHAINLINK_UPKEEP_ID=123456789"
    echo "  ./monitor-live-upkeep.sh"
    echo ""
    exit 1
fi

# Check if deployed addresses exist
if [ ! -f "deployed-addresses.json" ]; then
    echo "❌ deployed-addresses.json not found!"
    echo "   Deploy your automation contracts first:"
    echo "   make deploy-automation-production"
    exit 1
fi

echo "🎯 MONITORING SETUP"
echo "=================="
echo "Upkeep ID: $CHAINLINK_UPKEEP_ID"
echo "Network: Base Sepolia"
echo "Registry: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3"
echo ""

# Function to check upkeep status
check_upkeep_status() {
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S') - Checking upkeep status..."
    
    # Run the monitoring script
    CHAINLINK_UPKEEP_ID=$CHAINLINK_UPKEEP_ID make monitor-chainlink-upkeep
    
    return $?
}

# Function to show dashboard links
show_dashboard_links() {
    echo "🌐 DASHBOARD LINKS"
    echo "=================="
    echo "Your upkeep: https://automation.chain.link/base-sepolia/$CHAINLINK_UPKEEP_ID"
    echo "General dashboard: https://automation.chain.link/base-sepolia"
    echo "BaseScan: https://sepolia.basescan.org/address/$(jq -r '.AUTOMATION_KEEPER // "NOT_DEPLOYED"' deployed-addresses.json)"
    echo ""
}

# Function to check LINK consumption
check_link_consumption() {
    echo "💰 LINK CONSUMPTION CHECK"
    echo "========================"
    
    CHAINLINK_UPKEEP_ID=$CHAINLINK_UPKEEP_ID make check-link-consumption
    echo ""
}

# Function to test checkUpkeep
test_checkupkeep_function() {
    echo "🧪 TESTING CHECKUPKEEP FUNCTION"
    echo "==============================="
    
    make test-live-checkupkeep
    echo ""
}

# Main monitoring loop
main_menu() {
    echo "📋 MONITORING OPTIONS"
    echo "===================="
    echo "1. 🔍 Full upkeep status check"
    echo "2. 🚨 Emergency health check"
    echo "3. 💰 Check LINK consumption"
    echo "4. 🧪 Test checkUpkeep function"
    echo "5. 🔄 Start continuous monitoring (30s intervals)"
    echo "6. 📈 Comprehensive verification"
    echo "7. 🌐 Show dashboard links"
    echo "8. ❌ Exit"
    echo ""
    
    read -p "Choose option [1-8]: " choice
    
    case $choice in
        1)
            echo ""
            check_upkeep_status
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            CHAINLINK_UPKEEP_ID=$CHAINLINK_UPKEEP_ID make emergency-upkeep-check
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            check_link_consumption
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            test_checkupkeep_function
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            echo "🔄 STARTING CONTINUOUS MONITORING"
            echo "================================="
            echo "Checking every 30 seconds... Press Ctrl+C to stop"
            echo ""
            
            while true; do
                check_upkeep_status
                echo ""
                echo "💤 Waiting 30 seconds for next check..."
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                sleep 30
            done
            ;;
        6)
            echo ""
            CHAINLINK_UPKEEP_ID=$CHAINLINK_UPKEEP_ID make verify-automation-working
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            show_dashboard_links
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            echo "👋 Monitoring stopped. Your upkeep continues running!"
            echo ""
            echo "Quick commands for later:"
            echo "  export CHAINLINK_UPKEEP_ID=$CHAINLINK_UPKEEP_ID"
            echo "  make verify-automation-working"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
}

# Show initial setup info
echo "📊 INITIAL STATUS CHECK"
echo "======================"
check_upkeep_status

echo ""
echo "🎯 KEY INDICATORS TO WATCH:"
echo "=========================="
echo "✅ LINK Balance > 0        → Upkeep is funded"
echo "✅ Amount Spent > 0        → Automation is executing!"
echo "✅ Status: ACTIVE          → Upkeep is enabled"
echo "✅ checkUpkeep() = true    → Work is available"
echo ""

# Main loop
while true; do
    main_menu
    echo ""
done 