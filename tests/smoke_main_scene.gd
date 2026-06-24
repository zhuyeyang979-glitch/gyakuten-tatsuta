extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Could not load Main.tscn.")
		quit(1)
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		push_error("Could not instantiate Main.tscn.")
		quit(1)
		return

	get_root().add_child(instance)
	await process_frame

	if not instance.has_node("."):
		push_error("Main scene instance is invalid.")
		quit(1)
		return

	instance.queue_free()
	print("Main scene smoke test passed.")
	quit(0)
