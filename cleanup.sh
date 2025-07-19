#!/bin/bash

# SSH Push Tool - Cleanup Script
# This script removes SSH Push tool installations and cleans up configuration files
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
    echo "SSH Push Tool Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --force, -f          Force cleanup without confirmation prompts"
    echo "  --keep-config        Keep SSH configuration files"
    echo "  --keep-backups       Keep backup files"
    echo ""
    echo "Examples:"
    echo "  $0                   # Interactive cleanup"
    echo "  $0 --force           # Force cleanup without prompts"
    echo "  $0 --keep-config     # Cleanup but keep SSH config"
    echo ""
    echo "Recommended one-line cleanup:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh)"
    echo ""
    echo "This script is useful for:"
    echo "  • Cloning the repository fresh"
    echo "  • Troubleshooting installation issues"
    echo "  • Ensuring a clean state before reinstalling"
}

# Function to remove SSH Push tool from all locations
remove_ssh_push_tool() {
    print_status "Removing SSH Push tool from all locations..."
    
    # List of possible installation locations
    local install_locations=(
        "$HOME/.local/bin/ssh-push"
        "$HOME/.local/bin/ssh_push.py"
        "/usr/local/bin/ssh-push"
        "/usr/bin/ssh-push"
        "./ssh-push"
    )
    
    local removed_count=0
    for location in "${install_locations[@]}"; do
        if [[ -f "$location" ]]; then
            print_status "Found SSH Push tool at: $location"
            if rm "$location" 2>/dev/null; then
                print_success "Removed: $location"
                ((removed_count++))
            else
                print_warning "Failed to remove: $location (may need sudo)"
                if sudo rm "$location" 2>/dev/null; then
                    print_success "Removed with sudo: $location"
                    ((removed_count++))
                else
                    print_error "Could not remove: $location"
                fi
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_warning "No SSH Push tool installations found"
    else
        print_success "Removed $removed_count SSH Push tool installation(s)"
    fi
    
    # Remove empty directories
    if [[ -d "$HOME/.local/bin" ]] && [[ -z "$(ls -A "$HOME/.local/bin")" ]]; then
        rmdir "$HOME/.local/bin"
        print_status "Removed empty ~/.local/bin directory"
    fi
}

# Function to remove SSH Push command alias
remove_ssh_push_alias() {
    print_status "Removing SSH Push command alias from shell configurations..."
    
    # List of shell configuration files
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.bash_login"
    )
    
    local cleaned_count=0
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            if grep -q "alias ssh-push=" "$config_file" 2>/dev/null; then
                print_status "Found SSH Push alias in: $config_file"
                
                # Create backup
                local backup_file="$config_file.backup.$(date +%Y%m%d_%H%M%S)"
                cp "$config_file" "$backup_file"
                
                # Remove alias lines
                sed -i '/# SSH Push Tool alias/d' "$config_file"
                sed -i '/alias ssh-push=/d' "$config_file"
                
                print_success "Cleaned: $config_file"
                print_status "Backup created: $backup_file"
                ((cleaned_count++))
            fi
        fi
    done
    
    if [[ $cleaned_count -eq 0 ]]; then
        print_warning "No SSH Push aliases found in shell configurations"
    else
        print_success "Cleaned $cleaned_count shell configuration file(s)"
    fi
}

# Function to remove SSH configuration files
remove_ssh_config_files() {
    if [[ "$KEEP_CONFIG" == "true" ]]; then
        print_status "Keeping SSH configuration files (--keep-config specified)"
        return 0
    fi
    
    print_status "Removing SSH configuration files..."
    
    # List of possible SSH configuration files
    local config_files=(
        ".ssh_push_config.json"
        "$HOME/.ssh_push_config.json"
        "ssh_push_config.json"
        "*.ssh_config.json"
    )
    
    local removed_count=0
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            if rm "$config_file"; then
                print_success "Removed SSH config: $config_file"
                ((removed_count++))
            else
                print_warning "Failed to remove SSH config: $config_file"
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_warning "No SSH configuration files found"
    else
        print_success "Removed $removed_count SSH configuration file(s)"
    fi
}

# Function to remove backup files
remove_backup_files() {
    if [[ "$KEEP_BACKUPS" == "true" ]]; then
        print_status "Keeping backup files (--keep-backups specified)"
        return 0
    fi
    
    print_status "Removing backup files..."
    
    # Remove backup files created during installation/uninstallation
    local backup_files=(
        "$HOME/.bashrc.backup."*
        "$HOME/.zshrc.backup."*
        "$HOME/.bash_profile.backup."*
        "$HOME/.profile.backup."*
        "*.backup"
        "*.backup."*
    )
    
    local removed_count=0
    for backup_file in "${backup_files[@]}"; do
        if [[ -f "$backup_file" ]]; then
            if rm "$backup_file"; then
                print_success "Removed backup: $backup_file"
                ((removed_count++))
            else
                print_warning "Failed to remove backup: $backup_file"
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "No backup files found to remove"
    else
        print_success "Removed $removed_count backup file(s)"
    fi
}

