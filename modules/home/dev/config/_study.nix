{pkgs, ...}: let
  ompStudy = pkgs.writeShellApplication {
    name = "omp-study";
    runtimeInputs = with pkgs; [
      coreutils
    ];
    text = ''
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/omp-study"
      vault_file="$config_dir/vault"

      show_help() {
        cat <<'EOF'
      omp-study - Open OhMyPi as an Obsidian study partner

      USAGE:
        omp-study
        omp-study --set-vault
        omp-study --help

      The first run asks for an Obsidian vault. The path is the only
      machine-local setting and is stored in $XDG_CONFIG_HOME/omp-study/vault.
      EOF
      }

      configure_vault() {
        local candidate resolved tilde
        tilde="~"

        if [ ! -t 0 ]; then
          echo "Error: Vault setup requires an interactive terminal." >&2
          exit 1
        fi

        while true; do
          printf "Obsidian vault directory: "
          IFS= read -r candidate

          case "$candidate" in
            "$tilde") candidate="$HOME" ;;
            "$tilde/"*) candidate="$HOME/''${candidate#"$tilde/"}" ;;
          esac

          if ! resolved=$(realpath -e -- "$candidate" 2>/dev/null) || [ ! -d "$resolved" ]; then
            echo "That directory does not exist."
            continue
          fi

          mkdir -p -- "$config_dir"
          printf '%s\n' "$resolved" >"$vault_file"
          printf "Saved vault: %s\n" "$resolved"
          vault="$resolved"
          return
        done
      }

      case "''${1:-}" in
        "") ;;
        -h|--help)
          show_help
          exit 0
          ;;
        --set-vault)
          if [ "$#" -ne 1 ]; then
            echo "Error: --set-vault does not accept arguments." >&2
            exit 1
          fi
          configure_vault
          ;;
        *)
          echo "Error: Unknown option '$1'." >&2
          show_help >&2
          exit 1
          ;;
      esac

      if [ -z "''${vault:-}" ]; then
        if [ -f "$vault_file" ]; then
          IFS= read -r vault <"$vault_file"
        fi

        if [ -z "''${vault:-}" ] || [ ! -d "$vault" ]; then
          if [ -n "''${vault:-}" ]; then
            echo "Saved vault is unavailable: $vault"
          fi
          configure_vault
        fi
      fi

      exec omp --cwd "$vault" "/study"
    '';
  };
in {
  home.packages = [ompStudy];
}
