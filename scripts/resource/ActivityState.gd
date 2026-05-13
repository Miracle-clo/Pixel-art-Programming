# activity_state.gd
class_name ActivityState
extends Node

enum State {
	IDLE,             # 闲逛中
	QUEUING,          # 排队中
	ORDERING,         # 打饭中
	ORDER_COMPLETED,  # 点餐完成
	EATING,           # 吃饭中
	LEAVING           # 已离开
}

const DESCRIPTIONS = {
	State.IDLE: "闲逛中",
	State.QUEUING: "排队中",
	State.ORDERING: "打饭中",
	State.ORDER_COMPLETED: "准备用餐",
	State.EATING: "吃饭中",
	State.LEAVING: "已离开"
}
