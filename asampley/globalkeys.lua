local asampley = require('asampley')
local modkey = asampley.modkey

local awful = require('awful')
local gears = require('gears')
local menubar = require('menubar')
local naughty = require('naughty')

local sharedtags = require("sharedtags")
local xrandr = require("xrandr")

local undetected = function() naughty.notify { text = "Attempted to run undetected command" } end
local map_any_command = function(commands, default)
	local found = false

	for command,v in pairs(commands) do
		if os.execute("command -v '" .. command .. "'") then
			return v
		end
	end

	local text = ""

	for command,_ in pairs(commands) do
		text = text .. " '" .. command .. "'"
	end

	naughty.notify {
		preset = naughty.config.presets.critical,
		title = "Expecting at least one of these commands",
		text = text,
	}
	
	return default
end

local commands = {
	volume = {
		up = undetected,
		down = undetected,
		mute = undetected,
	},
	power = {
		poweroff = undetected,
		suspend = undetected,
		hibernate = undetected,
		restart = undetected,
	},
	screenshot = undetected
}

-- Set up locking which is handled in other desktop environments
local lock = map_any_command {
	["xss-lock"] = map_any_command({
		slock = "slock",
		i3lock = "i3lock -n",
	}, false),
}

if lock then awful.util.spawn("xss-lock -- " .. lock) end

local screenshot_directory = os.getenv("HOME").."/Pictures/Screenshots"
os.execute("mkdir -p '"..screenshot_directory.."'")

commands.volume = map_any_command {
	pactl = {
		up = function() awful.util.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false) end,
		down = function() awful.util.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false) end,
		mute = function() awful.util.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false) end,
	},
	amixer = {
		up = function() awful.util.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false) end,
		down = function() awful.util.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false) end,
		mute = function() awful.util.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false) end,
	},
} or commands.volume

map_any_command({
	systemctl = function()
		commands.power.poweroff = function() awful.spawn { "systemctl", "poweroff" } end
		commands.power.restart = function() awful.spawn { "systemctl", "reboot" } end
		map_any_command({
			loginctl = function()
				commands.power.suspend = function() awful.spawn.with_shell("loginctl lock-session && systemctl suspend") end
				commands.power.hibernate = function() awful.spawn("loginctl lock-session && systemctl hibernate") end
			end
		}, function() end)()
	end
}, function() end)()

map_any_command({
	scrot = function()
		local scrot = function(opts)
			local ret = "scrot"

			if opts.selection then ret = ret.." -s" end
			if opts.clipboard then
				ret = ret.." - | xclip -selection clipboard -t image/png"
			else
				ret = ret.." '"..screenshot_directory.."/%FT%T"..".png'"
			end

			naughty.notify({ text = ret })

			return ret
		end

		commands.screenshot = function(opts) awful.spawn.with_shell(scrot(opts)) end

		if not os.execute("command -v xclip") then
			local _old = commands.screenshot

			commands.screenshot = function(opts)
				if opts.clipboard then
					return undetected()
				else
					return _old(opts)
				end
			end
		end
	end
})()

