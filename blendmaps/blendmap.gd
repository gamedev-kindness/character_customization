extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var tris = []
var size
func _ready():
	size = Vector2(1024, 1024)
func mi_mesh_texture(mi, size, mode):
	self.size = size
	var mesh = mi.get_mesh()
	generate_mesh_texture(mesh, 0.4, size, mode)
	
func generate_mesh_texture(mesh, pscale, size, mode):
	tris.clear()
	var t = MeshDataTool.new()
	t.create_from_surface(mesh, 0)
	for f in range(t.get_face_count()):
		var v1 = t.get_face_vertex(f, 0)
		var v2 = t.get_face_vertex(f, 1)
		var v3 = t.get_face_vertex(f, 2)
		var p1
		var p2
		var p3
		if mode == 0:
			p1 = (t.get_vertex(v1)) * pscale
			p2 = (t.get_vertex(v2)) * pscale
			p3 = (t.get_vertex(v3)) * pscale
		elif mode == 1:
			p1 = (t.get_vertex_normal(v1)) * pscale
			p2 = (t.get_vertex_normal(v2)) * pscale
			p3 = (t.get_vertex_normal(v3)) * pscale
		var u1 = t.get_vertex_uv(v1) * size
		var u2 = t.get_vertex_uv(v2) * size
		var u3 = t.get_vertex_uv(v3) * size
		tris.push_back([[u1, u2 , u3],[p1, p2, p3]])
		update()
func _draw():
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.5, 0.5, 0.5, 1.0), true)
	print("tris: ", tris.size())
	var maxv = Vector3()
	var minv = Vector3()
	for t in tris:
		var uvs = t[0]
		var data = t[1]
		var colors = []
		for vec in data:
			colors.push_back(Color(vec.x + 0.5, vec.y + 0.5, vec.z + 0.5, 1))
			if maxv.x < vec.x:
				maxv.x = vec.x
			if maxv.y < vec.y:
				maxv.y = vec.y
			if maxv.z < vec.z:
				maxv.z = vec.z
			if minv.x > vec.x:
				minv.x = vec.x
			if minv.y > vec.y:
				minv.y = vec.y
			if minv.z > vec.z:
				minv.z = vec.z
		draw_polygon(uvs, colors, PoolVector2Array(), null, null, true)
	print(maxv, minv)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
