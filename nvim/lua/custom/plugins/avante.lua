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
    -- PROVIDER
    -- =========================================================
    provider = 'ollama',

    providers = {
      ollama = {
        endpoint = 'http://127.0.0.1:11434',

        -- MUCH FASTER MODEL
        --
        -- Recommended:
        -- qwen2.5:7b
        -- qwen2.5-coder:7b
        -- llama3.1:8b
        --
        model = 'qwen2.5-coder:32b',

        timeout = 30000,

        -- IMPORTANT:
        -- disable agentic prompting
        use_ReAct_prompt = false,

        extra_request_body = {
          options = {

            -- HUGE speed improvement
            num_ctx = 4096,

            -- Slight creativity for snippets
            temperature = 0.3,

            -- Faster responses
            top_p = 0.9,

            -- Keep model warm
            keep_alive = '30m',

            -- Optional:
            -- num_predict = 512,
          },
        },
      },
    },

    -- =========================================================
    -- MODE
    -- =========================================================

    -- IMPORTANT:
    -- no autonomous editing
    mode = 'legacy',

    -- =========================================================
    -- BEHAVIOUR
    -- =========================================================
    behaviour = {

      auto_focus_sidebar = true,

      -- inline completions are expensive
      auto_suggestions = false,

      -- DO NOT EDIT FILES
      auto_apply_diff_after_generation = false,

      -- better UX
      jump_result_buffer_on_finish = false,

      -- disable image handling
      support_paste_from_clipboard = false,

      -- simpler/faster
      minimize_diff = true,

      -- disable token counting
      enable_token_counting = false,

      -- IMPORTANT:
      -- prevents huge context injection
      auto_add_current_file = false,

      -- disable all tool approvals
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
    -- REPO MAP
    -- =========================================================
    repo_map = {
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
    -- RAG
    -- =========================================================
    rag_service = {
      enabled = false,
    },
  },
}
