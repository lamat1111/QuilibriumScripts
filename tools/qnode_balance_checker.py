#!/usr/bin/env python3

import subprocess
import os
import csv
import random
from datetime import datetime, timedelta

# Function to get the unclaimed balance
def get_unclaimed_balance():
    try:
        node_command = ['./node-1.4.19-linux-amd64', '-node-info']
        node_directory = os.path.expanduser('~/ceremonyclient/node')
        result = subprocess.run(node_command, cwd=node_directory, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        output = result.stdout.decode('utf-8')
        
        for line in output.split('\n'):
            if 'Unclaimed balance' in line:
                balance = float(line.split()[2])
                return balance
    except subprocess.CalledProcessError as e:
        print(f"Error running node command: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    return None

# Function to write data to CSV file
def write_to_csv(filename, data):
    try:
        # Check if file exists to determine if headers need to be written
        file_exists = os.path.isfile(filename)
        with open(filename, 'a', newline='') as file:
            writer = csv.writer(file)
            if not file_exists:
                writer.writerow(["time", "balance", "increase"])  # Write headers if file is empty
            writer.writerow(data)
    except Exception as e:
        print(f"Error writing to CSV file: {e}")

# Main function to run once per execution
def main():
    try:
        current_time = datetime.now()
        balance = get_unclaimed_balance()
        if balance is not None:
            home_dir = os.getenv('HOME', '/root')
            filename = f"{home_dir}/scripts/balance_log.csv"
            
            # Calculate previous hour time range
            start_time = current_time - timedelta(hours=1)
            
            # For now, we're using the current balance instead of get_unclaimed_balance_at_time
            balance_one_hour_ago = balance
            
            # Calculate increase in balance over one hour
            increase = balance - balance_one_hour_ago
            
            # Format increase to 4 decimal places
            formatted_increase = f"{increase:.4f}"
            
            # Format balance to 2 decimal places
            formatted_balance = f"{balance:.2f}"

            # Print data
            data_to_write = [
                current_time.strftime('%d/%m/%Y %H:%M'),
                formatted_balance,
                formatted_increase
            ]
            print(','.join(data_to_write))
            
            # Write to CSV file
            write_to_csv(filename, data_to_write)
    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
