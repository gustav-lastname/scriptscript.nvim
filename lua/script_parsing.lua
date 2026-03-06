---@class scripts.Part
---@field type? 'action'|'line'
---@field roles? string[]
---@field content? string

---@class scripts.Scene
---@field name? string
---@field parts? scripts.Part[]
---@field roles? string[]

---@class scripts.Script
---@field name? string
---@field scenes? scripts.Scene[]
---@field roles? string[]

---@class scripts.Scripts
---@field scripts scripts.Script[]
---@field roles string[]

--- Add a role to scene, script or script collection
---@param role string
---@param container scripts.Scene|scripts.Script|scripts.Scripts
local function add_role(role, container)
    for _, exicting_role in ipairs(container.roles) do
        if exicting_role == role then return end
    end

    table.insert(container.roles, role)
end

---Parse a line header
---@param line string
---@return scripts.Part
local function parse_line(line)
    -- Trim h3 markdown
    line = line:sub(5)

    local part = { type = 'line', roles = {} }

    -- Extract potential action
    local action_start = line:find("*")
    if action_start then
        part.content = line:sub(action_start, line:find("*", action_start + 1))
        line = line:sub(1, action_start - 2)
    else
        part.content = ""
    end

    -- Add all roles
    local role_sep_point = line:find("+")
    while role_sep_point do
        table.insert(part.roles, line:sub(1, role_sep_point - 1))
        line = line:sub(role_sep_point + 1)
        role_sep_point = line:find("+")
    end
    table.insert(part.roles, line)

    return part
end

---Take a buffer and pare it
---@param opts { bufnr : number }
---@return scripts.Scripts
local function parse_script(opts)
    opts = opts or {}
    opts.bufnr = opts.bufnr or 0

    ---@type scripts.Scripts
    local scripts = {
        scripts = {},
        roles = {},
    }

    ---@type string[]
    local rows = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)

    ---@type scripts.Script
    local current_script = {}

    ---@type scripts.Scene
    local current_scene = {}

    ---@type scripts.Part
    local current_part

    vim.print(rows)

    for _, row in ipairs(rows) do
        if row ~= "" then
            if row:find("^# ") then                                         -- Script header
                current_script = {
                    name = row:sub(3),
                    scenes = {},
                    roles = {}
                }

                table.insert(scripts.scripts, current_script)

            elseif row:find("^## ") then                                    -- Scene header
                current_scene = {
                    name = row:sub(4),
                    parts = {},
                    roles = {}
                }

                table.insert(current_script.scenes, current_scene)

            elseif row:find("^*[^*]") then                                  -- Action row
                current_part = { type = 'action', content = row:sub(2, #row-1) }

                table.insert(current_scene.parts, current_part)

            elseif row:find("^### ") then                                   -- Line header
                current_part = parse_line(row)

                table.insert(current_scene.parts, current_part)

                for _, role in ipairs(current_part.roles) do
                    add_role(role, current_scene)
                end

            elseif current_part.type == 'line' then                         -- Line content
                local required_newline = current_part.content~="" and '\n' or ''
                current_part.content = current_part.content..required_newline..row
            end
        end
    end

    -- Populate role fields in scripts and script collections
    for _, script in ipairs(scripts.scripts) do
        for _, scene in ipairs(script.scenes) do
            for _, role in ipairs(scene.roles) do
                add_role(role, script)
            end
        end

        for _, role in ipairs(script.roles) do
            add_role(role, scripts)
        end
    end

    return scripts
end

return parse_script
