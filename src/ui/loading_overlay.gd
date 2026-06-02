class_name LoadingOverlay
extends CanvasLayer

var terrain_manager: Node
var _panel: ColorRect
var _label: Label
var _bar: ProgressBar


func setup(p_terrain_manager: Node) -> void:
	terrain_manager = p_terrain_manager


func _ready() -> void:
	layer = 20
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.06, 0.92)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	add_child(_panel)

	_label = Label.new()
	_label.text = "preparando mundo"
	_label.anchor_left = 0.5
	_label.anchor_top = 0.5
	_label.anchor_right = 0.5
	_label.anchor_bottom = 0.5
	_label.offset_left = -220.0
	_label.offset_top = -52.0
	_label.offset_right = 220.0
	_label.offset_bottom = -16.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.84))
	add_child(_label)

	_bar = ProgressBar.new()
	_bar.anchor_left = 0.5
	_bar.anchor_top = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_bottom = 0.5
	_bar.offset_left = -180.0
	_bar.offset_top = 8.0
	_bar.offset_right = 180.0
	_bar.offset_bottom = 24.0
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 0.0
	_bar.show_percentage = false
	add_child(_bar)


func _process(_delta: float) -> void:
	if terrain_manager == null:
		return

	var progress: float = terrain_manager.get_generation_progress()
	var pending: int = terrain_manager.get_pending_chunk_count()
	_bar.value = progress
	_label.text = "%s\nchunks pendentes: %d | %.0f%%" % [
		terrain_manager.get_status_message(),
		pending,
		progress * 100.0,
	]

	if progress >= 0.99 and pending <= 0:
		visible = false
