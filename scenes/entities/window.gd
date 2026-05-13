# window.gd
extends Area2D

@onready var info_box = %Info_win
var queue: Array = []
var current_queue_size: int = 0
var serving_customer = null
var serve_progress: int = 0
var serve_time_needed: int = 3 # 打饭所需帧数
var linger_progress: int = 0
var linger_time_needed: int = 180 # 取餐后在窗口旁等候的帧数（180帧≈3秒）
var is_lingering: bool = false    # 是否处于等候阶段
var window_name = "1号风味窗口"
var today_menu = "甜甜花酿鸡"

func _ready():
	add_to_group("windows")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	info_box.hide()

func _process(_delta):
	# 仿真逻辑：处理排队
	if serving_customer != null:
		if not is_lingering:
			# 阶段1：打饭中
			serve_progress += 1
			if serve_progress >= serve_time_needed:
				# 打完饭，进入等候阶段（人仍然占据队列位置）
				is_lingering = true
				linger_progress = 0
		else:
			# 阶段2：取餐后在窗口旁等候
			linger_progress += 1
			if linger_progress >= linger_time_needed:
				_finish_serving()
	elif not queue.is_empty():
		# 引用队首但不 pop，让人仍然占据在队列之中
		serving_customer = queue[0]
		if serving_customer.has_method("set_state"):
			serving_customer.set_state(ActivityState.State.ORDERING)
		serve_progress = 0
		is_lingering = false

func _finish_serving():
	if serving_customer:
		# 从队列中移除（现在才真正离开窗口队列）
		if not queue.is_empty() and queue[0] == serving_customer:
			queue.pop_front()
			current_queue_size = queue.size()

		# 1. 切换状态
		if serving_customer.has_method("set_state"):
			serving_customer.set_state(ActivityState.State.ORDER_COMPLETED)

		# 2. 直接调用 Autoload 单例
		if SimulationEngine.has_method("assign_table"):
			SimulationEngine.assign_table(serving_customer)
			print("窗口已通过单例通知引擎：[", serving_customer.name, "] 准备就餐")
		else:
			push_error("Autoload 中未找到 SimulationEngine 或缺少 assign_table 方法")

	serving_customer = null
	is_lingering = false

func add_to_queue(person):
	if queue.has(person):
		return
	queue.append(person)
	current_queue_size = queue.size()

## 从队列中移除指定的人（如：取消排队）
func remove_from_queue(person):
	if queue.has(person):
		queue.erase(person)
		current_queue_size = queue.size()
		if person.has_method("set_state"):
			person.set_state(ActivityState.State.LEAVING)

## 从队首移除指定数量的人，可选让他们离开场景
func reduce_queue(amount: int = 1) -> Array:
	var removed = []
	var count = mini(amount, queue.size())
	for i in range(count):
		var person = queue.pop_front()
		if person:
			removed.append(person)
			if person.has_method("set_state"):
				person.set_state(ActivityState.State.LEAVING)
	current_queue_size = queue.size()
	return removed

func _on_mouse_entered():
	var q_size = queue.size() + (1 if serving_customer else 0)
	
	# 逻辑判断状态
	var status_text = "正常营业"
	if q_size > 5:
		status_text = "极度拥挤"
	
	# 调用 InfoBox 的显示函数，传入更多信息
	info_box.display_window(
		window_name, 
		status_text, 
		q_size, 
		today_menu
	)

func _on_mouse_exited():
	if info_box:
		info_box.hide()
