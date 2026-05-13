extends Node

# 注意：单例不建议使用 const 预加载主场景里的资源，除非路径绝对固定
# 如果运行报错，请确认此路径正确
const PERSON_SCENE = preload("res://scenes/entities/person.tscn")

@export var spawn_rate: float = 1
var time_elapsed: float = 0.0

# 缓存数组
var windows: Array = []
var tables: Array = []

func _ready():
	# 单例启动时，主场景可能还没加载，所以这里我们先不抓取
	# 具体的抓取留在第一次产生小人或者 assign_table 时进行
	pass

# 核心：刷新环境感知
func refresh_nodes():
	windows = get_tree().get_nodes_in_group("windows")
	tables = get_tree().get_nodes_in_group("tables")

func _process(delta):
	time_elapsed += delta
	if time_elapsed >= spawn_rate:
		time_elapsed = 0
		_spawn_and_direct_person()

func _spawn_and_direct_person():
	# 每次产生人之前，确保我们知道窗口在哪
	if windows.is_empty():
		refresh_nodes()

	if windows.is_empty():
		push_warning("仿真引擎：找不到任何窗口，请确认窗口已打组！")
		return

	var p = PERSON_SCENE.instantiate()

	# 1. 坐标修正：(400, -200)
	p.global_position = Vector2(400, -200)

	# 2. 【关键】单例要把人加到当前运行的主场景里，而不是加到单例节点下
	# get_tree().current_scene 指向的就是你的 Canteen.tscn
	get_tree().current_scene.add_child(p)

	var target_win = get_best_window(p.global_position)
	if target_win:
		# 这里使用 ActivityState 全局单例
		p.move_to_node(target_win, ActivityState.State.QUEUING)

func get_best_window(current_pos: Vector2) -> Node:
	var best_win = null
	var min_cost = 999999.0

	for w in windows:
		# 这里的 w.queue 对应你 Window 脚本里的变量名
		var queue_size = w.queue.size() if "queue" in w else 0
		var dist = current_pos.distance_to(w.global_position)
		var cost = dist + (queue_size * 200.0)

		if cost < min_cost:
			min_cost = cost
			best_win = w
	return best_win

# 这个方法现在由 window.gd 直接调用：SimulationEngine.assign_table(person)
func assign_table(person: CharacterBody2D):
	refresh_nodes()
	var best_table = null
	var min_dist = 999999.0

	if tables.is_empty():
		push_warning("仿真引擎：找不到任何桌子，请确认桌子已打组！")
		return

	for t in tables:
		if t.has_method("is_full") and not t.is_full():
			var d = person.global_position.distance_to(t.global_position)
			if d < min_dist:
				min_dist = d
				best_table = t

	if best_table:
		# 1. 获取该桌子下一个空位的全局坐标
		var target_global_pos = best_table.get_next_available_seat_global_pos()
		
		if target_global_pos == null:
			push_error("无法获取座位坐标")
			return

		# 2. 设置小人的 target_node 为桌子，以便到达时触发吃饭逻辑（必须在 add_occupant 前）
		person.target_node = best_table
		
		# 3. 占位（防止后续的小人挤到同一个座位）
		best_table.add_occupant(person)

		# 4. 引导小人前往具体的座位坐标
		person.move_to_position(target_global_pos, ActivityState.State.ORDER_COMPLETED)

		print("[assign_table] 已分配 ", person.name, " 到 ", best_table.name, " 的餐位，目标全局坐标: ", target_global_pos)
	else:
		push_warning("仿真引擎：没有可用的桌子，所有桌子都已满员！")

## 减少指定窗口的排队人数（从队首移除）
func reduce_queue_at_window(window_node, amount: int = 1) -> Array:
	if window_node and window_node.has_method("reduce_queue"):
		return window_node.reduce_queue(amount)
	return []

## 减少所有窗口的排队人数
func reduce_all_queues(amount: int = 1):
	refresh_nodes()
	for w in windows:
		w.reduce_queue(amount)
