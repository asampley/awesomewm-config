local awful = require("awful")
local gears = require("gears")
local sharedtags = require("sharedtags")

return sharedtags(gears.table.map(
	function(tag)
		tag.layout = awful.layout.layouts[1]
		return tag
	end,
	{
		{ name = "1", key = "1" },
		{ name = "2", key = "2" },
		{ name = "3", key = "3" },
		{ name = "4", key = "4" },
		{ name = "5", key = "5" },
		{ name = "6", key = "6" },
		{ name = "7", key = "7" },
		{ name = "8", key = "8" },
		{ name = "9", key = "9" },
		{ name = "0", key = "0" },
	}
))

