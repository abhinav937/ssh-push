#!/bin/bash

# SSH Push Tool - Uninstall Script
# This script removes the ssh-push command alias, SSH Push tool, and cleans up configuration files
# Version: 2.0.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Helper functions with timestamps
print_status() { echo -e "${BLUE}[$(get_timestamp)] [INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[$(get_timestamp)] [SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[$(get_timestamp)] [WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[$(get_timestamp)] [ERROR]${NC} $1"; }
print_header() { echo -e "${PURPLE}${BOLD}$1${NC}"; }

# Function to show help
show_help() {
    echo "SSH Push Tool Uninstall Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --force, -f          Force removal without confirmation prompts"
    echo "  --keep-config        Keep SSH configuration files"
    echo "  --keep-backups       Keep backup files"
    echo ""
    echo "Examples:"
    echo "  $0                   # Interactive uninstallation"
    echo "  $0 --force           # Force removal without prompts"
    echo "  $0 --keep-config     # Remove tool but keep SSH config"
    echo ""
    echo "Recommended one-line uninstallation:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)"
}

# Function to remove SSH Push tool
remove_ssh_push_tool() {
    print_status "Removing SSH Push tool..."
    
    # Remove the ssh-push from ~/.local/bin (where install script puts it)
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    if [[ -f "$ssh_push_script" ]]; then
        if rm "$ssh_push_script"; then
            print_success "SSH Push tool removed from $ssh_push_script"
        else
            print_error "Failed to remove SSH Push tool from $ssh_push_script"
            return 1
        fi
    else
        print_warning "SSH Push tool not found at $ssh_push_script"
    fi
    
    # Remove the Python script if it exists
    local python_script="$HOME/.local/bin/ssh_push.py"
    if [[ -f "$python_script" ]]; then
        if rm "$python_script"; then
            print_success "Python script removed from $python_script"
        else
            print_warning "Failed to remove Python script from $python_script"
        fi
    fi
    
    # Remove the ~/.local/bin directory if it's empty
    if [[ -d "$HOME/.local/bin" ]] && [[ -z "$(ls -A "$HOME/.local/bin")" ]]; then
        rmdir "$HOME/.local/bin"
        print_status "Removed empty ~/.local/bin directory"
    fi
    
    # Also check /usr/local/bin (old installation location)
    local old_ssh_push_script="/usr/local/bin/ssh-push"
    if [[ -f "$old_ssh_push_script" ]]; then
        print_status "Found SSH Push tool in old location: $old_ssh_push_script"
        if sudo rm "$old_ssh_push_script" 2>/dev/null; then
            print_success "SSH Push tool removed from old location"
        else
            print_warning "Failed to remove SSH Push tool from old location (may need manual removal)"
        fi
    fi
}

