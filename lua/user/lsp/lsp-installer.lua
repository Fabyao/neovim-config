local status_ok, mason = pcall(require, "mason")
if not status_ok then
  return
end

local status_ok_1, mason_lspconfig = pcall(require, "mason-lspconfig")
if not status_ok_1 then
  return
end

local servers = {  
  "angularls",
  "sumneko_lua",
  "cssls",
  "html",
  "tsserver",
  "rust_analyzer",   
}


local settings = {
  ui = {
    border = "rounded",
    icons = {
      package_installed = "◍",
      package_pending = "◍",
      package_uninstalled = "◍",
    },
  },
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
}

mason.setup(settings)
mason_lspconfig.setup {
  --ensure_installed = servers,
  automatic_installation = false,
}

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
  return
end

local opts = {}

local currentDir = vim.fn.getcwd()

 for _, server in pairs(servers) do
   opts = {
     on_attach = require("user.lsp.handlers").on_attach,
     capabilities = require("user.lsp.handlers").capabilities,
   }

   server = vim.split(server, "@")[1]

   if server == "angularls" then
     if string.find(currentDir, "Projects/cactus") then
      goto continue
     end
     local angularls_opts = require "user.lsp.settings.angularls"
     opts = vim.tbl_deep_extend("force", angularls_opts, opts)
   end  

   if server == "tsserver" then   
    local tsserver_opts = require "user.lsp.settings.tsserver"
    opts = vim.tbl_deep_extend("force", tsserver_opts, opts)
   end

   if server == "sumneko_lua" then
     local sumneko_opts = require "user.lsp.settings.sumneko_lua"
     opts = vim.tbl_deep_extend("force", sumneko_opts, opts)
   end

   if server == "rust_analyzer" then
    local rust_opts = require "user.lsp.settings.rust"
    -- opts = vim.tbl_deep_extend("force", rust_opts, opts)
    local rust_tools_status_ok, rust_tools = pcall(require, "rust-tools")
    if not rust_tools_status_ok then
      return
    end

    rust_tools.setup(rust_opts)
    goto continue
  end   

   lspconfig[server].setup(opts)
   ::continue::
 end

