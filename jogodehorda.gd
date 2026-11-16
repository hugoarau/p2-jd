extends Node2D


func spawn_inimigo():
	var new_inimigo = preload("res://inimigo.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_inimigo.global_position = %PathFollow2D.global_position
	add_child(new_inimigo)


func _on_timer_timeout() -> void:
	spawn_inimigo()


func _on_player_vida_zerada() -> void:
	%FimDeJogo.visible = true
	get_tree().paused = true
