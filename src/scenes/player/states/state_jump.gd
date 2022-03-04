extends PlayerState

# - Physics values -
const EASY_WALLJUMP: bool = true
var DRIFT_ACCELERATION: float = 0.0
var DRIFT_DECELERATION: float = 0.0
var DRIFT_MAX_SPEED: float = 0.0

var fast_fall_locked: bool = false
var current_jump_time: float = 0.0
var boost_magnitude: float = 0.0

var pad_unpressed_time: float = 0.0
var pad_last_pressed_time: int = 0

var run_mode: bool = null

func _init(player: KinematicBody2D).(player):
	player.connect("DATA_CHANGED", self, "player_data_changed")

func get_id() -> int:
	return Enums.PLAYER_STATE.JUMP

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	if "fall" in data and data["fall"]:
		current_jump_time = self.data["JUMP_MAX_DURATION"]
	else:
		player.velocity.y = 0.0
		current_jump_time = 0.0
	
	fast_fall_locked = player.crouching and previous_state.get_id() != Enums.PLAYER_STATE.RUN
	
	if "boost_magnitude" in data:
		boost_magnitude = data["boost_magnitude"]
	else:
		boost_magnitude = 0.0

func on_disabled(_next_state: PlayerState):
	.on_disabled(_next_state)
	player.set_collision_mask_bit(19, true)

func process(delta):
	.process(delta)
	
	player.set_collision_mask_bit(19, !is_fast_falling())
	
	player.crouching = Input.is_action_pressed("pad_down")
	var pad_x: int = InputManager.get_pad_x()
	
	if player.running:
		if pad_x != 0:
			pad_unpressed_time = 0.0
		else:
			pad_unpressed_time += delta
			if pad_unpressed_time >= data["RUN_DISABLE_TIME"]:
				player.running = false
				pad_unpressed_time = 0.0
	else:
		var pad_just_pressed: int = InputManager.get_pad_x(true)
		if pad_just_pressed != 0:
			if pad_just_pressed == sign(pad_last_pressed_time) and (OS.get_ticks_msec() - pad_last_pressed_time) / 1000.0 <= player_data["RUN_TRIGGER_WINDOW"]:
				player.running = true
			
			pad_last_pressed_time = OS.get_ticks_msec() * pad_just_pressed
	
	set_run_mode(player.running)
	
	if player.is_on_wall() and pad_x != 0 and sign(player.previous_velocity.x) == pad_x:
		player.wall_collided(pad_x)
	
	if player.is_on_floor():
		if pad_x == 0:
			player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		elif is_fast_falling():
			player.change_state(Enums.PLAYER_STATE.SLIDE, {"dash_magnitude": player.previous_velocity.y / data["FAST_FALL_MAX_SPEED"]})
		elif player.running:
			player.change_state(Enums.PLAYER_STATE.RUN)
		else:
			player.change_state(Enums.PLAYER_STATE.WALK)
		
#		if abs(player.previous_velocity.y) >= player.PARTICLE_EMISSION_SPEED_MIN:
#			player.emit_landing_particles(4 if is_fast_falling() else 2)
		
		return
	
	if (!Input.is_action_pressed("jump") and current_jump_time >= data["JUMP_MIN_DURATION"]) or player.is_on_ceiling():
		current_jump_time = data["JUMP_MAX_DURATION"]
	elif (player.is_squeezing_wall() or (player.is_on_wall() and EASY_WALLJUMP)) and Input.is_action_just_pressed("jump"):
		current_jump_time = 0.0
		player.vel_move_y((-data["WALLJUMP_BOOST_Y_FAST"] if is_fast_falling() else -data["WALLJUMP_BOOST_Y"]) * 0.8)
		player.vel_move_x((-data["WALLJUMP_BOOST_X_FAST"] if is_fast_falling() else -data["WALLJUMP_BOOST_X"]) * (sign(player.squeeze_amount_x) if player.is_squeezing_wall() else pad_x))
	
	if not player.crouching:
		fast_fall_locked = false

func physics_process(delta):
	.physics_process(delta)
	
	if current_jump_time < data["JUMP_MAX_DURATION"]:
		player.vel_move_y(-INF, ((data["JUMP_ACCELERATION_WALL"] if player.is_on_wall() else data["JUMP_ACCELERATION"]) + (data["JUMP_ACCELERATION_BOOST"] * boost_magnitude)) * delta)
		current_jump_time += delta
	elif is_fast_falling() and player.velocity.y < data["FAST_FALL_MAX_SPEED"]:
		player.vel_move_y(data["FAST_FALL_MAX_SPEED"], data["FAST_FALL_ACCELERATION"] * delta)
	
	var pad_x: int = InputManager.get_pad_x()
	if pad_x == 0:
		player.vel_move_x(0, DRIFT_DECELERATION * delta)
	elif sign(player.velocity.x) != pad_x and player.velocity.x != 0:
		player.vel_move_x(0.0, DRIFT_DECELERATION * delta)
		Overlay.SET("DECEL", true)
	else:
		player.vel_move_x(DRIFT_MAX_SPEED * pad_x, DRIFT_ACCELERATION * delta)
		Overlay.SET("DECEL", false)

func player_data_changed():
	run_mode = null
	set_run_mode(player.running)

func set_run_mode(value: bool):
	if value == run_mode:
		return
	run_mode = value
	
	var data: Dictionary = player.get_state_data(Enums.PLAYER_STATE.RUN if player.running else Enums.PLAYER_STATE.WALK)
	
	DRIFT_ACCELERATION = data["ACCELERATION"]
	DRIFT_DECELERATION = data["DECELERATION"]
	DRIFT_MAX_SPEED = data["MAX_SPEED"]

func is_fast_falling() -> bool:
	return player.crouching and not fast_fall_locked
