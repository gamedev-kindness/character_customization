extends Viewport

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func update_viewport(mi):
	render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$blendmap.mi_mesh_texture(mi, size)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	render_target_update_mode = Viewport.UPDATE_DISABLED
	var texture = get_texture()
	var ret = Image.new()
	ret.copy_from(texture.get_data())
	return ret

func _ready():
	pass
#	render_target_update_mode = Viewport.UPDATE_DISABLED

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
