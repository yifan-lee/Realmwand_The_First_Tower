class_name GameClearUI
extends CanvasLayer

signal clear_ui_closed

const DISCORD_WEBHOOK_CONFIG_PATH := "res://config/discord_webhook.cfg"
const DISCORD_WEBHOOK_USER_CONFIG_PATH := "user://discord_webhook.cfg"
const DISCORD_WEBHOOK_MAX_CONTENT_LENGTH := 2000

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
var _discord_webhook_url: String = ""


func _ready() -> void:
	ui_root.visible = false
	_discord_webhook_url = _load_discord_webhook_url()
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
	if _discord_webhook_url.is_empty():
		DisplayServer.clipboard_set(_current_summary)
		status_label.text = "【离线提示】Discord Webhook 未配置，已将战报复制到剪贴板！"
		status_label.modulate = Color("#FFD700")
		return
		
	upload_button.disabled = true
	status_label.text = "正在上传测试存档至 Discord，请稍候..."
	status_label.modulate = Color("#80CCFF")
	
	var body := _build_discord_multipart_body()
	var boundary := body["boundary"] as String
	var request_body := body["data"] as PackedByteArray
	var headers := ["Content-Type: multipart/form-data; boundary=%s" % boundary]
	var request_url := "%s?wait=true" % _discord_webhook_url
	var err := http_request.request_raw(request_url, headers, HTTPClient.METHOD_POST, request_body)
	if err != OK:
		upload_button.disabled = false
		_copy_report_fallback("上传请求发起失败（错误码 %d）" % err)
		status_label.modulate = Color("#FF6B6B")


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	upload_button.disabled = false
	# Discord webhook with wait=true returns 200 when the message is created.
	if result == HTTPRequest.RESULT_SUCCESS and (response_code >= 200 and response_code < 400):
		status_label.text = "✔ 测试存档已上传至 Discord，感谢体验！"
		status_label.modulate = Color("#55FF55")
	else:
		var reason := ""
		match result:
			HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE, HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR, HTTPRequest.RESULT_CONNECTION_ERROR:
				reason = "无法连接 Discord 服务器"
			HTTPRequest.RESULT_TIMEOUT:
				reason = "连接超时"
			_:
				reason = "HTTP 异常 (Code %d)" % response_code
		_copy_report_fallback("【提示】%s" % reason)
		status_label.modulate = Color("#FFD700")


func _load_discord_webhook_url() -> String:
	var config := ConfigFile.new()
	for path: String in [DISCORD_WEBHOOK_CONFIG_PATH, DISCORD_WEBHOOK_USER_CONFIG_PATH]:
		if config.load(path) == OK:
			var value := String(config.get_value("discord", "webhook_url", "")).strip_edges()
			if value.begins_with("https://discord.com/api/webhooks/") or value.begins_with("https://discordapp.com/api/webhooks/"):
				return value
	return ""


func _build_discord_multipart_body() -> Dictionary:
	var boundary := "----RealmwandBoundary%s" % Time.get_ticks_msec()
	var filename := "realmwand_test_report_%d.json" % int(Time.get_unix_time_from_system())
	var player_name := _player.player_data.display_name if (_player and _player.player_data) else "Player"
	var content := ("Realmwand 测试存档\n玩家：%s\n\n%s" % [player_name, _current_summary])
	if content.length() > DISCORD_WEBHOOK_MAX_CONTENT_LENGTH:
		content = content.left(DISCORD_WEBHOOK_MAX_CONTENT_LENGTH)
	var payload := {
		"content": content,
		"allowed_mentions": {"parse": []},
		"attachments": [{"id": 0, "filename": filename}]
	}
	var data := PackedByteArray()
	_append_multipart_text(data, boundary, "payload_json", JSON.stringify(payload), "application/json")
	data.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	data.append_array(("Content-Disposition: form-data; name=\"files[0]\"; filename=\"%s\"\r\n" % filename).to_utf8_buffer())
	data.append_array("Content-Type: application/json\r\n\r\n".to_utf8_buffer())
	data.append_array(_current_save_json.to_utf8_buffer())
	data.append_array("\r\n".to_utf8_buffer())
	data.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return {"boundary": boundary, "data": data}


func _append_multipart_text(data: PackedByteArray, boundary: String, field_name: String, value: String, content_type: String) -> void:
	data.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	data.append_array(("Content-Disposition: form-data; name=\"%s\"\r\n" % field_name).to_utf8_buffer())
	data.append_array(("Content-Type: %s\r\n\r\n" % content_type).to_utf8_buffer())
	data.append_array(value.to_utf8_buffer())
	data.append_array("\r\n".to_utf8_buffer())


func _copy_report_fallback(prefix: String) -> void:
	DisplayServer.clipboard_set(_current_save_json)
	status_label.text = "%s。完整存档 JSON 已复制到剪贴板！" % prefix


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
