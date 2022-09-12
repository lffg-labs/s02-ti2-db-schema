{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in let
      hooks = _: {
        postgres = ''
          set -euo pipefail

          export DBROOT="$(pwd)/.postgresql"
          export LOG_PATH="$DBROOT/log"

          export PGDATA="$DBROOT/data"
          export PGHOST="localhost"
          export PGPORT="5432"
          export PGUSER=$(whoami)
          export PGPASSWORD=postgres
          export PGDATABASE=local-postgres

          if [ ! -d "$DBROOT" ]; then
            echo "Creating fresh PostgreSQL directory..."
            mkdir -p "$DBROOT"
          fi
          if [ ! -d "$PGDATA" ]; then
            echo "Initializing PostgreSQL database..."
            pg_ctl initdb -D "$PGDATA" --silent -o '--no-locale'
          fi
          if [ ! -f "$DBROOT/.s.PGSQL.5432.lock" ]; then
            postgres -d 2 -D "$PGDATA" > "$DBROOT/db.log" 2>&1 < /dev/null &
            echo "ok"
          fi
        '';
      };
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          postgresql_14
        ];
        shellHook = with pkgs.lib;
          concatStrings (attrValues (hooks pkgs));
      };
    });
}
