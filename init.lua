vim.loader.enable()

-- Set up nixInfo global
_G.nixInfo = require(vim.g.nix_info_plugin_name)
nixInfo.lze = setmetatable(require("lze"), getmetatable(require("lzextras")))
function nixInfo.get_nix_plugin_path(name)
  return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
end

-- Disable plugins not installed by nix
nixInfo.lze.register_handlers({
  {
    spec_field = "auto_enable",
    set_lazy = false,
    modify = function(plugin)
      if type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
        if not nixInfo.get_nix_plugin_path(plugin.name) then
          plugin.enabled = false
        end
      end
      return plugin
    end,
  },
})

-- Leader keys (must be set before plugin keybinds)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.hlsearch = true
vim.opt.inccommand = "split"
vim.opt.scrolloff = 10
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = "yes"
vim.o.mouse = "a"
vim.opt.cpoptions:append("I")
vim.o.expandtab = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = "menu,preview,noselect"
vim.o.termguicolors = true

-- Disable auto comment on enter
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Netrw
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })

-- Clipboard
vim.keymap.set({ "v", "x", "n" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>Y", '"+yy', { desc = "Yank line to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-p>", "<C-r><C-p>+", { desc = "Paste from clipboard (insert)" })
vim.keymap.set("x", "<leader>P", '"_dP', { desc = "Paste over selection" })

-- Plugins
nixInfo.lze.load({
  {
    "gruvbox.nvim",
    auto_enable = true,
    colorscheme = "gruvbox",
  },
  {
    "nvim-treesitter",
    lazy = false,
    auto_enable = true,
    after = function()
      local function try_attach(buf, lang)
        if not vim.treesitter.language.add(lang) then
          return false
        end
        vim.treesitter.start(buf, lang)
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        vim.o.foldlevel = 99
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        return true
      end

      local installable = require("nvim-treesitter").get_available()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if not try_attach(args.buf, lang) and vim.tbl_contains(installable, lang) then
            require("nvim-treesitter").install(lang):await(function()
              try_attach(args.buf, lang)
            end)
          end
        end,
      })
    end,
  },
  {
    "telescope.nvim",
    auto_enable = true,
    cmd = { "Telescope" },
    keys = {
      { "<leader>sf", desc = "Find Files" },
      { "<leader>sg", desc = "Live Grep" },
      { "<leader>sh", desc = "Help Tags" },
      { "<leader>sw", desc = "Grep Word" },
      { "<leader>sd", desc = "Diagnostics" },
      { "<leader>sr", desc = "Resume" },
      { "<leader><leader>s", desc = "Buffers" },
    },
    after = function()
      local telescope = require("telescope")
      telescope.setup({})
      pcall(telescope.load_extension, "fzf")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Grep word" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Diagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Resume" })
      vim.keymap.set("n", "<leader><leader>s", builtin.buffers, { desc = "Buffers" })
    end,
  },
  {
    "gitsigns.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map({ "n", "v" }, "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(gs.next_hunk)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })

          map({ "n", "v" }, "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(gs.prev_hunk)
            return "<Ignore>"
          end, { expr = true, desc = "Previous hunk" })

          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Stage hunk" })
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Reset hunk" })
          map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
          map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>gb", function()
            gs.blame_line({ full = false })
          end, { desc = "Blame line" })
          map("n", "<leader>gd", gs.diffthis, { desc = "Diff against index" })
          map("n", "<leader>gD", function()
            gs.diffthis("~")
          end, { desc = "Diff against last commit" })
          map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "Toggle blame line" })
          map("n", "<leader>gtd", gs.toggle_deleted, { desc = "Toggle deleted" })
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
        end,
      })
      vim.cmd([[hi GitSignsAdd guifg=#04de21]])
      vim.cmd([[hi GitSignsChange guifg=#83fce6]])
      vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
    end,
  },
})

vim.cmd.colorscheme("gruvbox")
