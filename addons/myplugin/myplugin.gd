@tool
extends EditorPlugin

var plugin_control: Control

func _enter_tree():
	plugin_control = preload("./my_plugin_control.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(plugin_control)
	plugin_control.hide()

func _has_main_screen():
	return true

func _make_visible(visible):
	plugin_control.visible = visible

func _get_plugin_name():
	return "Custom Plugin"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Line2D", "EditorIcons")

func _exit_tree() -> void:
	if plugin_control:
		plugin_control.queue_free()
