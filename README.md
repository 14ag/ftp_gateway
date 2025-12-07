
# Windows FTP helper

Small Windows script to automate connecting to an FTP server using Windows Explorer

## Summary
This project creates a desktop `.ini` configuration and uses built-in Windows tools (Explorer + VBScript + PowerShell) to simplify FTP connections for users on Windows.

## Features
- Creates a `.ini` file on the desktop with connection settings.
- Uses Windows Explorer as the FTP client.
- Network helper scripts to detect network gateways and ping ftp ports.

## Requirements
- Windows 10
- PowerShell enabled
- VBScript enabled
- Firewall permissions to reach FTP server
- subnet mask `255.255.255.0`

## Quick start
1. Download the latest release

## File overview
- `main.bat` — main entry point / menu
- `main_test.bat` — test-mode (dry run)
- `lab2.bat` — helper / example task
- `GetGateways.vbs` — discovers gateway(s) on the local network
- `ip.vbs` — shows/manipulates IP information
- `icon11.ico` — icon used for shortcuts
- `.gitignore` — files to ignore in commits

## Configuration
The script writes an `.ini` file to the desktop named `ftpconfig.ini`. Example contents:

