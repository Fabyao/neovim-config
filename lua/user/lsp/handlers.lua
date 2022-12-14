local M = {}

local status_cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_cmp_ok then
	return
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = false
M.capabilities = cmp_nvim_lsp.update_capabilities(M.capabilities)

M.setup = function()
	local signs = {

		{ name = "DiagnosticSignError", text = "" },
		{ name = "DiagnosticSignWarn", text = "" },
		{ name = "DiagnosticSignHint", text = "" },
		{ name = "DiagnosticSignInfo", text = "" },
	}

	for _, sign in ipairs(signs) do
		vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
	end

	local config = {
		virtual_text = false, -- disable virtual text
		signs = {
			active = signs, -- show signs
		},
		update_in_insert = true,
		underline = true,
		severity_sort = true,
		float = {
			focusable = true,
			style = "minimal",
			border = "rounded",
			source = "if_many",
			header = "",
			prefix = "",
		},
	}

	vim.diagnostic.config(config)

	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "rounded",
	})

	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border = "rounded",
	})
end

-- ILLUMINATE SECTION
local illuminate_status_ok, illuminate = pcall(require, "illuminate")
local function lsp_highlight_document(client)
	if not illuminate_status_ok then
		return
	end
	illuminate.on_attach(client)
	-- end
end

-- INLAY HINT SECTION
local status_lsp_inlayhints_ok, lsp_inlayhints = pcall(require, "lsp-inlayhints")
local function lsp_inlayhints_document(bufnr, client)
	if not status_lsp_inlayhints_ok then
		return
	end
	lsp_inlayhints.on_attach(bufnr, client)
	-- end
end

-- FORMAT ONE SAVE HINT SECTION
local is_format_on_save_active = false
local function lsp_enable_format_save()
	if not is_format_on_save_active then
		M.enable_format_on_save()
		is_format_on_save_active = true
	end
end

local function eslint_format_on_save()
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = { "*.tsx", "*.ts", "*.jsx", "*.js" },
		command = "silent! EslintFixAll",
		group = vim.api.nvim_create_augroup("eslint_format_on_save", {}),
	})
	vim.notify("Eslint format on save enabled")
end

local function lsp_keymaps(bufnr)
	local opts = { noremap = true, silent = true }
	local keymap = vim.api.nvim_buf_set_keymap
	keymap(bufnr, "n", "gD", "<cmd>Telescope lsp_declarations<CR>", opts)
	keymap(bufnr, "n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
	keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	keymap(bufnr, "n", "gI", "<cmd>Telescope lsp_implementations<CR>", opts)
	keymap(bufnr, "n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
	keymap(bufnr, "n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	vim.cmd([[ command! Format execute 'lua vim.lsp.buf.format({ async = true }) ' ]])
	keymap(bufnr, "n", "<leader>lf", "<cmd>Format<cr>", opts)
	keymap(bufnr, "n", "<leader>li", "<cmd>LspInfo<cr>", opts)
	keymap(bufnr, "n", "<leader>lI", "<cmd>LspInstallInfo<cr>", opts)
	keymap(bufnr, "n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
	keymap(bufnr, "n", "<leader>lj", "<cmd>lua vim.diagnostic.goto_next({buffer=0})<cr>", opts)
	keymap(bufnr, "n", "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>", opts)
	keymap(bufnr, "n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
	keymap(bufnr, "n", "<leader>ls", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	keymap(bufnr, "n", "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
end

M.on_attach = function(client, bufnr)
	if client.name == "tsserver" then
		lsp_keymaps(bufnr)
		lsp_highlight_document(client)

		client.server_capabilities.document_formatting = false
		client.server_capabilities.document_range_formatting = false
		client.server_capabilities.documentFormattingProvider = false
		lsp_inlayhints_document(bufnr, client)
		lsp_enable_format_save()
		return
	end

	if client.name == "angularls" then
		lsp_keymaps(bufnr)
		lsp_highlight_document(client)

		client.server_capabilities.document_formatting = false
		client.server_capabilities.document_range_formatting = false
		client.server_capabilities.documentFormattingProvider = false
		lsp_inlayhints_document(bufnr, client)
		lsp_enable_format_save()
		return
	end
	if client.name == "eslint" then
		eslint_format_on_save()
	end
end

function M.enable_format_on_save()
	vim.cmd([[
    augroup format_on_save
      autocmd! 
      autocmd BufWritePre * lua vim.lsp.buf.format({ async = false }) 
    augroup end
  ]])
	vim.notify("Enabled format on save")
end

function M.disable_format_on_save()
	M.remove_augroup("format_on_save")
	vim.notify("Disabled format on save")
end

function M.toggle_format_on_save()
	if vim.fn.exists("#format_on_save#BufWritePre") == 0 then
		M.enable_format_on_save()
	else
		M.disable_format_on_save()
	end
end

function M.remove_augroup(name)
	if vim.fn.exists("#" .. name) == 1 then
		vim.cmd("au! " .. name)
	end
end

vim.cmd([[ command! LspToggleAutoFormat execute 'lua require("user.lsp.handlers").toggle_format_on_save()' ]])

return M
