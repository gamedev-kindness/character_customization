extends Control

const map_width = 1024
const map_height = 1024
const def_cell_size = 16
onready var progress = $progress

class Tri:
	var u
	var p
	var n
	var v
	var um
	func _init():
		u = []
		p = []
		n = []
		v = []
		um = []
		for zp in [u, p, v, n, um]:
			zp.resize(3)
	static func sgn(p1, p2, p3):
		return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
	static func pt_tri(pt, tri):
		var b1 = sgn(pt, tri.um[0], tri.um[1]) < 0
		var b2 = sgn(pt, tri.um[1], tri.um[2]) < 0
		var b3 = sgn(pt, tri.um[2], tri.um[0]) < 0
		return b1 == b2 && b2 == b3
	func inside(p):
		return pt_tri(p, self)
class Qnode:
	var r
	var items
	var children
	const MAX_ITEMS = 4
	static func create(x, y, w, h):
		var ret = Qnode.new()
		ret.r = Rect2(x, y, w, h)
		ret.items = []
		ret.children = []
		return ret
	func insert(v):
		var ok = false
		for p in v.um:
			if r.has_point(p):
				ok = true
		var rp = Rect2(0, 0, 0, 0)
		for p in v.um:
			rp = rp.expand(p)
		if rp.encloses(r) || rp.intersects(r):
			ok = true
		if !ok:
			return
		if items.size() < MAX_ITEMS:
			items.push_back(v)
			return
		else:
			if children.size() == 0:
				children.resize(4)
				var hx = r.size.x / 2.0
				var hy = r.size.y / 2.0
				children[0] = create(r.position.x + 0, r.position.y + 0 , hx, hy)
				children[1] = create(r.position.x + hx, r.position.y + 0 , hx, hy)
				children[2] = create(r.position.x + hx, r.position.y + hy , hx, hy)
				children[3] = create(r.position.x + 0, r.position.y + hy , hx, hy)
			for k in children:
				k.insert(v)
	func get_points(x, y):
		var ret = []
		if !r.has_point(Vector2(x, y)):
			return ret
		for k in items:
			if k.inside(Vector2(x, y)):
				ret.push_back(k)
		for k in children:
			for l in k.get_points(x, y):
				if l.inside(Vector2(x, y)):
					ret.push_back(l)
		return ret
class GridCell:
	var x
	var y
	var points
	func insert(v):
		points.append(v)
class Grid:
	var cells
	var cell_size
	var w
	var h
	var qtree
	func get_cell(fx, fy):
		var x = int(fx / cell_size)
		var y = int(fy / cell_size)
		return cells[x + w * y]
	# x, y - CELL coordinates
	static func make_cell(x, y):
		var ret = GridCell.new()
		ret.x = x
		ret.y = y
		ret.points = []
		return ret
	func setup(w, h, c):
		self.w = w
		self.h = h
		cells = []
		cells.resize(w * h)
		for i in range(h):
			for j in range(w):
				cells[i * w + j] = make_cell(j, i)
		cell_size = c
		qtree = Qnode.create(0, 0, w * c, h * c)
	func insert(v):
		for p in v.um:
			var cell = get_cell(p.x, p.y)
			cell.insert(v)
		qtree.insert(v)
	func get_points(x, y):
		return qtree.get_points(x, y)
	func dump():
		print("width: ", w)
		print("height: ", h)
		print("cells: ", cells.size())
		
		
static func make_grid(w, h, c):
	var grid = Grid.new()
	grid.setup(int(w/c), int(h/c), c)
	return grid

