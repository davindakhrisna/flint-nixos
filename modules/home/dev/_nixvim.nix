{
  config,
  inputs,
  lib,
  ...
}: {
  config = lib.mkIf (builtins.elem config.dev ["minimal" "full"]) (lib.mkMerge [
    {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    }
    (import ./nixvim/_core.nix {inherit inputs;})
    (import ./nixvim/_editor.nix {})
    (import ./nixvim/_git.nix {})
    (import ./nixvim/_keymaps.nix {})
    (import ./nixvim/_ui.nix {})
  ]);
}
