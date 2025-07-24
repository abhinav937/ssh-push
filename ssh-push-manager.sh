#!/bin/bash

# SSH Push Tool - Unified Manager Script
# Version: 3.0.1 - Handles install, uninstall, and update operations

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
    echo "SSH Push Tool - Unified Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  install, i     Install SSH Push tool"
    echo "  uninstall, u   Uninstall SSH Push tool"
    echo "  update, up     Update SSH Push tool"
    echo "  status, s      Show installation status"
    echo "  help, h        Show this help message"
    echo ""
    echo "Options:"
    echo "  --force, -f    Force operation without prompts"
    echo "  --keep-config  Keep SSH configuration files (uninstall only)"
    echo ""
    echo "Examples:"
    echo "  $0 install                    # Install SSH Push tool"
    echo "  $0 update                     # Update SSH Push tool"
    echo "  $0 uninstall                  # Uninstall SSH Push tool"
    echo "  $0 install --force            # Force install without prompts"
    echo "  $0 uninstall --keep-config   # Uninstall but keep SSH config"
    echo ""
    echo "One-line commands:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) update"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall"
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
Version: 3.0.1
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
    parser.add_argument('--version', action='version', version='ssh-push 3.0.1')
    
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

# Function to remove SSH Push tool
remove_ssh_push_tool() {
    print_status "Removing SSH Push tool..."
    
    local script_path="$HOME/.local/bin/ssh-push"
    
    if [[ -f "$script_path" ]]; then
        if rm "$script_path"; then
            print_success "SSH Push tool removed from $script_path"
        else
            print_error "Failed to remove SSH Push tool"
            return 1
        fi
    else
        print_warning "SSH Push tool not found at $script_path"
    fi
    
    # Remove the ~/.local/bin directory if it's empty
    if [[ -d "$HOME/.local/bin" ]] && [[ -z "$(ls -A "$HOME/.local/bin")" ]]; then
        rmdir "$HOME/.local/bin"
        print_status "Removed empty ~/.local/bin directory"
    fi
}

# Function to remove shell alias
remove_shell_alias() {
    print_status "Removing SSH Push command alias..."
    
    # Determine shell configuration file
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [[ -f "$shell_rc" ]]; then
        # Remove ssh-push alias lines
        if grep -q "alias ssh-push=" "$shell_rc"; then
            # Create backup
            local backup_file="$shell_rc.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$shell_rc" "$backup_file"
            
            # Remove alias lines
            sed -i '/# SSH Push Tool alias/d' "$shell_rc"
            sed -i '/alias ssh-push=/d' "$shell_rc"
            
            print_success "SSH Push alias removed from $shell_rc"
            print_status "Backup created: $backup_file"
        else
            print_warning "SSH Push alias not found in $shell_rc"
        fi
    else
        print_warning "Shell configuration file not found: $shell_rc"
    fi
}

# Function to remove SSH configuration files
remove_ssh_config_files() {
    if [[ "$KEEP_CONFIG" == "true" ]]; then
        print_status "Keeping SSH configuration files (--keep-config specified)"
        return 0
    fi
    
    print_status "Removing SSH configuration files..."
    
    # Remove SSH configuration file
    local ssh_config=".ssh_push_config.json"
    if [[ -f "$ssh_config" ]]; then
        if rm "$ssh_config"; then
            print_success "SSH configuration file removed: $ssh_config"
        else
            print_warning "Failed to remove SSH configuration file: $ssh_config"
        fi
    else
        print_warning "SSH configuration file not found: $ssh_config"
    fi
    
    # Remove SSH configuration file from home directory (if it exists there)
    local home_ssh_config="$HOME/.ssh_push_config.json"
    if [[ -f "$home_ssh_config" ]]; then
        if rm "$home_ssh_config"; then
            print_success "SSH configuration file removed from home: $home_ssh_config"
        else
            print_warning "Failed to remove SSH configuration file from home: $home_ssh_config"
        fi
    fi
}

