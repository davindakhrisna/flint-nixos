{
  flake.homeModules.utils-starship = {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = true;

        format = ''
          [╭─](bright-black) $directory $git_branch$git_status$fill $nodejs$python$golang$nix_shell$cmd_duration[─╮](bright-black)
          [╰─](bright-black)$character '';

        fill = {
          symbol = " ";
        };

        character = {
          success_symbol = "[❯](bold cyan)";
          error_symbol = "[❯](bold red)";
        };

        directory = {
          style = "bold cyan";
          truncation_length = 4;
          truncate_to_repo = true;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };

        git_branch = {
          symbol = " ";
          style = "bold magenta";
          format = "on [$symbol$branch]($style) ";
        };

        git_status = {
          style = "bold red";
          format = "([$all_status$ahead_behind]($style) )";
        };

        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state](bold cyan) ";
        };

        cmd_duration = {
          min_time = 500;
          format = "took [$duration](bold yellow) ";
        };

        nodejs = {
          symbol = "󰎙 ";
          format = "via [$symbol($version )](bold green)";
        };

        python = {
          symbol = "󰌠 ";
          format = "via [(\${symbol}\${pyenv_prefix}(\${version} )(\(\$virtualenv\) ))](bold yellow)";
        };

        golang = {
          symbol = "󰟓 ";
          format = "via [$symbol($version )](bold cyan)";
        };
      };
    };
  };
}
