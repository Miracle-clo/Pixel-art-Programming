extends PanelContainer

@onready var title_label = %TitleLabel
@onready var status_label = %StatusLabel
@onready var detail_label = %DetailLabel

func _ready():
	hide()

# 设置背景颜色的新函数
func set_bg_color(color: Color):
	# 获取当前的 StyleBox 并创建一个副本（防止修改原始资源影响其他实例）
	var new_stylebox = get_theme_stylebox("panel").duplicate()
	new_stylebox.bg_color = color
	# 将修改后的副本应用到当前节点
	add_theme_stylebox_override("panel", new_stylebox)

func display(title: String, status: String, detail: String):
	if title_label: title_label.text = title
	if status_label: status_label.text = status
	if detail_label: detail_label.text = detail
	show()
