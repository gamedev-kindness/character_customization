extends Control

func apply_slider(name, oldval, newval):
	update_scene(name, oldval, newval)

func slider_update(val, obj, cat, entry):
#	print(cat + "::" + entry + " changed to " + str(val))
	var conf = globals.config
	if conf.sliders.has(entry):
		apply_slider(entry, globals.character_copy[entry], val)
	globals.character_copy[entry] = val
func text_update(val, obj, cat, entry):
	print(cat + "::" + entry + " changed to " + str(val))
	globals.character_copy[entry] = val
func update_scene(entry, old_val, new_val):
	$Gender.update($VBoxContainer/HBoxContainer/ViewportContainer/Viewport/charscene_root, entry, old_val, new_val)
func _ready():
	var config = globals.config
	if globals.character_copy == null:
		globals.character_copy = {}
	for k in config.categories:
		print(k.name)
		var c = preload("res://character_edit/scroll.tscn").instance()
		c.set_name(k.name)
		var scrolldata = c.get_node("scrolldata")
		for m in k.sliders:
			var defaultval = m.default
			if globals.character_copy.has(m.name):
				defaultval = globals.character_copy[m.name]
			else:
				globals.character_copy[m.name] = defaultval
			var label = load("res://character_edit/entry_label.tscn").instance()
			label.set_text(m.name)
			scrolldata.add_child(label)
			if m.type == "slider":
				var slider = load("res://character_edit/entry_slider.tscn").instance()
				slider.min_value = m.min
				slider.max_value = m.max
				slider.value = defaultval
				slider.connect("value_changed", self, "slider_update", [slider, k.name, m.name])
				scrolldata.add_child(slider)
			elif m.type == "color_picker":
				var color_picker = load("res://character_edit/entry_color_picker.tscn").instance()
				scrolldata.add_child(color_picker)
			elif m.type == "string":
				var string_editor = load("res://character_edit/entry_line.tscn").instance()
				string_editor.set_text(defaultval)
				string_editor.connect("text_changed", self, "text_update", [string_editor, k.name, m.name])
				scrolldata.add_child(string_editor)
			else:
				print("unknown type: " + m.type)
				var control = Control.new()
				scrolldata.add_child(control)
		$VBoxContainer/HBoxContainer/Tabs.add_child(c)
	update_scene("", -1, 0)
