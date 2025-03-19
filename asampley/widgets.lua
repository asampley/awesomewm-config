local awful = require('awful')
local wibox = require('wibox')
local vicious = require('vicious')

local cpu_graph = awful.widget.graph()
cpu_graph:set_width(75)
cpu_graph:set_height(30)
cpu_graph:set_border_color('#222222')
cpu_graph:set_color({
	type = "linear",
	from = { 75, 0 },
	to = { 75, 30 },
	stops = {{0, "#FF0000"}, {1, "#00FF00" }}
})

vicious.register(cpu_graph, vicious.widgets.cpu, "$1", 1)

local volume = wibox.widget.textbox()
vicious.register(volume, vicious.widgets.volume, "$1$2", 2, "Master")

return {
	cpu_graph = cpu_graph,
	volume = volume,
}
