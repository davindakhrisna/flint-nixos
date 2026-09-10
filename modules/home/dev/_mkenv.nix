{pkgs, ...}: let
  templatesDir = ./templates;

  mkenvScript = pkgs.writeShellApplication {
    name = "mkenv";
    runtimeInputs = with pkgs; [
      fzf
      direnv
      git
      coreutils
      gnused
      gawk
    ];
    text = ''
      TEMPLATES_DIR="${templatesDir}"
      USER_TEMPLATES_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/mkenv/templates"

      show_help() {
        cat <<'EOF'
      mkenv - Bootstrap direnv & standalone Nix Flake development environments

      USAGE:
        mkenv [OPTIONS] [STACK] [DIRECTORY]

      ARGUMENTS:
        STACK         Tech stack to initialize (e.g. ts, go, py, rust, c, flutter, nix).
                      If omitted, an interactive fzf selector will prompt you.
        DIRECTORY     Optional target directory. If specified, it will be created if
                      it does not exist. Defaults to current directory (.).

      OPTIONS:
        -l, --list    List all available stacks and aliases
        -f, --force   Overwrite existing flake.nix or .envrc if they already exist
        -h, --help    Show this help message

      AVAILABLE STACKS:
        ts, typescript, node   Node.js 22, TypeScript, pnpm, Yarn, Bun, Biome
        go, golang             Go, gopls, Air, golangci-lint, Delve
        py, python, uv         Python 3, uv, Ruff, Pyright, Black
        rust, rs, cargo        Rust, Cargo, rust-analyzer, Clippy, rustfmt, pkg-config
        c, cpp, c++            GCC, Make, CMake, pkg-config, clang tools, GDB, Valgrind
        flutter, dart          Flutter, JDK 17, Android tools
        nix, flake             Alejandra, nixfmt, nil, deadnix, statix, nix-prefetch-github

      CUSTOM TEMPLATES:
        Drop a directory containing a flake.nix into:
        ~/.config/mkenv/templates/<stack_name>/
        User custom templates automatically override built-in templates.
      EOF
      }

      list_stacks() {
        cat <<'EOF'
      Available development stacks:
        ts       (aliases: typescript, node, nodejs, js)
                 TypeScript, Node.js 22, pnpm, yarn, bun, biome
        go       (aliases: golang)
                 Go, gopls, air, golangci-lint, delve
        py       (aliases: python, uv)
                 Python 3, uv, ruff, pyright, black
        rust     (aliases: rs, cargo)
                 Rust, cargo, rust-analyzer, clippy, rustfmt
        c        (aliases: cpp, c++)
                 C/C++, GCC, gnumake, cmake, clang-tools, gdb, valgrind
        flutter  (aliases: dart)
                 Flutter, Dart, JDK 17, Android SDK tools
        nix      (aliases: flake)
                 Alejandra, nixfmt, nil, deadnix, statix, nix-prefetch-github
      EOF

        if [ -d "$USER_TEMPLATES_DIR" ]; then
          echo ""
          echo "User custom templates ($USER_TEMPLATES_DIR):"
          for d in "$USER_TEMPLATES_DIR"/*; do
            if [ -d "$d" ]; then
              echo "  * $(basename "$d")"
            fi
          done
        fi
      }

      resolve_alias() {
        case "$1" in
          ts|typescript|node|nodejs|js) echo "ts" ;;
          go|golang)                   echo "go" ;;
          py|python|uv)                echo "py" ;;
          rust|rs|cargo)               echo "rust" ;;
          c|cpp|"c++")                 echo "c" ;;
          flutter|dart)                echo "flutter" ;;
          nix|flake)                   echo "nix" ;;
          *)                           echo "$1" ;;
        esac
      }

      # Parse command line flags
      FORCE=0
      STACK=""
      TARGET_DIR=""

      while [ $# -gt 0 ]; do
        case "$1" in
          -h|--help)
            show_help
            exit 0
            ;;
          -l|--list|list)
            list_stacks
            exit 0
            ;;
          -f|--force)
            FORCE=1
            shift
            ;;
          -*)
            echo "Error: Unknown option '$1'" >&2
            echo "Run 'mkenv --help' for usage." >&2
            exit 1
            ;;
          *)
            if [ -z "$STACK" ]; then
              STACK="$1"
            elif [ -z "$TARGET_DIR" ]; then
              TARGET_DIR="$1"
            else
              echo "Error: Unexpected extra argument '$1'" >&2
              exit 1
            fi
            shift
            ;;
        esac
      done

      # Interactive picker if no stack provided
      if [ -z "$STACK" ]; then
        if [ ! -t 0 ]; then
          show_help
          exit 1
        fi

        CHOICE=$(cat <<'EOF' | fzf --prompt="Select Tech Stack > " --height=45% --layout=reverse --border --inline-info || true
      ts       · TypeScript, Node.js, pnpm, Bun, Biome
      go       · Go, gopls, Air, golangci-lint, Delve
      py       · Python, uv, Ruff, Pyright, Black
      rust     · Rust, Cargo, rust-analyzer, Clippy, rustfmt
      c        · C/C++, GCC, CMake, Clang-tools, GDB, Valgrind
      flutter  · Flutter, Dart, JDK 17, Android tools
      nix      · Alejandra, nixfmt, nil, Deadnix, Statix, nix-prefetch-github
      EOF
      )

        if [ -z "$CHOICE" ]; then
          echo "No stack selected. Aborting."
          exit 0
        fi

        STACK=$(echo "$CHOICE" | awk '{print $1}')
      fi

      CANONICAL_STACK=$(resolve_alias "$STACK")

      # Find template source
      SRC_DIR=""
      if [ -d "$USER_TEMPLATES_DIR/$CANONICAL_STACK" ]; then
        SRC_DIR="$USER_TEMPLATES_DIR/$CANONICAL_STACK"
      elif [ -d "$USER_TEMPLATES_DIR/$STACK" ]; then
        SRC_DIR="$USER_TEMPLATES_DIR/$STACK"
      elif [ -d "$TEMPLATES_DIR/$CANONICAL_STACK" ]; then
        SRC_DIR="$TEMPLATES_DIR/$CANONICAL_STACK"
      fi

      TEMPLATE_FILE=""
      if [ -n "$SRC_DIR" ]; then
        if [ -f "$SRC_DIR/flake.nix.template" ]; then
          TEMPLATE_FILE="$SRC_DIR/flake.nix.template"
        elif [ -f "$SRC_DIR/flake.nix" ]; then
          TEMPLATE_FILE="$SRC_DIR/flake.nix"
        fi
      fi

      if [ -z "$TEMPLATE_FILE" ]; then
        echo "Error: Tech stack '$STACK' not found." >&2
        echo "Run 'mkenv --list' to see available stacks." >&2
        exit 1
      fi

      # Switch to target directory if provided
      if [ -n "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        cd "$TARGET_DIR"
      fi

      CURRENT_DIR=$(pwd)

      # Safety check for existing files
      if [ "$FORCE" -eq 0 ]; then
        if [ -f "flake.nix" ] || [ -f ".envrc" ]; then
          echo "Error: 'flake.nix' or '.envrc' already exists in $CURRENT_DIR." >&2
          echo "Use --force (-f) to overwrite existing configuration." >&2
          exit 1
        fi
      fi

      echo "🚀 Bootstrapping '$CANONICAL_STACK' environment in $CURRENT_DIR..."

      # Copy template to flake.nix
      cp -f "$TEMPLATE_FILE" ./flake.nix
      chmod 644 ./flake.nix

      # Create .envrc
      cat <<'EOF' > .envrc
      use flake
      EOF

      # Ensure generated state and build results stay untracked.
      if [ -f .gitignore ]; then
        if ! grep -qxF ".direnv/" .gitignore; then
          printf "\n.direnv/\n" >> .gitignore
        fi
        if ! grep -qxF "result" .gitignore; then
          printf "result\n" >> .gitignore
        fi
      else
        cat <<'EOF' > .gitignore
      .direnv/
      result
      EOF
      fi

      # If inside a git repository, add intent for flake.nix
      if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git add -N flake.nix 2>/dev/null || true
        git add -N .gitignore 2>/dev/null || true
      fi

      # Allow direnv
      if command -v direnv >/dev/null 2>&1; then
        direnv allow .
      fi

      echo "✨ Successfully initialized '$CANONICAL_STACK' environment!"
      echo "   • flake.nix  (isolated Nix flake)"
      echo "   • .envrc     (use flake)"
      echo "   • .gitignore (ignores .direnv/ & result)"
      echo "   • direnv     (allowed)"
    '';
  };

  zshCompletion = pkgs.writeText "_mkenv" ''
    #compdef mkenv

    local -a stacks
    stacks=(
      'ts:TypeScript & Node.js (pnpm, bun, biome)'
      'typescript:TypeScript & Node.js'
      'node:Node.js'
      'go:Go development (gopls, air, delve)'
      'golang:Go development'
      'py:Python & uv (ruff, pyright, black)'
      'python:Python & uv'
      'uv:Python with uv package manager'
      'rust:Rust development (cargo, rust-analyzer, clippy)'
      'rs:Rust development'
      'cargo:Rust development'
      'c:C/C++ development (gcc, cmake, gdb)'
      'cpp:C++ development'
      'flutter:Flutter & Dart mobile development'
      'dart:Flutter & Dart mobile development'
      'nix:Nix tooling & formatting (alejandra, nixfmt, nil, deadnix, statix)'
      'flake:Nix flake tooling'
    )

    _arguments -s \
      '(-h --help)'{-h,--help}'[Show help message]' \
      '(-l --list)'{-l,--list}'[List available stacks and aliases]' \
      '(-f --force)'{-f,--force}'[Force overwrite existing flake.nix/.envrc]' \
      '1:stack:(($stacks))' \
      '2:directory:_files -/'
  '';

  mkenvPkg = pkgs.symlinkJoin {
    name = "mkenv";
    paths = [mkenvScript];
    postBuild = ''
      mkdir -p $out/share/zsh/site-functions
      cp ${zshCompletion} $out/share/zsh/site-functions/_mkenv
    '';
  };
in {
  home.packages = [mkenvPkg];
}
