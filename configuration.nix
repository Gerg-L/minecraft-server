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
    initrd.systemd.enable = true;
    enableContainers = false;
  };

  networking = {
    usePredictableInterfaceNames = false;
    hostName = "bitch-pooter";
    useNetworkd = false;
    useDHCP = false;
    firewall.enable = true;
  };

  systemd.network.networks.default = {
    name = "en*";
    DHCP = "yes";
    networkConfig.IPv6AcceptRA = true;
    linkConfig.RequiredForOnline = "routable";
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
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
      settings.PermitRootLogin = "no";
    };
    userborn.enable = true;
  };

  security.sudo.execWheelOnly = true;

  users.users = {
    root.hashedPassword = "!";
    sacc = {
      initialHashsedPassword = "";
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        #TODO: add isacc key
        #gerg-phone
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZKIp3iObuxEUPx1dsMiN3vyMaMQb0N1gKJY78TtRxd"
        #gerg-windows
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpYY2uw0OH1Re+3BkYFlxn0O/D8ryqByJB/ljefooNc"
        #gerg-desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWbwkFJmRBgyWyWU+w3ksZ+KuFw9uXJN3PwqqE7Z/i8"
      ];
    };
  };

  programs = {
    mtr.enable = true;
    command-not-found.enable = false;
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
  #TODO: gen kernelModules from nixos-generate-config

}
