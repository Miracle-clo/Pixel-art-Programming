# table.gd
extends Area2D

@onready var info_box = %InfoBox
var capacity: int = 4
var occupants: Array = []

# 定义四个餐位相对于桌子中心的偏移
# 根据常见桌子模型，调整偏移使人物贴近可坐位置
var seat_offsets = [
	Vector2(0, -20),   # 1. 北 (12点) - 上方
	Vector2(20, 0),    # 2. 东 (3点) - 右方
	Vector2(0, 20),    # 3. 南 (6点) - 下方
	Vector2(-20, 0)    # 4. 西 (9点) - 左方
]

func _ready():
	add_to_group("tables")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func is_full() -> bool:
	return occupants.size() >= capacity

func get_next_available_seat_global_pos() -> Vector2:
	var index = occupants.size()
	if index < capacity:
		# 关键：用桌子的全局坐标 + 偏移
		var seat_pos = global_position + seat_offsets[index]
		print("[", name, "] 座位 ", index, " 全局位置: ", seat_pos)
		return seat_pos
	return global_position

func get_seat_index_for_person(person) -> int:
	"""获取指定人物在座位中的索引"""
	return occupants.find(person)
	
func _on_mouse_entered():
	if not info_box: return
	
	var count = occupants.size()
	var target_color: Color
	
	# 根据人数逻辑判断颜色
	# 使用 Color8(r, g, b) 可以直接输入 0-255 的整数值
	if count <= 1:
		target_color = Color8(95, 176, 50)   # 绿色
	elif count == 2:
		target_color = Color8(153, 161, 36)  # 黄色
	elif count == 3:
		target_color = Color8(201, 138, 40)  # 橙色
	else: # 即 count == 4
		target_color = Color8(252, 94, 22)   # 红色
	
	# 先设置颜色，再显示内容
	info_box.set_bg_color(target_color)
	
	var status_text = "占用情况: %d/%d" % [count, capacity]
	var detail_text = "状态: " + ("请就座" if count < 4 else "已满员")
	
	info_box.display("餐桌信息", status_text, detail_text)

func _on_mouse_exited():
	info_box.hide()
	

func add_occupant(p):
	if not occupants.has(p):
		occupants.append(p)

func remove_occupant(p):
	if occupants.has(p):
		occupants.erase(p)
