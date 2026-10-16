extends SceneTree
## Run with --headless --path . -s tests/hiding/inspect_assets.gd.
func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var appliances: Node3D = load("res://Blender models/appliances.glb").instantiate() as Node3D
	root.add_child(appliances)
	for group: Node in appliances.get_children():
		if group.name == &"Asset_Table":
			for node: Node in group.find_children("*", "MeshInstance3D", true, false):
				var mesh: MeshInstance3D = node as MeshInstance3D
				print("TABLE ", mesh.name, " ", mesh.global_transform * mesh.get_aabb())
	var clown: Node3D = load("res://Blender models/ps1-clown.glb").instantiate() as Node3D
	root.add_child(clown)
	for node: Node in clown.find_children("*", "Skeleton3D", true, false):
		var skeleton: Skeleton3D = node as Skeleton3D
		for bone: int in skeleton.get_bone_count():
			print("BONE ", bone, " ", skeleton.get_bone_name(bone), " ", skeleton.get_bone_rest(bone))
	var animation: AnimationPlayer = clown.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for title: String in animation.get_animation_list():
		var clip: Animation = animation.get_animation(title)
		print("ANIMATION ", title, " ", clip.length, " tracks ", clip.get_track_count())
	appliances.free()
	clown.free()
	quit()
