#!/bin/bash

# SSH Push Tool - Simple Uninstall Script
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
    echo "SSH Push Tool - Simple Uninstall"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --force, -f    Force uninstallation without prompts"
    echo "  --keep-config  Keep SSH configuration files"
    echo ""
    echo "Examples:"
    echo "  $0             # Interactive uninstallation"
    echo "  $0 --force     # Force uninstallation"
    echo "  $0 --keep-config # Remove tool but keep SSH config"
    echo ""
    echo "One-line uninstallation:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)"
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

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    local script_path="$HOME/.local/bin/ssh-push"
    
    # Check if SSH Push tool is still present
    if [[ -f "$script_path" ]]; then
        print_warning "SSH Push tool still exists at: $script_path"
    else
        print_success "SSH Push tool removed"
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
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)"
    echo ""
    print_status "Note: You may need to restart your terminal for all changes to take effect"
}

# Function to confirm uninstallation
confirm_uninstallation() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo "SSH Push Tool Uninstallation"
    echo "============================"
    
    echo "This will remove the SSH Push tool and all its components:"
    echo "  • SSH Push tool executable"
    echo "  • Shell alias"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
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
    
    # Remove shell alias
    remove_shell_alias
    
    # Remove SSH configuration files
    remove_ssh_config_files
    
    # Verify uninstallation
    verify_uninstallation
    
    # Show uninstallation summary
    show_uninstallation_summary
}

# Run main uninstallation
main_uninstallation 