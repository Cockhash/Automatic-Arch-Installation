#!/usr/bin/env sh

echo "--------------------------------------"
echo "--   Install additional packages    --"
echo "--------------------------------------"

PKGS=(
    # --- XORG Display Rendering
        'xorg'                      # Base Package
        'xorg-drivers'              # Display Drivers 
        'xorg-server'               # XOrg server
        'xorg-xinit'                # XOrg init
        'xorg-xinput'               # Xorg xinput
        'mesa'                      # Open source version of OpenGL
        
    # --- Setup Desktop
        'plasma-meta'               # Desktop Environment
        'xdg-user-dirs'             # KDE Applications
        'sddm'                      # Login Display Manager
        'packagekit-qt5'            # Discover Back-end for standard arch repos
        
    # --- Networking Setup
        'wpa_supplicant'            # Key negotiation for WPA wireless networks
        'dialog'                    # Enables shell scripts to trigger dialog boxex
        'openvpn'                   # Open VPN support
        'networkmanager-openvpn'    # Open VPN plugin for NM
        'network-manager-applet'    # System tray icon/utility for network connectivity
    
    # --- Audio
        'alsa-utils'            # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
        'alsa-plugins'          # ALSA plugins
        'pulseaudio'            # Pulse Audio sound components
        'pulseaudio-alsa'       # ALSA configuration for pulse audio
        'pavucontrol'           # Pulse Audio volume control
        'pnmixer'               # System tray volume control
        
    # --- Bluetooth
        'bluez'                 # Daemons for the bluetooth protocol stack
        'bluez-utils'           # Bluetooth development and debugging utilities
        'bluez-firmware'        # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
        'blueberry'             # Bluetooth configuration tool
        'pulseaudio-bluetooth'  # Bluetooth support for PulseAudio
    
    # --- Printers
        'cups'                  # Open source printer drivers
        'cups-pdf'              # PDF support for cups
        'ghostscript'           # PostScript interpreter
        'gsfonts'               # Adobe Postscript replacement fonts
        'hplip'                 # HP Drivers
        'system-config-printer' # Printer setup  utility
            
    # TERMINAL UTILITIES --------------------------------------------------
        'zsh'                   # Zsh-Shell
        'bleachbit'             # File deletion utility
        'cronie'                # cron jobs
        'curl'                  # Remote content retrieval
        'wget'                  # Remote content retrieval
        'gtop'                  # System monitoring via terminal
        'htop'                  # Process viewer
        'hardinfo'              # Hardware info app
        'neofetch'              # Shows system info when you launch terminal
        'ntp'                   # Network Time Protocol to set time via network.
        'numlockx'              # Turns on numlock in X11
        'openssh'               # SSH connectivity tools
        'p7zip'                 # 7z compression program
        'rsync'                 # Remote file sync utility
        'speedtest-cli'         # Internet speed via terminal
        'terminus-font'         # Font package with some bigger fonts for login terminal
        'tlp'                   # Advanced laptop power management
        'unrar'                 # RAR compression program
        'unzip'                 # Zip compression program
        'zip'                   # Zip compression program
        'terminator'            # Terminal emulator
        'vim'                   # Terminal Editor
        'zenity'                # Display graphical dialog boxes via shell scripts
        
    # DISK UTILITIES ------------------------------------------------------
        'android-tools'         # ADB for Android
        'android-file-transfer' # Android File Transfer
        'autofs'                # Auto-mounter
        'btrfs-progs'           # BTRFS Support
        'dosfstools'            # DOS Support
        'exfat-utils'           # Mount exFat drives
        'gparted'               # Disk utility
        'gvfs-mtp'              # Read MTP Connected Systems
        'gvfs-smb'              # More File System Stuff
        'ntfs-3g'               # Open source implementation of NTFS file system
        'parted'                # Disk utility
        'samba'                 # Samba File Sharing
        'smartmontools'         # Disk Monitoring
        'smbclient'             # SMB Connection 
        'xfsprogs'              # XFS Support
        
    # GENERAL UTILITIES ---------------------------------------------------
        'freerdp'               # RDP Connections
        'libvncserver'          # VNC Connections
        'remmina'               # Remote Connection
        'veracrypt'             # Disc encryption utility
        'keepassxc'             # Password Manager
        
    # DEVELOPMENT ---------------------------------------------------------
        'clang'                 # C Lang compiler
        'cmake'                 # Cross-platform open-source make system
        'code'                  # Visual Studio Code
        'electron'              # Cross-platform development using Javascript
        'git'                   # Version control system
        'gcc'                   # C/C++ compiler
        'glibc'                 # C libraries
        'meld'                  # File/directory comparison
        'nodejs'                # Javascript runtime environment
        'npm'                   # Node package manager
        'python'                # Scripting language
        'yarn'                  # Dependency management (Hyper needs this)
        'atom'                  # Code Editor
        'go'                    # Import programming language
        
    # MEDIA ---------------------------------------------------------------
        'obs-studio'            # Record your screen
        'vnc'                   # Video player
        
    # GRAPHICS AND DESIGN -------------------------------------------------
        'gimp'                  # GNU Image Manipulation Program
        
    # Browser --------------------------------------------------------------
        'firefox'               # Browser
        'chromium'              # Alternative Browser
        'torbrowser-launcher'   # Onion Routing, Tor
        
    # COMMUNICATION--------------------------------------------------------
        'thunderbird'           # Mail Client
        'element-desktop'       # Matrix Client for Communication
        
    # OTHERS --------------------------------------------------------------
    
        'timeshift'             # Backup programm  
        'libreoffice'           # Office Suite
        'filezilla'             # SSH File Transfer
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    pacman -S ${PKG} --noconfirm --needed
done
