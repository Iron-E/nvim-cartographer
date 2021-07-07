# nvim-cartographer

This is a plugin for Neovim which aims to simplify setting and deleting with keybindings / mappings in Lua The target audience is users who are trying to port from an `init.vim` to an `init.lua` following the release of Neovim 0.5.

Here is an example:

```lua
-- This is how you map with the Neovim API
vim.api.nvim_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', {noremap=true, silent=true})

-- This is how you do that with `nvim-cartographer`
map().n.nore.silent['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

## Installation

This plugin can be installed with any plugin manager. I use [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if not vim.loop.fs_stat(fn.glob(install_path)) then
	os.execute('git clone https://github.com/wbthomason/packer.nvim '..install_path)
end

vim.api.nvim_command 'packadd packer.nvim'

return require('packer').startup {function(use)
	use {'wbthomason/packer.nvim', opt=true}
	use 'Iron-E/nvim-cartographer'
end}
```

## Usage

To import this plugin, add the following line to the top of any file you wish to use this plugin in:

```lua
local map = require 'cartographer'
```

This plugin implements a builder to make toggling options as easy as possible. You may specify zero to one of `nvim_set_keymap`'s `mode` argument (i.e. you can `map().x` or `map()`).

A `cartographer` operation can be configured further. It supports all of the `:map-arguments`. `nore` is used to perform a non-recursive `:map`:

```lua
-- `:map` 'gt' in normal mode to searching for symbol references with the LSP
map().n.nore.silent['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

The above is equivalent to the following VimL:

```vim
" This is how you bind `gr` to the builtin LSP symbol-references command
nnoremap <silent> gr <Cmd>lua vim.lsp.buf.references()<CR>
```

### Delete

You can unset a `:map`ping as well. To do this, set a `<lhs>` to `nil` instead of any `<rhs>`:

```lua
-- `:unmap` 'zfo' in `x` mode
map().x['zfo'] = nil
```

### Multiple Modes

You can `:map` to multiple `modes` if necessary. All you must do is use a `for` loop:

```lua
-- Map `gr` to LSP symbol references in 'x' and 'n' modes.
for _, mode in ipairs({'n', 'x'}) do
	map()[mode].nore.expr['<Tab>'] = 'pumvisible() ? "\\<C-n>" : check_backspace() ? "\\<Tab>" : compe#complete()'
end
```
