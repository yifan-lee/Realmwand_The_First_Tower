class_name GameClearUI
extends CanvasLayer

signal clear_ui_closed

@export_group("Google Forms Telemetry")
## 你的 Google Forms 提交地址（格式形如：https://docs.google.com/forms/d/e/XXXX/formResponse）
@export var google_form_url: String = "https://docs.google.com/forms/d/e/1FAIpQLSe6QWxVIHWMv5Jio7Jfi5snXtUfuCiRRnYIkHRhA9q43G7BBQ/formResponse"
## 表单中“玩家昵称”对应的字段 entry ID
@export var entry_player_name: String = "entry.1201494523"
## 表单中“战报摘要”对应的字段 entry ID
@export var entry_summary: String = "entry.887923593"
## 表单中“完整存档JSON”对应的字段 entry ID
@export var entry_save_json: String = "entry.302181984"

@onready var ui_root: Control = $ClearRoot
@onready var title_label: Label = %TitleLabel
@onready var summary_text_edit: TextEdit = %SummaryTextEdit
@onready var upload_button: Button = %UploadButton
@onready var copy_summary_button: Button = %CopySummaryButton
@onready var copy_json_button: Button = %CopyJsonButton
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel
@onready var http_request: HTTPRequest = %HTTPRequest

var _player: Player
var _save_manager: SaveManager
var _current_summary: String = ""
var _current_save_json: String = ""


func _ready() -> void:
	ui_root.visible = false
	upload_button.pressed.connect(_on_upload_pressed)
	copy_summary_button.pressed.connect(_on_copy_summary_pressed)
	copy_json_button.pressed.connect(_on_copy_json_pressed)
	close_button.pressed.connect(_on_close_pressed)
	http_request.request_completed.connect(_on_http_request_completed)


func open(player: Player, save_manager: SaveManager) -> void:
	_player = player
	_save_manager = save_manager
	
	if _player != null:
		_player.lock_movement(&"game_clear")
		
	if _save_manager != null:
		_current_summary = _save_manager.generate_clear_summary_text()
		_current_save_json = _save_manager.export_save_json_string("通关战报存档")
	else:
		_current_summary = "通关成功！"
		_current_save_json = "{}"
		
	summary_text_edit.text = _current_summary
	status_label.text = "点击下方按钮可一键上传战报或复制到剪贴板"
	status_label.modulate = Color("#A0A0A0")
	upload_button.disabled = false
	
	ui_root.visible = true
	upload_button.grab_focus()


func close() -> void:
	ui_root.visible = false
	if _player != null:
		_player.unlock_movement(&"game_clear")
	clear_ui_closed.emit()


func _on_upload_pressed() -> void:
	if google_form_url.strip_edges().is_empty():
		DisplayServer.clipboard_set(_current_summary)
		status_label.text = "【离线提示】Google Forms URL 未配置，已自动将通关战报复制到剪贴板！"
		status_label.modulate = Color("#FFD700")
		return
		
	upload_button.disabled = true
	status_label.text = "正在上传战报至 Google Forms / Sheets，请稍候..."
	status_label.modulate = Color("#80CCFF")
	
	var p_name := _player.player_data.display_name if (_player and _player.player_data) else "Player"
	var body_parts: Array[String] = [
		"%s=%s" % [entry_player_name.uri_encode(), p_name.uri_encode()],
		"%s=%s" % [entry_summary.uri_encode(), _current_summary.uri_encode()],
		"%s=%s" % [entry_save_json.uri_encode(), _current_save_json.uri_encode()]
	]
	var form_body := "&".join(body_parts)
	var headers := ["Content-Type: application/x-www-form-urlencoded"]
	
	var err := http_request.request(google_form_url, headers, HTTPClient.METHOD_POST, form_body)
	if err != OK:
		upload_button.disabled = false
		DisplayServer.clipboard_set(_current_summary)
		status_label.text = "上传请求发起失败（错误码 %d），已将战报复制到剪贴板！" % err
		status_label.modulate = Color("#FF6B6B")


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	upload_button.disabled = false
	# Google Forms 成功提交通常返回 200 OK 或 302/303 Redirect
	if result == HTTPRequest.RESULT_SUCCESS and (response_code >= 200 and response_code < 400):
		status_label.text = "✔ 战报上传成功！数据已同步至在线表格，感谢体验！"
		status_label.modulate = Color("#55FF55")
	else:
		DisplayServer.clipboard_set(_current_summary)
		status_label.text = "网络连接异常 (Code %d)，已自动将战报复制到剪贴板！" % response_code
		status_label.modulate = Color("#FFD700")


func _on_copy_summary_pressed() -> void:
	DisplayServer.clipboard_set(_current_summary)
	status_label.text = "✔ 已将战报文字摘要复制到剪贴板！"
	status_label.modulate = Color("#55FF55")


func _on_copy_json_pressed() -> void:
	DisplayServer.clipboard_set(_current_save_json)
	status_label.text = "✔ 已将完整存档代码(JSON)复制到剪贴板！可供开发者 100% 导入复现。"
	status_label.modulate = Color("#55FF55")


func _on_close_pressed() -> void:
	close()
