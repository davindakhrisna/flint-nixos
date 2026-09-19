{self, ...}: {
  flake.homeModules = {
    shell = {...}: {
      imports = with self.homeModules; [
        utils-zsh
        utils-starship
        utils-cli
      ];
    };

    utils = self.homeModules.shell;
    shell-zsh = self.homeModules.utils-zsh;
    shell-starship = self.homeModules.utils-starship;
    shell-cli = self.homeModules.utils-cli;
  };
}
