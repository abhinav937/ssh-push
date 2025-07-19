#!/bin/bash

# SSH Push Tool Installation Script
# Cross-platform installation with professional UI and comprehensive error handling
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
print_update() { echo -e "${CYAN}[$(get_timestamp)] [UPDATE]${NC} $1"; }
print_header() { echo -e "${PURPLE}${BOLD}$1${NC}"; }

# Store original directory
ORIGINAL_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check for updates
check_for_updates() {
    print_status "Checking for updates..."
    
    local updates_found=false
    
    # Check for script self-updates (only when running via curl)
    if [[ -z "$SCRIPT_DIR" ]] || [[ "$SCRIPT_DIR" == "/tmp" ]]; then
        print_status "Checking for script updates..."
        local temp_script="/tmp/install_check.sh"
        local timestamp=$(date +%s)
        if curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$temp_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh?t=$timestamp" 2>/dev/null; then
            # Compare with current script (if we can determine it)
            local current_script=""
            if [[ -n "$BASH_SOURCE" ]] && [[ -f "$BASH_SOURCE" ]]; then
                current_script="$BASH_SOURCE"
            elif [[ -f "/tmp/install.sh" ]]; then
                current_script="/tmp/install.sh"
            fi
            
            if [[ -n "$current_script" ]] && [[ -f "$current_script" ]]; then
                if ! cmp -s "$temp_script" "$current_script"; then
                    print_status "Script update available"
                    updates_found=true
                    # Download the updated script
                    if cp "$temp_script" "$current_script" 2>/dev/null; then
                        chmod +x "$current_script"
                        print_success "Script updated to latest version"
                    else
                        print_warning "Could not update script automatically"
                    fi
                else
                    print_success "Script is up to date"
                fi
            else
                print_status "Could not determine current script location for comparison"
            fi
            rm -f "$temp_script"
        else
            print_warning "Could not check for script updates"
        fi
    fi
    
    # Check ssh-push tool updates
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    if [[ -f "$ssh_push_script" ]]; then
        local temp_script="/tmp/ssh_push_check"
        local timestamp=$(date +%s)
        if curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$temp_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push?t=$timestamp" 2>/dev/null; then
            if ! cmp -s "$temp_script" "$ssh_push_script"; then
                print_update "SSH Push tool update available"
                updates_found=true
            else
                print_success "SSH Push tool is up to date"
            fi
            rm -f "$temp_script"
        else
            print_warning "Could not check SSH Push tool updates"
        fi
    fi
    
    if [[ "$updates_found" == "true" ]]; then
        return 0  # Updates needed
    else
        return 1  # No updates needed
    fi
}

# Function to update all components
update_all_components() {
    print_status "Updating all components..."
    
    local updates_performed=false
    
    # Update ssh-push tool
    if update_ssh_push_tool; then
        updates_performed=true
    fi
    
    if [[ "$updates_performed" == "true" ]]; then
        print_success "All available updates completed"
        return 0
    else
        print_status "No updates were needed"
        return 1
    fi
}

# Function to update ssh-push tool
update_ssh_push_tool() {
    print_status "Updating SSH Push tool..."
    
    local ssh_push_script=""
    
    # Check if we're running from a git repository (local installation)
    if [[ -f "$SCRIPT_DIR/ssh-push" ]]; then
        ssh_push_script="$SCRIPT_DIR/ssh-push"
        print_status "Using local SSH Push tool from repository"
        return 0
    else
        # We're running via curl, so we need to download/update the tool
        ssh_push_script="$HOME/.local/bin/ssh-push"
        mkdir -p "$(dirname "$ssh_push_script")"
        
        local temp_script="/tmp/ssh_push_new"
        
        # Download latest version with cache-busting
        local timestamp=$(date +%s)
        if curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$temp_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push?t=$timestamp" 2>/dev/null; then
            # Check if files are different
            if [[ ! -f "$ssh_push_script" ]] || ! cmp -s "$temp_script" "$ssh_push_script"; then
                mv "$temp_script" "$ssh_push_script"
                chmod +x "$ssh_push_script"
                print_success "SSH Push tool updated to $ssh_push_script"
                return 0
            else
                rm "$temp_script"
                print_status "SSH Push tool is already up to date"
                return 1
            fi
        else
            print_error "Failed to download SSH Push tool update"
            rm -f "$temp_script"
            return 1
        fi
    fi
}

