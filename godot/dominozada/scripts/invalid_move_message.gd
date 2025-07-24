extends CanvasLayer

@onready var message_label := $Control/CenterContainer/Panel/MessageLabel
@onready var panel := $Control/CenterContainer/Panel

var tween: Tween

func _ready():
	visible = false

func show_message(text: String, duration: float = 2.0):
	"""Show invalid move message for specified duration"""
	message_label.text = text
	visible = true
	
	# Create fade in/out animation
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	# Fade in
	panel.modulate.a = 0.0
	tween.tween_property(panel, "modulate:a", 0.9, 0.3)
	
	# Hold
	tween.tween_interval(duration - 0.6)
	
	# Fade out
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)
