-- NixOS uses system-provided LSP binaries and formatters.
-- Mason is disabled to prevent Mason from attempting to download incompatible FHS binaries.
return {
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
}
