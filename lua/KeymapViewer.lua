local api = vim.api
local M = {}

-- State management
local viz_buf = -1
local recording = false
local sequence = {}
local viz_visible = false

-- Configuration
local config = {
  width = 30,
  position = 'right',
  persistence_file = vim.fn.expand('~/.config/nvim/keymap_viz_data.json')
}

-- Load configuration
local function load_config()
  config.width = vim.g.keymap_viz_width or config.width
  config.position = vim.g.keymap_viz_position or config.position
  config.persistence_file = vim.g.keymap_viz_persistence_file or config.persistence_file
end

function M.start_recording()
  recording = true
  sequence = {}
  vim.notify("Recording keymap...")
end

function M.stop_recording()
  recording = false
  M.save_sequence()
  M.show_visualization()
  vim.notify("Recording stopped")
end

function M.capture_keys()
  if recording then
    local key = vim.fn.getcharstr()
    table.insert(sequence, key)
  end
end

function M.toggle_visualization()
  if viz_visible then
    M.hide_visualization()
  else
    M.show_visualization()
  end
end

function M.show_visualization()
  if viz_buf == -1 or not api.nvim_buf_is_valid(viz_buf) then
    local cmd = config.position == 'right' and 'botright' or 'topleft'
    vim.cmd(cmd .. ' vertical ' .. config.width .. 'new')
    viz_buf = api.nvim_get_current_buf()
    api.nvim_buf_set_option(viz_buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(viz_buf, 'bufhidden', 'hide')
    api.nvim_buf_set_option(viz_buf, 'swapfile', false)
    api.nvim_buf_set_option(viz_buf, 'modifiable', false)
    api.nvim_buf_set_option(viz_buf, 'number', false)
    api.nvim_buf_set_option(viz_buf, 'wrap', false)
    api.nvim_buf_set_option(viz_buf, 'signcolumn', 'no')
    api.nvim_buf_set_option(viz_buf, 'colorcolumn', '')
    api.nvim_buf_set_option(viz_buf, 'foldcolumn', '0')

    -- Buffer-local mappings
    api.nvim_buf_set_keymap(viz_buf, 'n', 'q', ':lua require("keymap_viz").hide_visualization()<CR>', { silent = true, noremap = true })
    api.nvim_buf_set_keymap(viz_buf, 'n', '<ESC>', ':lua require("keymap_viz").hide_visualization()<CR>', { silent = true, noremap = true })

    viz_visible = true
  else
    local winnr = vim.fn.bufwinnr(viz_buf)
    if winnr == -1 then
      local cmd = config.position == 'right' and 'botright vertical ' .. config.width .. 'split' or 'topleft vertical ' .. config.width .. 'split'
      vim.cmd(cmd)
      api.nvim_win_set_buf(0, viz_buf)
      viz_visible = true
    end
  end

  M.load_sequence()
  M.update_visualization()
end

function M.hide_visualization()
  local winnr = vim.fn.bufwinnr(viz_buf)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'wincmd c')
    viz_visible = false
  end
end

function M.update_visualization()
  if api.nvim_buf_is_valid(viz_buf) then
    local winnr = vim.fn.bufwinnr(viz_buf)
    if winnr ~= -1 then
      vim.api.nvim_set_current_win(winnr)
      api.nvim_buf_set_option(viz_buf, 'modifiable', true)
      api.nvim_buf_set_lines(viz_buf, 0, -1, false, {'Keymap Sequence:', ''})
      for _, key in ipairs(sequence) do
        api.nvim_buf_set_lines(viz_buf, -1, -1, false, {'○ ' .. key})
      end
      api.nvim_buf_set_option(viz_buf, 'modifiable', false)
      vim.cmd('wincmd p')
    end
  end
end

function M.clear_sequence()
  sequence = {}
  M.save_sequence()
  M.update_visualization()
  vim.notify("Sequence cleared")
end

function M.save_sequence()
  local file = io.open(config.persistence_file, "w")
  if file then
    file:write(vim.fn.json_encode(sequence))
    file:close()
  else
    vim.notify("Error: Could not save sequence to file", vim.log.levels.ERROR)
  end
end

function M.load_sequence()
  local file = io.open(config.persistence_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    sequence = vim.fn.json_decode(content) or {}
  else
    sequence = {}
  end
end

-- Setup function for users to configure the plugin
function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", config, user_config)
  load_config()
end

-- Commands
api.nvim_create_user_command('KeymapVizStart', function() M.start_recording() end, {})
api.nvim_create_user_command('KeymapVizStop', function() M.stop_recording() end, {})
api.nvim_create_user_command('KeymapVizToggle', function() M.toggle_visualization() end, {})
api.nvim_create_user_command('KeymapVizClear', function() M.clear_sequence() end, {})

-- Default mappings
local function set_keymap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true, silent = true })
end

set_keymap('n', '<Leader>vs', ':KeymapVizStart<CR>')
set_keymap('n', '<Leader>ve', ':KeymapVizStop<CR>')
set_keymap('n', '<Leader>vt', ':KeymapVizToggle<CR>')
set_keymap('n', '<Leader>vc', ':KeymapVizClear<CR>')

-- Auto-capture keys
local group = api.nvim_create_augroup('KeymapViz', { clear = true })
api.nvim_create_autocmd('CursorHold', {
  group = group,
  callback = M.capture_keys
})

return M
