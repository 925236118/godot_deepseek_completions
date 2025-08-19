@tool
class_name ResultCode
extends Control
@onready var code_edit: CodeEdit = %CodeEdit
@onready var loading_container: MarginContainer = $LoadingContainer
@onready var code_container: MarginContainer = $CodeContainer
@onready var loading_point: Label = $LoadingContainer/MarginContainer/HBoxContainer/LoadingPoint
@onready var insert_button: Button = $CodeContainer/PanelContainer/VBoxContainer/HBoxContainer/HBoxContainer/InsertButton
@onready var re_generate_button: Button = $CodeContainer/PanelContainer/VBoxContainer/HBoxContainer/HBoxContainer/ReGenerateButton

signal insert_code(code: String)
signal regenerate
signal discard_code

var loading_point_count: int = 0

func _ready() -> void:
	var highlighter = GDScriptSyntaxHighlighter.new()
	code_edit.syntax_highlighter = highlighter

func show_loading():
	loading_container.show()
	code_container.hide()
	insert_button.disabled = true
	re_generate_button.disabled = true

func add_code(code: String):
	loading_container.hide()
	code_container.show()
	code_edit.text += code
	code_edit.editable = false
	code_edit.scroll_vertical = 10000

func show_code(code: String):
	loading_container.hide()
	code_container.show()
	code_edit.text = code

func handle_generate_finish():
	code_edit.editable = true
	insert_button.disabled = false
	re_generate_button.disabled = false

func _on_insert_button_pressed() -> void:
	insert_code.emit(code_edit.text)

func _on_re_generate_button_pressed() -> void:
	regenerate.emit()

func _on_discard_button_pressed() -> void:
	discard_code.emit()

func _on_loading_timer_timeout() -> void:
	loading_point_count += 1
	loading_point.text = ".".repeat((loading_point_count + 1) % 4)

func clear():
	code_edit.text = ""
