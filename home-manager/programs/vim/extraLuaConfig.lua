vim.opt.runtimepath:append("/home/gabriela/projects/quint/tree-sitter-quint/queries")
vim.treesitter.language.add('quint', { path = "/home/gabriela/projects/quint/tree-sitter-quint/quint.so" })

require'nvim-treesitter.configs'.setup {
  indent = {
    enable = true
  }
}
