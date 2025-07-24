# SSH Push Tool

A simple, self-contained tool for pushing files to remote devices via SSH with a streamlined workflow.

## Features

- **Self-contained**: Single Python script with no external dependencies
- **Cross-platform**: Works on Linux, macOS, FreeBSD, and Windows (WSL)
- **Simple installation**: One-line curl installation
- **Easy configuration**: Interactive setup process
- **Project-specific**: Different SSH settings for different projects
- **No dependencies**: Only requires Python 3 and SSH client
- **Unified management**: Single script handles install, update, and uninstall
- **Bulk operations**: Push all files with `--all` option
- **Speed testing**: Test file transfer performance with `--speed-test`
- **Robust error handling**: Enhanced validation and error recovery

## Quick Installation

### One-Line Installation (Recommended)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install
```

### Alternative: Clone and Install
```bash
git clone https://github.com/abhinav937/ssh-push.git
cd ssh-push
./ssh-push-manager.sh install
```

## Quick Update

### One-Line Update
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) update
```

## Quick Uninstallation

### One-Line Uninstallation
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall
```

### Force Uninstallation (no prompts)
```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall --force
```

## Unified Management Script

The `ssh-push-manager.sh` script provides all management operations:

```bash
# Install
ssh-push-manager.sh install

# Update
ssh-push-manager.sh update

# Uninstall
ssh-push-manager.sh uninstall

# Check status
ssh-push-manager.sh status

# Show help
ssh-push-manager.sh help
```

### One-Line Commands

```bash
# Install
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install

# Update
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) update

# Uninstall
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall

# Check status
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) status
```

## What Gets Installed

- **Single executable**: Self-contained Python script in `~/.local/bin/ssh-push`
- **Shell alias**: `ssh-push` command added to your shell configuration
- **No external files**: Everything is contained in one script

## Usage

After installation, you can use the SSH Push tool from anywhere:

```bash
# Setup SSH configuration
ssh-push --setup

# Test SSH connection
ssh-push --test

# Test file transfer speed
ssh-push --speed-test

# Push files
ssh-push file1.v file2.v

# Push all files in current directory
ssh-push --all

# List remote files
ssh-push --list

# Show help
ssh-push --help
```

## Quick Start

1. **Setup SSH Configuration:**
   ```bash
   ssh-push --setup
   ```
   This will prompt you for:
   - Remote hostname/IP (e.g., `pi@192.168.1.100`)
   - SSH port (default: 22)
   - Remote working directory (default: `~/fpga_work`)
   - Authentication method (SSH key or password)
   - SSH key path (if using key authentication)

2. **Test Connection:**
   ```bash
   ssh-push --test
   ```

3. **Push Files:**
   ```bash
   # Push specific files
   ssh-push file1.v file2.v icesugar_nano.pcf
   
   # Push all files in current directory
   ssh-push --all
   ```

4. **Test File Transfer Speed:**
   ```bash
   ssh-push --speed-test
   ```

5. **List Remote Files:**
   ```bash
   ssh-push --list
   ```

## Usage Examples

```bash
# Setup configuration
ssh-push --setup

# Edit existing configuration
ssh-push --edit

# Push single file
ssh-push blinky.v

# Push multiple files
ssh-push top.v clock.v icesugar_nano.pcf

# Push all non-hidden files in current directory
ssh-push --all

# Push with verbose output
ssh-push --verbose top.v

# List files on remote
ssh-push --list

# Show current configuration
ssh-push --config

# Test SSH connection
ssh-push --test

# Test file transfer speed
ssh-push --speed-test

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
ssh-push --setup  # Configure for project A
ssh-push file1.v file2.v

# In project B directory  
ssh-push --setup  # Configure for project B
ssh-push file3.v file4.v
```

### Bulk File Operations
```bash
# Push all non-hidden files in current directory
ssh-push --all

# Push all files with verbose output
ssh-push --all --verbose
```

### Verbose Output
```bash
# See detailed transfer information
ssh-push --verbose file.v
```

### Configuration Management
```bash
# Show current configuration
ssh-push --config

# Edit configuration
ssh-push --edit

# Test current configuration
ssh-push --test
```

### Speed Testing
```bash
# Test file transfer speed with 10MB test file
ssh-push --speed-test

# Test file transfer speed (short flag)
ssh-push -st
```

The speed test feature:
- Creates a temporary test file with random data
- Transfers it to the remote host using your SSH configuration
- Measures and displays transfer speed in MB/s and Mbps
- Automatically cleans up test files
- Helps diagnose network performance issues

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

2. **Check installation status:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) status
   ```

3. **Reinstall if needed:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install
   ```

4. **Check shell configuration:**
   ```bash
   grep "ssh-push" ~/.bashrc
   ```

## Uninstallation

### One-Line Uninstallation (Recommended)
```bash
# With confirmation prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall

# Force removal without prompts
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall --force

# Remove tool but keep configuration
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall --keep-config
```

### Manual Uninstallation
```bash
# Remove everything (with confirmation)
./ssh-push-manager.sh uninstall

# Remove everything without confirmation
./ssh-push-manager.sh uninstall --force

# Remove tool but keep configuration
./ssh-push-manager.sh uninstall --keep-config
```

### Uninstallation Options

- **Interactive**: `./ssh-push-manager.sh uninstall` (asks for confirmation)
- **Force**: `./ssh-push-manager.sh uninstall --force` (no prompts)
- **Keep Config**: `./ssh-push-manager.sh uninstall --keep-config` (keep SSH configuration)

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

## Version History

### Version 3.2.0 (Current)
- **New Feature**: Added `--speed-test` and `-st` options for file transfer speed testing
- **Speed Testing**: Creates test files and measures transfer performance
- **Enhanced Diagnostics**: Helps identify network performance issues
- **Automatic Cleanup**: Removes test files after speed testing
- **Short Flag Support**: Added `-st` as shorthand for `--speed-test`

### Version 3.1.0
- **New Feature**: Added `--all` option to push all non-hidden files
- **Enhanced Error Handling**: Better validation and error recovery
- **Improved Installation**: Fixed alias corruption issues
- **Repository Cleanup**: Removed obsolete files for cleaner maintenance
- **Better Robustness**: Added path validation and executable verification

### Version 3.0.1
- **Unified Management**: Single script handles install, update, and uninstall
- **Self-contained Design**: Complete Python tool embedded in manager script
- **Cross-platform Support**: Works on Linux, macOS, FreeBSD, and Windows (WSL)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This tool is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This tool was inspired by the need for a simple, reliable way to push files to remote development devices, particularly for FPGA development workflows. 