local shared_utils = require('code_action_menu.shared_utils')
local MenuWindow = require('code_action_menu.windows.menu_window')
local DetailsWindow = require('code_action_menu.windows.details_window')
local DiffWindow = require('code_action_menu.windows.diff_window')
local WarningMessageWindow = require('code_action_menu.windows.warning_message_window')

local menu_window_instance = nil
local details_window_instance = nil
local diff_window_instance = nil
local warning_message_window_instace = nil

local function close_code_action_menu()
  if details_window_instance ~= nil then
    details_window_instance:close()
    details_window_instance = nil
  end

  if diff_window_instance ~= nil then
    diff_window_instance:close()
    diff_window_instance = nil
  end

  if menu_window_instance ~= nil then
    menu_window_instance:close()
    menu_window_instance = nil
  end
end

local function close_warning_message_window()
  if warning_message_window_instace ~= nil then
    warning_message_window_instace:close()
    warning_message_window_instace = nil
  end
end

local function open_code_action_menu()
  -- Might still be open.
  close_code_action_menu()
  close_warning_message_window()

  local use_range = vim.api.nvim_get_mode().mode ~= 'n'
  local all_actions = shared_utils.request_servers_for_actions(use_range)

  if #all_actions == 0 then
    warning_message_window_instace = WarningMessageWindow:new()
    warning_message_window_instace:open()
    vim.api.nvim_command('autocmd! CursorMoved <buffer> ++once lua require("code_action_menu").close_warning_message_window()')
  else
    menu_window_instance = MenuWindow:new(all_actions)
    menu_window_instance:open()
  end
end

local function update_selected_action()
  local selected_action = menu_window_instance:get_selected_action()

  if details_window_instance == nil then
    details_window_instance = DetailsWindow:new(selected_action)
  else
    details_window_instance:set_action(selected_action)
  end

  details_window_instance:open({ window_to_dock_on = menu_window_instance.window_number })

  if diff_window_instance == nil then
    diff_window_instance = DiffWindow:new(selected_action)
  else
    diff_window_instance:set_action(selected_action)
  end

  diff_window_instance:open({ window_to_dock_on = details_window_instance.window_number })
end

local function execute_selected_action()
  local selected_action = menu_window_instance:get_selected_action()

  if selected_action:is_disabled() then
    vim.api.nvim_notify('Can not execute disabled action!', vim.log.levels.ERROR, {})
  else
    close_code_action_menu() -- Close first to execute the action in the correct buffer.
    selected_action:execute()
  end
end

local function select_line_and_execute_action(line_number)
  vim.validate({['to select menu line number'] = { line_number, 'number' }})

  vim.api.nvim_win_set_cursor(menu_window_instance.window_number, { line_number, 0 })
  execute_selected_action()
end

return {
  open_code_action_menu = open_code_action_menu,
  update_selected_action = update_selected_action,
  close_code_action_menu = close_code_action_menu,
  close_warning_message_window = close_warning_message_window,
  execute_selected_action = execute_selected_action,
  select_line_and_execute_action = select_line_and_execute_action,
}
