-------------
-- LSP config
-------------
-- See ~/.dotfiles/vim/plugins.vim for the Plug directives

local lspconfig = require('lspconfig')

-- lsp_signature
-- https://github.com/ray-x/lsp_signature.nvim#full-configuration-with-default-values
local on_attach_lsp_signature = function(client, bufnr)
  require('lsp_signature').on_attach({
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      floating_window = true,
      handler_opts = {
        border = "single"
      },
      zindex = 99,     -- <100 so that it does not hide completion popup.
      fix_pos = false, -- Let signature window change its position when needed, see GH-53
      toggle_key = '<M-x>',  -- Press <Alt-x> to toggle signature on and off.
    })
end

-- Customize LSP behavior
-- [[ A callback executed when LSP engine attaches to a buffer. ]]
local on_attach = function(client, bufnr)
  -- Always use signcolumn for the current buffer
  vim.wo.signcolumn = 'yes:1'

  -- Activate LSP signature on attach.
  on_attach_lsp_signature(client, bufnr)

  -- Activate LSP status on attach (see a configuration below).
  require('lsp-status').on_attach(client)

  -- Keybindings
  -- https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local opts = { noremap=true, silent=true }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  if vim.fn.exists(':Telescope') then
    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts)
  else
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  end
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  --buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  if vim.fn.has('nvim-0.6.0') > 0 then
    buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  else
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  end
  --buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  --buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  --buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  --buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  --buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  --buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  --buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

-- Add global keymappings for LSP actions
-- F3, F12: goto definition
vim.cmd [[
  map  <F12>  gd
  imap <F12>  <ESC>gd
  map  <F3>   <F12>
  imap <F3>   <F12>
]]
-- Shift+F12: show usages/references
vim.cmd [[
  map  <F24>  gr
  imap <F24>  <ESC>gr
]]


-- Register and activate LSP servers (managed by nvim-lsp-installer)
local builtin_lsp_servers = {
  -- List name of LSP servers that will be automatically installed and managed by :LspInstall.
  -- LSP servers will be installed locally at: ~/.local/share/nvim/lsp_servers
  -- @see(lspinstall): https://github.com/williamboman/nvim-lsp-installer
  'pyright',
  'vimls',
  'tsserver',
}
-- Optional and additional LSP setup options other than (common) on_attach, capabilities, etc.
-- @see(config): https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local lsp_setup_opts = {}
lsp_setup_opts['pyright'] = {
  settings = {
    python = {
    },
  },
}
lsp_setup_opts['sumneko_lua'] = vim.tbl_extend('force',
  require("lua-dev").setup {}, {
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',   -- Lua 5.1/LuaJIT
        },
        completion = { callSnippet = "Disable" },
        workspace = { maxPreload = 8000 },
      },
    },
  }
)

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach,

    -- Suggested configuration by nvim-cmp
    capabilities = require('cmp_nvim_lsp').update_capabilities(
     vim.lsp.protocol.make_client_capabilities()
    ),
  }

  -- Customize the options passed to the server
  opts = vim.tbl_extend("error", opts, lsp_setup_opts[server.name] or {})

  -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- Automatically install if a required LSP server is missing.
for _, lsp_name in ipairs(builtin_lsp_servers) do
  local ok, lsp = require('nvim-lsp-installer.servers').get_server(lsp_name)
  ---@diagnostic disable-next-line: undefined-field
  if ok and not lsp:is_installed() then
    vim.defer_fn(function()
      -- lsp:install()   -- headless
      lsp_installer.install(lsp_name)   -- with UI (so that users can be notified)
    end, 0)
  end
end

-------------------------
-- LSP Handlers (general)
-------------------------
-- :help lsp-method
-- :help lsp-handler

local lsp_handlers_hover = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'single'
})
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
  local bufnr, winnr = lsp_handlers_hover(err, result, ctx, config)
  if winnr ~= nil then
    vim.api.nvim_win_set_option(winnr, "winblend", 20)  -- opacity for hover
  end
  return bufnr, winnr
end


------------------
-- LSP diagnostics
------------------
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization

