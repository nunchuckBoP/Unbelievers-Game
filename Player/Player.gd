extends KinematicBody2D

# global variables that are exposed to the
# property panel
export (int) var run_speed
export (int) var jump_speed
export (int) var gravity

# Declare member variables here.
enum {IDLE, RUN, JUMP, HURT, DEAD}
var state
var anim
var new_anim
var velocity = Vector2()

signal life_changed
signal dead

var life

func start(pos):
	life = 3
	emit_signal('life_changed', life)
	position = pos
	show()
	change_state(IDLE)
	
func hurt():
	if state != HURT:
		change_state(HURT)

func get_input():
	if state == HURT:
		return # Return nothing, don't allow movement when hurt
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_pressed('jump')
	var jump_released = Input.is_action_just_released('jump')
		
	# movement occurs in all states
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite.flip_h = true
	# only allow jump when on the ground
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	# IDLE transistions to RUN when moving
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN transistions to IDLE when standing still
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# transistions to JUMP when falling off edge
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)
	if state == JUMP and is_on_floor():
		change_state(IDLE)
	if state == JUMP and jump_released and velocity.y < 0:
		velocity.y = 0
	if state == JUMP and velocity.y > 0:
		new_anim = 'Jump_Down'
		
# Called when the node enters the scene tree for the first time.
func _ready():
	change_state(IDLE)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			new_anim = 'idle'
		RUN:
			new_anim = 'Run'
		HURT:
			new_anim = "Hurt"
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			life -= 1
			emit_signal('life_changed', life)
			yield(get_tree().create_timer(0.5), 'timeout')
			change_state(IDLE)
			if life < 0:
				change_state(DEAD)
		JUMP:
			new_anim = "Jump_Up"
		DEAD:
			emit_signal('dead')
			hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	velocity.y += gravity * delta
	
	get_input()
	
	if new_anim != anim:
		anim = new_anim
		$AnimationPlayer.play(anim)
	# move the player
	
	velocity = move_and_slide(velocity, Vector2(0, -1))	
