#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    color=$1
    text=$2
    echo -e "${color}${text}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if it doesn't exist
install_package() {
    if ! command_exists "$1"; then
        echo "Installing $1..."
        sudo apt-get update && sudo apt-get install -y "$1"
    fi
}

# Function to get CPU information
get_cpu_info() {
    lscpu | grep -E "Model name|CPU MHz"
}

# Function to get total RAM in GB
get_ram_info() {
    free -h | awk '/^Mem:/ {print $2}'
}

# Function to check CPU boost status
check_cpu_boost() {
    if [ -f "/sys/devices/system/cpu/cpufreq/boost" ]; then
        boost_status=$(cat /sys/devices/system/cpu/cpufreq/boost)
        if [ "$boost_status" -eq 1 ]; then
            echo "CPU Boost: Enabled"
        else
            echo "CPU Boost: Disabled"
        fi
    else
        echo "CPU Boost: Status not available"
    fi
}

# Function to check CPU governor (performance mode)
check_cpu_governor() {
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        echo "CPU Governor: $governor"
    else
        echo "CPU Governor: Not available"
    fi
}

# Install necessary tools
install_package sysbench
install_package stress-ng
install_package lm-sensors
install_package dmidecode

# Create log file
LOG_FILE=~/CPU_benchmark_results.txt

# Function to run tests and output results
run_tests() {
    {
        print_color $BLUE "System Information:"
        print_color $BLUE "==================="
        echo "Hostname: $(hostname)"
        echo "IP Address: $(hostname -I | awk '{print $1}')"
        echo "OS: $(lsb_release -ds)"
        echo "Kernel: $(uname -r)"
        echo

        print_color $BLUE "CPU Information:"
        print_color $BLUE "================="
        get_cpu_info
        echo "CPU Cores: $(nproc)"
        echo "Total RAM: $(get_ram_info)"
        echo

        print_color $BLUE "CPU Settings:"
        print_color $BLUE "=============="
        check_cpu_boost
        check_cpu_governor
        echo

        print_color $BLUE "CPU Frequency Information:"
        print_color $BLUE "==========================="
        cat /proc/cpuinfo | grep "MHz"
        echo

        print_color $BLUE "Memory Information:"
        print_color $BLUE "===================="
        free -h
        echo

        print_color $GREEN "CPU Benchmark Results:"
        print_color $GREEN "======================"
        
        print_color $YELLOW "1. Sysbench CPU Test (Multi-threaded, Prime Numbers):"
        sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run | grep -E "total time:|events per second:|total number of events:"
        echo
        
        print_color $YELLOW "2. Sysbench Single-threaded CPU Test:"
        sysbench cpu --cpu-max-prime=20000 --threads=1 run | grep -E "total time:|events per second:|total number of events:"
        echo
        
        print_color $YELLOW "3. Stress-ng CPU Test (1 minute):"
        stress-ng --cpu $(nproc) --timeout 1m --metrics-brief
        echo
        
        print_color $YELLOW "4. Sysbench Memory Test:"
        sysbench memory --memory-block-size=1K --memory-total-size=10G run | grep -E "Operations|Transferred|total time:"
        echo
        
        print_color $YELLOW "5. Processor Information:"
        lscpu | grep -E "Model name|Vendor ID|CPU family|CPU MHz|Cache"
        echo
        
        print_color $YELLOW "6. CPU Temperature (if available):"
        if command_exists sensors; then
            sensors | grep -i "core"
        else
            echo "Temperature information not available (lm-sensors not installed)"
        fi
        echo

        print_color $YELLOW "7. Additional CPU Details:"
        sudo dmidecode -t processor
        echo

    } | tee $LOG_FILE
}

# Run tests and display results
run_tests
print_color $GREEN "Comprehensive CPU benchmark completed. Results are saved in $LOG_FILE"
