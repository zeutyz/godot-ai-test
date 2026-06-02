extends SceneTree

const WORLD_LIGHTING_RIG_SCRIPT = preload("res://src/world/world_lighting_rig.gd")


func _init() -> void:
	var rig: Node3D = WORLD_LIGHTING_RIG_SCRIPT.new()
	get_root().add_child(rig)
	await process_frame
	var report: Dictionary = rig.get_quality_report()
	print("VISUAL_QUALITY sdfgi=%s ssao=%s ssil=%s glow=%s sun_shadows=%s shadow_distance=%.1f voxel_gi_size_x=%.1f" % [
		str(report["sdfgi"]),
		str(report["ssao"]),
		str(report["ssil"]),
		str(report["glow"]),
		str(report["sun_shadows"]),
		float(report["shadow_distance"]),
		float(report["voxel_gi_size_x"]),
	])
	var passes: bool = bool(report["sdfgi"]) and bool(report["ssao"]) and bool(report["ssil"]) and bool(report["glow"]) and bool(report["sun_shadows"])
	passes = passes and float(report["shadow_distance"]) >= 300.0 and float(report["voxel_gi_size_x"]) >= 240.0
	rig.free()
	quit(0 if passes else 1)
