local awful = require('awful')
local wibox = require('wibox')
local vicious = require('vicious')

local graph_width = 30
local graph_height = 30
local graph_interval = 5

local cpu_graph = awful.widget.graph()
cpu_graph:set_width(graph_width)
cpu_graph:set_height(graph_height)
cpu_graph:set_border_color('#2222bb')
cpu_graph:set_color({
	type = "linear",
	from = { 0, 0 },
	to = { 0, 30 },
	stops = {{0, "#FF0000"}, {1, "#0000FF"}}
})

vicious.register(cpu_graph, vicious.widgets.cpu, "$1", graph_interval)

local mem_graph = awful.widget.graph()
mem_graph:set_width(graph_width)
mem_graph:set_height(graph_height)
mem_graph:set_border_color('#22bb22')
mem_graph:set_color({
	type = "linear",
	from = { 0, 0 },
	to = { 0, 30 },
	stops = {{0, "#FF0000"}, {1, "#00FF00"}}
})

vicious.register(mem_graph, vicious.widgets.mem, "$1", graph_interval)

return {
	cpu_graph = cpu_graph,
	mem_graph = mem_graph,
	volume = volume,
}
