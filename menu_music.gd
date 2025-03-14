extends AudioStreamPlayer2D

func fade_out_music(duration: float = 10.0):
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
