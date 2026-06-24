extends Control

const GameDataResource := preload("res://scripts/GameData.gd")
const STORY_PATH := "res://data/story.json"
const MAX_REPUTATION := 5

var game_data
var current_node_id := ""
var current_line_index := 0
var current_debate_id := ""
var current_statement_index := 0
var reputation := MAX_REPUTATION
var feedback_text := ""
var present_mode := false
var selected_evidence_id := ""
var evidence_unlocked: Dictionary = {}
var examined_actions: Dictionary = {}

var header_title: Label
var reputation_label: Label
var main_box: VBoxContainer
var evidence_panel: PanelContainer
var evidence_box: VBoxContainer
var footer_box: HBoxContainer


func _ready() -> void:
	game_data = GameDataResource.new()
	_build_shell()

	if not game_data.load_from_file(STORY_PATH):
		_show_boot_error("无法读取剧情数据。")
		return

	var errors: Array[String] = game_data.validate()
	if not errors.is_empty():
		_show_boot_error("\n".join(errors))
		return

	_show_title()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#10151f")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	header_title = _make_label("", 24, Color("#f4f1de"))
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_title)

	reputation_label = _make_label("", 20, Color("#ef476f"))
	reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reputation_label.custom_minimum_size = Vector2(230, 0)
	header.add_child(reputation_label)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var main_panel := PanelContainer.new()
	main_panel.add_theme_stylebox_override("panel", _panel_style(Color("#17202f"), Color("#3d5a80")))
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(main_panel)

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 14)
	main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(main_box)

	evidence_panel = PanelContainer.new()
	evidence_panel.add_theme_stylebox_override("panel", _panel_style(Color("#20222e"), Color("#ffd166")))
	evidence_panel.custom_minimum_size = Vector2(340, 0)
	evidence_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(evidence_panel)

	evidence_box = VBoxContainer.new()
	evidence_box.add_theme_constant_override("separation", 10)
	evidence_panel.add_child(evidence_box)

	var footer_panel := PanelContainer.new()
	footer_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111827"), Color("#2a9d8f")))
	root.add_child(footer_panel)

	footer_box = HBoxContainer.new()
	footer_box.add_theme_constant_override("separation", 10)
	footer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_panel.add_child(footer_box)