# Function to self-update the script
self_update_script() {
    # Only attempt self-update when running via curl (not from local repository)
    if [[ -z "$SCRIPT_DIR" ]] || [[ "$SCRIPT_DIR" == "/tmp" ]]; then
        print_status "Checking for script self-updates..."
        
        # Clear any local curl cache
        if command -v curl-config &> /dev/null; then
            local curl_cache_dir=$(curl-config --ca-path 2>/dev/null | sed 's|/ca-bundle.crt||')
            if [[ -n "$curl_cache_dir" ]] && [[ -d "$curl_cache_dir" ]]; then
                print_status "Clearing curl cache..."
                rm -rf "$curl_cache_dir"/* 2>/dev/null || true
            fi
        fi
        
        local temp_script="/tmp/install_self_update.sh"
        # Add cache-busting headers and timestamp to bypass caching
        local timestamp=$(date +%s)
        if [[ "${NO_CACHE:-false}" == "true" ]]; then
            print_status "Forcing cache bypass..."
        fi
        print_status "Downloading latest script version (timestamp: $timestamp)..."
        if curl -s -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" -o "$temp_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh?t=$timestamp" 2>/dev/null; then
            # Extract version numbers for comparison
            local current_version=""
            local latest_version=""
            
            if [[ -n "$BASH_SOURCE" ]] && [[ -f "$BASH_SOURCE" ]]; then
                current_version=$(grep -o "Version: [0-9.]*" "$BASH_SOURCE" | cut -d' ' -f2)
            fi
            latest_version=$(grep -o "Version: [0-9.]*" "$temp_script" | cut -d' ' -f2)
            
            print_status "Current version: ${current_version:-unknown}, Latest version: ${latest_version:-unknown}"
            
            # Try to determine the current script location
            local current_script=""
            if [[ -n "$BASH_SOURCE" ]] && [[ -f "$BASH_SOURCE" ]]; then
                current_script="$BASH_SOURCE"
            elif [[ -f "/tmp/install.sh" ]]; then
                current_script="/tmp/install.sh"
            fi
            
            if [[ -n "$current_script" ]] && [[ -f "$current_script" ]]; then
                if ! cmp -s "$temp_script" "$current_script"; then
                    print_status "Script update available (current: ${current_version:-unknown}, latest: ${latest_version:-latest}) - updating..."
                    if cp "$temp_script" "$current_script" 2>/dev/null; then
                        chmod +x "$current_script"
                        print_success "Script updated to version ${latest_version:-latest}"
                        # Re-execute the updated script
                        exec bash "$current_script" "$@"
                        exit 0
                    else
                        print_warning "Could not update script automatically"
                    fi
                else
                    print_success "Script is up to date (version: ${current_version:-unknown})"
                fi
            else
                print_status "Could not determine current script location for self-update"
            fi
            rm -f "$temp_script"
        else
            print_warning "Could not check for script self-updates"
        fi
    fi
}

# Function to setup ssh-push tool
setup_ssh_push_tool() {
    print_status "Setting up SSH Push tool..."
    
    # Check if ssh-push tool needs updating
    local ssh_push_updated=false
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    
    if [[ -f "$ssh_push_script" ]]; then
        local temp_script="/tmp/ssh_push_check"
        local timestamp=$(date +%s)
        if curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$temp_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push?t=$timestamp" 2>/dev/null; then
            if ! cmp -s "$temp_script" "$ssh_push_script"; then
                # Update ssh-push tool
                mv "$temp_script" "$ssh_push_script"
                chmod +x "$ssh_push_script"
                print_update "SSH Push tool updated successfully"
                ssh_push_updated=true
            else
                rm "$temp_script"
                print_success "SSH Push tool is up to date"
            fi
        else
            print_warning "Could not check SSH Push tool updates"
        fi
    else
        # First time installation
        update_ssh_push_tool
        ssh_push_updated=true
    fi
    
    # Determine shell configuration file
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    # Remove existing ssh-push alias if present
    if grep -q "alias ssh-push=" "$shell_rc" 2>/dev/null; then
        sed -i.bak '/# SSH Push Tool alias/d' "$shell_rc"
        sed -i.bak '/alias ssh-push=/d' "$shell_rc"
    fi
    
    # Add ssh-push alias - use the correct path based on installation method
    local ssh_push_script=""
    if [[ -f "$SCRIPT_DIR/ssh-push" ]]; then
        ssh_push_script="$SCRIPT_DIR/ssh-push"
    else
        ssh_push_script="$HOME/.local/bin/ssh-push"
    fi
    
    # Add the alias to shell configuration
    echo "" >> "$shell_rc"
    echo "# SSH Push Tool alias" >> "$shell_rc"
    echo "alias ssh-push='$ssh_push_script'" >> "$shell_rc"
    
    print_success "SSH Push tool alias added to $shell_rc"
    print_status "You can now use 'ssh-push' command from anywhere"
}

# Function to detect OS and architecture
detect_platform() {
    print_status "Detecting platform..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
      linux)
        case "$ARCH" in
          x86_64) PLATFORM="linux-x64" ;;
          aarch64) PLATFORM="linux-arm64" ;;
          riscv64) PLATFORM="linux-riscv64" ;;
          *) print_error "Unsupported architecture for Linux: $ARCH"; exit 1 ;;
        esac
        ;;
      darwin)
        case "$ARCH" in
          x86_64) PLATFORM="darwin-x64" ;;
          arm64) PLATFORM="darwin-arm64" ;;
          *) print_error "Unsupported architecture for macOS: $ARCH"; exit 1 ;;
        esac
        ;;
      freebsd)
        case "$ARCH" in
          amd64) PLATFORM="freebsd-x64" ;;
          *) print_error "Unsupported architecture for FreeBSD: $ARCH"; exit 1 ;;
        esac
        ;;
      mingw* | msys* | cygwin*)
        if [ "$ARCH" != "x86_64" ]; then
          print_error "Unsupported architecture for Windows: $ARCH"; exit 1
        fi
        PLATFORM="windows-x64"
        ;;
      *)
        print_error "Unsupported OS: $OS"; exit 1
        ;;
    esac
    
    print_success "Detected platform: $PLATFORM ($OS $ARCH)"
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed."
        print_status "Please install Python 3 and try again."
        exit 1
    fi
    
    # Check for SSH client
    if ! command -v ssh &> /dev/null; then
        print_error "SSH client is required but not installed."
        print_status "Please install OpenSSH client and try again."
        exit 1
    fi
    
    # Check for SCP
    if ! command -v scp &> /dev/null; then
        print_error "SCP is required but not installed."
        print_status "Please install OpenSSH client (includes SCP) and try again."
        exit 1
    fi
    
    print_success "Python 3 found: $(python3 --version)"
    print_success "SSH client found: $(ssh -V 2>&1)"
    print_success "SCP found: $(scp -V 2>&1 | head -n1)"
}

# Function to install ssh-push tool
install_ssh_push_tool() {
    print_status "Installing SSH Push tool..."
    
    # Create installation directory
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    # Copy ssh-push script
    local ssh_push_script="$install_dir/ssh-push"
    
    if [[ -f "$SCRIPT_DIR/ssh-push" ]]; then
        # Local installation
        cp "$SCRIPT_DIR/ssh-push" "$ssh_push_script"
        print_status "Using local ssh-push script"
    else
        # Remote installation
        local timestamp=$(date +%s)
        if curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$ssh_push_script" "https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push?t=$timestamp" 2>/dev/null; then
            print_status "Downloaded ssh-push script from repository"
        else
            print_error "Failed to download ssh-push script"
            exit 1
        fi
    fi
    
    # Make executable
    chmod +x "$ssh_push_script"
    print_success "SSH Push tool installed to $ssh_push_script"
    
    # Copy Python script if it exists
    if [[ -f "$SCRIPT_DIR/ssh_push.py" ]]; then
        cp "$SCRIPT_DIR/ssh_push.py" "$install_dir/"
        print_success "Python script copied to $install_dir/"
    fi
}

# Function to setup shell alias
setup_shell_alias() {
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
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    echo "" >> "$shell_rc"
    echo "# SSH Push Tool alias" >> "$shell_rc"
    echo "alias ssh-push='$ssh_push_script'" >> "$shell_rc"
    
    print_success "SSH Push alias added to $shell_rc"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local ssh_push_script="$HOME/.local/bin/ssh-push"
    
    if [[ -f "$ssh_push_script" ]]; then
        print_success "SSH Push tool file exists"
    else
        print_error "SSH Push tool file NOT found"
        exit 1
    fi
    
    if [[ -x "$ssh_push_script" ]]; then
        print_success "SSH Push tool is executable"
    else
        print_error "SSH Push tool is NOT executable"
        exit 1
    fi
    
    # Check if ~/.local/bin is in PATH
    if echo "$PATH" | grep -q "$HOME/.local/bin"; then
        print_success "$HOME/.local/bin is in PATH"
    else
        print_warning "$HOME/.local/bin is NOT in PATH"
        print_status "You may need to restart your terminal or run: source $shell_rc"
    fi
    
    # Test if command is accessible
    if command -v ssh-push &> /dev/null; then
        print_success "ssh-push command is accessible"
    else
        print_warning "ssh-push command is NOT accessible in current session"
        print_status "Try: source $shell_rc or restart your terminal"
    fi
}

# Function to show help
show_help() {
    echo "SSH Push Tool Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --update-only        Check for updates and update components"
    echo "  --force-update       Force update even if tools are available"
    echo "  --no-cache           Bypass caching for updates"
    echo "  --check-updates      Check for available updates"
    echo ""
    echo "Installation Options:"
    echo "  --local              Install from local repository (default)"
    echo "  --remote             Install from remote repository"
    echo ""
    echo "Examples:"
    echo "  $0                   # Full installation"
    echo "  $0 --update-only     # Update existing installation"
    echo "  $0 --check-updates   # Check for updates only"
    echo ""
    echo "Recommended one-line installation:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)"
}

# Main installation function
main_installation() {
    print_header "SSH Push Tool Installation"
    print_header "=========================="
    
    # Detect platform
    detect_platform
    
    # Check dependencies
    check_dependencies
    
    # Install ssh-push tool
    install_ssh_push_tool
    
    # Setup shell alias
    setup_shell_alias
    
    # Verify installation
    verify_installation
    
    print_header "Installation Complete!"
    print_success "SSH Push tool has been installed successfully"
    print_status "You can now use 'ssh-push' command from anywhere"
    print_status "To get started, run: ssh-push --help"
    print_status "To setup SSH configuration, run: ssh-push -s"
    print_status ""
    print_status "To uninstall later, run:"
    print_status "  bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)"
}

# Parse command line arguments
UPDATE_ONLY=false
FORCE_UPDATE=false
NO_CACHE=false
CHECK_UPDATES=false
LOCAL_INSTALL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --update-only)
            UPDATE_ONLY=true
            shift
            ;;
        --force-update)
            FORCE_UPDATE=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --check-updates)
            CHECK_UPDATES=true
            shift
            ;;
        --local)
            LOCAL_INSTALL=true
            shift
            ;;
        --remote)
            LOCAL_INSTALL=false
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
if [[ "$CHECK_UPDATES" == "true" ]]; then
    if check_for_updates; then
        print_status "Updates are available"
        exit 0
    else
        print_status "No updates available"
        exit 1
    fi
elif [[ "$UPDATE_ONLY" == "true" ]]; then
    if update_all_components; then
        print_success "Updates completed successfully"
    else
        print_status "No updates were needed"
    fi
else
    # Self-update check (only for remote installations)
    if [[ "$LOCAL_INSTALL" == "false" ]]; then
        self_update_script
    fi
    
    # Run main installation
    main_installation
fi 