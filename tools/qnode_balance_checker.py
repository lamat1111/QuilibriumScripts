#!/usr/bin/env python3

import subprocess
import os
import csv
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

# Function to read the last entry from CSV file
def read_last_entry_from_csv(filename):
    try:
        with open(filename, 'r') as file:
            reader = csv.reader(file)
            last_row = None
            for row in reader:
                last_row = row
            return last_row
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return None

# Function to write data to CSV file
def write_to_csv(filename, data):
    try:
        with open(filename, 'a', newline='') as file:
            writer = csv.writer(file)
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
            hostname = os.getenv('HOSTNAME', 'unknown')
            filename = f"{home_dir}/scripts/rewards_log_{hostname}.csv"
            
            # Read last entry from CSV file
            last_entry = read_last_entry_from_csv(filename)
            if last_entry:
                last_timestamp = datetime.strptime(last_entry[0], '%d/%m/%Y %H:%M')
                last_balance = float(last_entry[1])
                last_increase = float(last_entry[2])
            else:
                last_timestamp = current_time - timedelta(hours=1)
                last_balance = balance
                last_increase = 0.0
            
            # Calculate increase in balance since last recorded entry
            increase = balance - last_balance
            
            # Print data
            data_to_write = [
                current_time.strftime('%d/%m/%Y %H:%M'),
                str(balance),
                str(increase)
            ]
            print(','.join(data_to_write))
            
            # Write to CSV file
            write_to_csv(filename, data_to_write)
    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
