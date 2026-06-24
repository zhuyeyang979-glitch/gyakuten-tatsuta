extends RefCounted
class_name GameData

var metadata: Dictionary = {}
var evidence: Dictionary = {}
var evidence_order: Array[String] = []
var nodes: Dictionary = {}
var debates: Dictionary = {}


func load_from_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open story data: %s" % path)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Story data must be a JSON object: %s" % path)
		return false

	metadata = parsed.get("metadata", {})
	nodes = parsed.get("nodes", {})
	debates = parsed.get("debates", {})
	evidence.clear()
	evidence_order.clear()

	for item in parsed.get("evidence", []):
		var id := String(item.get("id", ""))
		if id.is_empty():
			continue
		evidence[id] = item
		evidence_order.append(id)

	return true


func validate() -> Array[String]:
	var errors: Array[String] = []

	_require_dict(metadata, "metadata", errors)
	_require_dict(nodes, "nodes", errors)
	_require_dict(debates, "debates", errors)

	if evidence_order.is_empty():
		errors.append("At least one evidence item is required.")

	for evidence_id in evidence_order:
		var item: Dictionary = evidence[evidence_id]
		for key in ["id", "name", "description", "detail", "unlocked"]:
			if not item.has(key):
				errors.append("Evidence '%s' is missing '%s'." % [evidence_id, key])

	for node_id in nodes.keys():
		var node: Dictionary = nodes[node_id]
		var mode := String(node.get("mode", "story"))
		if not node.has("lines"):
			errors.append("Node '%s' is missing 'lines'." % node_id)

		var next_id := String(node.get("next", ""))
		if not next_id.is_empty() and not nodes.has(next_id):
			errors.append("Node '%s' points to missing next node '%s'." % [node_id, next_id])

		if mode == "debate":
			var debate_id := String(node.get("debate_id", ""))
			if debate_id.is_empty() or not debates.has(debate_id):
				errors.append("Node '%s' references missing debate '%s'." % [node_id, debate_id])

		if mode == "investigation":
			for action in node.get("investigations", []):
				var unlock_id := String(action.get("unlock_evidence", ""))
				if not unlock_id.is_empty() and not evidence.has(unlock_id):
					errors.append("Investigation '%s' unlocks missing evidence '%s'." % [action.get("id", ""), unlock_id])

	for debate_id in debates.keys():
		var debate: Dictionary = debates[debate_id]
		var statements: Array = debate.get("statements", [])
		if statements.is_empty():
			errors.append("Debate '%s' has no statements." % debate_id)
		for statement in statements:
			var statement_id := String(statement.get("id", ""))
			for key in ["speaker", "text", "press_text", "hint", "contradiction_evidence_id", "success_node", "wrong_penalty"]:
				if not statement.has(key):
					errors.append("Statement '%s/%s' is missing '%s'." % [debate_id, statement_id, key])

			var evidence_id := String(statement.get("contradiction_evidence_id", ""))
			if not evidence_id.is_empty() and not evidence.has(evidence_id):
				errors.append("Statement '%s/%s' references missing evidence '%s'." % [debate_id, statement_id, evidence_id])

			var success_node := String(statement.get("success_node", ""))
			if not success_node.is_empty() and not nodes.has(success_node):
				errors.append("Statement '%s/%s' points to missing success node '%s'." % [debate_id, statement_id, success_node])

	return errors


func get_first_node_id() -> String:
	return "intro"


func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})


func get_debate(debate_id: String) -> Dictionary:
	return debates.get(debate_id, {})


func get_evidence(evidence_id: String) -> Dictionary:
	return evidence.get(evidence_id, {})


func get_first_correct_statement(debate_id: String) -> Dictionary:
	var debate: Dictionary = get_debate(debate_id)
	for statement in debate.get("statements", []):
		if not String(statement.get("contradiction_evidence_id", "")).is_empty():
			return statement
	return {}


func _require_dict(value, label: String, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("%s must be a dictionary." % label)
