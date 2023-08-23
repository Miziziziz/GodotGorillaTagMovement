@tool
class_name XRToolsHandPusher
extends CharacterBody3D


@onready var hand_controller : XRController3D = get_parent()

signal move_by_offset

func is_xr_class(name : String) -> bool:
	return name == "XRToolsHandPusher"

func _ready():
	top_level = true
	global_transform = hand_controller.global_transform

const MAX_DRAG_AMNT = 0.1
func _physics_process(delta):
	if hand_controller == null:
		return
	var offset_to_hand = hand_controller.global_position - global_position
	velocity = offset_to_hand / delta
	var last_pos = global_position
	move_and_slide()
	
	var move_offset : Vector3
	var is_colliding = is_on_ceiling() or is_on_floor() or is_on_wall()
	if get_slide_collision_count() > 0:
		move_offset = global_position - hand_controller.global_position
		var drag_offset = last_pos - global_position
		move_offset += drag_offset
		global_position = last_pos
	else:
		move_offset = global_position - hand_controller.global_position
	move_by_offset.emit(move_offset)
	
	if offset_to_hand.length() > 0.2:
		reset_position()
	
	$Colliding.visible = is_colliding
	$NotColliding.visible != is_colliding

func offset_with_drag(offset:Vector3):
	global_position += offset

func reset_position():
	if hand_controller == null:
		return
	global_transform = hand_controller.global_transform

## This function searches from the specified node for the left controller
## [XRToolsHandPusher] assuming the node is a sibling of the [XOrigin3D].
static func find_left(node : Node) -> XRToolsHandPusher:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsHandPusher") as XRToolsHandPusher

## This function searches from the specified node for the right controller
## [XRToolsHandPusher] assuming the node is a sibling of the [XOrigin3D].
static func find_right(node : Node) -> XRToolsHandPusher:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsHandPusher") as XRToolsHandPusher


