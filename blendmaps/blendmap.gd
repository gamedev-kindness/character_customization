extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var tris = []
func _ready():
	pass
func mi_mesh_texture(mi, size):
	var mesh = mi.get_mesh()
	var bb = mi.get_aabb()
	print(bb)
	generate_mesh_texture(mesh, bb.position, 0.4, size)
	
func generate_mesh_texture(mesh, offset, pscale, size):
	tris.clear()
	var t = MeshDataTool.new()
	t.create_from_surface(mesh, 0)
	for f in range(t.get_face_count()):
		var v1 = t.get_face_vertex(f, 0)
		var v2 = t.get_face_vertex(f, 1)
		var v3 = t.get_face_vertex(f, 2)
		var p1 = (t.get_vertex(v1) - offset) * pscale
		var p2 = (t.get_vertex(v2) - offset) * pscale
		var p3 = (t.get_vertex(v3) - offset) * pscale
		var u1 = t.get_vertex_uv(v1) * size
		var u2 = t.get_vertex_uv(v2) * size
		var u3 = t.get_vertex_uv(v3) * size
		tris.push_back([[u1, u2, u3],[p1, p2, p3]])
		update()
func _draw():
	print("tris: ", tris.size())
	var maxv = Vector3()
	var minv = Vector3()
	for t in tris:
		var uvs = t[0]
		var data = t[1]
		var colors = []
		for vec in data:
			colors.push_back(Color(vec.x, vec.y, vec.z, 1))
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