-- Customize how to show diagnostics:
-- No virtual text (distracting!), show popup window on hover.
if vim.fn.has('nvim-0.6.0') > 0 then
  -- @see https://github.com/neovim/neovim/pull/16057 for new APIs
  vim.diagnostic.config({
    virtual_text = false,
    underline = {
      -- Do not underline text when severity is low (INFO or HINT).
      severity = {min = vim.diagnostic.severity.WARN},
    },
    float = {
      source = 'always',
      focusable = false,   -- See neovim#16425
      border = 'single',

      -- Customize how diagnostic message will be shown: show error code.
      format = function(diagnostic)
        -- See null-ls.nvim#632, neovim#17222 for how to pick up `code`
        local user_data
        user_data = diagnostic.user_data or {}
        user_data = user_data.lsp or user_data.null_ls or user_data
        local code = (
          -- TODO: symbol is specific to pylint (will be removed)
          diagnostic.symbol or diagnostic.code or
          user_data.symbol or user_data.code
        )
        if code then
          return string.format("%s (%s)", diagnostic.message, code)
        else return diagnostic.message
        end
      end,
    }
  })
  _G.LspDiagnosticsShowPopup = function()
    return vim.diagnostic.open_float(0, {scope="cursor"})
  end
else  -- neovim 0.5.0
  -- @see :help lsp-handler-configuration
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
      vim.lsp.diagnostic.on_publish_diagnostics, {
        virtual_text = false,     -- disable virtual text
        signs = true,             -- show signs
        update_in_insert = false, -- delay update diagnostics
        -- display_diagnostic_autocmds = { "InsertLeave" },
      }
    )
  _G.LspDiagnosticsShowPopup = function()
    ---@diagnostic disable-next-line: deprecated
    return vim.lsp.diagnostic.show_line_diagnostics({
      focusable = false,
      border = 'single',
    })
  end
end

-- Show diagnostics in a pop-up window on hover
_G.LspDiagnosticsPopupHandler = function()
  local current_cursor = vim.api.nvim_win_get_cursor(0)
  local last_popup_cursor = vim.w.lsp_diagnostics_last_cursor or {nil, nil}

  -- Show the popup diagnostics window,
  -- but only once for the current cursor location (unless moved afterwards).
  if not (current_cursor[1] == last_popup_cursor[1] and current_cursor[2] == last_popup_cursor[2]) then
    vim.w.lsp_diagnostics_last_cursor = current_cursor
    local _, winnr = _G.LspDiagnosticsShowPopup()
    if winnr ~= nil then
      vim.api.nvim_win_set_option(winnr, "winblend", 20)  -- opacity for diagnostics
    end
  end
end
vim.cmd [[
augroup LSPDiagnosticsOnHover
  autocmd!
  autocmd CursorHold *   lua _G.LspDiagnosticsPopupHandler()
augroup END
]]

-- Redefine signs (:help diagnostic-signs)
-- neovim <= 0.5.1
vim.fn.sign_define("LspDiagnosticsSignError",       {text = "✘", texthl = "DiagnosticSignError"})
vim.fn.sign_define("LspDiagnosticsSignWarning",     {text = "", texthl = "DiagnosticSignWarn"})
vim.fn.sign_define("LspDiagnosticsSignInformation", {text = "i", texthl = "DiagnosticSignInfo"})
vim.fn.sign_define("LspDiagnosticsSignHint",        {text = "", texthl = "DiagnosticSignHint"})
-- neovim >= 0.6.0
vim.fn.sign_define("DiagnosticSignError",  {text = "✘", texthl = "DiagnosticSignError"})
vim.fn.sign_define("DiagnosticSignWarn",   {text = "", texthl = "DiagnosticSignWarn"})
vim.fn.sign_define("DiagnosticSignInfo",   {text = "i", texthl = "DiagnosticSignInfo"})
vim.fn.sign_define("DiagnosticSignHint",   {text = "", texthl = "DiagnosticSignHint"})
vim.cmd [[
hi DiagnosticSignError    guifg=#e6645f ctermfg=167
hi DiagnosticSignWarn     guifg=#b1b14d ctermfg=143
hi DiagnosticSignHint     guifg=#3e6e9e ctermfg=75
]]


---------------------------------
-- nvim-cmp: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-cmp#recommended-configuration
-- ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua

vim.o.completeopt = "menu,menuone,noselect"

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line-1, line, true)[1]:sub(col, col):match('%s') == nil
end

