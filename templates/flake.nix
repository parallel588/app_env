{
  description = "Basic Elixir dev environment with Forgejo repo init";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    setupScript = pkgs.writeShellScriptBin "init" ''
    #!/usr/bin/env bash
    set -euo pipefail

    export ASDF_DIR=""
    export PATH="${pkgs.elixir}/bin:${pkgs.erlang}/bin:$PATH"
    export MIX_ENV=dev

    PROJECT_DIR=''${1:-$(pwd)}
    cd "$PROJECT_DIR"

    echo "Installing Phoenix generator..."
    mix archive.install hex phx_new 

    mix archive.install hex igniter_new

  '';      
      
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [ git curl jq erlang elixir ];
      shellHook = ''
        echo "Welcome to your Nix dev shell!"
      '';
    };

    apps.${system} = {
      setup_app = {
        type = "app";
        program = "${setupScript}/bin/init";
      };
    };
  };
}
