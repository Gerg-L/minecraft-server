{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    nvim-flake.url = "github:Gerg-L/nvim-flake";
    sops.url = "github:Mic92/sops-nix";
  };
  outputs = inputs: {
    nixosConfigurations.bitch-pooter = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./minecraft.nix
        ./minecraftModule.nix
        ./configuration.nix
        ./disko.nix
        ./nix.nix
        ./zsh.nix
        ./matrix.nix
        ./sops.nix
        inputs.disko.nixosModules.default
      ];
    };
  };
}
