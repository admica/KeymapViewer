# Keymap Viewer for Neovim

A plugin to visualize your key mappings in Neovim.

## Installation

Using [packer.nvim](https://github.com/admica/KeymapViewer.nvim):
```lua
use 'admica/KeymapViewer'

### Or with vim-plug:

Plug 'your-username/keymap-viz'

## Usage

Start recording with :KeymapVizStart or <Leader>vs.

Stop recording with :KeymapVizStop or <Leader>ve.

Toggle the visualization buffer with :KeymapVizToggle or <Leader>vt.

Clear recorded sequences with :KeymapVizClear or <Leader>vc.

## Configuration

```lua
require('KeymapViewer').setup({
    width = 30,  -- Width of the visualization buffer
    position = 'right', -- Position of the visualization buffer
    persistence_file = '~/.config/nvim/KeymapViewer_data.json' -- File to save/load sequences
})
```
