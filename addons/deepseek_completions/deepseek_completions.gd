@tool
extends EditorPlugin

var script_editor: ScriptEditor = null
var code_editor: CodeEdit = null

const RESULT_CODE = preload("result_code.tscn")
const DEEPSEEK_CHAT = preload("deepseek_chat.tscn")
var deepseek_node: DeepSeekChatStream = null

var result_window: Window = null
var result_code_container: ResultCode = null

func _enter_tree() -> void:
	script_editor = EditorInterface.get_script_editor()
	script_editor.editor_script_changed.connect(_on_editor_script_changed)
	if script_editor.get_current_editor():
		code_editor = script_editor.get_current_editor().get_base_editor()

func _on_editor_script_changed(script: Script):
	var code_index = script_editor.get_open_scripts().find(script)
	code_editor = script_editor.get_open_script_editors()[code_index].get_base_editor()
	if result_window:
		result_window.queue_free()
		result_window = null
		result_code_container = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_I and event.ctrl_pressed:
			#print("--- start completion ---")
			ai_completion()

func _exit_tree() -> void:
	script_editor = null
	code_editor = null
	if deepseek_node:
		deepseek_node.queue_free()
	if result_window:
		result_window.queue_free()
	result_code_container = null

func ai_completion():
	var caret_count = code_editor.get_caret_count()
	#print("caret_count ", caret_count)
	if caret_count > 1:
		return
	var caret_line = code_editor.get_caret_line()
	var caret_column = code_editor.get_caret_column()
	#print("caret_line ", caret_line)
	#print("caret_column ", caret_column)
	var code_string = ""
	for line in caret_line + 1:
		var text = code_editor.get_line(line)
		if line == caret_line:
			text = "".join(text.split("").slice(0, caret_column))
			code_string += text
		else:
			code_string += text
			code_string += '\n'
	#print(code_string)
	show_result_window()
	if not deepseek_node:
		deepseek_node = DEEPSEEK_CHAT.instantiate() as DeepSeekChatStream
		code_editor.add_child(deepseek_node)

		#deepseek_node.generate_finish.connect(_on_deepseek_node_generate_finish)
		deepseek_node.message.connect(_on_message)
		deepseek_node.generate_finish.connect(_on_deepseek_node_generate_finish)
	deepseek_node.post_message(code_string)

func show_result_window():
	var window_offset = Vector2(0, 60)
	var window_position = get_tree().root.position
	if result_window:
		result_window.show()
		result_window.position = code_editor.get_caret_draw_pos(0)
		result_code_container.show_loading()
		result_code_container.clear()
		result_window.set_size(Vector2(300, 100))
		result_window.position = Vector2i(code_editor.get_caret_draw_pos(0)) + Vector2i(code_editor.get_global_rect().position) + Vector2i(window_offset) + Vector2i(window_position)
	else:
		result_window = Window.new()
		result_window.hide()
		result_window.force_native = true
		result_window.borderless = true
		#result_window.always_on_top = true
		code_editor.add_child(result_window)
		result_window.window_input.connect(_result_window_input)
		result_window.close_requested.connect(result_window.hide)
		result_window.show()
		result_window.popup(Rect2(
			Vector2i(code_editor.get_caret_draw_pos(0)) + Vector2i(code_editor.get_global_rect().position) + Vector2i(window_offset) + Vector2i(window_position),
			Vector2(300, 100)
		))
		result_code_container = RESULT_CODE.instantiate() as ResultCode
		result_window.add_child(result_code_container)
		result_code_container.show_loading()
		result_code_container.insert_code.connect(_on_insert_code)
		result_code_container.discard_code.connect(_on_discard_code)
		result_code_container.regenerate.connect(_on_regenerate)
		result_code_container.clear()

var dragging = false
func _result_window_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.is_pressed()
	if event is InputEventMouseMotion and dragging:
		result_window.position += Vector2i(event.relative)

func _on_message(msg: String):
	if result_code_container:
		result_code_container.add_code(msg)
	if result_window:
		result_window.set_size(Vector2(1000, 300))

func _on_deepseek_node_generate_finish():
	if result_code_container:
		result_code_container.handle_generate_finish()

func _on_insert_code(msg):
	code_editor.insert_text_at_caret(msg)
	_on_discard_code()

func _on_discard_code():
	result_window.hide()
	deepseek_node.close()

func _on_regenerate():
	ai_completion()
