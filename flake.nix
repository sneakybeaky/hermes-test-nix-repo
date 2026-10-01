{
  description = "A Nix-flake-based Go development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      goVersion = 26; # Change this to update the whole stack

      # All systems nixpkgs exposes to flakes by default (x86_64-darwin
      # was dropped in nixpkgs 26.11, so it is deliberately absent).
      supportedSystems = inputs.nixpkgs.lib.systems.flakeExposed;
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              # go (version is specified by overlay)
              go

              # goimports, godoc, etc.
              gotools

              # https://github.com/golangci/golangci-lint
              golangci-lint

              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