func _show_title() -> void:
	current_node_id = ""
	_clear_container(main_box)
	_clear_container(footer_box)
	evidence_panel.visible = false
	header_title.text = String(game_data.metadata.get("title", "逆转辰田"))
	reputation_label.text = ""

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(spacer_top)

	var title := _make_label("逆转辰田", 56, Color("#f4f1de"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(title)

	var case_title := _make_label(String(game_data.metadata.get("case_title", "第一回")), 28, Color("#8bd3dd"))
	case_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(case_title)

	var subtitle := _make_label("文字冒险辩论雏形", 22, Color("#ffd166"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(subtitle)

	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(spacer_bottom)

	var start_button := _make_button("开始", Callable(self, "_start_game"))
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_box.add_child(start_button)


func _start_game() -> void:
	_reset_run_state()
	_go_node(game_data.get_first_node_id())


func _reset_run_state() -> void:
	reputation = MAX_REPUTATION
	feedback_text = ""
	present_mode = false
	selected_evidence_id = ""
	examined_actions.clear()
	evidence_unlocked.clear()

	for evidence_id in game_data.evidence_order:
		var item: Dictionary = game_data.get_evidence(evidence_id)
		evidence_unlocked[evidence_id] = bool(item.get("unlocked", false))


func _go_node(node_id: String) -> void:
	var node: Dictionary = game_data.get_node_data(node_id)
	if node.is_empty():
		_show_boot_error("找不到剧情节点：%s" % node_id)
		return

	current_node_id = node_id
	current_line_index = 0
	present_mode = false
	selected_evidence_id = ""

	match String(node.get("mode", "story")):
		"story":
			_render_story()
		"investigation":
			_render_investigation()
		"debate":
			current_debate_id = String(node.get("debate_id", ""))
			current_statement_index = 0
			_render_debate()
		"result":
			_render_result()
		_:
			_show_boot_error("未知节点模式：%s" % node.get("mode", ""))


func _render_story() -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	var lines: Array = node.get("lines", [])
	_update_header(String(node.get("scene", "")))
	evidence_panel.visible = true
	_render_evidence_panel()
	_clear_container(main_box)
	_clear_container(footer_box)

	if lines.is_empty():
		_advance_story()
		return

	current_line_index = clampi(current_line_index, 0, lines.size() - 1)
	var line: Dictionary = lines[current_line_index]
	main_box.add_child(_make_label(String(node.get("scene", "")), 20, Color("#ffd166")))
	main_box.add_child(_make_separator())
	main_box.add_child(_make_label(String(line.get("speaker", "")), 30, Color("#8bd3dd")))

	var text := _make_label(String(line.get("text", "")), 31, Color("#f4f1de"))
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(text)

	var button_text := "继续" if current_line_index + 1 >= lines.size() else "下一句"
	footer_box.add_child(_make_button(button_text, Callable(self, "_advance_story")))


func _advance_story() -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	var lines: Array = node.get("lines", [])
	current_line_index += 1
	if current_line_index >= lines.size():
		var next_id := String(node.get("next", ""))
		if next_id.is_empty():
			_render_result()
		else:
			_go_node(next_id)
	else:
		_render_story()


func _render_investigation() -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	_update_header(String(node.get("scene", "")))
	evidence_panel.visible = true
	_render_evidence_panel()
	_clear_container(main_box)
	_clear_container(footer_box)

	main_box.add_child(_make_label(String(node.get("scene", "")), 24, Color("#ffd166")))
	main_box.add_child(_make_separator())
	for line in node.get("lines", []):
		main_box.add_child(_make_label("%s：%s" % [line.get("speaker", ""), line.get("text", "")], 24, Color("#f4f1de")))

	var actions_label := _make_label("调查", 26, Color("#8bd3dd"))
	main_box.add_child(actions_label)

	for action in node.get("investigations", []):
		var action_id := String(action.get("id", ""))
		var title := String(action.get("title", "调查"))
		if examined_actions.has(action_id):
			title = "已调查 / " + title
		main_box.add_child(_make_button(title, Callable(self, "_choose_investigation").bind(action_id)))

	if not feedback_text.is_empty():
		main_box.add_child(_make_feedback_box(feedback_text))

	var ready := _all_investigations_done(node)
	footer_box.add_child(_make_button("进入辩论", Callable(self, "_advance_from_investigation"), not ready))
	footer_box.add_child(_make_button("回到标题", Callable(self, "_show_title")))


func _choose_investigation(action_id: String) -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	for action in node.get("investigations", []):
		if String(action.get("id", "")) == action_id:
			examined_actions[action_id] = true
			var unlock_id := String(action.get("unlock_evidence", ""))
			if not unlock_id.is_empty():
				evidence_unlocked[unlock_id] = true
			feedback_text = String(action.get("text", ""))
			_render_investigation()
			return


func _advance_from_investigation() -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	feedback_text = ""
	_go_node(String(node.get("next", "")))


func _all_investigations_done(node: Dictionary) -> bool:
	for action in node.get("investigations", []):
		if not examined_actions.has(String(action.get("id", ""))):
			return false
	return true


func _render_debate() -> void:
	var debate: Dictionary = game_data.get_debate(current_debate_id)
	var statements: Array = debate.get("statements", [])
	_update_header(String(debate.get("title", "交叉辩论")))
	evidence_panel.visible = true
	_render_evidence_panel()
	_clear_container(main_box)
	_clear_container(footer_box)

	if statements.is_empty():
		_show_boot_error("辩论没有陈述：%s" % current_debate_id)
		return

	current_statement_index = clampi(current_statement_index, 0, statements.size() - 1)
	var statement: Dictionary = statements[current_statement_index]

	main_box.add_child(_make_label(String(debate.get("title", "")), 24, Color("#ffd166")))
	main_box.add_child(_make_label("对手：" + String(debate.get("opponent", "")), 20, Color("#8bd3dd")))
	main_box.add_child(_make_separator())
	main_box.add_child(_make_label("第 %d / %d 句" % [current_statement_index + 1, statements.size()], 20, Color("#9ca3af")))
	main_box.add_child(_make_label(String(statement.get("speaker", "")), 30, Color("#8bd3dd")))

	var statement_text := _make_label(String(statement.get("text", "")), 32, Color("#f4f1de"))
	statement_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(statement_text)

	if not feedback_text.is_empty():
		main_box.add_child(_make_feedback_box(feedback_text))

	footer_box.add_child(_make_button("前一句", Callable(self, "_move_statement").bind(-1), current_statement_index == 0))
	footer_box.add_child(_make_button("后一句", Callable(self, "_move_statement").bind(1), current_statement_index == statements.size() - 1))
	footer_box.add_child(_make_button("追问", Callable(self, "_press_statement")))
	footer_box.add_child(_make_button("指证", Callable(self, "_enter_present_mode")))


func _move_statement(delta: int) -> void:
	current_statement_index += delta
	feedback_text = ""
	present_mode = false
	selected_evidence_id = ""
	_render_debate()


func _press_statement() -> void:
	var statement: Dictionary = _current_statement()
	present_mode = false
	feedback_text = "%s\n\n【提示】%s" % [statement.get("press_text", ""), statement.get("hint", "")]
	_render_debate()


func _enter_present_mode() -> void:
	present_mode = true
	selected_evidence_id = ""
	feedback_text = "选择证物进行指证。"
	_render_debate()


func _present_or_select_evidence(evidence_id: String) -> void:
	if present_mode and _current_mode() == "debate":
		_present_evidence(evidence_id)
		return

	selected_evidence_id = evidence_id
	_rerender_current_mode()


func _present_evidence(evidence_id: String) -> void:
	var statement: Dictionary = _current_statement()
	var expected := String(statement.get("contradiction_evidence_id", ""))
	if not expected.is_empty() and evidence_id == expected:
		var evidence_name := String(game_data.get_evidence(evidence_id).get("name", evidence_id))
		feedback_text = "异议成立：%s 击中了这句陈述的前提。" % evidence_name
		_go_node(String(statement.get("success_node", "")))
		return

	var penalty := int(statement.get("wrong_penalty", 1))
	reputation -= penalty
	present_mode = false
	selected_evidence_id = evidence_id
	if reputation <= 0:
		reputation = 0
		_go_node("fail_retry")
		return

	var wrong_name := String(game_data.get_evidence(evidence_id).get("name", evidence_id))
	feedback_text = "%s 还不能推翻这句话。信誉 -%d。" % [wrong_name, penalty]
	_render_debate()


func _render_result() -> void:
	var node: Dictionary = game_data.get_node_data(current_node_id)
	_update_header(String(node.get("scene", "")))
	evidence_panel.visible = true
	_render_evidence_panel()
	_clear_container(main_box)
	_clear_container(footer_box)

	main_box.add_child(_make_label(String(node.get("scene", "")), 30, Color("#ffd166")))
	main_box.add_child(_make_separator())
	for line in node.get("lines", []):
		main_box.add_child(_make_label("%s：%s" % [line.get("speaker", ""), line.get("text", "")], 28, Color("#f4f1de")))

	var ending := String(node.get("ending", ""))
	if ending == "debate_win":
		main_box.add_child(_make_feedback_box("阶段胜利：本月位格的关键裂缝已被指出。"))
	else:
		main_box.add_child(_make_feedback_box("辩论失败。可以从交叉辩论重新尝试。"))
		footer_box.add_child(_make_button("重试辩论", Callable(self, "_retry_debate")))

	footer_box.add_child(_make_button("回到标题", Callable(self, "_show_title")))


func _retry_debate() -> void:
	reputation = MAX_REPUTATION
	feedback_text = ""
	present_mode = false
	selected_evidence_id = ""
	_go_node("main_debate")


func _render_evidence_panel() -> void:
	_clear_container(evidence_box)

	var heading := _make_label("证物", 24, Color("#ffd166"))
	evidence_box.add_child(heading)
	if present_mode:
		evidence_box.add_child(_make_label("指证中", 18, Color("#ef476f")))

	var has_visible_evidence := false
	for evidence_id in game_data.evidence_order:
		if not bool(evidence_unlocked.get(evidence_id, false)):
			continue
		has_visible_evidence = true
		var item: Dictionary = game_data.get_evidence(evidence_id)
		var title := String(item.get("name", evidence_id))
		if evidence_id == selected_evidence_id:
			title = "> " + title
		evidence_box.add_child(_make_button(title, Callable(self, "_present_or_select_evidence").bind(evidence_id)))

	if not has_visible_evidence:
		evidence_box.add_child(_make_label("无", 18, Color("#9ca3af")))

	if not selected_evidence_id.is_empty():
		var selected: Dictionary = game_data.get_evidence(selected_evidence_id)
		evidence_box.add_child(_make_separator())
		evidence_box.add_child(_make_label(String(selected.get("description", "")), 18, Color("#f4f1de")))
		evidence_box.add_child(_make_label(String(selected.get("detail", "")), 16, Color("#cbd5e1")))


func _current_statement() -> Dictionary:
	var debate: Dictionary = game_data.get_debate(current_debate_id)
	var statements: Array = debate.get("statements", [])
	if statements.is_empty():
		return {}
	current_statement_index = clampi(current_statement_index, 0, statements.size() - 1)
	return statements[current_statement_index]


func _current_mode() -> String:
	if current_node_id.is_empty():
		return "title"
	return String(game_data.get_node_data(current_node_id).get("mode", "story"))


func _rerender_current_mode() -> void:
	match _current_mode():
		"title":
			_show_title()
		"story":
			_render_story()
		"investigation":
			_render_investigation()
		"debate":
			_render_debate()
		"result":
			_render_result()


func _update_header(scene_name: String) -> void:
	var title := String(game_data.metadata.get("title", "逆转辰田"))
	header_title.text = title if scene_name.is_empty() else "%s / %s" % [title, scene_name]

	var marks := ""
	for index in range(MAX_REPUTATION):
		marks += "■" if index < reputation else "□"
	reputation_label.text = "信誉 " + marks


func _show_boot_error(message: String) -> void:
	_clear_container(main_box)
	_clear_container(footer_box)
	evidence_panel.visible = false
	header_title.text = "逆转辰田"
	reputation_label.text = ""
	main_box.add_child(_make_label("启动失败", 34, Color("#ef476f")))
	main_box.add_child(_make_feedback_box(message))


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_button(text: String, target: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(target)
	return button


func _make_feedback_box(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#2d1f30"), Color("#ef476f")))
	var label := _make_label(text, 21, Color("#f4f1de"))
	panel.add_child(label)
	return panel


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", Color("#3d5a80"))
	return separator


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	return style


func _clear_container(container: Container) -> void:
	while container.get_child_count() > 0:
		var child := container.get_child(0)
		container.remove_child(child)
		child.queue_free()
