#!/bin/bash

# SSH Push Tool - Simple Installation Script
# Version: 3.0.0 - Complete rebuild from scratch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show help
show_help() {
    echo "SSH Push Tool - Simple Installation"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --force, -f    Force installation without prompts"
    echo ""
    echo "Examples:"
    echo "  $0             # Interactive installation"
    echo "  $0 --force     # Force installation"
    echo ""
    echo "One-line installation:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)"
}

# Function to create the self-contained ssh-push script
create_ssh_push_script() {
    local install_dir="$HOME/.local/bin"
    local script_path="$install_dir/ssh-push"
    
    print_status "Creating self-contained SSH Push script..."
    
    # Create the installation directory
    mkdir -p "$install_dir"
    
    # Create the self-contained script
    if ! cat > "$script_path" << 'EOF'
#!/usr/bin/env python3
"""
SSH Push Tool - Self-contained script for pushing files to remote devices
Version: 3.0.0
"""

import os
import sys
import json
import argparse
import subprocess
import getpass
from pathlib import Path

class SSHPushTool:
    def __init__(self):
        self.config_file = ".ssh_push_config.json"
        self.config = self.load_config()
    
    def load_config(self):
        """Load SSH configuration from file"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                return None
        return None
    
    def save_config(self, config):
        """Save SSH configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"Configuration saved to {self.config_file}")
            return True
        except IOError as e:
            print(f"Error saving configuration: {e}")
            return False
    
    def setup_config(self):
        """Interactive setup of SSH configuration"""
        print("SSH Push Tool Configuration Setup")
        print("==================================")
        
        config = {}
        
        # Hostname
        while True:
            hostname = input("Remote hostname/IP (e.g., pi@192.168.1.100): ").strip()
            if hostname:
                config['hostname'] = hostname
                break
            print("Hostname is required.")
        
        # Port
        port = input("SSH port (default: 22): ").strip()
        config['port'] = int(port) if port.isdigit() else 22
        
        # Remote directory
        remote_dir = input("Remote working directory (default: ~/fpga_work): ").strip()
        config['remote_dir'] = remote_dir if remote_dir else "~/fpga_work"
        
        # Authentication method
        while True:
            auth_method = input("Authentication method (key/password) [key]: ").strip().lower()
            if not auth_method:
                auth_method = "key"
            if auth_method in ["key", "password"]:
                config['auth_method'] = auth_method
                break
            print("Please choose 'key' or 'password'.")
        
        # SSH key path (if using key authentication)
        if auth_method == "key":
            key_path = input("SSH key path (default: ~/.ssh/id_rsa): ").strip()
            config['key_path'] = key_path if key_path else "~/.ssh/id_rsa"
        
        if self.save_config(config):
            print("Configuration setup complete!")
            return True
        return False
    
    def edit_config(self):
        """Edit existing configuration"""
        if not self.config:
            print("No configuration found. Run setup first.")
            return False
        
        print("Current configuration:")
        self.show_config()
        
        if input("Edit configuration? (y/N): ").lower() == 'y':
            return self.setup_config()
        return True
    
    def show_config(self):
        """Show current configuration"""
        if not self.config:
            print("No SSH configuration found.")
            print("Run with --setup to create configuration.")
            return
        
        print("Current SSH configuration:")
        print(f"  Hostname: {self.config.get('hostname', 'Not set')}")
        print(f"  Port: {self.config.get('port', 'Not set')}")
        print(f"  Remote Directory: {self.config.get('remote_dir', 'Not set')}")
        print(f"  Auth Method: {self.config.get('auth_method', 'Not set')}")
        if self.config.get('auth_method') == 'key':
            print(f"  SSH Key: {self.config.get('key_path', 'Not set')}")
    
    def test_connection(self):
        """Test SSH connection"""
        if not self.config:
            print("No configuration found. Run setup first.")
            return False
        
        print("Testing SSH connection...")
        
        # Build SSH command
        ssh_cmd = ["ssh"]
        
        if self.config.get('auth_method') == 'key':
            ssh_cmd.extend(["-i", os.path.expanduser(self.config['key_path'])])
        
        ssh_cmd.extend(["-p", str(self.config['port'])])
        ssh_cmd.append(self.config['hostname'])
        ssh_cmd.append("echo 'SSH connection successful!'")
        
        try:
            result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                print("SSH connection successful!")
                return True
            else:
                print(f"SSH connection failed: {result.stderr}")
                return False
        except subprocess.TimeoutExpired:
            print("SSH connection timed out.")
            return False
        except Exception as e:
            print(f"SSH connection error: {e}")
            return False
    
    def list_remote_files(self):
        """List files in remote directory"""
        if not self.config:
            print("No configuration found. Run setup first.")
            return False
        
        print("Listing remote files...")
        
        # Build SSH command
        ssh_cmd = ["ssh"]
        
        if self.config.get('auth_method') == 'key':
            ssh_cmd.extend(["-i", os.path.expanduser(self.config['key_path'])])
        
        ssh_cmd.extend(["-p", str(self.config['port'])])
        ssh_cmd.append(self.config['hostname'])
        ssh_cmd.append(f"ls -la {self.config['remote_dir']}")
        
        try:
            result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                print("Remote files:")
                print(result.stdout)
            else:
                print(f"Failed to list remote files: {result.stderr}")
        except Exception as e:
            print(f"Error listing remote files: {e}")
    
    def push_files(self, files, verbose=False):
        """Push files to remote device"""
        if not self.config:
            print("No configuration found. Run setup first.")
            return False
        
        if not files:
            print("No files specified to push.")
            return False
        
        print(f"Pushing {len(files)} file(s) to remote device...")
        
        # Build SCP command
        scp_cmd = ["scp"]
        
        if verbose:
            scp_cmd.append("-v")
        
        if self.config.get('auth_method') == 'key':
            scp_cmd.extend(["-i", os.path.expanduser(self.config['key_path'])])
        
        scp_cmd.extend(["-P", str(self.config['port'])])
        scp_cmd.extend(files)
        scp_cmd.append(f"{self.config['hostname']}:{self.config['remote_dir']}")
        
        try:
            if verbose:
                print(f"Running: {' '.join(scp_cmd)}")
            
            result = subprocess.run(scp_cmd, timeout=60)
            if result.returncode == 0:
                print("Files pushed successfully!")
                return True
            else:
                print("Failed to push files.")
                return False
        except subprocess.TimeoutExpired:
            print("File transfer timed out.")
            return False
        except Exception as e:
            print(f"Error pushing files: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(
        description="SSH File Push Tool - Push files to remote device",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  ssh-push --setup                    # Setup SSH configuration
  ssh-push --edit                     # Edit existing configuration
  ssh-push blinky.v                   # Push single file
  ssh-push file1.v file2.v            # Push multiple files
  ssh-push --list                     # List remote files
  ssh-push --test                     # Test SSH connection
  ssh-push --config                   # Show configuration
  ssh-push --verbose blinky.v         # Push with verbose output
        """
    )
    
    parser.add_argument('files', nargs='*', help='Files to push to remote host')
    parser.add_argument('--setup', '-s', action='store_true', help='Setup SSH configuration')
    parser.add_argument('--edit', '-e', action='store_true', help='Edit existing SSH configuration')
    parser.add_argument('--list', '-l', action='store_true', help='List files in remote working directory')
    parser.add_argument('--test', '-t', action='store_true', help='Test SSH connection')
    parser.add_argument('--config', '-c', action='store_true', help='Show current configuration')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--version', action='version', version='ssh-push 3.0.0')
    
    args = parser.parse_args()
    
    tool = SSHPushTool()
    
    # Handle different commands
    if args.setup:
        tool.setup_config()
    elif args.edit:
        tool.edit_config()
    elif args.list:
        tool.list_remote_files()
    elif args.test:
        tool.test_connection()
    elif args.config:
        tool.show_config()
    elif args.files:
        tool.push_files(args.files, args.verbose)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF
    then
        print_error "Failed to create SSH Push script"
        return 1
    fi
    
    # Make the script executable
    if ! chmod +x "$script_path"; then
        print_error "Failed to make SSH Push script executable"
        return 1
    fi
    
    print_success "SSH Push script created at $script_path"
    
    echo "$script_path"
}

# Function to setup shell alias
setup_shell_alias() {
    local script_path="$1"
    
    print_status "Setting up shell alias..."
    
    # Determine shell configuration file
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    # Remove existing alias if present
    if grep -q "alias ssh-push=" "$shell_rc" 2>/dev/null; then
        sed -i.bak '/# SSH Push Tool alias/d' "$shell_rc"
        sed -i.bak '/alias ssh-push=/d' "$shell_rc"
        print_status "Removed existing ssh-push alias"
    fi
    
    # Add new alias
    echo "" >> "$shell_rc"
    echo "# SSH Push Tool alias" >> "$shell_rc"
    echo "alias ssh-push='$script_path'" >> "$shell_rc"
    
    print_success "SSH Push alias added to $shell_rc"
}

# Function to verify installation
verify_installation() {
    local script_path="$1"
    
    print_status "Verifying installation..."
    
    # Wait a moment for file system to sync
    sleep 0.5
    
    if [[ -f "$script_path" ]]; then
        print_success "SSH Push script exists"
    else
        print_error "SSH Push script NOT found"
        return 1
    fi
    
    if [[ -x "$script_path" ]]; then
        print_success "SSH Push script is executable"
    else
        print_error "SSH Push script is NOT executable"
        return 1
    fi
    
    # Test if command is accessible
    if command -v ssh-push &> /dev/null; then
        print_success "ssh-push command is accessible"
    else
        print_warning "ssh-push command is NOT accessible in current session"
        print_status "Try: source ~/.bashrc or restart your terminal"
    fi
    
    # Test the script directly
    if "$script_path" --version &> /dev/null; then
        print_success "SSH Push script runs correctly"
    else
        print_error "SSH Push script failed to run"
        return 1
    fi
}

# Function to confirm installation
confirm_installation() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo "SSH Push Tool Installation"
    echo "=========================="
    echo "This will install SSH Push tool to ~/.local/bin/"
    echo "and add an alias to your shell configuration."
    echo ""
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
}

# Parse command line arguments
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main installation
main_installation() {
    # Confirm installation
    confirm_installation
    
    # Create the self-contained script
    local script_path=$(create_ssh_push_script)
    
    # Setup shell alias
    setup_shell_alias "$script_path"
    
    # Small delay to ensure file system sync
    sleep 1
    
    # Verify installation (but don't fail if verification has issues)
    if ! verify_installation "$script_path"; then
        print_warning "Verification had some issues, but installation may still be successful"
        print_status "Testing ssh-push command directly..."
        if "$script_path" --version &> /dev/null; then
            print_success "SSH Push script works correctly"
        else
            print_error "SSH Push script failed to run"
            exit 1
        fi
    fi
    
    # Show completion message
    echo ""
    print_success "SSH Push tool has been installed successfully!"
    print_status "You can now use 'ssh-push' command from anywhere"
    print_status "To get started, run: ssh-push --help"
    print_status "To setup SSH configuration, run: ssh-push --setup"
    echo ""
    print_status "To uninstall later, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)"
}

# Run main installation
main_installation 