static func build_grid(grid, mesh):
	var mesh_tool = MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	for k in range(mesh_tool.get_face_count()):
		var p0 = mesh_tool.get_face_vertex(k, 0)
		var p1 = mesh_tool.get_face_vertex(k, 1)
		var p2 = mesh_tool.get_face_vertex(k, 2)
		var u0 = mesh_tool.get_vertex_uv(p0)
		var u1 = mesh_tool.get_vertex_uv(p1)
		var u2 = mesh_tool.get_vertex_uv(p2)
		var v0 = mesh_tool.get_vertex(p0)
		var v1 = mesh_tool.get_vertex(p1)
		var v2 = mesh_tool.get_vertex(p2)
		var n0 = mesh_tool.get_vertex_normal(p0)
		var n1 = mesh_tool.get_vertex_normal(p1)
		var n2 = mesh_tool.get_vertex_normal(p2)
		var tri = Tri.new()
		var vm = Vector2(map_width, map_height)
		tri.um = [u0 * vm, u1 * vm, u2 * vm]
		tri.p = [p0, p1, p2]
		tri.u = [u0, u1, u2]
		tri.v = [v0, v1, v2]
		tri.n = [n0, n1, n2]
		grid.insert(tri)
	mesh_tool.clear()
# x, y - image coordinates
static func closest_tri(x, y, grid):
	var cell = grid.get_cell(x, y)
	# triangles
	var points = cell.points
	points += grid.get_points(x, y)
#		print("quadtree points: ", points.size())
#		print("x:", x)
#		print("y:", y)
#		print("rect:", grid.qtree.r)
#	print("points: ", points.size())
	var dst = Vector2(x, y).distance_squared_to(points[0].um[0])
	var best = points[0]
	for k in points:
		for l in k.um:
			var ndst = Vector2(x, y).distance_squared_to(l)
			if dst > ndst:
				best = k
				dst = ndst
	return best
static func get_triangulated_data(x, y, grid):
	var tri = closest_tri(x, y, grid)
	var ret = {}
	if !tri.inside(Vector2(x, y)):
		ret.v = Vector3()
		ret.n = Vector3()
		return ret;
		
	var pts = tri.u
	var weights = []
	var d = 0.0
	var ndx = float(x) / float(map_width)
	var ndy = float(y) / float(map_height)
	var npos = Vector2(ndx, ndy)
	for k in pts:
		var nd = 1.0 / (1.0 + npos.distance_to(k))
		d += nd
		weights.push_back(nd)
	for k in range(weights.size()):
			weights[k] = weights[k] / d
	var vx = Vector3()
	var nx = Vector3()
	for k in range(tri.v.size()):
#		var nweight = 1.0 - weights[k] / d
		var nweight = weights[k]
		vx += tri.v[k] * nweight
		nx += tri.n[k] * nweight
	ret.v = vx
	ret.n = nx
#	print("d: ", d, " weights: ", weights, " npos: ", npos, " vx: ", vx, "nx: ", nx)
	return ret
		
func _ready():
	var config = globals.config
	var pr = 0.0
	progress.set_value(pr)
	yield(get_tree(), "idle_frame")
	var pr_inc_map = 100.0 / config.target_blendmaps.keys().size()
	for k in config.target_blendmaps.keys():
		var bm = config.target_blendmaps[k]
		var model = bm.model
		var base = bm.base
		var path_vertices = bm.path_vertices
		var path_normals = bm.path_normals
		if model == null || base == null || path_vertices == null || path_normals == null:
			pr += pr_inc_map
			continue
		var model_data = config.target_models[model]
		var base_data = config.target_models[base]
		var model_scene = load(model_data.scene).instance()
		add_child(model_scene)
		var base_scene = load(base_data.scene).instance()
		add_child(base_scene)
		var model_mi = globals.find_mesh_instance(model_scene, model_data.mesh)
		var base_mi = globals.find_mesh_instance(base_scene, base_data.mesh)
		if model_mi == null || base_mi == null:
			pr += pr_inc_map
			continue
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		yield(get_tree(), "idle_frame")
		var grid_model = make_grid(map_height, map_width, def_cell_size)
		var grid_base = make_grid(map_height, map_width, def_cell_size)
		build_grid(grid_model, model_mi.get_mesh())
		yield(get_tree(), "idle_frame")
		build_grid(grid_base, base_mi.get_mesh())
		yield(get_tree(), "idle_frame")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
