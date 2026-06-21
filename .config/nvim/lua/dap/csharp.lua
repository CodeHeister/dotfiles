local dap = require("dap")

dap.adapters.coreclr = {
  type = 'executable',
  command = '/usr/bin/netcoredbg',
  args = { '--interpreter=vscode' }
}

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Auto-launch .NET Core",
    request = "launch",
	program = function()
	  local cwd = vim.fn.getcwd()

	  -- Найти .csproj
	  local csproj_files = vim.fn.globpath(cwd, "*.csproj", false, true)
	  if #csproj_files == 0 then
		error("Файл .csproj не найден в текущей директории: " .. cwd)
	  end

	  -- Используем имя проекта из .csproj
	  local csproj_path = csproj_files[1]
	  local project_name = vim.fn.fnamemodify(csproj_path, ":t:r") -- имя без .csproj

	  -- Путь к Debug-сборкам
	  local debug_dir = cwd .. "/bin/Debug"
	  local net_versions = vim.fn.globpath(debug_dir, "*", false, true)

	  if #net_versions == 0 then
		error("Сборки Debug не найдены. Выполни: dotnet build -c Debug")
	  end

	  -- Берём самую последнюю (после сортировки)
	  table.sort(net_versions)
	  local latest_version = net_versions[#net_versions]

	  -- Собираем путь к DLL
	  local dll_path = latest_version .. "/" .. project_name .. ".dll"
	  if vim.fn.filereadable(dll_path) == 0 then
		error("Не найден .dll файл: " .. dll_path)
	  end

	  return dll_path
	end
  },
 {
    type = "coreclr",
    name = "Attach to process",
    request = "attach",
    processId = function()
      local output = vim.fn.system('ps -ef | grep dotnet | grep -v grep')
      local processes = {}
      for line in output:gmatch("[^\r\n]+") do
        local pid = line:match("%s(%d+)%s")
        if pid then table.insert(processes, pid) end
      end
      if #processes == 0 then
        print("No dotnet processes found")
        return nil
      end
      local choice = vim.fn.input("Choose PID: " .. table.concat(processes, ", ") .. ": ")
      return tonumber(choice)
    end,
  },
}
