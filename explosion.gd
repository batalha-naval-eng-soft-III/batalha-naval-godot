extends AnimatedSprite2D


func _ready():
	play("explode")
	connect("animation_finished", Callable(self, "queue_free"))
