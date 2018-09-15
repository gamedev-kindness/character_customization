extends Node2D

onready var view = get_parent().get_node("blendmap_viewport")
onready var progress = get_parent().get_node("progress")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var config = globals.config
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
		var model_mi = globals.find_mesh_instance(model_scene, model_data.mesh)
		var base_scene = load(base_data.scene).instance()
		add_child(base_scene)
		var base_mi = globals.find_mesh_instance(base_scene, base_data.mesh)
		if model_mi == null || base_mi == null:
			continue
		var img_v = Image.new()
		img_v.create(1024, 1024, false, Image.FORMAT_RGB8)
		var img_n = Image.new()
		img_n.create(1024, 1024, false, Image.FORMAT_RGB8)
		var model_grid = $grid.build_grid(model_mi.get_mesh())
		var base_grid = $grid.build_grid(base_mi.get_mesh())
		$grid.build_difference(model_grid, base_grid, img_v, img_n)
		globals.create_png(img_v, bm.path_vertices)
		globals.create_png(img_n, bm.path_normals)
		continue
		print("p1")
		var image1 = yield(view.update_viewport(model_mi, 0), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		print("p2")
		var image2 = yield(view.update_viewport(base_mi, 0), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		print("p3")
		var image3 = yield(view.update_viewport(model_mi, 1), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		print("p4")
		var image4 = yield(view.update_viewport(base_mi, 1), "completed")
		pr += pr_inc_map / 30.0
		progress.set_value(pr)
		var incr = (pr_inc_map - 4.0 * pr_inc_map / 30.0) / (2.0 * image1.get_height())
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
		globals.create_png(image_diff, bm.path_vertices)
		image_diff.copy_from(image3)
		image_diff.lock()
		image3.lock()
		image4.lock()
		for k in range(image3.get_height()):
			for l in range(image3.get_width()):
				var c1 = image3.get_pixel(l, k)
				var c2 = image4.get_pixel(l, k)
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
		image3.unlock()
		image4.unlock()
		globals.create_png(image_diff, bm.path_normals)
		remove_child(model_scene)
		model_scene.queue_free()
		remove_child(base_scene)
		base_scene.queue_free()
	print("done")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
