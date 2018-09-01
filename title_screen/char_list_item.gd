extends HBoxContainer
signal delete
signal edit

var signal_id

func set_item(id, pname):
	signal_id = id
	$name.set_text(pname)

func delete_item():
	emit_signal("delete", signal_id)

func edit_item():
	emit_signal("edit", signal_id)

func _ready():
	$edit_button.connect("pressed", self, "edit_item")
	$delete_button.connect("pressed", self, "delete_item")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
