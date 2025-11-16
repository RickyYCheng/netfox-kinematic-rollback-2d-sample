extends CharacterBody2D

@export var speed: float = 300
@export var jump_speed: float = 450
@export var acceleration: float = 3000
@export var gravity: float = 980
@export var input: Node
@export var sprite_2d: Sprite2D

@export var rollback_synchronizer: RollbackSynchronizer

var blink_color : Color:
	get(): return sprite_2d.material.get_shader_parameter("blink_color")
	set(v): sprite_2d.material.set_shader_parameter("blink_color", v)
var blink_intensity : float:
	get(): return sprite_2d.material.get_shader_parameter("blink_intensity")
	set(v): sprite_2d.material.set_shader_parameter("blink_intensity", v)

var _was_hit := false
func can_take_damage() -> bool:
	return true

var _hit_counts := 0
func take_damage(info: Dictionary, is_new_hit: bool = false) -> void:
	if is_new_hit:
		_was_hit = true
		_hit_counts += 1
	velocity.x = info.direction.x * 1000
	NetworkRollback.mutate(self)

var _tween: Tween
func _fx_local_play() -> void:
	if _was_hit:
		prints("[dmg]", _hit_counts)
		
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		blink_color = Color.RED
		blink_intensity = 1.0
		_tween.tween_property(self, "blink_intensity", 0.0, 0.3)
		
		_hit_counts = 0
		_was_hit = false

func _enter_tree() -> void:
	NetworkTime.after_tick_loop.connect(_fx_local_play)

func _exit_tree() -> void:
	NetworkTime.after_tick_loop.disconnect(_fx_local_play)

func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	force_update_transform()
	_force_update_is_on_floor()
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Movement
	var direction = input.movement
	
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	
	# Jump
	if input.is_jumping and is_on_floor():
		velocity.y = -jump_speed
	
	# move_and_slide assumes physics delta
	# multiplying velocity by NetworkTime.physics_factor compensates for it
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _force_update_is_on_floor() -> void:
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity
