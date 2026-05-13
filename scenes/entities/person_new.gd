extends CharacterBody2D

enum State { IDLE, QUEUING, ORDERING, ORDER_COMPLETED, EATING, LEAVING }

const SPEED = 200.0
@export var default_eat_duration := 10.0

var current_state = State.IDLE
var target_node: Node2D = null
var last_direction := "forward"

@onready var animated_sprite := $AnimatedSprite2D
@onready var agent := $NavigationAgent2D

func _ready():
	add_to_group("characters")
	agent.avoidance_enabled = true
	agent.radius = 12.0
	agent.max_speed = SPEED
	agent.path_desired_distance = 20.0
	agent.target_desired_distance = 30.0
	agent.velocity_computed.connect(_on_velocity_computed)
	update_animation("wait", last_direction)

func _physics_process(_delta):
	if current_state == State.IDLE or current_state == State.ORDER_COMPLETED or current_state == State.QUEUING or current_state == State.LEAVING:
		_process_navigation()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if current_state == State.EATING:
			_handle_eating_animation()
		else:
			update_animation("wait", last_direction)

func _process_navigation():
	if not target_node:
		return
	if agent.is_navigation_finished():
		_on_target_reached()
		return
	var next = agent.get_next_path_position()
	var direction = (next - global_position).normalized()
	agent.set_velocity(direction * SPEED)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	if velocity.length() > 5.0:
		var new_dir = _get_direction_string(velocity)
		if new_dir != last_direction:
			last_direction = new_dir
		update_animation("run", last_direction)
	else:
		update_animation("wait", last_direction)

func set_state(new_state: int):
	current_state = new_state

func move_to_position(global_pos: Vector2, new_state: int):
	current_state = new_state
	agent.target_position = global_pos

func move_to_node(node: Node2D, new_state: int):
	if not node: 
		return
	target_node = node
	move_to_position(node.global_position, new_state)

func _on_target_reached():
	velocity = Vector2.ZERO
	if current_state == State.LEAVING:
		queue_free()
		return
	if target_node and target_node.is_in_group("windows"):
		current_state = State.QUEUING
		if target_node.has_method("add_to_queue"):
			target_node.add_to_queue(self)
		target_node = null
	elif target_node and target_node.is_in_group("tables"):
		if target_node.has_method("add_occupant"):
			target_node.add_occupant(self)
			start_eating(default_eat_duration)
		target_node = null

func start_eating(duration: float):
	current_state = State.EATING
	_handle_eating_animation()
	await get_tree().create_timer(duration).timeout
	_finish_eating()

func _finish_eating():
	if target_node and target_node.has_method("remove_occupant"):
		target_node.remove_occupant(self)
		target_node = null
	move_to_position(Vector2(400, 100), State.LEAVING)

func _handle_eating_animation():
	var eat_anim = "player eat " + last_direction
	if animated_sprite.sprite_frames.has_animation(eat_anim):
		if animated_sprite.animation != eat_anim:
			animated_sprite.play(eat_anim)

func _get_direction_string(vel: Vector2) -> String:
	if abs(vel.x) > abs(vel.y):
		return "right" if vel.x > 0 else "left"
	else:
		return "back" if vel.y < 0 else "forward"

func update_animation(action: String, direction: String):
	var anim_name = "player " + action + " " + direction
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

func _exit_tree():
	if is_inside_tree():
		remove_from_group("characters")
