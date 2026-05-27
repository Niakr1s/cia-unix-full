# cia-unix

I needed a working binary copy of
[cia-unix](https://github.com/shijimasoft/cia-unix) project, so I made it here.
Feel free to use.

# Usage with nix flakes

Add this to flake.nix:
```nix
inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mysecrets = {
      url = "git+ssh://git@github.com/Niakr1s/secrets.git?ref=main&shallow=1";
      # url = "git@github.com:Niakr1s/secrets.git";
      flake = false;
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    cia-unix = {
      url = "github:Niakr1s/cia-unix-full";
    };
};
```

And somwhere in configuration.nix:
```nix
environment.systemPackages = [
    inputs.cia-unix.packages.${pkgs.system}.default
];
```
