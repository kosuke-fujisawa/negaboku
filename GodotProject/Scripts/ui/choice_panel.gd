class_name ChoicePanel
extends Control

# 選択肢パネル
# Unity版の選択肢システムをGodot UIで再実装

signal choice_selected(choice_index: int, choice_text: String)
signal choice_hovered(choice_index: int)

@export var button_height: int = 50
@export var button_spacing: int = 10
@export var max_visible_choices: int = 6

var background_panel: Panel
var scroll_container: ScrollContainer
var choice_container: VBoxContainer
var choice_buttons = []

var current_choices = []
var enabled_choices = []
var choice_data = []

func _ready():
	setup_ui()
	visible = false

func setup_ui():
	# 背景パネル
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	background_panel.size = Vector2(600, 400)
	background_panel.position = Vector2(-300, -200)
	add_child(background_panel)
	
	# スクロールコンテナ
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.custom_minimum_size = Vector2(580, 380)
	scroll_container.position = Vector2(10, 10)
	background_panel.add_child(scroll_container)
	
	# 選択肢コンテナ
	choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	choice_container.add_theme_constant_override("separation", button_spacing)
	scroll_container.add_child(choice_container)

func show_choices(choices: Array, enabled_states: Array = [], extra_data: Array = []):
	if choices.is_empty():
		return
	
	current_choices = choices.duplicate()
	
	# enabled_statesが指定されていない場合、すべて有効にする
	if enabled_states.is_empty():
		enabled_choices = []
		for i in choices.size():
			enabled_choices.append(true)
	else:
		enabled_choices = enabled_states.duplicate()
	
	choice_data = extra_data.duplicate()
	
	create_choice_buttons()
	visible = true
	
	# 最初の有効な選択肢にフォーカス
	focus_first_enabled_choice()

func create_choice_buttons():
	# 既存のボタンをクリア
	clear_choice_buttons()
	
	for i in current_choices.size():
		var button = Button.new()
		button.name = "ChoiceButton" + str(i)
		button.text = current_choices[i]
		button.custom_minimum_size.y = button_height
		button.disabled = not enabled_choices[i]
		
		# ボタンの外観設定
		if enabled_choices[i]:
			button.add_theme_color_override("font_color", Color.WHITE)
		else:
			button.add_theme_color_override("font_color", Color.GRAY)
			button.text += " (利用不可)"
		
		# シグナル接続
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		button.mouse_entered.connect(_on_choice_button_hovered.bind(i))
		
		choice_container.add_child(button)
		choice_buttons.append(button)

func clear_choice_buttons():
	for button in choice_buttons:
		if button:
			button.queue_free()
	choice_buttons.clear()

func focus_first_enabled_choice():
	for i in choice_buttons.size():
		if enabled_choices[i]:
			choice_buttons[i].grab_focus()
			break

func _on_choice_button_pressed(choice_index: int):
	if choice_index < 0 or choice_index >= current_choices.size():
		return
	
	if not enabled_choices[choice_index]:
		return
	
	var choice_text = current_choices[choice_index]
	choice_selected.emit(choice_index, choice_text)
	hide_choices()

func _on_choice_button_hovered(choice_index: int):
	choice_hovered.emit(choice_index)

func hide_choices():
	visible = false
	current_choices.clear()
	enabled_choices.clear()
	choice_data.clear()
	clear_choice_buttons()

# キーボード入力での選択
func _input(event: InputEvent):
	if not visible:
		return
	
	if event.is_action_pressed("ui_up"):
		focus_previous_choice()
	elif event.is_action_pressed("ui_down"):
		focus_next_choice()
	elif event.is_action_pressed("ui_accept"):
		select_focused_choice()
	elif event.is_action_pressed("ui_cancel"):
		# キャンセル可能な場合の処理
		hide_choices()

func focus_previous_choice():
	var current_focus_index = get_focused_choice_index()
	if current_focus_index == -1:
		return
	
	for i in range(current_focus_index - 1, -1, -1):
		if enabled_choices[i]:
			choice_buttons[i].grab_focus()
			return
	
	# 最初が見つからない場合、最後から探す
	for i in range(choice_buttons.size() - 1, current_focus_index, -1):
		if enabled_choices[i]:
			choice_buttons[i].grab_focus()
			return

func focus_next_choice():
	var current_focus_index = get_focused_choice_index()
	if current_focus_index == -1:
		return
	
	for i in range(current_focus_index + 1, choice_buttons.size()):
		if enabled_choices[i]:
			choice_buttons[i].grab_focus()
			return
	
	# 最後が見つからない場合、最初から探す
	for i in range(0, current_focus_index):
		if enabled_choices[i]:
			choice_buttons[i].grab_focus()
			return

func get_focused_choice_index() -> int:
	for i in choice_buttons.size():
		if choice_buttons[i].has_focus():
			return i
	return -1

func select_focused_choice():
	var focused_index = get_focused_choice_index()
	if focused_index != -1 and enabled_choices[focused_index]:
		_on_choice_button_pressed(focused_index)

# 選択肢の条件チェック機能
func update_choice_conditions(relationship_system, party_members: Array):
	for i in current_choices.size():
		if i < choice_data.size():
			var data = choice_data[i]
			var is_enabled = check_choice_condition(data, relationship_system, party_members)
			enabled_choices[i] = is_enabled
			
			if choice_buttons.size() > i:
				choice_buttons[i].disabled = not is_enabled
				if is_enabled:
					choice_buttons[i].add_theme_color_override("font_color", Color.WHITE)
					choice_buttons[i].text = current_choices[i]
				else:
					choice_buttons[i].add_theme_color_override("font_color", Color.GRAY)
					choice_buttons[i].text = current_choices[i] + " (条件未達成)"

func check_choice_condition(choice_data: Dictionary, relationship_system, party_members: Array) -> bool:
	# 関係値条件のチェック
	if choice_data.has("required_relationship_level"):
		var char1_id = choice_data.get("char1_id", "")
		var char2_id = choice_data.get("char2_id", "")
		var required_level = choice_data.get("required_relationship_level", "")
		
		if char1_id != "" and char2_id != "" and required_level != "":
			var current_level = relationship_system.get_relationship_level_string(char1_id, char2_id)
			if current_level != required_level:
				return false
	
	# レベル条件のチェック
	if choice_data.has("required_level"):
		var required_level = choice_data.get("required_level", 1)
		var char_id = choice_data.get("character_id", "")
		
		for member in party_members:
			if member.character_id == char_id:
				if member.level < required_level:
					return false
				break
	
	# アイテム所持チェック
	if choice_data.has("required_item"):
		# TODO: アイテムシステム実装後に追加
		pass
	
	return true

# アニメーション効果
func show_with_animation():
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)

func hide_with_animation():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_callback(func(): visible = false)


