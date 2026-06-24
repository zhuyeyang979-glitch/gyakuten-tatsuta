extends SceneTree

const GameDataResource := preload("res://scripts/GameData.gd")
const STORY_PATH := "res://data/story.json"


func _init() -> void:
	var exit_code := 0
	var data = GameDataResource.new()
	if not data.load_from_file(STORY_PATH):
		push_error("Could not load story data.")
		quit(1)
		return

	var errors: Array[String] = data.validate()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return

	exit_code = _validate_debate_flow(data)
	if exit_code == 0:
		print("Game data validation passed.")
	quit(exit_code)


func _validate_debate_flow(data) -> int:
	var debate: Dictionary = data.get_debate("means_and_results")
	if debate.is_empty():
		push_error("Missing target debate.")
		return 1

	var statements: Array = debate.get("statements", [])
	if statements.is_empty():
		push_error("Target debate has no statements.")
		return 1

	var correct_statement: Dictionary = data.get_first_correct_statement("means_and_results")
	if correct_statement.is_empty():
		push_error("Target debate has no correct evidence path.")
		return 1

	var evidence_id := String(correct_statement.get("contradiction_evidence_id", ""))
	if not data.evidence.has(evidence_id):
		push_error("Correct statement points to missing evidence.")
		return 1

	var success_node := String(correct_statement.get("success_node", ""))
	if not data.nodes.has(success_node):
		push_error("Correct statement points to missing success node.")
		return 1

	var reputation := 5
	var wrong_statement: Dictionary = statements[0]
	reputation -= int(wrong_statement.get("wrong_penalty", 1))
	if reputation != 4:
		push_error("Wrong evidence should reduce reputation by one.")
		return 1

	var zero_reputation := 1
	zero_reputation -= int(wrong_statement.get("wrong_penalty", 1))
	if zero_reputation > 0 or not data.nodes.has("fail_retry"):
		push_error("Reputation zero must have a fail/retry node.")
		return 1

	return 0
