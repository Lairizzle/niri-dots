return {
  'yetone/avante.nvim',

  event = 'VeryLazy',
  version = false,
  build = 'make',

  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',

    {
      'MeanderingProgrammer/render-markdown.nvim',
      ft = { 'markdown', 'Avante' },
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
    },
  },

  opts = {

    -- =========================================================
    -- CHAT ONLY PROMPT
    -- =========================================================

    system_prompt = [[
You are a coding assistant.

Only answer questions.
Provide explanations and example code.

Do not use tools.
Do not read files.
Do not edit files.
Do not create patches.
Do not run commands.
Do not act as an autonomous coding agent.
]],

    -- =========================================================
    -- PROVIDER
    -- =========================================================

    provider = 'ollama',

    providers = {

      ollama = {

        endpoint = 'http://127.0.0.1:11434',

        model = 'qwen2.5-coder:32b',

        timeout = 30000,

        -- Disable Ollama tool calls
        disable_tools = true,

        -- Disable ReAct agent prompting
        use_ReAct_prompt = false,

        extra_request_body = {

          options = {

            num_ctx = 4096,

            temperature = 0.3,

            top_p = 0.9,

            keep_alive = '30m',
          },
        },
      },
    },

    -- =========================================================
    -- MODE
    -- =========================================================

    -- No agent workflow
    mode = 'legacy',

    -- =========================================================
    -- DISABLE ALL TOOLS
    -- =========================================================

    disabled_tools = {

      'rag_search',
      'python',

      'git_diff',
      'git_commit',

      'glob',
      'search_keyword',

      'read_file',
      'read_file_toplevel_symbols',

      'create_file',
      'move_path',
      'copy_path',
      'delete_path',
      'create_dir',

      'bash',

      'web_search',
      'fetch',
    },

    -- =========================================================
    -- BEHAVIOUR
    -- =========================================================

    behaviour = {

      auto_focus_sidebar = true,

      auto_suggestions = false,

      auto_apply_diff_after_generation = false,

      jump_result_buffer_on_finish = false,

      support_paste_from_clipboard = false,

      minimize_diff = true,

      enable_token_counting = false,

      auto_add_current_file = false,

      -- Never auto approve anything
      auto_approve_tool_permissions = false,
    },

    -- =========================================================
    -- UI
    -- =========================================================

    windows = {

      position = 'right',

      width = 35,

      sidebar_header = {

        enabled = true,

        align = 'center',

        rounded = true,
      },

      input = {

        prefix = '> ',

        height = 6,
      },

      ask = {

        floating = false,

        start_insert = true,

        border = 'rounded',
      },

      edit = {

        border = 'rounded',

        start_insert = true,
      },
    },

    -- =========================================================
    -- FILE SELECTOR
    -- =========================================================

    selector = {

      provider = 'native',
    },

    file_selector = {

      provider = 'native',
    },

    -- =========================================================
    -- REPO MAP OFF
    -- =========================================================

    repo_map = {

      enabled = false,

      ignore_patterns = {

        '%.git',
        'node_modules',
        '__pycache__',
        'dist',
        'build',
      },
    },

    -- =========================================================
    -- HINTS
    -- =========================================================

    hints = {

      enabled = false,
    },

    -- =========================================================
    -- RAG OFF
    -- =========================================================

    rag_service = {

      enabled = false,
    },
  },
}
