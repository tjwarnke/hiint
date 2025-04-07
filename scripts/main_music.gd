extends AudioStreamPlayer

var is_playing_music = false

func _ready():
	if not is_playing_music:
		play()
		is_playing_music = true
		
func fade_out(audio_player: AudioStreamPlayer, duration: float = 30.0):
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): 
			audio_player.stop()
		)
		
