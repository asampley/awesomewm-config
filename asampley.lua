local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Start gtk settings to enable dark mode, etc.
awful.spawn{'/usr/libexec/gsd-xsettings'}

-- Start autostart programs from xdg spec
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart'
)

if not beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/tinted_theming.lua") then
	beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/default.lua")
end

return setmetatable(
    {}, {
        -- load submodules lazily to let this be requiredRand allow access to submodules
        __index = function(_, key)
            return require('asampley.'..key)
        end
    }
)
