extends Control
signal new_game_pressed
signal continue_pressed
signal options_pressed
signal quit_pressed
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func new_game_pressed():
	emit_signal("new_game_pressed")
	var new_game_menu = load("res://title_screen/new_game_menu.tscn")
	get_tree().change_scene_to(new_game_menu)

func continue_pressed():
	emit_signal("continue_pressed")

func options_pressed():
	emit_signal("options_pressed")

func quit_pressed():
	emit_signal("quit_pressed")
	get_tree().quit()

func _ready():
	$menu/menu_vbox/NewGame.connect("pressed", self, "new_game_pressed")
	$menu/menu_vbox/Continue.connect("pressed", self, "continue_pressed")
	$menu/menu_vbox/Options.connect("pressed", self, "options_pressed")
	$menu/menu_vbox/Quit.connect("pressed", self, "quit_pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
