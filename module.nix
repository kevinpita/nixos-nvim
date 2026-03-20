inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  config.settings.config_directory = ./.;

  config.specs.lze.data = with config.nvim-lib.neovimPlugins; [
    lze
    lzextras
  ];

  config.specs.general = {
    after = [ "lze" ];
    lazy = true;
    data = with pkgs.vimPlugins; [
      {
        data = vim-sleuth;
        lazy = false;
      }
      gitsigns-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      plenary-nvim
      nvim-treesitter.withAllGrammars
      nvim-tree-lua
      nvim-web-devicons
      diffview-nvim
      render-markdown-nvim
      which-key-nvim
    ];
  };

  config.specs.colorscheme = {
    after = [ "lze" ];
    lazy = true;
    data = with pkgs.vimPlugins; [
      gruvbox-nvim
    ];
  };

  config.extraPackages = with pkgs; [
    tree-sitter
    ripgrep
    fd
  ];

  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };
}
