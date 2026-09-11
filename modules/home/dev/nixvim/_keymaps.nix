_: {
  programs.nixvim.keymaps = [
    {
      key = "<leader>e";
      mode = "n";
      action = "<cmd>Neotree toggle<CR>";
      options.desc = "File explorer";
    }
    {
      key = "<leader>f";
      mode = "n";
      action = "<cmd>Telescope find_files<CR>";
      options.desc = "Find files";
    }
    {
      key = "<leader>g";
      mode = "n";
      action = "<cmd>Telescope live_grep<CR>";
      options.desc = "Search text";
    }
    {
      key = "<leader>,";
      mode = "n";
      action = "<cmd>Telescope buffers<CR>";
      options.desc = "Switch buffer";
    }
    {
      key = "<C-s>";
      mode = "n";
      action = "<cmd>write<CR>";
      options.desc = "Save file";
    }
    {
      key = "<C-q>";
      mode = "n";
      action = "<cmd>quit!<CR>";
      options.desc = "Quit without saving";
    }
    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      options.desc = "Left window";
    }
    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      options.desc = "Lower window";
    }
    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      options.desc = "Upper window";
    }
    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      options.desc = "Right window";
    }
    {
      key = "<A-j>";
      mode = "n";
      action = "<cmd>move .+1<CR>==";
      options.desc = "Move line down";
    }
    {
      key = "<A-k>";
      mode = "n";
      action = "<cmd>move .-2<CR>==";
      options.desc = "Move line up";
    }
    {
      key = "<esc>";
      mode = "n";
      action = "<cmd>nohlsearch<CR><esc>";
      options.desc = "Clear search";
    }
    {
      key = "<leader>ca";
      mode = ["n" "v"];
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      options.desc = "Code action";
    }
    {
      key = "<leader>cr";
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      options.desc = "Rename symbol";
    }
    {
      key = "<leader>cf";
      mode = ["n" "v"];
      action = "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<CR>";
      options.desc = "Format";
    }
    {
      key = "gd";
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      options.desc = "Definition";
    }
    {
      key = "gr";
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.references()<CR>";
      options.desc = "References";
    }
    {
      key = "K";
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      options.desc = "Hover documentation";
    }
    {
      key = "[d";
      mode = "n";
      action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
      options.desc = "Previous diagnostic";
    }
    {
      key = "]d";
      mode = "n";
      action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
      options.desc = "Next diagnostic";
    }
    {
      key = "[h";
      mode = "n";
      action = "<cmd>Gitsigns prev_hunk<CR>";
      options.desc = "Previous Git hunk";
    }
    {
      key = "]h";
      mode = "n";
      action = "<cmd>Gitsigns next_hunk<CR>";
      options.desc = "Next Git hunk";
    }
    {
      key = "<leader>ghs";
      mode = "n";
      action = "<cmd>Gitsigns stage_hunk<CR>";
      options.desc = "Stage hunk";
    }
    {
      key = "<leader>ghr";
      mode = "n";
      action = "<cmd>Gitsigns reset_hunk<CR>";
      options.desc = "Reset hunk";
    }
  ];
}
