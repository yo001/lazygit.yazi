local get_hoverd_file = ya.sync(function()
	local hovered = cx.active.current.hovered
	return hovered.url, hovered.cha.is_dir
end)
local function notify(title, content, level, timeout)
	ya.notify({
		title = title,
		content = content,
		level = level,
		timeout = timeout or 5,
	})
end

local function run_lazygit(args)
	permit = ya.hide()
	local output, err_code = Command("lazygit"):args(args):stderr(Command.PIPED):output()
	if err_code ~= nil then
		notify("Failed to run lazygit command", "Status: " .. err_code, "error")
		return false
	elseif not output.status.success then
		notify("lazygit failed, exit code " .. output.status.code, output.stderr, "error")
		return false
	end
	return true
end

local function handle_normal(show_notify)
	local output = Command("git"):arg("status"):stderr(Command.PIPED):output()
	if output.stderr ~= "" and show_notify then
		notify("lazygit", "Not in a git directory", "warn")
		return
	end
	run_lazygit({})
end

local function handle_hover(show_notify)
	local hovered_url, is_dir = get_hoverd_file()
	if (hovered_url == nil or not is_dir) and show_notify then
		notify("lazygit", "Not in a directory", "warn")
		return
	end
	run_lazygit({ "-p", tostring(hovered_url) })
end

local function handle_auto(show_notify)
	local output = Command("git"):arg("status"):stderr(Command.PIPED):output()
	if output.stderr ~= "" then
		handle_hover(show_notify)
	else
		handle_normal(show_notify)
	end
end

return {
	entry = function(_, job)
		if job.args[1] == "hover" then
			handle_hover(true)
		elseif job.args[1] == "auto" then
			handle_auto(true)
		else
			handle_normal(true)
		end
	end,
}
