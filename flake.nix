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
      
    initScript = pkgs.writeShellScriptBin "init" ''
      set -euo pipefail

      : ''${FORGEJO_TOKEN?"Environment variable FORGEJO_TOKEN is required"}
      FORGEJO_URL=''${FORGEJO_URL:-https://v13.next.forgejo.org}
      FORGEJO_REPO_NAME=''${FORGEJO_REPO_NAME:-myproject}

      echo "Creating repository '$FORGEJO_REPO_NAME' on Forgejo..."
      curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: token $FORGEJO_TOKEN" \
        "$FORGEJO_URL/api/v1/user/repos" \
        -d "{\"name\": \"$FORGEJO_REPO_NAME\", \"private\": false}" \
        -o /tmp/repo.json

      REPO_URL=$(jq -r .clone_url /tmp/repo.json)

      if [ "$REPO_URL" = "null" ] || [ -z "$REPO_URL" ]; then
        echo "❌ Failed to create repository. Response:"
        cat /tmp/repo.json
        exit 1
      fi

      PROJECT_DIR=''${1:-$(pwd)}
      cd "$PROJECT_DIR"      

      echo "Working directory: $(pwd)"
      echo "✅ Repository created: $REPO_URL"

      echo "Initializing local git repo..."
      git init -b main
      git add .
      git commit -m 'Initial commit'

      REPO_URL_AUTH="''${REPO_URL/https:\/\//https:\/\/$FORGEJO_TOKEN@}"
      git remote add origin "$REPO_URL_AUTH"
      git push -u origin main
    '';

  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [ git curl jq erlang elixir ];
      shellHook = ''
        echo "Welcome to your Nix dev shell!"
      '';
    };

    apps.${system} = {
      init = {
        type = "app";
        program = "${initScript}/bin/init";
      };

      setup_app = {
        type = "app";
        program = "${setupScript}/bin/init";
      };
    };
    templates = {
      default = {
        description = "Elixir dev template with Forgejo repo creation";
        path = ./.;
      };
      app = {
        description = "Elixir dev template with Forgejo repo creation";
        path = ./templates/.;
      };
    };
  };
}
