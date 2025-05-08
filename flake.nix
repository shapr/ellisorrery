{
  description = "ellisorrery";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: 
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: function rec {
          inherit system;
          compilerVersion = "ghc966";
          pkgs = nixpkgs.legacyPackages.${system};
          hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
            overrides = hfinal: hprev: {
              ellisorrery = hfinal.callCabal2nix "ellisorrery" ./. {};
            };
          };
        });
    in
    {
      # nix fmt
      formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

      # nix develop
      devShell = forAllSystems ({hsPkgs, pkgs, ...}:
        hsPkgs.shellFor {
          # withHoogle = true;
          packages = p: [
            p.ellisorrery
          ];
          buildInputs = with pkgs;
            [
              # Haskell
              hsPkgs.haskell-language-server
              haskellPackages.cabal-install
              cabal2nix
              haskellPackages.ghcid
              haskellPackages.fourmolu
              haskellPackages.cabal-fmt
              # Postgres
              postgresql_16
            ]
            ++ (builtins.attrValues (import ./scripts.nix {s = pkgs.writeShellScriptBin;}));

          shellHook = ''
            export PGDATA="$PWD/.postgres"
            export PGHOST="$PGDATA"
            export PGPORT=5432

            # Only initialize when interactive, was running into problems with the LSP
            if [ -t 1 ]; then
              if [ ! -d "$PGDATA" ]; then
                echo "Initializing PostgreSQL database in $PGDATA..."
                initdb --auth=trust --no-locale --encoding=UTF8

                echo "Starting PostgreSQL to create initial db"
                pg_ctl start -o "-k $PGHOST"
                createdb ellisorrery
                pg_ctl stop
              fi

              echo "PostgreSQL is ready. Use 'pg_ctl start -o \"-k $PGHOST\"' to start it."
            fi
          '';
        });

      # nix build
      packages = forAllSystems ({hsPkgs, ...}: {
          ellisorrery = hsPkgs.ellisorrery;
          default = hsPkgs.ellisorrery;
      });

      # You can't build the ellisorrery package as a check because of IFD in cabal2nix
      checks = {};

      # nix run
      apps = forAllSystems ({system, ...}: {
        ellisorrery = { 
          type = "app"; 
          program = "${self.packages.${system}.ellisorrery}/bin/ellisorrery"; 
        };
        default = self.apps.${system}.ellisorrery;
      });
    };
}
