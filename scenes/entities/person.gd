extends CharacterBody2D

# 建议在项目设置中定义全局 ActivityState，这里做个兼容定义
enum State { IDLE, QUEUING, ORDERING, ORDER_COMPLETED, EATING, LEAVING }

const SPEED = 200.0
@export var default_eat_duration := 10.0

# 核心状态变量
var current_state = State.IDLE
var target_node: Node2D = null
var last_direction := "forward"

@onready var animated_sprite := $AnimatedSprite2D
@onready var agent := $NavigationAgent2D

func _ready():
	add_to_group("characters")

	# 配置 RVO 避障
	agent.avoidance_enabled = true
	agent.radius = 12.0
	agent.max_speed = SPEED
	agent.path_desired_distance = 20.0
	agent.target_desired_distance = 30.0

	# 连接避障计算完成后的信号
	agent.velocity_computed.connect(_on_velocity_computed)

	update_animation("wait", last_direction)

func _physics_process(_delta):
	# 只有在需要移动的状态下才寻找路径
	if current_state == State.IDLE or current_state == State.ORDER_COMPLETED or current_state == State.QUEUING or current_state == State.LEAVING:
		_process_navigation()
	else:
		# 吃饭或点餐时，原地踏步
		velocity = Vector2.ZERO
		move_and_slide()
		if current_state == State.EATING:
			_handle_eating_animation()
		else:
			update_animation("wait", last_direction)

func _process_navigation():
	# 离场状态独立处理：用距离判断是否到达出口
	if current_state == State.LEAVING:
		if global_position.distance_to(Vector2(400, 100)) < 30:
			queue_free()
			return
		if agent.is_navigation_finished():
			agent.target_position = Vector2(400, 100)
		var exit_next = agent.get_next_path_position()
		var exit_dir = (exit_next - global_position).normalized()
		agent.set_velocity(exit_dir * SPEED)
		return

	if not target_node:
		return

	# 如果已经非常接近目标，直接触发到达逻辑（防止 RVO 在终点附近反复抖动）
	if agent.is_navigation_finished():
		_on_target_reached()
		return

	var next = agent.get_next_path_position()
	var direction = (next - global_position).normalized()

	# 发送速度指令给避障系统（不要直接给 velocity 赋值）
	agent.set_velocity(direction * SPEED)

# RVO 避障计算完毕后的回调（物理层真正移动的地方）
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

	# 动画处理
	if velocity.length() > 5.0:
		var new_dir = _get_direction_string(velocity)
		if new_dir != last_direction:
			last_direction = new_dir
		update_animation("run", last_direction)
	else:
		update_animation("wait", last_direction)

# --- 仿真指令核心接口 ---

## 供外部设置状态（窗口、引擎直接调用）
func set_state(new_state: int):
	current_state = new_state

## 由仿真引擎调用：分配目标
func move_to_position(global_pos: Vector2, new_state: int):
	current_state = new_state
	agent.target_position = global_pos

# 保留原有的 move_to_node 以便兼容窗口逻辑
func move_to_node(node: Node2D, new_state: int):
	if not node:
		return
	target_node = node
	move_to_position(node.global_position, new_state)

func _on_target_reached():
	velocity = Vector2.ZERO

	# 到达窗口逻辑
	if target_node and target_node.is_in_group("windows"):
		current_state = State.QUEUING
		if target_node.has_method("add_to_queue"):
			target_node.add_to_queue(self)
		target_node = null

	# 到达桌子逻辑
	elif target_node and target_node.is_in_group("tables"):
		if target_node.has_method("add_occupant"):
			target_node.add_occupant(self)
			start_eating(default_eat_duration)

# --- 行为动作 ---

func start_eating(duration: float):
	current_state = State.EATING
	_handle_eating_animation()
	await get_tree().create_timer(duration).timeout
	_finish_eating()

func _finish_eating():
	if target_node and target_node.has_method("remove_occupant"):
		target_node.remove_occupant(self)
		print(name, " left table ", target_node.name)

	move_to_position(Vector2(400, 100), State.LEAVING)

func _handle_eating_animation():
	var eat_anim = "player eat " + last_direction
	if animated_sprite.sprite_frames.has_animation(eat_anim):
		if animated_sprite.animation != eat_anim:
			animated_sprite.play(eat_anim)

# --- 工具函数 ---

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
