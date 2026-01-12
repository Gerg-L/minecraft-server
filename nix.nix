{
  lib,
  config,
  inputs,
  ...
}:
{
  nix = {
    channel.enable = false;
    registry = lib.pipe inputs [
      (lib.filterAttrs (_: lib.isType "flake"))
      (lib.mapAttrs (_: flake: { inherit flake; }))
      (x: x // { nixpkgs.flake = inputs.unstable; })
    ];
    nixPath = [ "/etc/nix/path" ];
    settings = {
      flake-registry = "";
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
        "no-url-literals"
        "pipe-operators"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "root" ];
      use-xdg-base-directories = true;
      auto-allocate-uids = true;
    };
  };

  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;
}