#		var base_tool = MeshDataTool.new()
#		base_tool.create_from_surface(base_mi.get_mesh(), 0)
		var pr_inc_line = (pr_inc_map - 3.0 * pr_inc_map / 30) / map_height
		var max_v = 0.0
		var max_n = 0.0
		var max_o = 0.0
		var vertices = []
		var normals = []
		var vertices_p = []
		var normals_p = []
		vertices.resize(map_height * map_width)
		normals.resize(map_height * map_width)
		vertices_p.resize(map_height * map_width)
		normals_p.resize(map_height * map_width)
		for n in range(map_height):
			for m in range(map_width):
				var d1 = get_triangulated_data(m, n, grid_model)
				var d2 = get_triangulated_data(m, n, grid_base)
				var vdiff = (d1.v - d2.v)
				var ndiff = (d1.n - d2.n)
				vertices[n * map_width + m] = vdiff
				normals[n * map_width + m] = ndiff
				vertices_p[n * map_width + m] = d1.v
				normals_p[n * map_width + m] = d1.n
				if vdiff.length() > max_v:
					max_v = vdiff.length()
				if ndiff.length() > max_n:
					max_n = ndiff.length()
				if d1.v.length() > max_o:
					max_o = d1.v.length()
#				if vdiff.length() > 1.0 || ndiff.length() > 1.0:
#					print("1:", "x: ", m, " y: ", n, " ", vdiff, " len: ", vdiff.length())
#					print("2:", "x: ", m, " y: ", n, " ", ndiff, " len: ", ndiff.length())
#				var cell1 = grid_model.get_cell(m, n)
#				var cell2 = grid_base.get_cell(m, n)
#				if cell1.points.size() > 0 && cell2.points.size():
#					print("1: x: ", m, " y: ", n, " size: ", cell1.points.size())
#					print("2: x: ", m, " y: ", n, " size: ", cell2.points.size())
			pr += pr_inc_line
			progress.set_value(pr)
			if randf() > 0.8:
				yield(get_tree(), "idle_frame")
		print("max_v: ", max_v)
		print("max_n: ", max_n)
		var blendmap_o1 = Image.new()
		blendmap_o1.create(map_width, map_height, false, Image.FORMAT_RGB8)
		var blendmap_v = Image.new()
		blendmap_v.create(map_width, map_height, false, Image.FORMAT_RGB8)
		var blendmap_n = Image.new()
		blendmap_n.create(map_width, map_height, false, Image.FORMAT_RGB8)
		blendmap_o1.lock()
		blendmap_v.lock()
		blendmap_n.lock()
		for n in range(map_height):
			for m in range(map_width):
				var vdata = vertices[map_width * n + m] / max_v * 0.5
				var ndata = vertices[map_width * n + m] / max_n * 0.5
				var odata = vertices_p[map_width * n + m] / max_o * 0.5
				var vcolor = Color(vdata.x + 0.5, vdata.y + 0.5, vdata.z + 0.5, 1)
				var ncolor = Color(ndata.x + 0.5, ndata.y + 0.5, ndata.z + 0.5, 1)
				var ocolor = Color(odata.x + 0.5, odata.y + 0.5, odata.z + 0.5, 1)
				blendmap_v.set_pixel(m, n, vcolor)
				blendmap_n.set_pixel(m, n, vcolor)
				blendmap_o1.set_pixel(m, n, ocolor)
		blendmap_o1.unlock()
		blendmap_v.unlock()
		blendmap_n.unlock()
		blendmap_o1.save_png(path_vertices + "_o1.png")
		blendmap_v.save_png(path_vertices)
		blendmap_n.save_png(path_normals)
		yield(get_tree(), "idle_frame")
				
		
		grid_model.dump()
		grid_base.dump()
		remove_child(model_scene)
		model_scene.queue_free()
		remove_child(base_scene)
		base_scene.queue_free()
#		pr += pr_inc_map
#		progress.set_value(pr)
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		yield(get_tree(), "idle_frame")
