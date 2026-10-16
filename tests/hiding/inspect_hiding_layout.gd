extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	for path: String in ["res://Blender models/ronalds.glb", "res://Blender models/appliances.glb"]:
		var scene: Node3D = load(path).instantiate() as Node3D
		root.add_child(scene)
		print("SOURCE ", path)
		for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			var title: String = String(mesh.get_path()).to_lower()
			if "table" in title or "booth" in title or "shelf" in title or "desk" in title:
				print(mesh.get_path(), " ", mesh.global_transform * mesh.get_aabb())
		scene.free()
	quit()
