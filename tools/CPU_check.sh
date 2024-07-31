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

# Install sysbench if not already installed
sudo apt-get update
sudo apt-get install -y sysbench

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

    # Run CPU benchmark
    sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run | grep -E "total time:|events per second:|total number of events:"

} > "$LOG_FILE"

echo "CPU benchmark completed. Results are saved in $LOG_FILE"
