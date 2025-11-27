local function get_workspace_settings(root_dir, config_file_path)
  local settings_path = root_dir .. config_file_path

  if vim.fn.filereadable(settings_path) then
    local settings_lines = vim.fn.readfile(settings_path)
    local content = table.concat(settings_lines, "\n")
    local isOk, projectSettings = pcall(vim.json.decode, content)

    if isOk then
      return projectSettings
    else
      vim.notify("Config files doesn't exists or is invalid: " .. config_file_path, vim.log.levels.INFO)
      return {}
    end
  end
end

return {
  get_workspace_settings = get_workspace_settings,
}
