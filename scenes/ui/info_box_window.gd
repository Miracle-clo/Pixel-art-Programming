extends PanelContainer

# 使用唯一名称引用节点
@onready var title_label = %TitleName
@onready var status_label = %StatusLabel
@onready var queue_label = %QueueLabel   # 原有的“人数”标签
@onready var menu_label = %MenuLabel     # 新增：显示菜品信息

func _ready():
	hide()
	# 确保信息框不会拦截鼠标信号，防止闪烁
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# 修改背景颜色的接口
func set_bg_color(color: Color):
	var new_stylebox = get_theme_stylebox("panel").duplicate()
	new_stylebox.bg_color = color
	add_theme_stylebox_override("panel", new_stylebox)

# 统一显示接口
func display_window(title: String, status: String, queue_count: int, menu: String = "加载中..."):
	if title_label: title_label.text = title
	if status_label: status_label.text = status
	if queue_label: queue_label.text = "当前排队：%d 人" % queue_count
	if menu_label: menu_label.text = "今日推荐：%s" % menu
	
	# 根据排队人数自动切换颜色
	_auto_color(queue_count)
	
	show()

func _auto_color(count: int):
	var target_color: Color
	if count <= 2:
		target_color = Color8(95, 176, 50)   # 绿色（畅通）
	elif count <= 5:
		target_color = Color8(153, 161, 36)  # 黄色（适中）
	else:
		target_color = Color8(252, 94, 22)   # 红色（拥挤）
	set_bg_color(target_color)
