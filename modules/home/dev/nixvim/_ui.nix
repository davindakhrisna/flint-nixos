_: {
  programs.nixvim.plugins = {
    neo-tree = {
      enable = true;
      settings = {
        enable_git_status = true;
        enable_diagnostics = true;
        filesystem = {
          follow_current_file.enabled = true;
          use_libuv_file_watcher = true;
          bind_to_cwd = false;
        };
        window = {
          width = 30;
          mappings."<space>" = "none";
        };
      };
    };

    telescope.enable = true;
    which-key.enable = true;
    web-devicons.enable = true;
  };
}
