extends Area2D

export(Player.UPGRADE) var type: int
onready var particles: CPUParticles2D = $CPUParticles2D

func _on_UpgradePickup_body_entered(body: Node):
	body.collect_upgrade(type)
	$Visual.visible = false
	$CollisionShape2D.queue_free()
	$SfxrStreamPlayer.play()
	
	# TODO
	TextNotification.create("Upgrade acquired: Walljump").clear_after(Notification.LENGTH_NORMAL)
	
	Game.set_node_layer(self, Game.LAYERS.UPGRADE_PICKUP)
	
	particles.modulate = $Visual/Main.modulate
	particles.emitting = true
	yield(Utils.yield_particle_completion(particles), "completed")
	
	queue_free()
