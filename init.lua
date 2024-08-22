local get_hoverd_file = ya.sync(function()
    local hovered = cx.active.current.hovered
    return hovered.url, hovered.cha.is_dir
end)

return {
    entry = function(_, args)
        if tostring(args[1]) == "hover" then
            local hovered_url, is_dir = get_hoverd_file()
            if hovered_url == nil or not is_dir then
                ya.notify({
                    title = "lazygit",
                    content = "Not in a directory",
                    level = "warn",
                    timeout = 5,
                })
                return
            end
            permit = ya.hide()
            local lg_output, err_code = Command("lazygit")
                :arg("-p")
                :arg(tostring(hovered_url))
                :stderr(Command.PIPED)
                :output()
            if err_code ~= nil then
                ya.notify({
                    title = "Failed to run lazygit command",
                    content = "Status: " .. err_code,
                    level = "error",
                    timeout = 5,
                })
                return
            end
            if not lg_output.status.success then
                ya.notify({
                    title = "lazygit in " .. hovered_url .. " failed, exit code " .. lg_output.status.code,
                    content = lg_output.stderr,
                    level = "error",
                    timeout = 5,
                })
                return
            end
        else
          local output = Command("git"):arg("status"):stderr(Command.PIPED):output()
          if output.stderr ~= "" then
              ya.notify({
                  title = "lazygit",
                  content = "Not in a git directory",
                  level = "warn",
                  timeout = 5,
              })
          else
              permit = ya.hide()
              local output, err_code = Command("lazygit"):stderr(Command.PIPED):output()
              if err_code ~= nil then
                  ya.notify({
                      title = "Failed to run lazygit command",
                      content = "Status: " .. err_code,
                      level = "error",
                      timeout = 5,
                  })
              elseif not output.status.success then
                  ya.notify({
                      title = "lazygit in" .. cwd .. "failed, exit code " .. output.status.code,
                      content = output.stderr,
                      level = "error",
                      timeout = 5,
                  })
              end
          end
        end
    end,
}