# Function to remove SSH Push command alias
remove_ssh_push_alias() {
    print_status "Removing SSH Push command alias..."
    
    # Determine shell configuration file
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
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

# Function to remove backup files
remove_backup_files() {
    if [[ "$KEEP_BACKUPS" == "true" ]]; then
        print_status "Keeping backup files (--keep-backups specified)"
        return 0
    fi
    
    print_status "Removing backup files..."
    
    # Remove backup files created during installation
    local backup_files=(
        "$HOME/.bashrc.backup."*
        "$HOME/.zshrc.backup."*
        "*.backup"
    )
    
    local backups_found=false
    for backup_file in "${backup_files[@]}"; do
        if [[ -f "$backup_file" ]]; then
            if rm "$backup_file"; then
                print_success "Backup file removed: $backup_file"
                backups_found=true
            else
                print_warning "Failed to remove backup file: $backup_file"
            fi
        fi
    done
    
    if [[ "$backups_found" == "false" ]]; then
        print_status "No backup files found to remove"
    fi
}

# Function to clean up temporary files
cleanup_temp_files() {
    print_status "Cleaning up temporary files..."
    
    # Remove temporary files created during installation
    local temp_patterns=(
        "/tmp/install_check.sh"
        "/tmp/ssh_push_check"
        "/tmp/ssh_push_new"
        "/tmp/install_self_update.sh"
        "ssh-push.tmp"
    )
    
    local temp_files_found=false
    for temp_file in "${temp_patterns[@]}"; do
        if [[ -f "$temp_file" ]]; then
            if rm "$temp_file"; then
                print_success "Temporary file removed: $temp_file"
                temp_files_found=true
            else
                print_warning "Failed to remove temporary file: $temp_file"
            fi
        fi
    done
    
    if [[ "$temp_files_found" == "false" ]]; then
        print_status "No temporary files found to remove"
    fi
}

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    local old_ssh_push_script="/usr/local/bin/ssh-push"
    local python_script="$HOME/.local/bin/ssh_push.py"
    
    # Check if SSH Push tool is still present
    if [[ -f "$ssh_push_script" ]]; then
        print_warning "SSH Push tool still exists at: $ssh_push_script"
    else
        print_success "SSH Push tool removed from ~/.local/bin"
    fi
    
    if [[ -f "$old_ssh_push_script" ]]; then
        print_warning "SSH Push tool still exists at old location: $old_ssh_push_script"
    else
        print_success "SSH Push tool removed from old location"
    fi
    
    if [[ -f "$python_script" ]]; then
        print_warning "Python script still exists at: $python_script"
    else
        print_success "Python script removed"
    fi
    
    # Check if alias is still present
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [[ -f "$shell_rc" ]] && grep -q "alias ssh-push=" "$shell_rc"; then
        print_warning "SSH Push alias still exists in $shell_rc"
    else
        print_success "SSH Push alias removed from shell configuration"
    fi
    
    # Check if command is still accessible
    if command -v ssh-push &> /dev/null; then
        print_warning "ssh-push command is still accessible"
        print_status "You may need to restart your terminal or run: hash -r"
    else
        print_success "ssh-push command is no longer accessible"
    fi
}

# Function to show uninstallation summary
show_uninstallation_summary() {
    print_header "Uninstallation Summary"
    print_header "======================"
    
    print_success "SSH Push tool has been uninstalled"
    print_status "The following components were removed:"
    echo "  • SSH Push tool executable"
    echo "  • Python script"
    echo "  • Shell alias"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
    if [[ "$KEEP_BACKUPS" != "true" ]]; then
        echo "  • Backup files"
    fi
    
    echo "  • Temporary files"
    
    print_status ""
    print_status "If you want to reinstall SSH Push tool, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)"
    print_status ""
    print_status "To perform a complete cleanup, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh)"
    
    print_status ""
    print_status "Note: You may need to restart your terminal for all changes to take effect"
}

# Function to confirm uninstallation
confirm_uninstallation() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    print_header "SSH Push Tool Uninstallation"
    print_header "============================"
    
    echo "This will remove the SSH Push tool and all its components:"
    echo "  • SSH Push tool executable"
    echo "  • Python script"
    echo "  • Shell alias"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
    if [[ "$KEEP_BACKUPS" != "true" ]]; then
        echo "  • Backup files"
    fi
    
    echo "  • Temporary files"
    echo ""
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
}

# Parse command line arguments
FORCE=false
KEEP_CONFIG=false
KEEP_BACKUPS=false

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
        --keep-config)
            KEEP_CONFIG=true
            shift
            ;;
        --keep-backups)
            KEEP_BACKUPS=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main uninstallation function
main_uninstallation() {
    # Confirm uninstallation
    confirm_uninstallation
    
    # Remove SSH Push tool
    remove_ssh_push_tool
    
    # Remove SSH Push command alias
    remove_ssh_push_alias
    
    # Remove SSH configuration files
    remove_ssh_config_files
    
    # Remove backup files
    remove_backup_files
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Verify uninstallation
    verify_uninstallation
    
    # Show uninstallation summary
    show_uninstallation_summary
}

# Run main uninstallation
main_uninstallation 