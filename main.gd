extends Node3D

func _ready():
	var xr_interface : XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		var vp : Viewport = get_viewport()
		vp.use_xr = true

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
