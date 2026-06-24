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

	_advance_story_node(game, "intro")
	if not _expect(game.current_node_id == "investigation", "Intro should lead to investigation."):
		quit(1)
		return

	for action_id in [
		"check_mainstream_note",
		"check_sophia_note",
		"check_theodicy_note",
		"check_roman_note",
		"check_world_note"
	]:
		game._choose_investigation(action_id)

	if not _expect(bool(game.evidence_unlocked.get("note_worldly_analogy", false)), "Investigation should unlock final note."):
		quit(1)
		return

	game._advance_from_investigation()
	_advance_story_node(game, "debate_opening")

	if not _expect(game.current_node_id == "debate_history", "Opening should lead to the first mini debate."):
		quit(1)
		return

	game._enter_present_mode()
	game._present_or_select_evidence("debate_rule_card")
	if not _expect(game.reputation == 4, "Wrong evidence should reduce reputation."):
		quit(1)
		return

	if not _solve_debate(game, "debate_history", 1, "note_mainstream", "win_history", "主流"):
		quit(1)
		return
	_advance_story_node(game, "win_history")

	if not _solve_debate(game, "debate_cosmos", 1, "note_sophia_single", "win_cosmos", "Sophia"):
		quit(1)
		return
	_advance_story_node(game, "win_cosmos")

	if not _solve_debate(game, "debate_theodicy", 1, "note_theodicy_gap", "win_theodicy", "解释恶"):
		quit(1)
		return
	_advance_story_node(game, "win_theodicy")

	if not _solve_debate(game, "debate_trinity", 0, "note_roman_context", "win_trinity", "二世纪"):
		quit(1)
		return
	_advance_story_node(game, "win_trinity")

	if not _solve_debate(game, "debate_life", 1, "note_worldly_analogy", "ending_first_win", "嘲讽"):
		quit(1)
		return

	if not _expect(game.current_node_id == "ending_first_win", "Fifth mini debate should reach the victory result."):
		quit(1)
		return

	print("Gameplay flow simulation passed.")
	game.queue_free()
	quit(0)


func _solve_debate(game: Node, debate_node_id: String, statement_index: int, evidence_id: String, expected_next_node: String, expected_hint: String) -> bool:
	if not _expect(game.current_node_id == debate_node_id, "Expected debate node: %s" % debate_node_id):
		return false

	while game.current_statement_index < statement_index:
		game._move_statement(1)

	game._press_statement()
	if not _expect(String(game.feedback_text).contains(expected_hint), "Pressing should reveal expected hint: %s" % expected_hint):
		return false

	game._choose_player_option(0)
	if not _expect(not String(game.feedback_text).is_empty(), "Player option should produce response text."):
		return false

	game._enter_present_mode()
	game._present_or_select_evidence(evidence_id)
	return _expect(game.current_node_id == expected_next_node, "Correct evidence should enter %s." % expected_next_node)


func _advance_story_node(game: Node, node_id: String) -> void:
	while game.current_node_id == node_id:
		game._advance_story()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
