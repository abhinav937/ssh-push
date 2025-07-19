# SSH Push Tool

A professional tool for pushing files to remote devices via SSH with a streamlined workflow and comprehensive error handling.

## Features

- **One-Command Push**: Push files to remote devices with a single command
- **Cross-Platform Support**: Works on Linux, macOS, FreeBSD, and Windows (WSL)
- **Flexible Configuration**: Support for custom SSH settings and authentication methods
- **Easy Installation**: Multiple installation options including one-line curl installation
- **Automatic Environment Management**: Tool automatically handles SSH configuration
- **Smart Connection Detection**: Automatic SSH connection testing with clear feedback
- **Intelligent Error Handling**: User-friendly error messages and helpful suggestions
- **Project-Specific Configuration**: Different SSH settings for different projects

## Quick Installation

### One-Line Installation (Recommended)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)
```

### Alternative: Clone and Install
```bash
git clone https://github.com/abhinav937/ssh-push.git
cd ssh-push
./install.sh
```

## Quick Uninstallation

### One-Line Uninstallation (with confirmation prompts)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)
```

### One-Line Uninstallation (force removal, no prompts)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh) -- --force
```

## Quick Cleanup

### One-Line Cleanup (with confirmation prompts)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh)
```

### One-Line Cleanup (force cleanup, no prompts)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh) -- --force
```

## Installation Options

- **Full Installation**: `./install.sh` (installs SSH Push tool and sets up shell alias)
- **Update Only**: `./install.sh --update-only` (checks for updates and updates tool)
- **Force Update**: `./install.sh --force-update` (forces update even if tool is available)
- **No Cache**: `./install.sh --no-cache` (bypasses caching for updates)
- **Check Updates**: `./install.sh --check-updates` (check for available updates only)

## What Gets Installed

- **SSH Push Tool**: `ssh-push` script installed to `~/.local/bin/ssh-push`
- **Python Script**: `ssh_push.py` installed to `~/.local/bin/ssh_push.py`
- **Shell Alias**: `ssh-push` command added to your shell configuration
- **Configuration Management**: Local project-specific SSH configuration

## Environment Setup

The installation script installs the SSH Push tool to `~/.local/bin/` and adds it to your PATH via shell alias. This gives you full control over when the tool is available.

### Manual Environment Sourcing
If you need to use the tool in a new terminal session without restarting:
```bash
source ~/.bashrc  # or ~/.zshrc for zsh users
```

### Automatic Environment Sourcing
The `ssh-push` command is automatically available in new terminal sessions after installation.

## Usage

After installation, you can use the SSH Push tool from anywhere:

```bash
# Basic usage
ssh-push file1.v file2.v

# With verbose output
ssh-push file1.v --verbose

# Setup SSH configuration
ssh-push -s

# Test SSH connection
ssh-push -t

# List remote files
ssh-push -l

# Show help
ssh-push --help
```

## Quick Start

1. **Setup SSH Configuration:**
   ```bash
   ssh-push -s
   ```
   This will prompt you for:
   - Remote hostname/IP (e.g., `pi@192.168.1.100`)
   - SSH port (default: 22)
   - Remote working directory (default: `~/fpga_work`)
   - Authentication method (SSH key or password)
   - SSH key path (if using key authentication)

2. **Test Connection:**
   ```bash
   ssh-push -t
   ```

3. **Push Files:**
   ```bash
   ssh-push file1.v file2.v icesugar_nano.pcf
   ```

4. **List Remote Files:**
   ```bash
   ssh-push -l
   ```

## Usage Examples

```bash
# Setup configuration
ssh-push -s                    # or ssh-push --setup

# Edit existing configuration
ssh-push -e                    # or ssh-push --edit

# Push single file
ssh-push blinky.v

# Push multiple files
ssh-push top.v clock.v icesugar_nano.pcf

# Push with verbose output
ssh-push top.v -v              # or ssh-push top.v --verbose

# List files on remote
ssh-push -l                    # or ssh-push --list

# Show current configuration
ssh-push -c                    # or ssh-push --config

