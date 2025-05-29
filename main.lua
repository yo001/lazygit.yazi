local permit = nil

local get_hoverd_file = ya.sync(function()
	local hovered = cx.active.current.hovered
	return hovered.url, hovered.cha.is_dir
end)
local function notify(title, content, level, timeout, show_notify)
	if not show_notify then
		return
	end

	ya.notify({
		title = title,
		content = content,
		level = level,
		timeout = timeout or 5,
	})
end

local function run_lazygit(args, show_notify)
	if permit ~= nil then
		permit:drop()
		permit = nil
	end

	permit = ya.hide()
	local output, err_code = Command("lazygit"):arg(args):stderr(Command.PIPED):output()
	if err_code ~= nil then
		notify("Failed to run lazygit command", "Status: " .. err_code, "error", nil, show_notify)
		return false
	elseif not output.status.success then
		notify("lazygit failed, exit code " .. output.status.code, output.stderr, "error", nil, show_notify)
		return false
	end
	return true
end

local function handle_normal(show_notify)
	local output = Command("git"):arg("status"):stderr(Command.PIPED):output()
	if output.stderr ~= "" then
		notify("lazygit", "Not in a git directory", "warn", nil, show_notify)
		return
	end
	return run_lazygit({})
end

local function handle_hover(show_notify)
	local hovered_url, is_dir = get_hoverd_file()
	if hovered_url == nil or not is_dir then
		notify("lazygit", "Not in a directory", "warn", nil, show_notify)
		return
	end
	return run_lazygit({ "-p", tostring(hovered_url) })
end

local function handle_auto(show_notify)
	local output = Command("git"):arg("status"):stderr(Command.PIPED):output()
	if output.stderr ~= "" then
		handle_hover(show_notify)
	else
		handle_normal(show_notify)
	end
end

local function handle_auto_hover_first(show_notify)
	local res = handle_hover(false)
	if not res then
		handle_normal(show_notify)
	end
end

return {
	entry = function(_, job)
		if job.args[1] == "hover" then
			handle_hover(true)
		elseif job.args[1] == "auto" then
			handle_auto(true)
		elseif job.args[1] == "auto_hover_first" then
			handle_auto_hover_first(true)
		else
			handle_normal(true)
		end
	end,
}
