local M = {}

local parse_script = require'script_parsing'

M.setup = function (opts)
    -- Do nothing
end

local function open_window()
    local buf_id = vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(buf_id, true, {
        relative = 'editor',
        width = vim.o.columns,
        height = vim.o.lines - 1,
        row = 0,
        col = 0,
    })

    return { buf = buf_id, win = win_id }
end

M.start_practice = function (opts)
    opts = opts or {}
    opts.bufnr = opts.bufnr or 0

    local scripts = parse_script({bufnr = opts.bufnr})

    local state = open_window()

    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, scripts.roles)
end

return M
