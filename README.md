# cia-unix

I needed a working binary copy of
[cia-unix](https://github.com/shijimasoft/cia-unix) project, so I made it here.
Feel free to use.

# Usage with nix flakes

Add this to flake.nix:
```nix
inputs = {
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