# Function to clean up temporary files
cleanup_temp_files() {
    print_status "Cleaning up temporary files..."
    
    # Remove temporary files created during installation
    local temp_files=(
        "/tmp/install_check.sh"
        "/tmp/ssh_push_check"
        "/tmp/ssh_push_new"
        "/tmp/install_self_update.sh"
        "ssh-push.tmp"
        "*.tmp"
        "*.temp"
    )
    
    local removed_count=0
    for temp_file in "${temp_files[@]}"; do
        if [[ -f "$temp_file" ]]; then
            if rm "$temp_file"; then
                print_success "Removed temp file: $temp_file"
                ((removed_count++))
            else
                print_warning "Failed to remove temp file: $temp_file"
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "No temporary files found to remove"
    else
        print_success "Removed $removed_count temporary file(s)"
    fi
}

# Function to clean up Python cache files
cleanup_python_cache() {
    print_status "Cleaning up Python cache files..."
    
    # Remove Python cache files
    local cache_items=(
        "__pycache__/"
        "*.pyc"
        "*.pyo"
        "*.pyd"
        ".Python"
        "*.egg-info/"
    )
    
    local removed_count=0
    for cache_item in "${cache_items[@]}"; do
        if [[ -e "$cache_item" ]]; then
            if rm -rf "$cache_item"; then
                print_success "Removed cache: $cache_item"
                ((removed_count++))
            else
                print_warning "Failed to remove cache: $cache_item"
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "No Python cache files found to remove"
    else
        print_success "Removed $removed_count Python cache item(s)"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if SSH Push tool is still present anywhere
    local remaining_locations=()
    
    if [[ -f "$HOME/.local/bin/ssh-push" ]]; then
        remaining_locations+=("$HOME/.local/bin/ssh-push")
    fi
    
    if [[ -f "/usr/local/bin/ssh-push" ]]; then
        remaining_locations+=("/usr/local/bin/ssh-push")
    fi
    
    if [[ -f "/usr/bin/ssh-push" ]]; then
        remaining_locations+=("/usr/bin/ssh-push")
    fi
    
    if command -v ssh-push &> /dev/null; then
        remaining_locations+=("$(which ssh-push)")
    fi
    
    if [[ ${#remaining_locations[@]} -eq 0 ]]; then
        print_success "SSH Push tool completely removed"
    else
        print_warning "SSH Push tool still found at:"
        for location in "${remaining_locations[@]}"; do
            echo "  • $location"
        done
    fi
    
    # Check if alias is still present
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
    local alias_found=false
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]] && grep -q "alias ssh-push=" "$config_file" 2>/dev/null; then
            print_warning "SSH Push alias still exists in: $config_file"
            alias_found=true
        fi
    done
    
    if [[ "$alias_found" == "false" ]]; then
        print_success "SSH Push aliases completely removed"
    fi
}

# Function to show cleanup summary
show_cleanup_summary() {
    print_header "Cleanup Summary"
    print_header "==============="
    
    print_success "SSH Push tool cleanup completed"
    print_status "The following components were cleaned:"
    echo "  • SSH Push tool installations"
    echo "  • Shell aliases"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
    if [[ "$KEEP_BACKUPS" != "true" ]]; then
        echo "  • Backup files"
    fi
    
    echo "  • Temporary files"
    echo "  • Python cache files"
    
    print_status ""
    print_status "You can now perform a fresh installation with:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)"
    print_status ""
    print_status "Or clone and install:"
    print_status "  git clone https://github.com/abhinav937/ssh-push.git && cd ssh-push && ./install.sh"
}

# Function to confirm cleanup
confirm_cleanup() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    print_header "SSH Push Tool Cleanup"
    print_header "===================="
    
    echo "This will remove all SSH Push tool installations and clean up:"
    echo "  • SSH Push tool executables"
    echo "  • Shell aliases"
    
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  • SSH configuration files"
    fi
    
    if [[ "$KEEP_BACKUPS" != "true" ]]; then
        echo "  • Backup files"
    fi
    
    echo "  • Temporary files"
    echo "  • Python cache files"
    echo ""
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
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

# Main cleanup function
main_cleanup() {
    # Confirm cleanup
    confirm_cleanup
    
    # Remove SSH Push tool from all locations
    remove_ssh_push_tool
    
    # Remove SSH Push command alias
    remove_ssh_push_alias
    
    # Remove SSH configuration files
    remove_ssh_config_files
    
    # Remove backup files
    remove_backup_files
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Clean up Python cache files
    cleanup_python_cache
    
    # Verify cleanup
    verify_cleanup
    
    # Show cleanup summary
    show_cleanup_summary
}

# Run main cleanup
main_cleanup 