local cmp = require('cmp')
cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  },
  documentation = {
    border = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'}  -- in a clockwise order
  },
  mapping = {
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = function(fallback)  -- see GH-231, GH-286
      if cmp.visible() then cmp.select_next_item()
      elseif has_words_before() then cmp.complete()
      else fallback() end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      else fallback() end
    end,
  },
  formatting = {
    format = function(entry, vim_item)
      -- fancy icons and a name of kind
      vim_item.kind = " " .. require("lspkind").presets.default[vim_item.kind] .. " " .. vim_item.kind
      -- set a name for each source (see the sources section below)
      vim_item.menu = ({
        buffer        = "[Buffer]",
        nvim_lsp      = "[LSP]",
        luasnip       = "[LuaSnip]",
        ultisnips     = "[UltiSnips]",
        nvim_lua      = "[Lua]",
        latex_symbols = "[Latex]",
      })[entry.source.name] or string.format("[%s]", entry.source.name)

      if vim_item.menu == "[LSP]" then
        -- Display which LSP servers this item came from.
        pcall(function()
          vim_item.menu = " " .. entry.source.source.client.name
        end)
      end

      return vim_item
    end,
  },
  sources = {
    -- Note: make sure you have proper plugins specified in plugins.vim
    -- https://github.com/topics/nvim-cmp
    { name = 'nvim_lsp', priority = 100 },
    { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
    { name = 'path', priority = 30, },
    { name = 'buffer', priority = 10 },
  },
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      require("cmp-under-comparator").under,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
}

-- Highlights for nvim-cmp's custom popup menu (GH-224)
vim.cmd [[
  " To be compatible with Pmenu (#fff3bf)
  hi CmpItemAbbr           guifg=#111111
  hi CmpItemAbbrMatch      guifg=#f03e3e gui=bold
  hi CmpItemAbbrMatchFuzzy guifg=#fd7e14 gui=bold
  hi CmpItemAbbrDeprecated guifg=#adb5bd
  hi CmpItemKindDefault    guifg=#cc5de8
  hi! def link CmpItemKind CmpItemKindDefault
  hi CmpItemMenu           guifg=#cfa050
]]

-----------------------------
-- Configs for PeekDefinition
-----------------------------
function PeekDefinition()
  local params = vim.lsp.util.make_position_params()
  local definition_callback = function (_, result)
    if result == nil or vim.tbl_isempty(result) then
      print("PeekDefinition: " .. "cannot find the definition.")
      return nil
    end
    --- either Location | LocationLink
    --- https://microsoft.github.io/language-server-protocol/specification#location
    local def_result = result[1]

    -- Peek defintion. Currently, use quickui but a better alternative should be found.
    -- vim.lsp.util.preview_location(result[1])
    local def_uri = def_result.uri or def_result.targetUri
    local def_range = def_result.range or def_result.targetSelectionRange
    vim.fn['quickui#preview#open'](vim.uri_to_fname(def_uri), {
        cursor = def_range.start.line,
        number = 1,   -- show line number
        persist = 0,
      })
  end
  -- Asynchronous request doesn't work very smoothly, so we use synchronous one with timeout;
  -- return vim.lsp.buf_request(0, 'textDocument/definition', params, definition_callback)
  local results, err = vim.lsp.buf_request_sync(0, 'textDocument/definition', params, 1000)
  if results then
    for client_id, result in pairs(results) do
      definition_callback(client_id, result.result)
    end
  else
    print("PeekDefinition: " .. err)
  end
end

vim.cmd [[
  command! -nargs=0 PeekDefinition      :lua PeekDefinition()
  command! -nargs=0 PreviewDefinition   :PeekDefinition
  nmap <leader>K     :<C-U>PeekDefinition<CR>
  nmap <silent> gp   :<C-U>PeekDefinition<CR>
]]


------------
-- LSPstatus
------------
local lsp_status = require('lsp-status')
lsp_status.config({
    -- Avoid using use emoji-like or full-width characters
    -- because it can often break rendering within tmux and some terminals
    -- See ~/.vim/plugged/lsp-status.nvim/lua/lsp-status.lua
    indicator_hint = '!',
    status_symbol = ' ',

    -- If true, automatically sets b:lsp_current_function
    -- (no longer used in favor of treesitter + nvim-gps)
    current_function = false,
})
lsp_status.register_progress()

-- LspStatus(): status string for airline
_G.LspStatus = function()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ''
end

-- :LspStatus (command): display lsp status
vim.cmd [[
command! -nargs=0 LspStatus   echom v:lua.LspStatus()
]]

-- Other LSP commands
vim.cmd [[
command! -nargs=0 LspDebug  :tab drop $HOME/.cache/nvim/lsp.log
]]

-----------------------------------
--- Fidget.nvim (LSP status widget)
-----------------------------------

if pcall(require, 'fidget') then
  -- https://github.com/j-hui/fidget.nvim/blob/main/doc/fidget.md
  -- Note: This will override lsp-status.nvim (progress handlers).
  require("fidget").setup {
    text = {
      --see ~/.vim/plugged/fidget.nvim/lua/fidget/spinners.lua
      spinner = "zip",
    },
    window = {
      relative = "win",
      blend = 50,
    },
  }
end