local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local globalkeys = gears.table.join(
	awful.key({ modkey, "Control" }, "p",
		function()
			awful.prompt.run {
				prompt       = '<b>(P)oweroff, (R)estart, (S)uspend, (H)ibernate, (L)ock: </b>',
				--bg_cursor    = '#ff0000',
				textbox      = awful.screen.focused().mypromptbox.widget,
				exe_callback = function(input)
					if not input or #input == 0 then return end

					local mode = input:sub(1, 1):lower()
					if mode == 'p' then commands.power.poweroff();
					elseif mode == 's' then commands.power.suspend();
					elseif mode == 'h' then commands.power.hibernate();
					elseif mode == 'r' then commands.power.restart();
					elseif mode == 'l' then awful.spawn { 'loginctl', 'lock-session' }
					else naughty.notify { text = 'Unknown shutdown method "' .. input .. '"' }
					end
				end
			}
		end,
		{ description = "power options", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "/", hotkeys_popup.show_help,
		{ description = "show help", group = "awesome" }),
	awful.key({ modkey, }, "Left", awful.tag.viewprev,
		{ description = "view previous", group = "tag" }),
	awful.key({ modkey, }, "Right", awful.tag.viewnext,
		{ description = "view next", group = "tag" }),
	awful.key({ modkey, }, "Escape", awful.tag.history.restore,
		{ description = "go back", group = "tag" }),

	awful.key({ modkey, }, "j",
		function()
			awful.client.focus.byidx(1)
		end,
		{ description = "focus next by index", group = "client" }
	),
	awful.key({ modkey, }, "k",
		function()
			awful.client.focus.byidx(-1)
		end,
		{ description = "focus previous by index", group = "client" }
	),
	awful.key({ modkey, }, "w", function() MY_MAIN_MENU:show() end,
		{ description = "show main menu", group = "awesome" }),

	-- Layout manipulation
	awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx(1) end,
		{ description = "swap with next client by index", group = "client" }),
	awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end,
		{ description = "swap with previous client by index", group = "client" }),
	awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative(1) end,
		{ description = "focus the next screen", group = "screen" }),
	awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end,
		{ description = "focus the previous screen", group = "screen" }),
	awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
		{ description = "jump to urgent client", group = "client" }),
	awful.key({ modkey, }, "Tab",
		function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end,
		{ description = "go back", group = "client" }),

	-- Standard program
	awful.key({ modkey, }, "Return", function() awful.spawn(TERMINAL) end,
		{ description = "open a terminal", group = "launcher" }),
	awful.key({ modkey, "Control" }, "r", awesome.restart,
		{ description = "reload awesome", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "q", awesome.quit,
		{ description = "quit awesome", group = "awesome" }),
	awful.key({ modkey, }, "l", function() awful.tag.incmwfact(0.05) end,
		{ description = "increase master width factor", group = "layout" }),
	awful.key({ modkey, }, "h", function() awful.tag.incmwfact(-0.05) end,
		{ description = "decrease master width factor", group = "layout" }),
	awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end,
		{ description = "increase the number of master clients", group = "layout" }),
	awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
		{ description = "decrease the number of master clients", group = "layout" }),
	awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1, nil, true) end,
		{ description = "increase the number of columns", group = "layout" }),
	awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end,
		{ description = "decrease the number of columns", group = "layout" }),
	awful.key({ modkey, }, "space", function() awful.layout.inc(1) end,
		{ description = "select next", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end,
		{ description = "select previous", group = "layout" }),

	awful.key({ modkey, "Control" }, "n",
		function()
			local c = awful.client.restore()
			-- Focus restored client
			if c then
				c:emit_signal(
					"request::activate", "key.unminimize", { raise = true }
				)
			end
		end,
		{ description = "restore minimized", group = "client" }),

	-- Prompt
	awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
		{ description = "run prompt", group = "launcher" }),

	awful.key({ modkey }, "x",
		function()
			awful.prompt.run {
				prompt       = "Run Lua code: ",
				textbox      = awful.screen.focused().mypromptbox.widget,
				exe_callback = awful.util.eval,
				history_path = awful.util.get_cache_dir() .. "/history_eval"
			}
		end,
		{ description = "lua execute prompt", group = "awesome" }),
	-- Menubar
	awful.key({ modkey }, "p", function() menubar.show() end,
		{ description = "show the menubar", group = "launcher" }),

	-- audio
	awful.key({}, "XF86AudioRaiseVolume", commands.volume.up),
	awful.key({}, "XF86AudioLowerVolume", commands.volume.down),
	awful.key({}, "XF86AudioMute", commands.volume.mute),

	-- screenshot
	awful.key({ modkey,                    }, "s", function() commands.screenshot { } end,
		{ description = "take screenshot", group = "screenshot" }),
	awful.key({ modkey,            "Shift" }, "s", function() commands.screenshot { selection = true } end,
		{ description = "take screenshot of selection", group = "screenshot" }),
	awful.key({ modkey, "Control"          }, "s", function() commands.screenshot { clipboard = true } end,
		{ description = "take screenshot to clipboard", group = "screenshot" }),
	awful.key({ modkey, "Control", "Shift" }, "s", function() commands.screenshot { clipboard = true, selection = true } end,
		{ description = "take screenshot of selection to clipboard", group = "screenshot" }),

	-- xrandr
	awful.key({ modkey, "Control", "Shift" }, "d", xrandr.xrandr)
)

-- Bind all key numbers to tags.
for i, t in ipairs(asampley.tags) do
	local key = t.key
	local name = t.name

	globalkeys = gears.table.join(globalkeys,
		-- View tag only.
		awful.key({ modkey }, key,
			function()
				local screen = awful.screen.focused()
				sharedtags.viewonly(t, screen)
			end,
			{ description = "view tag " .. name, group = "tag" }),
		-- Toggle tag display.
		awful.key({ modkey, "Shift" }, key,
			function()
				local screen = awful.screen.focused()
				sharedtags.viewtoggle(t, screen)
			end,
			{ description = "toggle tag #" .. i, group = "tag" }),
		-- Move client to tag.
		awful.key({ modkey, "Control" }, key,
			function()
				if client.focus then
					client.focus:move_to_tag(t)
				end
			end,
			{ description = "move focused client to tag " .. name, group = "tag" }),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, key,
			function()
				if client.focus then
					client.focus:toggle_tag(t)
				end
			end,
			{ description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

return globalkeys
