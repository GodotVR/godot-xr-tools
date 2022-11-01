---
title: Setup
permalink: /docs/setup/
---

There is no code needed to initialize the add on.

Every Godot XR project expects the following node tree in order to work:
![ARVR Setup]({{ site.url }}/assets/img/arvr_setup.png)


We do assume here that we have controllers. If you are writing a 3DOF game
 or experience those are not needed.

Many of the XR plugins will have scenes that configure this for you but often
with platform specific logic embedded. If you're creating a headset agnostic
game setting this up yourself is advised.

You will also need to add some code to initialise the XR plugin. See the instructions
for each plugins but it will follow this form:

```
func _ready():
	var interface = ARVRServer.find_interface("name of the plugin")
	if interface and interface.initialize():
		# turn the main viewport into an ARVR viewport:
		get_viewport().arvr = true

		# turn off v-sync
		OS.vsync_enabled = false

		# put our physics in sync with our expected frame rate:
		Engine.iterations_per_second= 90
```

Finally you should add the addons/vr-common/misc/VR_Common_Shader_Cache.tscn subscene
as a child of the ARVRCamera node:

This ensures the shaders that are used to render various parts of this toolkit are 
compiled when the game loads.
