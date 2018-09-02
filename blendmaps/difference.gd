extends Node2D

onready var view = get_parent().get_node("blendmap_viewport")
onready var progress = get_parent().get_node("progress")
export (String) var first = "makehuman-base"
export (String) var second = "female"
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func find_mesh_instance(root, name):
	var queue = root.get_children().duplicate()
	while queue.size() > 0:
		var item = queue[0]
		if item is MeshInstance && item.get_name().find(name) >= 0:
			return item
		queue.pop_front()
		for k in item.get_children():
			queue.append(k)
	return null

func create_png(img, path):
	var dir = Directory.new()
	if dir.file_exists(path):
		dir.remove(path)
	img.save_png(path)
	
func _ready():
	var fd = File.new()
	fd.open("res://character_edit/sliders.json", fd.READ)
	var jdata = fd.get_as_text()
#	var jlines = jdata.split("\n", false)
#	jdata = ""
#	for k in jlines:
#		jdata += k
	var d = JSON.parse(jdata)
	if d.error != OK:
		print(d.error_string)
		print(d.error_line)
		print(d.result)
		return
	var config = d.result
	var pr = 0.0
	progress.set_value(pr)
	var pr_inc_map = 100.0 / config.target_blendmaps.keys().size()
	for k in config.target_blendmaps.keys():
		var bm = config.target_blendmaps[k]
		var model = bm.model
		var base = bm.base
		var path_vertices = bm.path_vertices
		var path_normals = bm.path_normals
		if model == null || base == null || path_vertices == null || path_normals == null:
			continue
		var model_data = config.target_models[model]
		var base_data = config.target_models[base]
		if model_data == null || base_data == null:
			continue
		print(model_data)
		print(base_data)
		var model_scene = load(model_data.scene).instance()
		add_child(model_scene)
		var model_mi = find_mesh_instance(model_scene, model_data.mesh)
		var base_scene = load(base_data.scene).instance()
		add_child(base_scene)
		var base_mi = find_mesh_instance(base_scene, base_data.mesh)
		if model_mi == null || base_mi == null:
			continue
		var image1 = yield(view.update_viewport(model_mi), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		var image2 = yield(view.update_viewport(base_mi), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		var incr = (pr_inc_map - 2.0 * pr_inc_map / 30.0) / image1.get_height()
		var count_max = image1.get_height() / 30
		var count = 0
		var image_diff = Image.new()
		image_diff.copy_from(image2)
		image_diff.lock()
		image1.lock()
		image2.lock()
		for k in range(image1.get_height()):
			for l in range(image1.get_width()):
				var c1 = image1.get_pixel(l, k)
				var c2 = image2.get_pixel(l, k)
				var diff = Vector3(c2.r - c1.r + 1.0, c2.g - c1.g + 1.0, c2.b - c1.b + 1.0) * 0.5
				var cdiff = Color(diff.x, diff.y, diff.z, 1.0)
				image_diff.set_pixel(l, k, cdiff)
			count += 1
			pr += incr
			progress.set_value(pr)
			if count > count_max:
				yield(get_tree(), "idle_frame")
				count = 0
		image_diff.unlock()
		image1.unlock()
		image2.unlock()
		create_png(image_diff, bm.path_vertices)
	return
		
		

	if first == null || second == null:
		return
	var first_mi = find_mesh_instance($base, first)
	var second_mi = find_mesh_instance($"base-female", second)
	var image1 = yield(view.update_viewport(first_mi), "completed")
	pr = 1.0
	progress.set_value(pr)
	var image2 = yield(view.update_viewport(second_mi), "completed")
	pr = 2.0
	progress.set_value(pr)
	create_png(image1, "res://blendmaps/" + first_mi.get_name() + ".png")
	create_png(image2, "res://blendmaps/" + second_mi.get_name() + ".png")
	pr = 3.0
	progress.set_value(pr)
	var image_diff = Image.new()
	image_diff.copy_from(image2)
	image_diff.lock()
	image1.lock()
	image2.lock()
	var incr = (100 - pr) / image1.get_height()
	var count_max = image1.get_height() / 30
	var count = 0
	for k in range(image1.get_height()):
		pr += incr
		progress.set_value(pr)
		var maxdiff = Vector3()
		for l in range(image1.get_width()):
			var c1 = image1.get_pixel(l, k)
			var c2 = image2.get_pixel(l, k)
			var diff = Vector3(c2.r - c1.r + 1.0, c2.g - c1.g + 1.0, c2.b - c1.b + 1.0) * 0.5
			var cdiff = Color(diff.x, diff.y, diff.z, 1.0)
			image_diff.set_pixel(l, k, cdiff)
		count += 1
		if count > count_max:
			yield(get_tree(), "idle_frame")
			count = 0
	image_diff.unlock()
	image1.unlock()
	image2.unlock()
	
	create_png(image_diff, "res://blendmaps/" + second_mi.get_name() + "_diff.png")
	print("done")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
