extends Node2D

@onready var player: Player = $Player
@onready var pickup_message: Label = $UI/PickupMessage
@onready var pickup_message_timer: Timer = $UI/PickupMessageTimer


func _ready() -> void:
	player.item_added.connect(_on_player_item_added)
	pickup_message_timer.timeout.connect(_on_pickup_message_timer_timeout)


func _on_player_item_added(item_name: String) -> void:
	pickup_message.text = "Picked up: " + item_name
	pickup_message_timer.start()


func _on_pickup_message_timer_timeout() -> void:
	pickup_message.text = ""