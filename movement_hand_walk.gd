@tool
class_name XRToolsMovementHandWalk
extends XRToolsMovementProvider


## Movement provider order
@export var order : int = 15

## Velocity multiplier when flinging up walls
@export var fling_multiplier : float = 0.5
@export var max_velocity : float = 10.0

@export var grav : float = 9.8
var cur_grav_force : float = 0.0

# Velocity averager
@export var velocity_averages : int = 5
@onready var _averager := XRToolsVelocityAveragerLinear.new(velocity_averages)

@onready var _left_pusher_node := XRToolsHandPusher.find_left(self)
@onready var _right_pusher_node := XRToolsHandPusher.find_right(self)


func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementHandWalk" or super(name)

func _ready():
	super()
	_left_pusher_node.move_by_offset.connect(update_move_offset_l)
	_right_pusher_node.move_by_offset.connect(update_move_offset_r)

var move_offset_l : Vector3
var move_offset_r : Vector3
func update_move_offset_l(_move_offset: Vector3):
	move_offset_l = _move_offset
func update_move_offset_r(_move_offset: Vector3):
	move_offset_r = _move_offset

## Perform player physics movement
var _was_touching_floor = false
const MAX_MOVE_OFFSET = 0.1
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	if disabled or !enabled:
		return
	
	var left_collided = _left_pusher_node.get_slide_collision_count() != 0
	var right_collided = _right_pusher_node.get_slide_collision_count() != 0
	var touching_floor = _left_pusher_node.is_on_floor() or _right_pusher_node.is_on_floor() or player_body.is_on_floor()
	var touching_anything = left_collided or right_collided or player_body.get_slide_collision_count() != 0
	
	var total_move_offset = move_offset_l + move_offset_r
	var move_offset_len = total_move_offset.length()
	if move_offset_len > MAX_MOVE_OFFSET:
		total_move_offset = total_move_offset / move_offset_len * MAX_MOVE_OFFSET
	
	total_move_offset /= delta
	
	move_offset_l = Vector3.ZERO
	move_offset_r = Vector3.ZERO
	
	if touching_floor or total_move_offset.y > 0.0:
		cur_grav_force = 0.1
	else:
		cur_grav_force += grav * delta
	
	
	if touching_anything:
		_averager.add_distance(delta, total_move_offset)
	
	if touching_floor:
		if !_was_touching_floor:
			_averager.clear()
		player_body.velocity = total_move_offset
	else:
		player_body.velocity = _averager.velocity() * delta * fling_multiplier
		var v = player_body.velocity.length()
		if v > max_velocity:
			player_body.velocity = player_body.velocity / v * max_velocity
		player_body.velocity += total_move_offset
	
	player_body.velocity += Vector3.DOWN * cur_grav_force
	player_body.move_and_slide()
	
	_was_touching_floor = touching_floor
	return true


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify the left controller pickup
	if !XRToolsHandPusher.find_left(self):
		warnings.append("Unable to find left XRToolsHandPusher node")

	# Verify the right controller pickup
	if !XRToolsHandPusher.find_right(self):
		warnings.append("Unable to find right XRToolsHandPusher node")

	# Verify velocity averages
	if velocity_averages < 2:
		warnings.append("Minimum of 2 velocity averages needed")

	# Return warnings
	return warnings
