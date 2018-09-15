extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
#tmp tri store
var tris = []
# const sigmoid_amp = 3.0
const sigmoid_amp = 0.5
func create_mesh_texture(mi, pscale, size, p_min, mode):
	var mesh = mi.get_mesh()
	generate_mesh_texture(mesh, pscale, size, p_min, mode)
	
func generate_mesh_texture(mesh, pscale, size, p_min, mode):
	tris.clear()
	var t = MeshDataTool.new()
	t.create_from_surface(mesh, 0)
	for f in range(t.get_face_count()):
		var v1 = t.get_face_vertex(f, 0)
		var v2 = t.get_face_vertex(f, 1)
		var v3 = t.get_face_vertex(f, 2)
		var p1
		var p2
		var p3
		var widen = Vector3(sigmoid_amp, sigmoid_amp, sigmoid_amp)
		if mode == 0:
			p1 = (t.get_vertex(v1) - p_min) * pscale - widen
			p2 = (t.get_vertex(v2) - p_min) * pscale - widen
			p3 = (t.get_vertex(v3) - p_min) * pscale - widen
		elif mode == 1:
			p1 = (t.get_vertex_normal(v1)) * pscale - widen
			p2 = (t.get_vertex_normal(v2)) * pscale - widen
			p3 = (t.get_vertex_normal(v3)) * pscale - widen
		var u1 = t.get_vertex_uv(v1) * size
		var u2 = t.get_vertex_uv(v2) * size
		var u3 = t.get_vertex_uv(v3) * size
		tris.push_back([[u1, u2 , u3],[p1, p2, p3]])
		$view_texture/drawer.update()
	t.clear()
func get_min_point(mi):
	return mi.get_aabb().position
func get_max_point(mi):
	return mi.get_aabb().end

func update_viewport(mi, pscale, p_min, mode):
	$view_texture.render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	create_mesh_texture(mi, pscale, $view_data.size, p_min, mode)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$view_texture.render_target_update_mode = Viewport.UPDATE_DISABLED
	$view_data.render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$view_data/blurry.update()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$view_data.render_target_update_mode = Viewport.UPDATE_DISABLED
	var texture = $view_data.get_texture()
	var ret = Image.new()
	ret.copy_from(texture.get_data())
	return ret
func update_image(mi, pscale, p_min, mode):
	return yield(update_viewport(mi, pscale, p_min, mode), "completed")

func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))

func reverse_sigmoid(y):
	return log(y / (1.0 - y))

func draw_trie(what):
	what.draw_rect(Rect2(Vector2(), $view_data.size), Color(0, 0, 0), true)
	print("tris: ", tris.size())
#	for t in tris:
#		var center = Vector2()
#		var uvs = t[0]
#		for h in uvs:
#			center += h
#		center = center / 3.0
#		var uv_big = []
#		for h in uvs:
#			uv_big.push_back((h - center) * 1.25 + center)
#		var data = t[1]
#		var colors = []
#		for vec in data:
#			colors.push_back(Color(sigmoid(vec.x), sigmoid(vec.y), sigmoid(vec.z), 1))
#		what.draw_polygon(uv_big, colors, PoolVector2Array(), null, null, true)
	for t in tris:
		var uvs = t[0]
		var data = t[1]
		var colors = []
		for vec in data:
#			colors.push_back(Color(sigmoid(vec.x), sigmoid(vec.y), sigmoid(vec.z), 1))
			colors.push_back(Color(vec.x, vec.y, vec.z, 1))
		what.draw_polygon(uvs, colors, PoolVector2Array(), null, null, false)


func _ready():
	var progress = $progress
	var pr = 0.0
	var config = globals.config
	$view_texture/drawer.connect("draw", self, "draw_trie", [$view_texture/drawer])
	var vp = $view_texture.get_texture()
	$view_data/blurry.material.set_shader_param("tex_mesh", vp)
	progress.set_value(pr)
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
		if model_data == null || base_data == null:
			pr += pr_inc_map
			continue
		print(model_data)
		print(base_data)
		var model_scene = load(model_data.scene).instance()
		add_child(model_scene)
		var model_mi = globals.find_mesh_instance(model_scene, model_data.mesh)
		var base_scene = load(base_data.scene).instance()
		add_child(base_scene)
		var base_mi = globals.find_mesh_instance(base_scene, base_data.mesh)
		if model_mi == null || base_mi == null:
			pr += pr_inc_map
			continue
		var p_min = get_min_point(model_mi)
		var p_min_base = get_min_point(base_mi)
		var p_max = get_max_point(model_mi)
		var p_max_base = get_max_point(base_mi)
		print("min1: ", p_min, " min2: ", p_min_base, " max1: ", p_max, " max2: ", p_max_base)
		p_min.x = min(p_min.x, p_min_base.x)
		p_min.y = min(p_min.y, p_min_base.y)
		p_min.z = min(p_min.z, p_min_base.z)
		p_max.x = max(p_max.x, p_max_base.x)
		p_max.y = max(p_max.y, p_max_base.y)
		p_max.z = max(p_max.z, p_max_base.z)
		var xd = p_max - p_min
		var maxd = max(xd.x, max(xd.y, xd.z))
		var mind = min(xd.x, min(xd.y, xd.z))
		var pscale = 2.0 * sigmoid_amp / maxd
		var model_img = yield(update_viewport(model_mi, pscale, p_min, 0), "completed")
		var base_img = yield(update_viewport(base_mi, pscale, p_min, 0), "completed")
		var model_n_img = yield(update_viewport(model_mi, pscale, p_min, 1), "completed")
		var base_n_img = yield(update_viewport(base_mi, pscale, p_min, 1), "completed")
#		blouring(base_img)
#		var vdifference_img = calc_difference(model_img, base_img)
		globals.create_png(model_img, path_vertices + "_1.png")
		globals.create_png(base_img, path_vertices + "_2.png")
		globals.create_png(model_n_img, path_normals + "_1.png")
		globals.create_png(base_n_img, path_normals + "_2.png")
		var tex_m = ImageTexture.new()
		tex_m.create_from_image(model_img)
		var tex_b = ImageTexture.new()
		tex_b.create_from_image(base_img)
		$diff.render_target_update_mode = Viewport.UPDATE_ALWAYS
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		$diff/diffdata.get_material().set_shader_param("model", tex_m);
		$diff/diffdata.get_material().set_shader_param("base", tex_b);
#		globals.create_png(vdifference_img, path_vertices)
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		$diff.render_target_update_mode = Viewport.UPDATE_DISABLED
		var diff_texture = $diff.get_texture()
		var diff_img = Image.new()
		diff_img.copy_from(diff_texture.get_data())
		globals.create_png(diff_img, path_vertices)
		remove_child(model_scene)
		model_scene.queue_free()
		remove_child(base_scene)
		base_scene.queue_free()
		yield(get_tree(), "idle_frame")
	print("complete")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
