extends Area2D

func _physics_process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_enemy = enemies_in_range.front()
		look_at(target_enemy.global_position)

func shoot():
	const BALA = preload("res://bala.tscn")
	var new_bala = BALA.instantiate()
	new_bala.global_position = %PontoDeTiro.global_position
	new_bala.global_rotation = %PontoDeTiro.global_rotation
	%PontoDeTiro.add_child(new_bala)


func _on_timer_timeout() -> void:
	shoot()
