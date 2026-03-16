{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        consoleMode = "max";
        editor = false;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
      ];
    };
    enableContainers = false;
  };

  networking = {
    hostName = "bitch-pooter";
    useNetworkd = false;
    useDHCP = false;
    firewall.enable = true;
  };

  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.Name = "enp2s0";
      DHCP = "no";
      address = [ "192.168.0.50/24" ];
      gateway = [ "192.168.0.1" ];
      dns = [ "192.168.0.1" ];
      networkConfig.IPv6AcceptRA = true;
      linkConfig.RequiredForOnline = "routable";
    };
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xautolock.enable = false;
      excludePackages = [ pkgs.xterm ];
      desktopManager = {
        xterm.enable = false;
        xfce = {
          enable = true;
          enableScreensaver = true;
        };
      };
      displayManager.lightdm = {
        enable = true;
        greeters.gtk.enable = true;
      };
    };

    displayManager.defaultSession = "xfce";

    libinput = {
      enable = true;
      mouse.accelProfile = "flat";
    };
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    openssh = {
      enable = true;
      hostKeys = lib.mkForce [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      openFirewall = true;
      ports = [22 1007];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    userborn.enable = true;
  };

  security.sudo.execWheelOnly = true;

  users.users = {
    root.hashedPassword = "!";
    sacc = {
      initialHashedPassword = "";
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        #isaac windows
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK13mhFwVohh8CGMMmwWYUc8PHoryxPJNbiLEuxo5x5L"
        #gerg-phone
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZKIp3iObuxEUPx1dsMiN3vyMaMQb0N1gKJY78TtRxd"
        #gerg-windows
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpYY2uw0OH1Re+3BkYFlxn0O/D8ryqByJB/ljefooNc"
        #gerg-desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWbwkFJmRBgyWyWU+w3ksZ+KuFw9uXJN3PwqqE7Z/i8"
        #media-laptop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECXkK6pIIUFRY2igF1NyuVBVy4/2Izoy9eWhVih8O/8"
      ];
    };
  };

  programs = {
    mtr.enable = true;
    command-not-found.enable = false;
    git.enable = true;
  };

  documentation = {
    info.enable = false;
    nixos.enable = false;
  };

  environment = {
    systemPackages = [
      pkgs.bottom
      pkgs.efibootmgr
      pkgs.pciutils
      pkgs.nix-janitor
      pkgs.fzf
      pkgs.ripgrep
      inputs.nvim-flake.packages.${pkgs.stdenv.system}.default
    ];
    defaultPackages = lib.mkForce [ ];
  };
  system = {
    disableInstallerTools = true;
    tools.nixos-rebuild.enable = true;
    stateVersion = "26.05";
  };
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };
}
