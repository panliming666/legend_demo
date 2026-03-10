extends Node

class_name StoryModeSystem

# 剧情模式系统 - 单机核心内容

signal chapter_started(chapter_id: String)
signal chapter_completed(chapter_id: String)
signal story_event(event_id: String, text: String)
signal dialogue_started(npc_name: String, dialogue: Array)

# 章节状态
enum ChapterStatus {
	LOCKED,
	UNLOCKED,
	IN_PROGRESS,
	COMPLETED
}

# 剧情数据库
var story_database: Dictionary = {
	"chapter_1": {
		"id": "chapter_1",
		"name": "初入仙途",
		"description": "少年拜入三清，开启修仙之路",
		"scenes": [
			{
				"id": "scene_1_1",
				"type": "cutscene",
				"text": "混沌初开，天地鸿蒙。一位少年踏上了修仙之路...",
				"background": "opening"
			},
			{
				"id": "scene_1_2",
				"type": "dialogue",
				"npc": "神秘老者",
				"lines": [
					{"speaker": "神秘老者", "text": "少年，你我有缘。三清天尊正在收徒..."},
					{"speaker": "少年", "text": "三清？那是什么？"},
					{"speaker": "神秘老者", "text": "玉清、上清、太清，三大宗门。拜入其中，开启你的仙途。"}
				]
			},
			{
				"id": "scene_1_3",
				"type": "choice",
				"question": "你选择拜入哪个宗门？",
				"choices": [
					{"text": "玉清宗（法修）", "result": "yuqing"},
					{"text": "上清宗（符修）", "result": "shangqing"},
					{"text": "太清宗（剑修）", "result": "taiqing"}
				]
			},
			{
				"id": "scene_1_4",
				"type": "battle",
				"enemies": ["灵兽"],
				"objective": "击杀3只灵兽，证明你的实力"
			}
		],
		"unlocks": ["chapter_2"],
		"rewards": {"exp": 100, "gold": 50}
	},
	"chapter_2": {
		"id": "chapter_2",
		"name": "筑基之路",
		"description": "修炼筑基，突破境界",
		"scenes": [
			{
				"id": "scene_2_1",
				"type": "cutscene",
				"text": "经过数月苦修，你的修为已达到瓶颈..."
			},
			{
				"id": "scene_2_2",
				"type": "dialogue",
				"npc": "宗门长老",
				"lines": [
					{"speaker": "宗门长老", "text": "你的修为已足，可以尝试筑基了。"},
					{"speaker": "宗门长老", "text": "去灵气洞穴收集筑基材料吧。"}
				]
			},
			{
				"id": "scene_2_3",
				"type": "battle",
				"enemies": ["灵兽", "妖兽"],
				"objective": "收集筑基丹材料"
			},
			{
				"id": "scene_2_4",
				"type": "cutscene",
				"text": "筑基成功！你的修为大幅提升！"
			}
		],
		"unlocks": ["chapter_3"],
		"prerequisite": ["chapter_1"],
		"level_required": 5,
		"rewards": {"exp": 500, "gold": 200, "item": "筑基丹"}
	},
	"chapter_3": {
		"id": "chapter_3",
		"name": "秘境探险",
		"description": "探索秘境，获取传承",
		"scenes": [
			{
				"id": "scene_3_1",
				"type": "dialogue",
				"npc": "神秘修士",
				"lines": [
					{"speaker": "神秘修士", "text": "你听说过仙人陵墓吗？"},
					{"speaker": "神秘修士", "text": "那里藏着上古传承..."}
				]
			},
			{
				"id": "scene_3_2",
				"type": "dungeon",
				"dungeon": "immortal_tomb",
				"objective": "通关仙人陵墓"
			},
			{
				"id": "scene_3_3",
				"type": "cutscene",
				"text": "你在陵墓深处发现了上古传承！"
			}
		],
		"unlocks": ["chapter_4"],
		"prerequisite": ["chapter_2"],
		"level_required": 15,
		"rewards": {"exp": 2000, "gold": 1000, "item": "传承卷轴"}
	},
	"chapter_4": {
		"id": "chapter_4",
		"name": "龙之试炼",
		"description": "面对远古青龙，证明你的实力",
		"scenes": [
			{
				"id": "scene_4_1",
				"type": "cutscene",
				"text": "龙的咆哮震动天地..."
			},
			{
				"id": "scene_4_2",
				"type": "boss",
				"boss": "远古青龙",
				"objective": "击败远古青龙"
			},
			{
				"id": "scene_4_3",
				"type": "cutscene",
				"text": "龙息散去，你获得了龙血洗礼！"
			}
		],
		"unlocks": ["chapter_5"],
		"prerequisite": ["chapter_3"],
		"level_required": 30,
		"rewards": {"exp": 5000, "gold": 3000, "item": "龙血"}
	},
	"chapter_5": {
		"id": "chapter_5",
		"name": "三清终章",
		"description": "最终之战，证道成仙",
		"scenes": [
			{
				"id": "scene_5_1",
				"type": "cutscene",
				"text": "天地异变，魔劫降临..."
			},
			{
				"id": "scene_5_2",
				"type": "boss",
				"boss": "天魔领主",
				"objective": "击败天魔领主，拯救世界"
			},
			{
				"id": "scene_5_3",
				"type": "cutscene",
				"text": "恭喜！你已证道成仙！"
			},
			{
				"id": "scene_5_4",
				"type": "ending",
				"text": "【完】感谢游玩！\n\n已解锁：\n- 无尽模式\n- 多周目\n- 隐藏Boss"
			}
		],
		"prerequisite": ["chapter_4"],
		"level_required": 50,
		"rewards": {"exp": 10000, "gold": 10000, "item": "仙果"}
	}
}

