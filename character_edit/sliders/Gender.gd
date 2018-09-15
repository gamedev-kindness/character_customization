extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var bm_plus
var bm_minus
var bm_plus_img
var bm_minus_img
var current_mesh
var normals_plus_img
var normals_minus_img
var multipliers_p
var multipliers_n

func create_mesh_data(m, k):
	var md
	if m is MeshInstance:
		md = m.get_mesh()
	elif m is Mesh:
		md = m
	var t = MeshDataTool.new()
	t.create_from_surface(md, k)
	return t

func _ready():
	var config = globals.config
	var maps = config.sliders["Gender"].blendmaps
	bm_plus = []
	bm_minus = []
	bm_plus_img = []
	bm_minus_img = []
	normals_plus_img = []
	normals_minus_img = []
	multipliers_p = []
	multipliers_n = []
	for k in maps[0]:
		bm_plus.push_back(config.target_blendmaps[k])
		bm_plus_img.push_back(load(config.target_blendmaps[k].path_vertices))
#		normals_plus_img.push_back(load(config.target_blendmaps[k].path_normals))
		multipliers_p.push_back(config.target_blendmaps[k].multiplier_p)
		multipliers_n.push_back(config.target_blendmaps[k].multiplier_n)
	for k in maps[1]:
		bm_minus.push_back(config.target_blendmaps[k])
		bm_minus_img.push_back(load(config.target_blendmaps[k].path_vertices))
#		normals_minus_img.push_back(load(config.target_blendmaps[k].path_normals))
		multipliers_p.push_back(config.target_blendmaps[k].multiplier_p)
		multipliers_n.push_back(config.target_blendmaps[k].multiplier_n)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var orig_data
var current_data

func reverse_sigmoid(y):
	return log(y / (1.0 - y))

func apply_blendmap(mi, t, t2, image, val, mode):
	print("val: ", val)
	print(mi.get_name())
	mi.hide()
	var m = mi.get_mesh()
#	print("creating from surface")
#	t.create_from_surface(m, 0)
#	t2.create_from_surface(m, 0)
#	print("done creating from surface")
	image.lock()
	var count_max = 20
	var count = 0
	var aabb = mi.get_aabb()
	print("processing")
	for k in range(t.get_vertex_count()):
		var u = t.get_vertex_uv(k)
		var x = u.x * image.get_width()
		var y = (1.0 - u.y) * image.get_height()
		var c = image.get_pixel(x, y)
#		var v = Vector3(reverse_sigmoid(c.r), reverse_sigmoid(c.g), reverse_sigmoid(c.b)) * 1.0
		var v = Vector3(c.r - 0.5, c.g - 0.5, c.b - 0.5) * 2.0
		if mode == 0:
			var vx = t2.get_vertex(k)
#			v = vx * 0.05
			vx += v * val
			aabb = aabb.expand(vx)
			t.set_vertex(k, vx)
		elif mode == 1:
			var vx = t2.get_vertex_normal(k)
			vx += v * val
			t.set_vertex_normal(k, vx)
#		t.set_vertex_bones(k, PoolIntArray([0, 0, 0, 0]))
#		t.set_vertex_weights(k, PoolRealArray([0.0, 0.0, 0.0, 0.0]))
		count += 1
#		if count > count_max:
#			yield(get_tree(), "idle_frame")
#			count = 0
	print("complete")
	image.unlock()
	if m.get_surface_count() > 0:
		m.surface_remove(0)
	t.commit_to_surface(m)
	m.set_custom_aabb(aabb)
	print("surfaces: ", m.get_surface_count())
#	mi.set_mesh(m)
	mi.show()

var scenes = []
func update_data(models):
	pass
func update(root, entry, old_val, new_val):
	var config = globals.config
#	var models = config.sliders["Gender"].switch_models[0]
#	if scene_name == null:
#		scene_name = config.target_models[models[0]].scene
#	if mesh_name == null:
#		mesh_name = config.target_models[models[0]].mesh
	var new_gender = new_val
	if sign(new_gender) != sign(old_val):
		var models
		if new_gender >= 0:
			models = config.sliders["Gender"].switch_models[0]
		else:
			models = config.sliders["Gender"].switch_models[1]
		current_mesh = []
		current_data = []
		orig_data = []
		if scenes.size() > 0:
			for k in scenes:
				if k != null:
					root.remove_child(k)
					k.queue_free()
			scenes.clear()
		for k in range(models.size()):
			var scene_name
			var mesh_name
			scene_name = config.target_models[models[k]].scene
			mesh_name = config.target_models[models[k]].mesh
			print("mesh: ", k, " name: ", mesh_name)
			var scene = load(scene_name).instance()
			scenes.push_back(scene)
			root.add_child(scene)
			current_mesh.push_back(globals.find_mesh_instance(scene, mesh_name))
			orig_data.push_back(create_mesh_data(current_mesh[k], 0))
			current_data.push_back(create_mesh_data(current_mesh[k], 0))
	var img
	print("update2 ", new_gender, " ", old_val)
	if  new_gender != old_val:
		print("update")
		if new_gender >= 0:
			img = bm_plus_img
		else:
			img = bm_minus_img
		print(current_mesh)
		for idximg in range(img.size()):
			print("mesh: ", idximg)
			apply_blendmap(current_mesh[idximg], current_data[idximg], orig_data[idximg], img[idximg].get_data(), -(1.0 - abs(new_gender) / 100.0) * multipliers_p[idximg], 0)
#			apply_blendmap(current_mesh[idximg], current_data[idximg], orig_data[idximg], img[idximg].get_data(), -(1.0 - abs(new_gender) / 100.0) * multipliers_p[idximg], 1)
		print("done")
