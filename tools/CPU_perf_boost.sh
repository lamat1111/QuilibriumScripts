#!/bin/bash

# Function to check if the system is Linux and has an AMD processor
check_system_compatibility() {
    # Check if the system is Linux
    if [[ "$(uname)" != "Linux" ]]; then
        echo "Error: This script is intended for Linux systems only."
        exit 1
    fi

    # Check if the processor is AMD
    if ! grep -qi "amd" /proc/cpuinfo; then
        echo "Error: This script is intended for AMD processors only."
        exit 1
    fi

    echo "System compatibility check passed. Proceeding with the script."
}


# Function to check if the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi
}

# Function to check and install dependencies
check_and_install_dependencies() {
    local dependencies=("linux-tools-generic" "cpufrequtils")
    local to_install=()

    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "$dep" >/dev/null 2>&1; then
            to_install+=("$dep")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        echo "Installing required dependencies: ${to_install[*]}"
        apt-get update
        apt-get install -y "${to_install[@]}"
    else
        echo "All required dependencies are already installed."
    fi
}

# Function to perform system updates
update_system() {
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get autoremove -y
    apt-get autoclean
}

# Function to check and install specific kernel version
check_and_install_kernel() {
    local desired_kernel="5.19.0-50-generic"
    if uname -r | grep -q "$desired_kernel"; then
        echo "Kernel $desired_kernel is already installed. Skipping kernel installation."
    else
        echo "Installing kernel $desired_kernel..."
        apt-get install linux-image-$desired_kernel linux-headers-$desired_kernel -y
    fi
}

# Function to modify GRUB configuration
modify_grub() {
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash amd_pstate=passive"/' /etc/default/grub
    update-grub
}

# Function to set CPU governor to performance
set_cpu_governor() {
    echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

# Function to display system info
display_system_info() {
    echo "================================================"
    echo "Current System State:"
    echo "================================================"
    echo "Kernel version:"
    uname -r
    echo ""
    echo "CPU frequency scaling driver:"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver | sort | uniq
    echo ""
    echo "CPU frequency info:"
    cpupower frequency-info | grep -E "CPU|driver|frequency|governor"
    echo "================================================"
}

# Main script execution
check_system_compatibility
check_sudo
check_and_install_dependencies

echo "Updating system..."
update_system

echo "Current kernel version:"
uname -r

check_and_install_kernel

echo "Modifying GRUB configuration..."
modify_grub

echo "Setting CPU governor to performance..."
set_cpu_governor

echo "Script execution complete."

display_system_info
echo
echo "================================================"
echo "Please manually reboot your system to complete the process."
echo "After reboot, the new kernel version (if installed) and GRUB changes will take effect."
echo "To reboot, use the command: sudo reboot"
echo ""
echo "After rebooting, run these commands to see the updated system state:"
echo "sudo cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver"
echo "sudo cpupower frequency-info"
echo "================================================"