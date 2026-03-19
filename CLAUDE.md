# Neovim Config (nix-wrapper-modules)

This is a Nix-managed Neovim configuration using [nix-wrapper-modules](https://birdeehub.github.io/nix-wrapper-modules/) (BirdeeHub). It is the same approach as nixCats-nvim but using the newer wrapper module system.

## Project Structure

```
flake.nix    -- Nix flake: declares inputs (nixpkgs, plugins), outputs (packages, overlays, NixOS/HM modules)
module.nix   -- Main Nix module: declares specs (plugin groups), extraPackages, settings, specMods
init.lua     -- Neovim Lua config: all vim options, keymaps, and plugin setup via `lze`
```

## How It Works: Two-Phase System

### Phase 1: Nix side (`flake.nix` + `module.nix`)

Nix declares **what** plugins/tools are installed and groups them into **specs**.

**Adding plugins from nixpkgs:** Add them directly in `module.nix` under a `config.specs.<name>.data` list:
```nix
config.specs.general.data = with pkgs.vimPlugins; [
  snacks-nvim
  nvim-lspconfig
  # ...
];
```

**Adding plugins NOT in nixpkgs:** Add a flake input with the `plugins-` prefix in `flake.nix`:
```nix
inputs.plugins-myplugin = {
  url = "github:author/myplugin";
  flake = false;
};
```
Then reference it via `config.nvim-lib.neovimPlugins.myplugin` in `module.nix`. The `plugins-` prefix is stripped to form the name.

**Adding external tools (LSPs, formatters, linters):** Use `extraPackages` on a spec:
```nix
config.specs.nix = {
  data = null;
  extraPackages = with pkgs; [ nixd nixfmt ];
};
```

### Phase 2: Lua side (`init.lua`)

Lua handles **how** plugins are configured and loaded, using `lze` (lazy loader).

**`nixInfo` global:** The bridge between Nix and Lua. Fetch Nix-defined values:
```lua
nixInfo("default_value", "settings", "colorscheme")  -- returns the Nix setting or default
nixInfo(nil, "plugins", "lazy", "plugin-name")        -- check if a plugin was installed
nixInfo(false, "settings", "cats", "lua")             -- check if a spec/category is enabled
```

**`nixInfo.lze.load { ... }`** takes a list of lze specs. Each spec has:
- `name` (string, first positional) -- plugin name
- `auto_enable = true` -- auto-disable if not installed by Nix
- `for_cat = "specname"` -- disable if that top-level spec is not enabled
- `event`, `cmd`, `ft`, `keys` -- lazy-loading triggers
- `before`, `after` -- functions to run before/after loading
- `lsp = { ... }` -- LSP configuration (handled by lzextras.lsp handler)
- `lazy = false` -- load at startup instead of lazily

## Specs and Categories

Top-level specs in `module.nix` (`config.specs.*`) act as **categories**:
- `general` -- core plugins (snacks, lspconfig, treesitter, etc.)
- `lua` -- Lua development tools (lazydev, lua_ls, stylua)
- `nix` -- Nix development tools (nixd, nixfmt)
- `lze` -- the lazy loader itself
- `colorscheme` -- active colorscheme plugin

Each spec can be enabled/disabled. The `config.settings.cats` option auto-generates a `{ specname = bool }` map accessible in Lua via `nixInfo(false, "settings", "cats", "specname")`.

## Common Tasks

### Add a new plugin (from nixpkgs)

1. **Nix:** Add the vimPlugin to the appropriate spec's `data` list in `module.nix`
2. **Lua:** Add an lze spec in `init.lua` with `auto_enable = true` and configuration

### Add a new plugin (not in nixpkgs)

1. **Nix:** Add `inputs.plugins-<name>` in `flake.nix` with `flake = false`
2. **Nix:** Reference `config.nvim-lib.neovimPlugins.<name>` in a spec's `data` in `module.nix`
3. **Lua:** Add an lze spec in `init.lua`

### Add a new LSP

1. **Nix:** Add the LSP server package to `extraPackages` in the relevant spec in `module.nix`
2. **Lua:** Add an lze spec with `lsp = { filetypes = { ... }, settings = { ... } }`

### Add a new formatter/linter

1. **Nix:** Add the package to `extraPackages` in `module.nix`
2. **Lua:** Configure it in the `conform.nvim` or `nvim-lint` spec in `init.lua`

## Build and Test

```bash
nix build .              # Build the neovim derivation
./result/bin/nvim        # Test the built binary
nix flake update         # Update all flake inputs (plugins, nixpkgs)
```

## Installation Methods

- **Standalone package:** `nix build .` or add to flake inputs and use the overlay
- **NixOS module:** `wrappers.neovim.enable = true` via `nixosModules.neovim`
- **Home Manager:** `wrappers.neovim.enable = true` via `homeModules.neovim`

## Debugging

```vim
:lua require('lzextras').debug.display(require(vim.g.nix_info_plugin_name))
" Shows all Nix-provided values (plugins, settings, info)

:lua nixInfo.lze.debug.display(nixInfo.plugins)
" Shows plugin names as known to the loader
```

## Key References

- [nix-wrapper-modules docs](https://birdeehub.github.io/nix-wrapper-modules/)
- [neovim wrapper docs](https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html)
- [tips and tricks](https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html#tips-and-tricks)
- [lze (lazy loader)](https://github.com/BirdeeHub/lze)
- [lzextras](https://github.com/BirdeeHub/lzextras)
