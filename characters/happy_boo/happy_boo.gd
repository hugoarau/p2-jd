extends Node2D


var _facing: StringName = &"down"
@onready var _animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	# Cada personagem recebe suas proprias animacoes, sem alterar o recurso compartilhado.
	var library: AnimationLibrary = _animation_player.get_animation_library("").duplicate(true)
	_animation_player.remove_animation_library("")
	_animation_player.add_animation_library("", library)
	for direction in [&"left", &"right", &"up", &"down"]:
		# Reaproveita o ciclo das pernas nas quatro direções, mudando a pose do corpo/rosto.
		for action in [&"idle", &"walk"]:
			var animation: Animation = library.get_animation(action).duplicate(true)
			var side_view: bool = direction == &"left" or direction == &"right"
			var horizontal_scale: float = 0.82 if side_view else 1.0
			if direction == &"left":
				horizontal_scale = -horizontal_scale
			# Perfil: corpo estreito, rosto deslocado e espelhamento ao olhar para a esquerda.
			_set_pose_track(animation, ^"Colorizer:scale", Vector2(horizontal_scale, 1.0))
			_set_pose_track(animation, ^"Colorizer/SquareBody/SquareFace:position", Vector2(18 if side_view else 0, -17))
			_set_pose_track(animation, ^"Colorizer/SquareBody/SquareFace:scale", Vector2(0.72 if side_view else 1.0, 1.0))
			# Ao subir, esconde o rosto para mostrar as costas; ao descer, volta à frente.
			_set_pose_track(animation, ^"Colorizer/SquareBody/SquareFace:visible", direction != &"up")
			library.add_animation(StringName("%s_%s" % [action, direction]), animation)
	play_idle_animation()


func _set_pose_track(animation: Animation, path: NodePath, value: Variant) -> void:
	var track: int = animation.find_track(path, Animation.TYPE_VALUE)
	if track >= 0:
		animation.remove_track(track)
	track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
	animation.track_insert_key(track, 0.0, value)


func play_idle_animation() -> void:
	# Parar mantém a última direção, em vez de virar o personagem sempre para baixo.
	_play(StringName("idle_%s" % _facing))


func play_walk_animation(direction: Vector2 = Vector2.DOWN) -> void:
	if direction.is_zero_approx():
		play_idle_animation()
		return
	# Em diagonais, usa o eixo predominante para escolher uma das quatro orientações.
	if absf(direction.x) > absf(direction.y):
		_facing = &"left" if direction.x < 0.0 else &"right"
	else:
		_facing = &"up" if direction.y < 0.0 else &"down"
	_play(StringName("walk_%s" % _facing))


func _play(animation_name: StringName) -> void:
	# Não reinicia a animação a cada frame; em uma curva, preserva a fase da passada.
	if _animation_player.current_animation == animation_name and _animation_player.is_playing():
		return
	var keep_step: bool = _animation_player.current_animation.begins_with("walk_") and animation_name.begins_with("walk_")
	var step_time: float = _animation_player.current_animation_position if keep_step else 0.0
	# A orientacao muda imediatamente; o ciclo das pernas continua durante uma curva.
	_animation_player.play(animation_name, 0.0)
	if keep_step:
		_animation_player.seek(step_time, true)
	_animation_player.advance(0.0)
