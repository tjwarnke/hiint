extends AudioStreamPlayer

var is_playing_music = false

func _ready():
	if not is_playing_music:
		play()
		is_playing_music = true
		
func fade_out_music(duration: float = 30.0):
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
