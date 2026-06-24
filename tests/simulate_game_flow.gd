extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	var game: Node = packed.instantiate()
	get_root().add_child(game)
	await process_frame

	if not _expect(game.current_node_id == "", "Game should start on title."):
		quit(1)
		return

	game._start_game()
	if not _expect(game.current_node_id == "intro", "Start should enter intro."):
		quit(1)
		return

	while game.current_node_id == "intro":
		game._advance_story()

	if not _expect(game.current_node_id == "investigation", "Intro should lead to investigation."):
		quit(1)
		return

	game._choose_investigation("review_history")
	game._choose_investigation("check_handout")
	game._choose_investigation("inspect_power")
	if not _expect(bool(game.evidence_unlocked.get("town_power_log", false)), "Investigation should unlock town_power_log."):
		quit(1)
		return

	game._advance_from_investigation()
	while game.current_node_id == "debate_opening":
		game._advance_story()

	if not _expect(game.current_node_id == "main_debate", "Debate opening should lead to main debate."):
		quit(1)
		return

	game._enter_present_mode()
	game._present_or_select_evidence("ar_glasses")
	if not _expect(game.reputation == 4, "Wrong evidence should reduce reputation."):
		quit(1)
		return

	game._move_statement(1)
	game._move_statement(1)
	game._press_statement()
	if not _expect(String(game.feedback_text).contains("异常电场"), "Pressing the contradiction should reveal a hint."):
		quit(1)
		return

	game._enter_present_mode()
	game._present_or_select_evidence("town_power_log")
	if not _expect(game.current_node_id == "reveal_mimeiko_spirit", "Correct evidence should enter reveal node."):
		quit(1)
		return

	while game.current_node_id == "reveal_mimeiko_spirit":
		game._advance_story()

	if not _expect(game.current_node_id == "ending_truth_thread", "Reveal node should reach the victory result."):
		quit(1)
		return

	print("Gameplay flow simulation passed.")
	game.queue_free()
	quit(0)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
