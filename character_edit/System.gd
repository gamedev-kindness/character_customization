extends VBoxContainer
signal reset
signal new_char
signal open_file
signal save_as
signal exit_editor

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func exit_editor_pressed():
	emit_signal("exit_editor")
	if globals.character_editor_mode == globals.CH_EDITOR_STARTGAME:
		globals.character_copy.name = globals.character_copy["First name"] + " " + globals.character_copy["Last name"]
		globals.characters.append(globals.character_copy)
		globals.character_copy = null
		print(globals.characters)
	elif globals.character_editor_mode == globals.CH_EDITOR_EXISTING:
		globals.character_copy.name = globals.character_copy["First name"] + " " + globals.character_copy["Last name"]
		globals.characters[globals.current_character_id] = globals.character_copy
		globals.character_copy = null
		print(globals.characters)
	var new_game_menu = preload("res://title_screen/new_game_menu.tscn")
	get_tree().change_scene_to(new_game_menu)

# Called when the node enters the scene tree for the first time.

func _ready():
	if globals.character_editor_mode == globals.CH_EDITOR_STARTGAME:
		$system_buttons/NewChar.hide()
	$system_buttons/ExitEditor.connect("pressed", self, "exit_editor_pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
