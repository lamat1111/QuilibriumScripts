#!/usr/bin/env python3

import subprocess
import os
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
        with open(filename, 'w') as file:
            file.write("date and time,balance,increase\n")
            for row in data:
                file.write(','.join(map(str, row)) + '\n')
    except Exception as e:
        print(f"Error writing to CSV file: {e}")

# Main function to run once per hour
def main():
    try:
        balance = get_unclaimed_balance()
        current_time = datetime.now()
        
        if balance is not None:
            home_dir = os.getenv('HOME', '/root')
            filename = f"{home_dir}/scripts/rewards_log_{os.getenv('HOSTNAME', 'unknown')}.csv"
            
            # Calculate previous hour time range
            start_time = current_time.replace(minute=0, second=0, microsecond=0) - timedelta(hours=1)
            end_time = start_time + timedelta(hours=1)
            
            # Calculate increase in balance
            previous_hour_data = []
            while current_time > start_time:
                previous_hour_data.append([
                    current_time.strftime('%d/%m/%Y %H:%M'),
                    balance,
                    0  # Placeholder for increase, filled below
                ])
                current_time -= timedelta(minutes=1)
            
            for i in range(len(previous_hour_data)-1, 0, -1):
                previous_hour_data[i][2] = previous_hour_data[i][1] - previous_hour_data[i-1][1]

            # Write to CSV file
            write_to_csv(filename, previous_hour_data)
            
            print(f"Data written to {filename} for {start_time.strftime('%d/%m/%Y %H:%M')} - {end_time.strftime('%d/%m/%Y %H:%M')}")
    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
