_: {
  programs.nixvim.plugins.gitsigns = {
    enable = true;
    settings = {
      current_line_blame = false;
      signs = {
        add.text = "▎";
        change.text = "▎";
        delete.text = "";
        topdelete.text = "";
        changedelete.text = "▎";
      };
    };
  };
}
