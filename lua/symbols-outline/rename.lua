local vim = vim

local state = require('symbols-outline').state

local M = {}

local function get_rename_params(node, winnr)
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local fn = "file://" .. vim.api.nvim_buf_get_name(bufnr)

    return {
        textDocument = {uri = fn},
        position = {line = node.line, character = node.character},
        bufnr = bufnr
    }
end

function M.rename()
    local current_line = vim.api.nvim_win_get_cursor(state.outline_win)[1]
    local node = state.flattened_outline_items[current_line]

    local params = get_rename_params(node, state.code_win)

    local new_name = vim.fn.input("New Name: ", node.name)
    if not new_name or new_name == "" or new_name == node.name then return end

    params.newName = new_name

    vim.lsp.buf_request(params.bufnr, "textDocument/rename", params,
                        function(_, _, result)
        if result ~= nil then
            vim.lsp.util.apply_workspace_edit(result)
        end
    end)
    -- kind of a hack but we want the state to always be the latest, so unload
    -- this module for the next time it is called its gonna be F R E S H
    package.loaded["symbols-outline.rename"] = nil
end

return M
