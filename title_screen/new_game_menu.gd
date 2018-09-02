extends Control
signal new_game
signal new_character
signal edit_character

func new_game():
	emit_signal("new_game")
	var game_scene = preload("res://game/game_scene.tscn")
	get_tree().change_scene_to(game_scene)
func rebuild_list():
	var charlist = $buttons/character_list/scroll
	for c in charlist.get_children():
		if c != null:
			c.queue_free()
	for r in range(globals.characters.size()):
		var hb = preload("res://title_screen/char_list_item.tscn").instance()
		hb.set_item(r, globals.characters[r].name)
		hb.connect("delete", self, "remove_character")
		hb.connect("edit", self, "edit_character")
		charlist.add_child(hb)
func remove_character(id):
	globals.characters.remove(id)
	rebuild_list()
func edit_character(id):
	emit_signal("edit_character")
	print("edit")
	var char_editor = preload("res://character_edit/character_ui.tscn")
	globals.character_editor_mode = globals.CH_EDITOR_EXISTING
	globals.current_character_id = id
	globals.character_copy = globals.characters[id].duplicate()
	get_tree().change_scene_to(char_editor)
func new_character():
#	globals.characters.append({"name":"ZZZ" + str(characters.size()), "obj": null})
#	globals.characters.sort()
#	rebuild_list()
	emit_signal("new_character")
	var char_editor = preload("res://character_edit/character_ui.tscn")
	globals.character_editor_mode = globals.CH_EDITOR_STARTGAME
	get_tree().change_scene_to(char_editor)
func _ready():
	$buttons/StartGame.connect("pressed", self, "new_game")
	$buttons/NewCharacter.connect("pressed", self, "new_character")
	rebuild_list()

func _process(delta):
	if globals.characters.size() == 0 && !$buttons/StartGame.is_disabled():
		$buttons/StartGame.set_disabled(true)
	elif globals.characters.size() != 0 && $buttons/StartGame.is_disabled():
		$buttons/StartGame.set_disabled(false)
