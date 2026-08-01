return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      -- 1. THIS BLOCK HIDES THE FILES
      filtered_items = {
        visible = false, -- true just grays them out; false hides them completely
        hide_by_pattern = {
          '*.uid', -- Filters out your Godot uid files
        },
      },
      -- 2. YOUR EXISTING MAPPINGS STAY HERE
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
