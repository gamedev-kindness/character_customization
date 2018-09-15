extends Node

var characters = []
enum {CH_EDITOR_STARTGAME, CH_EDITOR_EXISTING}
var character_editor_mode = CH_EDITOR_STARTGAME
var current_character_id = -1
var character_copy
var config
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
	config = d.result

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
	
