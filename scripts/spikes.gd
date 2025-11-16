@tool
extends ShapeCast2D

const INT32_MAX :=  0x7fffffff
const INT32_MIN := -0x80000000

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var direction := DIRECTION.UP:
	get: return direction
	set(v): 
		direction = v
		_reset_shape()
@export_range(1, INT32_MAX) var counts: int = 1:
	get: return counts
	set(v):
		counts = v
		
		_reset_shape()
@export var unit: Vector2 = Vector2(24, 24)
## Shortens the length of the shape cast's target position. [br]
## This value represents the percentage of the original length to trim (0 = no trim, 1 = full trim).
@export_range(0, 1, 0.1) var tolerance: float:
	get: return tolerance
	set(v):
		tolerance = v
		_reset_shape()

@onready var rewindable_hit_action: RewindableAction = $RewindableHitAction

func _init() -> void:
	shape = SegmentShape2D.new()
	
	collide_with_bodies = false
	collide_with_areas = true
	enabled = false
	
	_reset_shape()

func _ready() -> void:
	rewindable_hit_action.mutate(self)

func _rollback_tick(delta: float, tick: int, is_fresh: bool) -> void:
	rewindable_hit_action.set_active(false)
	_emit_damage()

func _emit_damage() -> void:
	force_shapecast_update()
	var hit_count := get_collision_count()
	for hit_idx in range(hit_count):
		var target: Node2D = get_collider(hit_idx).owner
		if not target.has_method("take_damage") \
		or not target.has_method("can_take_damage") \
		or not target.can_take_damage():
			continue
		
		var dir_vec := Vector2.ZERO
		match direction:
			DIRECTION.UP:
				dir_vec = Vector2.UP
			DIRECTION.DOWN:
				dir_vec = Vector2.DOWN
			DIRECTION.LEFT:
				dir_vec = Vector2.LEFT
			DIRECTION.RIGHT:
				dir_vec = Vector2.RIGHT
		
		rewindable_hit_action.set_active(true)
		match rewindable_hit_action.get_status():
			RewindableAction.ACTIVE, RewindableAction.CONFIRMING:
				var is_new_hit := false
				if not rewindable_hit_action.has_context():
					rewindable_hit_action.set_context(true)
					is_new_hit = true
				target.take_damage({ "direction": dir_vec }, is_new_hit)
			RewindableAction.CANCELLING:
				rewindable_hit_action.erase_context()

func _reset_shape() -> void:
	match direction:
		DIRECTION.UP:
			target_position = Vector2.UP * unit.y * (1. - tolerance)
			shape.a = Vector2(-unit.x * counts / 2., 0)
			shape.b = Vector2(+unit.x * counts / 2., 0)
		DIRECTION.DOWN:
			target_position = Vector2.DOWN * unit.y * (1. - tolerance)
			shape.a = Vector2(-unit.x * counts / 2., 0)
			shape.b = Vector2(+unit.x * counts / 2., 0)
		DIRECTION.LEFT:
			target_position = Vector2.LEFT * unit.x * (1. - tolerance)
			shape.a = Vector2(0, -unit.x * counts / 2.)
			shape.b = Vector2(0, +unit.x * counts / 2.)
		DIRECTION.RIGHT:
			target_position = Vector2.RIGHT * unit.x * (1. - tolerance)
			shape.a = Vector2(0, -unit.x * counts / 2.)
			shape.b = Vector2(0, +unit.x * counts / 2.)
