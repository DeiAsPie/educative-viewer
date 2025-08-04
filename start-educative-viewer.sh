#!/bin/bash

# Educative Viewer Service Installer
# Installs and configures systemd service for auto-start on boot
# Uses rootless Podman with least privileges for maximum security

echo "=== Educative Viewer Service Installer (Rootless Podman) ==="

# Check prerequisites
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed or not in PATH"
    echo "Please install Podman first: https://podman.io/getting-started/installation"
    exit 1
fi

if ! command -v podman-compose &> /dev/null; then
    echo "Error: podman-compose is not installed or not in PATH"
    echo "Install with: pip install podman-compose"
    exit 1
fi

# Verify podman rootless configuration
echo "Checking Podman configuration..."
if ! podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null | grep -q true; then
    echo "Error: Podman rootless mode is not properly configured"
    echo "Please configure Podman for rootless operation:"
    echo "  1. Run: podman system migrate"
    echo "  2. Ensure /etc/subuid and /etc/subgid are configured"
    exit 1
fi

echo "✓ Podman rootless configuration verified"

current_user=$(whoami)
user_id=$(id -u)

# Verify user namespace support
if [ ! -f "/etc/subuid" ] || ! grep -q "^$current_user:" /etc/subuid; then
    echo "Warning: User namespace mapping may not be configured in /etc/subuid"
fi

echo "Installing user systemd service for user: $current_user (UID: $user_id)"
echo "Security features: User session service, rootless containers, no sudo required"

# Create user systemd directory if it doesn't exist
mkdir -p ~/.config/systemd/user

# Copy service file to user systemd directory
if cp educative-viewer.service ~/.config/systemd/user/; then
    echo "✓ Service file copied to ~/.config/systemd/user/"
else
    echo "✗ Failed to copy service file"
    exit 1
fi

# Reload user systemd daemon
if systemctl --user daemon-reload; then
    echo "✓ User systemd daemon reloaded"
else
    echo "✗ Failed to reload user systemd daemon"
    exit 1
fi

# Enable the service to start on boot (user session)
if systemctl --user enable educative-viewer.service; then
    echo "✓ Service enabled for auto-start on user login"
else
    echo "✗ Failed to enable service"
    exit 1
fi

# Enable lingering so the service starts even without user login
if loginctl enable-linger "$current_user" 2>/dev/null; then
    echo "✓ User lingering enabled (service starts on boot)"
else
    echo "⚠ Could not enable lingering (service will start on user login only)"
fi

# Start the service now
if systemctl --user start educative-viewer.service; then
    echo "✓ Service started successfully"
    
    # Verify the service is running
    sleep 2
    if systemctl --user is-active educative-viewer.service | grep -q "active"; then
        echo "✓ Service is running in user session with rootless Podman"
    fi
else
    echo "⚠ Service installed but failed to start"
    echo "Check logs with: systemctl --user status educative-viewer"
fi

echo ""
echo "=== Installation Complete! ==="
echo "The Educative Viewer service has been installed as a user service with maximum security:"
echo ""
echo "🔒 Security Features Enabled:"
echo "  • User systemd service (no sudo required for management)"
echo "  • Rootless Podman execution (no root privileges in containers)"
echo "  • User namespace isolation (PODMAN_USERNS=keep-id)"
echo "  • Service runs entirely in user session"
echo "  • No system-wide privileges required"
echo "  • Automatic cleanup on user logout (unless lingering enabled)"
echo ""
echo "🚀 Service Management Commands (no sudo needed):"
echo "  systemctl --user start educative-viewer     # Start the service"
echo "  systemctl --user stop educative-viewer      # Stop the service"
echo "  systemctl --user status educative-viewer    # Check service status"
echo "  systemctl --user restart educative-viewer   # Restart the service"
echo "  journalctl --user -u educative-viewer -f    # View live logs"
echo ""
echo "🌐 Application will be available at: http://localhost:5000/edu-viewer/"
echo "📝 The service will automatically start on user login (or boot if lingering enabled)."
