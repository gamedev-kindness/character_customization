extends CanvasItem

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _draw():
	draw_rect(Rect2(0, 0, 1024, 1024), Color(1, 0, 0), true)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
