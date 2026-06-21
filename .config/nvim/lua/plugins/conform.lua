return {
    "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                php = { "php_cs_fixer" }
            },
            format_on_save = {
                timeout_ms = 500,
            }
        })
    end
}