# Test SSH connection
ssh-push -t                    # or ssh-push --test
```

## Configuration

The tool stores configuration in `.ssh_push_config.json` in the current directory:

```json
{
  "hostname": "pi@192.168.1.100",
  "port": 22,
  "remote_dir": "~/fpga_work",
  "auth_method": "key",
  "key_path": "~/.ssh/id_rsa"
}
```

**Benefits of local configuration:**
- Different SSH settings for different projects
- Configuration stays with the project
- Easy to share project-specific settings
- No conflicts between different projects

## SSH Key Setup

For secure authentication, set up SSH keys:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096
   ```

2. **Copy public key to remote device:**
   ```bash
   ssh-copy-id pi@192.168.1.100
   ```

3. **Test key authentication:**
   ```bash
   ssh pi@192.168.1.100
   ```

## Advanced Usage

### Project-Specific Configuration
```bash
# In project A directory
ssh-push -s  # Configure for project A
ssh-push file1.v file2.v

# In project B directory  
ssh-push -s  # Configure for project B
ssh-push file3.v file4.v
```

### Verbose Output
```bash
# See detailed transfer information
ssh-push file.v --verbose
```

### Configuration Management
```bash
# Show current configuration
ssh-push -c

# Edit configuration
ssh-push -e

# Test current configuration
ssh-push -t
```

## Troubleshooting

### SSH Connection Issues

1. **Check SSH service** on remote device:
   ```bash
   sudo systemctl status ssh
   ```

2. **Test basic SSH connection:**
   ```bash
   ssh pi@192.168.1.100
   ```

3. **Check firewall settings** on both local and remote devices

### Permission Issues

1. **Check SSH key permissions:**
   ```bash
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   ```

2. **Check remote directory permissions:**
   ```bash
   ssh pi@192.168.1.100 "ls -la ~/fpga_work"
   ```

### File Transfer Issues

1. **Check disk space** on remote device:
   ```bash
   ssh pi@192.168.1.100 "df -h"
   ```

2. **Check file permissions** on source files:
   ```bash
   ls -la file1.v file2.v
   ```

### Installation Issues

1. **Check if tool is installed:**
   ```bash
   which ssh-push
   ```

2. **Reinstall if needed:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/install.sh)
   ```

3. **Check shell configuration:**
   ```bash
   grep "ssh-push" ~/.bashrc
   ```

## Uninstallation

### One-Line Uninstallation (Recommended)
```bash
# With confirmation prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh)

# Force removal without prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/uninstall.sh) -- --force
```

### Manual Uninstallation
```bash
# Remove everything (with confirmation)
./uninstall.sh

# Remove everything without confirmation
./uninstall.sh --force

# Remove tool but keep configuration
./uninstall.sh --keep-config
```

### Uninstallation Options

- **Interactive**: `./uninstall.sh` (asks for confirmation)
- **Force**: `./uninstall.sh --force` (no prompts)
- **Keep Config**: `./uninstall.sh --keep-config` (keep SSH configuration)
- **Keep Backups**: `./uninstall.sh --keep-backups` (keep backup files)

## Cleanup

### One-Line Cleanup (Recommended)
```bash
# With confirmation prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh)

# Force cleanup without prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/cleanup.sh) -- --force
```

### Manual Cleanup
```bash
# Interactive cleanup
./cleanup.sh

# Force cleanup without prompts
./cleanup.sh --force

# Cleanup but keep SSH config
./cleanup.sh --keep-config
```

### Cleanup Options

- **Interactive**: `./cleanup.sh` (asks for confirmation)
- **Force**: `./cleanup.sh --force` (no prompts)
- **Keep Config**: `./cleanup.sh --keep-config` (keep SSH configuration)
- **Keep Backups**: `./cleanup.sh --keep-backups` (keep backup files)

## Platform Support

### Supported Platforms
- Linux (x86_64, ARM64, RISC-V64)
- macOS (x86_64, ARM64)
- FreeBSD (x86_64)
- Windows (WSL, x86_64)

### Dependencies
- Python 3
- OpenSSH client (ssh, scp)
- curl (for installation)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This tool is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This tool was inspired by the need for a simple, reliable way to push files to remote development devices, particularly for FPGA development workflows. 