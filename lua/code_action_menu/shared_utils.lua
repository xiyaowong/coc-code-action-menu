local Command = require('code_action_menu.lsp_objects.actions.command')
local CodeAction = require('code_action_menu.lsp_objects.actions.code_action')

local function get_buffer_width(buffer_number)
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  local longest_line = ''

  for _, line in ipairs(buffer_lines) do
    if #line > #longest_line then
      longest_line = line
    end
  end

  return #longest_line
end

local function get_buffer_height(buffer_number)
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  return #buffer_lines
end

local function is_buffer_empty(buffer_number)
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  return #buffer_lines == 0 or (#buffer_lines == 1 and #buffer_lines[1] == 0)
end

local function request_servers_for_actions(mode, cb)
  if not cb then
    local all_actions = {}

    for _, data in ipairs(vim.fn.CocAction('codeActions', mode)) do
      local action

      if type(data.edit) == 'table' or type(data.command) == 'table' then
        action = CodeAction:new(data)
      else
        action = Command:new(data)
      end

      table.insert(all_actions, action)
    end

    return all_actions
  else
    vim.fn.CocActionAsync('codeActions', mode, function(err, res)
      if err ~= vim.NIL then
        return
      end

      local all_actions = {}

      for _, data in ipairs(res) do
        local action

        if type(data.edit) == 'table' or type(data.command) == 'table' then
          action = CodeAction:new(data)
        else
          action = Command:new(data)
        end

        table.insert(all_actions, action)
      end

      cb(all_actions)
    end)
  end
end

local function order_actions(action_table, key_a, key_b)
  local action_a = action_table[key_a]
  local action_b = action_table[key_b]

  if action_b:is_preferred() and not action_a:is_preferred() then
    return false
  elseif action_a:is_disabled() and not action_b:is_disabled() then
    return false
  else
    -- Ordering function needs to return `true` at some point for every element.
    return key_a < key_b
  end
end

local function get_ordered_action_table_keys(action_table)
  vim.validate({ ['action table to sort'] = { action_table, 'table' } })
  local keys = {}

  for key in pairs(action_table) do
    local index = #keys + 1
    keys[index] = key
  end

  table.sort(keys, function(key_a, key_b)
    return order_actions(action_table, key_a, key_b)
  end)

  return keys
end

-- Put preferred actions at start, disabled at end
local function iterate_actions_ordered(action_table)
  vim.validate({ ['actions to sort'] = { action_table, 'table' } })

  local keys = get_ordered_action_table_keys(action_table)
  local index = 0

  return function()
    index = index + 1

    if keys[index] then
      return index, action_table[keys[index]]
    end
  end
end

local function get_action_at_index_ordered(action_table, index)
  vim.validate({ ['actions to sort'] = { action_table, 'table' } })

  local keys = get_ordered_action_table_keys(action_table)
  local key_for_index = keys[index]
  return action_table[key_for_index]
end

return {
  get_buffer_width = get_buffer_width,
  get_buffer_height = get_buffer_height,
  is_buffer_empty = is_buffer_empty,
  request_servers_for_actions = request_servers_for_actions,
  iterate_actions_ordered = iterate_actions_ordered,
  get_action_at_index_ordered = get_action_at_index_ordered,
}