---------------
-- trouble.nvim
---------------
require("trouble").setup {
    -- https://github.com/folke/trouble.nvim#setup
    mode = "document_diagnostics",
    auto_preview = false,
}


----------------------------------------
-- Formatting, Linting, and Code actions
----------------------------------------
-- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/CONFIG.md
-- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
-- @see ~/.vim/plugged/null-ls.nvim/lua/null-ls/builtins
local executable = function(cmd)
  -- @see BUILTINS.md#conditional-registration
  return function(utils)
    return vim.fn.executable(cmd)
  end
end
if pcall(require, "null-ls") then
  local null_ls = require("null-ls")
  local h = require("null-ls.helpers")

  local _cond = function(cmd, source)
    if vim.fn.executable(cmd) > 0 then return source
    else return nil end
  end
  local _exclude_nil = function(tbl)
    return vim.tbl_filter(function(s) return s ~= nil end, tbl)
  end
  null_ls.setup({
    sources = _exclude_nil {
      -- [[ Auto-Formatting ]]
      -- @python (pip install yapf isort)
      _cond("yapf", null_ls.builtins.formatting.yapf),
      _cond("isort", null_ls.builtins.formatting.isort),
      -- @javascript
      null_ls.builtins.formatting.prettier,

      -- Linting (diagnostics)
      -- @python: pylint, flake8
      _cond("pylint", null_ls.builtins.diagnostics.pylint.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          condition = function(utils)
            -- https://pylint.pycqa.org/en/latest/user_guide/run.html#command-line-options
            return (
              utils.root_has_file("pylintrc") or
              utils.root_has_file(".pylintrc")) or
              utils.root_has_file("setup.cfg")
          end,
        })),
      _cond("flake8", null_ls.builtins.diagnostics.flake8.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          -- Activate when flake8 is available and any project config is found,
          -- per https://flake8.pycqa.org/en/latest/user/configuration.html
          condition = function(utils)
            return (
              utils.root_has_file("setup.cfg") or
              utils.root_has_file("tox.ini") or
              utils.root_has_file(".flake8"))
          end,
          -- Ignore some too aggressive errors (indentation, lambda, etc.)
          -- @see https://pycodestyle.pycqa.org/en/latest/intro.html#error-codes
          extra_args = {"--extend-ignore", "E111,E114,E731"},
          -- Override flake8 diagnostics levels
          -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/issues/538
          on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): ((%u)%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            {
              severities = {
                E = h.diagnostics.severities["warning"], -- Changed to warning!
                W = h.diagnostics.severities["warning"],
                F = h.diagnostics.severities["information"],
                D = h.diagnostics.severities["information"],
                R = h.diagnostics.severities["warning"],
                S = h.diagnostics.severities["warning"],
                I = h.diagnostics.severities["warning"],
                C = h.diagnostics.severities["warning"],
              },
            }),
        })),
    },

    -- Debug mode: Use :NullLsLog for viewing log files (~/.cache/nvim/null-ls.log)
    debug = false,
  })

  -- Commands for LSP formatting. :Format
  -- FormattingOptions: @see https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#formattingOptions
  vim.cmd [[
    command! LspFormatSync        lua vim.lsp.buf.formatting_sync({}, 5000)
    command! -range=0 Format      LspFormat
  ]]

  -- Automatic formatting
  -- see ~/.vim/after/ftplugin/python.vim for filetype use
  vim.cmd [[
    augroup LspAutoFormatting
    augroup END
    command! LspAutoFormattingOn      lua _G.LspAutoFormattingStart()
    command! LspAutoFormattingOff     lua _G.LspAutoFormattingStop()
  ]]
  _G.LspAutoFormattingStart = function ()
    vim.cmd [[
    augroup LspAutoFormatting
      autocmd!
      autocmd BufWritePre *    :lua _G.LspAutoFormattingTrigger()
    augroup END
    ]]
    vim.notify("Lsp Auto-Formatting has been turned on.")
  end
  _G.LspAutoFormattingTrigger = function ()
    -- Disable on some files (e.g., external packages)
    if string.find(vim.fn.bufname(), '/site-packages/') then
      return false
    end
    -- TODO: Enable only on the current project specified by PATH.
    if vim.tbl_count(vim.lsp.buf_get_clients()) > 0 then
      vim.lsp.buf.formatting_sync({}, 1000)
      return true
    end
    return false
  end
  _G.LspAutoFormattingStop = function ()
    vim.cmd [[ autocmd! LspAutoFormatting ]]
    vim.notify("Lsp Auto-Formatting has been turned off.", 'warn')
  end

end   -- if null-ls
