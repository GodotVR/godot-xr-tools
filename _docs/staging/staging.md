---
title: Staging
permalink: /docs/staging/
---

## Introduction
Staging is the process of dynamically switching scenes (sometimes called zones).

## Staging Setup
The first item to construct for staging is the stage itself. This is done by
creating a new scene inheriting from `/addons/godot-xr-tools/staging/staging.tscn`. 

The following shows a basic staging scene with a standard godot splash image:
![Staging Setup]({{ site.url }}/assets/img/staging/staging_setup.png)

The staging script needs to be configured to specify the main scene to load
when starting, and also whether to prompt for continue on every scene
transition.
![Staging Configuration]({{ site.url }}/assets/img/staging/staging_config.png)

The `LoadingScreen` node should be configured to specify the splash
screen to show in the background while loading data or prompting for continue.

## Scene Construction
Staged scenes (or zones) are scenes inheriting from
`/addons/godot-xr-tools/staging/scene_base.tscn`.

This base scene only contains a basic XR Rig for the player; so a common practice
is to create a game-specific base-scene with the XR Rig populated with the
movement and interaction functionality desired for the player:
![Game Scene Base Setup]({{ site.url }}/assets/img/staging/game_scene_base_setup.png)

The game scenes/zones are then constructed inheriting from this game-specific scene
base bringing in the configured player, so the scenes/zones only need to deal with
the content.

![Game Scene Setup]({{ site.url }}/assets/img/staging/game_scene_setup.png)

## Scene switching
Scene switching must be triggered by code such as:
```gdscript
# Find the XRToolsSceneBase ancestor of the current node
var scene_base : XRToolsSceneBase = XRTools.find_xr_ancestor(self, "*", "XRToolsSceneBase")
if not scene_base:
	return

# Request loading the next scene
scene_base.load_scene("res://zones/zone_2.tscn")
```

> The [Godot-XR-Template](https://github.com/GodotVR/godot-xr-template) project extends
  staging with game persistence as well as scene-switching helper scripts.


### Spawn Point
By default the player will spawn in to the location where the XR Rig is 
positioned in the scene. The `XRToolsSceneBase.load_scene` method takes
an optional second argument which specifies the player spawn point as:
- A name of a Node3D (such as a Marker3D)
- A Vector3
- A Transform3D
- An object with a `get_spawn_position` method returning a name/Vector3/Transform3D