# 章节进度
var chapter_progress: Dictionary = {}  # chapter_id: {status, current_scene}
var completed_chapters: Array = []
var current_chapter: String = ""
var current_scene_index: int = 0

# 游戏选择
var player_choices: Dictionary = {}  # 存储玩家的选择

func _ready():
	init_chapters()
	load_story_data()

# 初始化章节
func init_chapters():
	for chapter_id in story_database.keys():
		if not chapter_progress.has(chapter_id):
			chapter_progress[chapter_id] = {
				"status": ChapterStatus.LOCKED,
				"current_scene": 0
			}
	
	# 第一章默认解锁
	if chapter_progress.has("chapter_1"):
		chapter_progress["chapter_1"].status = ChapterStatus.UNLOCKED

# 开始章节
func start_chapter(chapter_id: String) -> Dictionary:
	var chapter = story_database.get(chapter_id)
	if chapter == null:
		return {"success": false, "message": "章节不存在"}
	
	var progress = chapter_progress.get(chapter_id)
	if progress == null:
		return {"success": false, "message": "章节未解锁"}
	
	if progress.status == ChapterStatus.LOCKED:
		return {"success": false, "message": "章节已锁定"}
	
	current_chapter = chapter_id
	current_scene_index = 0
	progress.status = ChapterStatus.IN_PROGRESS
	
	emit_signal("chapter_started", chapter_id)
	
	# 播放第一个场景
	return play_current_scene()