# Function to check installation status
check_installation_status() {
    print_status "Checking SSH Push tool installation status..."
    
    local script_path="$HOME/.local/bin/ssh-push"
    local shell_rc=""
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    echo "Installation Status:"
    echo "==================="
    
    # Check if script exists
    if [[ -f "$script_path" ]]; then
        print_success "✓ SSH Push script found at: $script_path"
    else
        print_warning "✗ SSH Push script not found at: $script_path"
    fi
    
    # Check if script is executable
    if [[ -x "$script_path" ]]; then
        print_success "✓ SSH Push script is executable"
    else
        print_warning "✗ SSH Push script is not executable"
    fi
    
    # Check if alias exists
    if [[ -f "$shell_rc" ]] && grep -q "alias ssh-push=" "$shell_rc"; then
        print_success "✓ SSH Push alias found in: $shell_rc"
    else
        print_warning "✗ SSH Push alias not found in: $shell_rc"
    fi
    
    # Check if command is accessible
    if command -v ssh-push &> /dev/null; then
        print_success "✓ ssh-push command is accessible"
    else
        print_warning "✗ ssh-push command is not accessible"
    fi
    
    # Check for configuration files
    local config_files=(".ssh_push_config.json" "$HOME/.ssh_push_config.json")
    local config_found=false
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            print_success "✓ SSH configuration found: $config_file"
            config_found=true
        fi
    done
    
    if [[ "$config_found" == "false" ]]; then
        print_warning "✗ No SSH configuration files found"
    fi
}

# Function to confirm operation
confirm_operation() {
    local operation="$1"
    
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo "SSH Push Tool - $operation"
    echo "=========================="
    
    case "$operation" in
        "Install")
            echo "This will install SSH Push tool to ~/.local/bin/"
            echo "and add an alias to your shell configuration."
            ;;
        "Uninstall")
            echo "This will remove the SSH Push tool and all its components:"
            echo "  • SSH Push tool executable"
            echo "  • Shell alias"
            if [[ "$KEEP_CONFIG" != "true" ]]; then
                echo "  • SSH configuration files"
            fi
            ;;
        "Update")
            echo "This will update the SSH Push tool to the latest version."
            echo "Your existing configuration will be preserved."
            ;;
    esac
    
    echo ""
    read -p "Continue with $operation? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "$operation cancelled"
        exit 0
    fi
}

# Function to install SSH Push tool
install_ssh_push() {
    print_status "Installing SSH Push tool..."
    
    # Create the self-contained script
    local script_path=$(create_ssh_push_script)
    
    # Setup shell alias
    setup_shell_alias "$script_path"
    
    # Show completion message
    echo ""
    print_success "SSH Push tool has been installed successfully!"
    print_status "You can now use 'ssh-push' command from anywhere"
    print_status "To get started, run: ssh-push --help"
    print_status "To setup SSH configuration, run: ssh-push --setup"
    echo ""
    print_status "To update later, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) update"
}

# Function to uninstall SSH Push tool
uninstall_ssh_push() {
    print_status "Uninstalling SSH Push tool..."
    
    # Remove SSH Push tool
    remove_ssh_push_tool
    
    # Remove shell alias
    remove_shell_alias
    
    # Remove SSH configuration files
    remove_ssh_config_files
    
    # Show uninstallation summary
    echo ""
    print_success "SSH Push tool has been uninstalled"
    print_status "The following components were removed:"
    echo "  • SSH Push tool executable"
    echo "  • Shell alias"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
    echo ""
    print_status "If you want to reinstall SSH Push tool, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install"
    echo ""
    print_status "Note: You may need to restart your terminal for all changes to take effect"
}

# Function to update SSH Push tool
update_ssh_push() {
    print_status "Updating SSH Push tool..."
    
    # Check if tool is currently installed
    local script_path="$HOME/.local/bin/ssh-push"
    if [[ ! -f "$script_path" ]]; then
        print_warning "SSH Push tool is not installed. Installing instead..."
        install_ssh_push
        return
    fi
    
    # Create the updated self-contained script
    local new_script_path=$(create_ssh_push_script)
    
    # Show completion message
    echo ""
    print_success "SSH Push tool has been updated successfully!"
    print_status "Your existing configuration has been preserved."
    print_status "To verify the update, run: ssh-push --version"
}

# Parse command line arguments
COMMAND=""
FORCE=false
KEEP_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        install|i)
            COMMAND="install"
            shift
            ;;
        uninstall|u)
            COMMAND="uninstall"
            shift
            ;;
        update|up)
            COMMAND="update"
            shift
            ;;
        status|s)
            COMMAND="status"
            shift
            ;;
        help|h)
            show_help
            exit 0
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --keep-config)
            KEEP_CONFIG=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
case "$COMMAND" in
    install)
        confirm_operation "Install"
        install_ssh_push
        ;;
    uninstall)
        confirm_operation "Uninstall"
        uninstall_ssh_push
        ;;
    update)
        confirm_operation "Update"
        update_ssh_push
        ;;
    status)
        check_installation_status
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac 