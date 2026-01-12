{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    nvim-flake.url = "github:Gerg-L/nvim-flake";
  };
  outputs = inputs: {
    nixosConfigurations.bitch-pooter = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        ./disko.nix
        ./nix.nix
        ./zsh.nix
        inputs.disko.nixosModules.default
      ];
    };
  };
}
