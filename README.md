# nvim-cartographer

This is a plugin for Neovim which aims to simplify setting and deleting with keybindings / mappings in Lua The target audience is users who are trying to port from an `init.vim` to an `init.lua` following the release of Neovim 0.5.

Here is an example:

```lua
-- This is how you map with the Neovim API
vim.api.nvim_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', {noremap=true, silent=true})

-- This is how you do that with `nvim-cartographer`
map.n.nore.silent['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

## Installation

This plugin can be installed with any plugin manager and used with Neovim 0.7+. I use [packer.nvim](https://github.com/wbthomason/packer.nvim):

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

This plugin implements a builder to make toggling options as easy as possible. You may specify zero to one of `nvim_set_keymap`'s `mode` argument (i.e. you can `map.x` or `map`). It also supports all of the `:h :map-arguments`. `nore` is used to perform a non-recursive `:map`. The ordering of arguments is not important:

```lua
assert(vim.deep_equal(map.n.nore.silent.unique, map.silent.n.unique.nore))
```

Here is an example:

```lua
-- `:map` 'gt' in normal mode to searching for symbol references with the LSP
map.n.nore.silent.unique['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

The above is equivalent to the following VimL:

```vim
" This is how you bind `gr` to the builtin LSP symbol-references command
nnoremap <silent><unique> gr <Cmd>lua vim.lsp.buf.references()<CR>
```

### Buffer-Local Mapping

You can create mappings for specific buffers:

```lua
local nnoremap = require('cartographer').n.nore.silent

-- Only buffer sets map to current buffer
nnoremap.buffer['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'

-- You can specify bufnr like <bufer=n>
-- This keymap will be set for buffer 3
nnoremap.buffer3['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

### Hooks

You can register a function to be called when mapping or unmapping. This function has the same parameters as `nvim_buf_set_keymap`.

```lua
local map = require 'cartographer'
map:hook(function(buffer, mode, lhs, rhs, opts)
	-- setup which-key, etc
	print(vim.inspect(lhs)..' was mapped to '..vim.inspect(rhs))
end)
map['zxpp'] = vim.lsp.buf.definition
```

The `buffer` parameter will be `nil` when the mapping is not [buffer-local](#buffer-local-mapping).

### Lua Functions

You can also register `local` lua `function`s to mappings, rather than attempt to navigate `v:lua`/`luaeval` bindings:

```lua
local map = require 'cartographer'

local function float_term()
	local buffer = vim.api.nvim_create_buf(false, true)
	local window = vim.api.nvim_open_win(buffer, true,
	{
		relative = 'cursor',
		height = math.floor(vim.go.lines / 2),
		width = math.floor(vim.go.columns / 2),
		col = 0,
		row = 0,
	})
	vim.api.nvim_command 'terminal'
end

map.n.nore.silent['<Tab>'] = float_term
```

### Multiple Modes

You can `:map` to multiple `mode`s if necessary.

```lua
-- Map `gr` to LSP symbol references in 'x' and 'n' modes.
map.n.x.nore.expr['<Tab>'] = 'pumvisible() ? "\\<C-n>" : check_backspace() ? "\\<Tab>" : compe#complete()'
```

### Unmapping

You can `:unmap` as well by setting a `<lhs>` to `nil` instead of any `<rhs>`:

```lua
-- `:unmap` 'zfo' in `x` mode
map.x['zfo'] = nil
```

