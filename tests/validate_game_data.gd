extends SceneTree

const GameDataResource := preload("res://scripts/GameData.gd")
const STORY_PATH := "res://data/story.json"

const TARGET_DEBATES := [
	"valentinus_history",
	"valentinus_cosmos",
	"valentinus_theodicy",
	"valentinus_trinity",
	"valentinus_life"
]


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
	for debate_id in TARGET_DEBATES:
		var debate: Dictionary = data.get_debate(debate_id)
		if debate.is_empty():
			push_error("Missing target debate: %s" % debate_id)
			return 1

		var statements: Array = debate.get("statements", [])
		if statements.is_empty():
			push_error("Target debate has no statements: %s" % debate_id)
			return 1

		var correct_statement: Dictionary = data.get_first_correct_statement(debate_id)
		if correct_statement.is_empty():
			push_error("Target debate has no correct evidence path: %s" % debate_id)
			return 1

		var evidence_id := String(correct_statement.get("contradiction_evidence_id", ""))
		if not data.evidence.has(evidence_id):
			push_error("Correct statement points to missing evidence: %s / %s" % [debate_id, evidence_id])
			return 1

		var success_node := String(correct_statement.get("success_node", ""))
		if not data.nodes.has(success_node):
			push_error("Correct statement points to missing success node: %s / %s" % [debate_id, success_node])
			return 1

	var first_debate: Dictionary = data.get_debate(TARGET_DEBATES[0])
	var first_statements: Array = first_debate.get("statements", [])
	var reputation := 5
	var wrong_statement: Dictionary = first_statements[0]
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
