{ lib, niriModule }:

# Niri compositor configuration
# Returns both system and home configurations
# Niri is a scrollable-tiling Wayland compositor
{
  enable ? true,
  
  # Display manager options
  displayManager ? "greetd",  # "greetd" or "sddm" or null for autologin
  
  # Basic system preferences
  useXWayland ? true,  # Enable XWayland for X11 app support
  
  # Home-manager user config options
  user ? null,  # Username for home-manager config
  
  # Niri-specific options
  niriPackage ? null,  # Use default from niri-flake or specify custom
}:

let
  hasUser = user != null;

in {
  # System-level configuration
  system = {
    # Enable niri in the system
    programs.niri = {
      enable = enable;
    } // lib.optionalAttrs (niriPackage != null) {
      package = niriPackage;
    };
    
    # XWayland support
    programs.xwayland.enable = useXWayland;
    
    # Essential Wayland/graphics packages
    environment.systemPackages = with lib; [
      # Basic Wayland tools will be added by niri-flake
      # Add any additional system-level packages here
    ];
    
    # Display manager configuration
    services = lib.optionalAttrs (displayManager == "greetd") {
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "niri-session";  # niri-flake provides this
            user = if hasUser then user else "greeter";
          };
        };
      };
    } // lib.optionalAttrs (displayManager == "sddm") {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    
    # Graphics and hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # For 32-bit applications
    };
    
    # Security and session management
    security.polkit.enable = true;
    security.rtkit.enable = true;  # Real-time scheduling for audio
    
    # XDG portal for desktop integration
    xdg.portal = {
      enable = true;
      extraPortals = [ ];  # niri-flake handles portals
      config.common.default = "*";
    };
    
    # DBus for desktop applications
    services.dbus.enable = true;
    
    # PipeWire for audio (recommended for Wayland)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
  
  # Home-manager configuration (per-user)
  home = lib.optionalAttrs hasUser {
    ${user} = {
      # Import niri home-manager module
      imports = [ niriModule ];
      
      # Enable niri for this user
      programs.niri = {
        enable = true;
        
        # Basic niri configuration
        # Users can extend this with their own config
        settings = {
          # Example basic config - users should customize
          input = {
            keyboard = {
              xkb = {
                layout = "us";
              };
            };
            
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };
          
          # Prefer dark theme
          prefer-no-csd = true;
          
          # Example keybindings (users should customize)
          binds = {
            # Mod is the Super/Windows key by default
            "Mod+Return".action.spawn = "alacritty";  # Terminal
            "Mod+D".action.spawn = "fuzzel";  # App launcher
            "Mod+Q".action.close-window = {};
            
            # Window management
            "Mod+Left".action.focus-column-left = {};
            "Mod+Right".action.focus-column-right = {};
            "Mod+Up".action.focus-window-up = {};
            "Mod+Down".action.focus-window-down = {};
            
            # Workspace switching
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
          };
          
          # Example layout settings
          layout = {
            gaps = 8;
            center-focused-column = "never";
          };
        };
      };
      
      # Recommended applications for niri
      # Users should add these to their system or home packages:
      # - Terminal: alacritty, kitty, foot, etc.
      # - Launcher: fuzzel, rofi-wayland, wofi, etc.
      # - Notifications: mako, dunst, etc.
      # - Status bar: waybar (or use niri's built-in bar)
      home.packages = [ ];
    };
  };
  
  # Metadata
  meta = {
    compositorEnabled = enable;
    displayManager = displayManager;
    xwaylandEnabled = useXWayland;
    configuredUser = user;
    postInstallInstructions = ''
      Niri Configuration:
      
      Basic niri setup is complete!
      
      Next steps:
      1. Install a terminal emulator:
         environment.systemPackages = [ pkgs.alacritty ];
      
      2. Install an app launcher:
         environment.systemPackages = [ pkgs.fuzzel ];
      
      3. Customize niri config in your home-manager:
         programs.niri.settings = { ... };
      
      4. Check niri documentation:
         https://github.com/YaLTeR/niri
      
      Default keybindings:
      - Mod+Return: Terminal (alacritty)
      - Mod+D: App launcher (fuzzel)
      - Mod+Q: Close window
      - Mod+Arrow: Navigate windows
      - Mod+1-4: Switch workspaces
      
      Note: Mod key is Super/Windows key
    '';
  };
}
