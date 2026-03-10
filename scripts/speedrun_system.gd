extends Node

class_name SpeedrunSystem

# 速通计时系统 - 单机挑战

signal timer_started()
signal timer_stopped(final_time: float)
signal split_recorded(split_name: String, time: float)
signal personal_best(type: String, new_record: float)

# 计时类型
enum TimerType {
	FULL_GAME,      # 全剧情通关
	CHAPTER,        # 单章
	BOSS_RUSH,      # Boss连战
	ENDLESS_TOWER,  # 无尽塔
	ROGUELIKE,      # Roguelike
	CHALLENGE       # 挑战模式
}

# 计时状态
var is_running: bool = false
var start_time: int = 0
var elapsed_time: float = 0.0
var current_type: int = TimerType.FULL_GAME

# 分段计时
var splits: Dictionary = {}  # split_name: time
var split_times: Array = []  # 记录每次分段

# 最佳记录
var personal_bests: Dictionary = {}  # type: best_time

# 对比记录
var comparison_time: float = 0.0  # 对比的最佳记录

func _ready():
	load_speedrun_data()

func _process(delta):
	if is_running:
		elapsed_time += delta

# 开始计时
func start_timer(timer_type: int):
	is_running = true
	current_type = timer_type
	start_time = Time.get_ticks_msec()
	elapsed_time = 0.0
	splits.clear()
	split_times.clear()
	
	# 加载对比记录
	if personal_bests.has(timer_type):
		comparison_time = personal_bests[timer_type]
	
	emit_signal("timer_started")
	print("速通计时开始：", TimerType.keys()[timer_type])

# 停止计时
func stop_timer() -> Dictionary:
	if not is_running:
		return {"success": false, "message": "计时未开始"}
	
	is_running = false
	
	# 检查是否新记录
	var is_new_best = false
	if not personal_bests.has(current_type):
		personal_bests[current_type] = elapsed_time
		is_new_best = true
	elif elapsed_time < personal_bests[current_type]:
		personal_bests[current_type] = elapsed_time
		is_new_best = true
	
	if is_new_best:
		emit_signal("personal_best", TimerType.keys()[current_type], elapsed_time)
	
	emit_signal("timer_stopped", elapsed_time)
	
	var result = {
		"success": true,
		"final_time": elapsed_time,
		"formatted_time": format_time(elapsed_time),
		"is_new_best": is_new_best,
		"splits": splits.duplicate()
	}
	
	save_speedrun_data()
	print("速通结束：", format_time(elapsed_time))
	
	return result

# 记录分段
func record_split(split_name: String) -> Dictionary:
	if not is_running:
		return {"success": false, "message": "计时未开始"}
	
	splits[split_name] = elapsed_time
	split_times.append({
		"name": split_name,
		"time": elapsed_time
	})
	
	emit_signal("split_recorded", split_name, elapsed_time)
	
	# 对比
	var diff = 0.0
	if comparison_time > 0:
		# 简化对比，假设等比例
		diff = elapsed_time - comparison_time
	
	return {
		"success": true,
		"split_name": split_name,
		"time": elapsed_time,
		"formatted": format_time(elapsed_time),
		"diff": diff,
		"formatted_diff": format_diff(diff)
	}

# 格式化时间
func format_time(time: float) -> String:
	var hours = int(time / 3600)
	var minutes = int((time - hours * 3600) / 60)
	var seconds = int(time - hours * 3600 - minutes * 60)
	var milliseconds = int((time - int(time)) * 1000)
	
	if hours > 0:
		return "%d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
	else:
		return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

# 格式化差异
func format_diff(diff: float) -> String:
	var sign = "+" if diff >= 0 else ""
	return sign + format_time(abs(diff))

# 获取当前计时
func get_current_time() -> Dictionary:
	return {
		"running": is_running,
		"elapsed": elapsed_time,
		"formatted": format_time(elapsed_time) if is_running else ""
	}

# 获取分段列表
func get_splits() -> Array:
	return split_times.duplicate()

# 获取最佳记录
func get_personal_best(timer_type: int) -> Dictionary:
	var best = personal_bests.get(timer_type, -1)
	
	return {
		"type": timer_type,
		"type_name": TimerType.keys()[timer_type],
		"best_time": best,
		"formatted": format_time(best) if best >= 0 else "无记录"
	}

# 获取所有最佳记录
func get_all_personal_bests() -> Array:
	var result = []
	
	for timer_type in TimerType.keys():
		result.append(get_personal_best(TimerType[timer_type]))
	
	return result

# 重置记录
func reset_records():
	personal_bests.clear()
	splits.clear()
	split_times.clear()
	save_speedrun_data()

# 保存/加载
func save_speedrun_data():
	var config = ConfigFile.new()
	config.set_value("speedrun", "bests", personal_bests)
	config.save("user://speedrun.cfg")

func load_speedrun_data():
	if FileAccess.file_exists("user://speedrun.cfg"):
		var config = ConfigFile.new()
		if config.load("user://speedrun.cfg") == OK:
			personal_bests = config.get_value("speedrun", "bests", {})
