# SSH Push Tool

A simple tool for pushing files to remote devices via SSH.

## Features

- Self-contained Python script
- Works on Linux, macOS, FreeBSD, and Windows (WSL)
- One-line installation
- Interactive setup
- Project-specific SSH settings
- No external dependencies
- Bulk file operations
- Speed testing
- Automatic SSH key setup

## Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install
```

## Update

```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) update
```

## Uninstall

```bash
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) uninstall
```

## Quick Start

1. **Setup configuration:**
   ```bash
   ssh-push --setup
   ```

2. **Test connection:**
   ```bash
   ssh-push --test
   ```

3. **Push files:**
   ```bash
   ssh-push file1.v file2.v
   ssh-push --all  # Push all files
   ```

## Usage Examples

```bash
# Setup SSH configuration
ssh-push --setup

# Edit configuration
ssh-push --edit

# Push files
ssh-push file1.v file2.v

# Push all files
ssh-push --all

# List remote files
ssh-push --list

# Test connection
ssh-push --test

# Test speed
ssh-push --speed-test

# Show configuration
ssh-push --config
```

## Configuration

The tool stores configuration in `.ssh_push_config.json`:

```json
{
  "hostname": "pi@192.168.1.100",
  "port": 22,
  "remote_dir": "~/fpga_work",
  "auth_method": "key",
  "key_path": "~/.ssh/id_rsa"
}
```

## SSH Key Setup

### Automatic Setup
The tool can automatically set up SSH keys during configuration:

```bash
ssh-push --setup
```

When you choose key authentication, it will:
1. Check for existing SSH keys
2. Generate new key if needed
3. Copy key to remote machine
4. Set up passwordless authentication

### Manual Setup
```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id pi@192.168.1.100
```

## Troubleshooting

### SSH Connection Issues
```bash
# Check SSH service
sudo systemctl status ssh

# Test basic connection
ssh pi@192.168.1.100
```

### Permission Issues
```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Installation Issues
```bash
# Check installation
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) status

# Reinstall if needed
bash <(curl -s https://raw.githubusercontent.com/abhinav937/ssh-push/main/ssh-push-manager.sh) install
```

## Version History

### Version 3.3.3
- Fixed redundant "Generating" messages during SSH key setup
- Cleaner user feedback during key generation process

### Version 3.3.2
- Fixed SSH key generation to handle existing keys properly
- Improved text messages and user feedback
- Streamlined SSH key setup process

### Version 3.3.1
- Fixed SSH key copying to allow password input
- Improved interactive SSH key setup process

### Version 3.3.0
- Automatic SSH key setup
- Passwordless authentication
- Smart key management

### Version 3.2.0
- Speed testing feature
- File transfer performance measurement

### Version 3.1.0
- Bulk file operations
- Enhanced error handling

## License

MIT License 