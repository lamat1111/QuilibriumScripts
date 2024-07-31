#!/bin/bash

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
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    echo "CPU Governor: $governor"
}

# Install necessary tools
sudo apt-get update
sudo apt-get install -y sysbench stress-ng

# Create and write to log file
LOG_FILE=~/CPU_check.txt

{
    echo "System Information:"
    echo "==================="
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "OS: $(lsb_release -ds)"
    echo "Kernel: $(uname -r)"
    echo
    echo "CPU Information:"
    get_cpu_info
    echo "CPU Cores: $(nproc)"
    echo "Total RAM: $(get_ram_info)"
    echo
    echo "CPU Settings:"
    check_cpu_boost
    check_cpu_governor
    echo
    echo "CPU Benchmark Results:"
    echo "======================"
    
    echo "1. Sysbench CPU Test (Prime Numbers):"
    sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run | grep -E "total time:|events per second:|total number of events:"
    echo
    
    echo "2. Sysbench Single-threaded CPU Test:"
    sysbench cpu --cpu-max-prime=20000 --threads=1 run | grep -E "total time:|events per second:|total number of events:"
    echo
    
    echo "3. Stress-ng CPU Test (1 minute):"
    stress-ng --cpu $(nproc) --timeout 60s --metrics-brief
    echo
    
    echo "4. Sysbench Memory Test:"
    sysbench memory --memory-block-size=1K --memory-total-size=10G run | grep -E "Operations|Transferred|total time:"
    echo
    
    echo "5. Processor Information:"
    lscpu | grep -E "Model name|Vendor ID|CPU family|CPU MHz|Cache"
    echo
    
    echo "6. CPU Temperature (if available):"
    if command -v sensors &> /dev/null; then
        sensors | grep -i "core"
    else
        echo "Temperature information not available (lm-sensors not installed)"
    fi

} > "$LOG_FILE"

echo "Comprehensive CPU benchmark completed. Results are saved in $LOG_FILE"
