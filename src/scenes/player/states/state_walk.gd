extends PlayerState

var crouch_mode: bool = false

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.WALK

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	crouch_mode = player.crouching
	player.running = false

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("pad_down")
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP)
		return
	
	if player.can_fall():
		player.change_state(Enums.PLAYER_STATE.JUMP, {"fall": true})
		return
	
#	if not crouch_mode and player.crouching:
#		player.change_state(Enums.PLAYER_STATE.SLIDE)
#		return
	
	if Input.is_action_pressed("run"):
		player.change_state(Enums.PLAYER_STATE.RUN)
		return
	
	if InputManager.get_pad_x() == 0:
		player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return

func physics_process(delta):
	.physics_process(delta)
	
	var pad_x: int = InputManager.get_pad_x()
	if sign(player.velocity.x) != pad_x and player.velocity.x != 0:
		player.vel_move_x(0.0, data["DECELERATION"] * delta)
	else:
		player.vel_move_x(data["MAX_SPEED"] * pad_x, data["ACCELERATION"] * delta)
