extends Node

var characters = []
enum {CH_EDITOR_STARTGAME, CH_EDITOR_EXISTING}
var character_editor_mode = CH_EDITOR_STARTGAME
var current_character_id = -1
var character_copy
