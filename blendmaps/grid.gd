extends Node

const map_width = 1024
const map_height = 1024
var cell_size = 8
func get_grid_w():
	return int((map_width - 1)/ cell_size + 1)
func get_grid_h():
	return int((map_height - 1)/ cell_size + 1)
func calc_cell_size(mesh):
	while cell_size < 128:
		var gdata = []
		gdata.resize(get_grid_h() * get_grid_w())
		for k in range(gdata.size()):
			gdata[k] = 0
		print("size: ", gdata.size())
		var t = MeshDataTool.new()
		var orig_cell_pos = -1
		t.create_from_surface(mesh, 0)
		var count = 0
		for k in range(t.get_vertex_count()):
			var uv = t.get_vertex_uv(k)
			var x = uv.x * map_width
			var y = uv.y * map_height
			var cell_pos = get_cell_pos(x, y)
			gdata[cell_pos] += 1
		var ok = true
		for k in gdata:
			if k > 0 && k < 3:
				cell_size += 1
				print("call_size: ", cell_size)
				ok = false
				break
		if ok:
			break
	
func build_grid(mesh):
	calc_cell_size(mesh)
	var grid = []
	var grid_w = get_grid_w()
	var grid_h = get_grid_h()
	grid.resize(grid_h * grid_w)
	for k in range(grid.size()):
		grid[k] = []
	var t = MeshDataTool.new()
	t.create_from_surface(mesh, 0)
	for k in range(t.get_vertex_count()):
		var uv = t.get_vertex_uv(k)
		var x = uv.x * map_width
		var y = uv.y * map_height
		var cell_x = int(x / cell_size)
		var cell_y = int(y / cell_size)
		var cell_pos = get_cell_pos(x, y)
		var grid_pos = cell_pos
		grid[grid_pos].push_back([Vector2(x, y), t.get_vertex(k), t.get_vertex_normal(k)])
	for k in range(grid.size()):
		if grid[k].size() < 3:
			var o1 = k + 1
			var o2 = k - 1
			while grid[k].size() < 3:
				if o1 < grid.size():
					if grid[o1].size() > 0:
						grid[k] += grid[o1]
					o1 += 1
				if o2 > 0:
					if grid[o2].size() > 0:
						grid[k] += grid[o2]
					o2 -= 1
				if o1 >= grid.size() && o2 < 0:
					break
		
	return grid

func get_closest(x, y, points):
	if points.size() < 3:
		return []
	var p = Vector2(x, y)
	var best = points[0]
	var ret = []
	var dst = p.distance_squared_to(points[0][0])
	while ret.size() < 3:
		for tp in points:
			if tp in ret:
				continue
			var ndst = p.distance_squared_to(tp[0])
			if ndst < dst:
				dst = ndst
				best = tp
		ret.push_back(best)
	return ret
		
func get_cell_pos(x, y):
		var cell_x = int(x / cell_size)
		var cell_y = int(y / cell_size)
		var cell_pos = cell_y * get_grid_w() + cell_x
		return cell_pos
func get_cell(grid, x, y):
	var cell_pos = get_cell_pos(x, y)
	return grid[cell_pos]

func get_weight(x, y, p):
	var w = Vector2(x, y).distance_to(p) / Vector2(map_width, map_height).length()
	return w
	
func build_difference(grid_model, grid_base, diffv, diffn):
	var grid_w = int(map_width / cell_size)
	var grid_h = int(map_height / cell_size)
	var orig_cell_pos = -1
	var points_model = []
	var points_base = []
	diffv.lock()
	diffn.lock()
	for k in range(map_height):
		for l in range(map_width):
			var cell_pos = get_cell_pos(l, k)
			if orig_cell_pos != cell_pos:
				points_model = get_cell(grid_model, l, k)
				points_base = get_cell(grid_base, l, k)
				orig_cell_pos = cell_pos
			if points_model.size() >= 3 && points_base.size() >= 3:
				var closest_m = get_closest(l, k, points_model)
				var md1 = get_weight(l, k, closest_m[0][0])
				var md2 = get_weight(l, k, closest_m[1][0])
				var md3 = get_weight(l, k, closest_m[2][0])
				var closest_b = get_closest(l, k, points_base)
				var bd1 = get_weight(l, k, closest_b[0][0])
				var bd2 = get_weight(l, k, closest_b[1][0])
				var bd3 = get_weight(l, k, closest_b[2][0])
				var mvv = closest_m[0][1] * md1 + closest_m[1][1] * md2 + closest_m[2][1] * md3
				var mvn = closest_m[0][2] * md1 + closest_m[1][2] * md2 + closest_m[2][2] * md3
				var bvv = closest_b[0][1] * bd1 + closest_b[1][1] * bd2 + closest_b[2][1] * bd3
				var bvn = closest_b[0][2] * bd1 + closest_b[1][2] * bd2 + closest_b[2][2] * bd3
				var vd = (mvv - bvv)
				var nd = mvn - bvn
				var cv = Color(vd.x * 0.3 + 0.5, vd.y * 0.3 + 0.5, vd.z * 0.3 + 0.5)
				var cn = Color(nd.x * 0.3 + 0.5, nd.y * 0.3 + 0.5, nd.z * 0.3 + 0.5)
				diffv.set_pixel(l, k, cv)
				diffn.set_pixel(l, k, cn)
#				print("closest_m", closest_m)
#				print("closest_b", closest_b)
			elif points_model.size() == 0 && points_base.size() == 0:
				continue
			else:
				print("bad cell " + str(cell_pos) + " " + str(points_model.size()) + " " + str(points_base.size()))
				continue
	diffv.unlock()
	diffn.unlock()
