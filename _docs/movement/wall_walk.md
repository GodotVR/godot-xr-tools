---
title: Wall Walk
permalink: /docs/wall_walk/
---


## Introduction
Wall walking is a common feature in many 2D and 3D games, and has started
appearing in VR games (for players with strong stomachs).

This movement provider allows the player to walk on objects which have a
physics layer matching the provider's mask.

See [Physics Layers]({{ site.url }}/docs/physics_layers/) for recommendations on
how to configure physics layers for Godot XR Tools.


## Setup
The wall walk movement is implemented as a movement scene that needs to be 
  added to the [XROrigin3D](https://docs.godotengine.org/en/stable/classes/class_xrorigin3d.html) node. This will add a [PlayerBody](https://godotvr.github.io/godot-xr-tools/docs/player_body/) if necessary.

The following shows a player configuration including wall walking:
![Wall Walk Setup]({{ site.url }}/assets/img/wall_walk/wall_walk_setup.png)

The functionality works out of the box but can be further configured:
![Wall Walk Configuration]({{ site.url }}/assets/img/wall_walk/wall_walk_config.png)


## Configuration

### XRToolsMovementWallWalk

| Property | Description |
| ---- | ------------ |
| Enabled            | When ticked the movement function is enabled |
| Order              | The order in which this movement is applied when multiple movement functions are used |
| Follow Mash        | The physics layers that support wall walking |
| Stick Distance     | How far away from the wall the player can jump |
| Stick Strength     | Wall "pseudo-gravity" exerted on the player |