# 播放当前场景
func play_current_scene() -> Dictionary:
	if current_chapter.is_empty():
		return {"success": false, "message": "未在剧情中"}
	
	var chapter = story_database[current_chapter]
	var scene = chapter.scenes[current_scene_index]
	
	emit_signal("story_event", scene.id, scene.get("text", ""))
	
	match scene.type:
		"cutscene":
			return {
				"success": true,
				"type": "cutscene",
				"text": scene.text,
				"background": scene.get("background", "")
			}
		"dialogue":
			emit_signal("dialogue_started", scene.npc, scene.lines)
			return {
				"success": true,
				"type": "dialogue",
				"npc": scene.npc,
				"lines": scene.lines
			}
		"choice":
			return {
				"success": true,
				"type": "choice",
				"question": scene.question,
				"choices": scene.choices
			}
		"battle":
			return {
				"success": true,
				"type": "battle",
				"enemies": scene.enemies,
				"objective": scene.objective
			}
		"boss":
			return {
				"success": true,
				"type": "boss",
				"boss": scene.boss,
				"objective": scene.objective
			}
		"dungeon":
			return {
				"success": true,
				"type": "dungeon",
				"dungeon": scene.dungeon,
				"objective": scene.objective
			}
		"ending":
			return {
				"success": true,
				"type": "ending",
				"text": scene.text
			}
	
	return {"success": false, "message": "未知场景类型"}

# 完成当前场景
func complete_scene(result: Dictionary = {}) -> Dictionary:
	if current_chapter.is_empty():
		return {"success": false, "message": "未在剧情中"}
	
	var chapter = story_database[current_chapter]
	
	# 处理选择结果
	if result.has("choice"):
		player_choices[current_chapter] = result.choice
	
	current_scene_index += 1
	
	# 检查章节是否完成
	if current_scene_index >= chapter.scenes.size():
		return complete_chapter()
	
	# 播放下一场景
	return play_current_scene()

# 完成章节
func complete_chapter() -> Dictionary:
	if current_chapter.is_empty():
		return {"success": false, "message": "未在剧情中"}
	
	var chapter = story_database[current_chapter]
	
	# 更新状态
	chapter_progress[current_chapter].status = ChapterStatus.COMPLETED
	completed_chapters.append(current_chapter)
	
	# 解锁下一章
	for unlock_id in chapter.get("unlocks", []):
		if chapter_progress.has(unlock_id):
			chapter_progress[unlock_id].status = ChapterStatus.UNLOCKED
	
	emit_signal("chapter_completed", current_chapter)
	
	var rewards = chapter.rewards.duplicate()
	
	var completed_id = current_chapter
	current_chapter = ""
	current_scene_index = 0
	
	save_story_data()
	
	return {
		"success": true,
		"completed_chapter": completed_id,
		"rewards": rewards,
		"next_chapters": chapter.get("unlocks", [])
	}

# 获取章节信息
func get_chapter_info(chapter_id: String) -> Dictionary:
	var chapter = story_database.get(chapter_id)
	if chapter == null:
		return {}
	
	var progress = chapter_progress.get(chapter_id, {})
	
	return {
		"id": chapter_id,
		"name": chapter.name,
		"description": chapter.description,
		"status": progress.get("status", ChapterStatus.LOCKED),
		"level_required": chapter.get("level_required", 1),
		"rewards": chapter.rewards,
		"completed": chapter_id in completed_chapters
	}

# 获取所有章节
func get_all_chapters() -> Array:
	var result = []
	
	for chapter_id in story_database.keys():
		result.append(get_chapter_info(chapter_id))
	
	return result

# 获取剧情进度
func get_story_progress() -> Dictionary:
	return {
		"completed_chapters": completed_chapters.size(),
		"total_chapters": story_database.size(),
		"current_chapter": current_chapter,
		"current_scene": current_scene_index
	}

# 检查是否通关
func has_completed_story() -> bool:
	return "chapter_5" in completed_chapters

# 保存/加载
func save_story_data():
	var config = ConfigFile.new()
	config.set_value("story", "progress", chapter_progress)
	config.set_value("story", "completed", completed_chapters)
	config.set_value("story", "choices", player_choices)
	config.save("user://story.cfg")

func load_story_data():
	if FileAccess.file_exists("user://story.cfg"):
		var config = ConfigFile.new()
		if config.load("user://story.cfg") == OK:
			chapter_progress = config.get_value("story", "progress", {})
			completed_chapters = config.get_value("story", "completed", [])
			player_choices = config.get_value("story", "choices", {})
