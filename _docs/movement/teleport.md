---
title: Teleport
permalink: /docs/teleport/
---


## Introduction
If positional tracking is available the player can physically move through
the world but is always constrained by the available physical space.

Teleport is one solution to this problem and allows the player to point to a
location they want to move to and then teleport to that new location.

Many experience this as a more pleasant way of moving around larger 3D worlds
but the player instantly moving to a new location can cause some game play issues.

## Setup
The teleporter is implemented as a function scene. These are scenes that can be
added to the controller node that they should work with.

So if we want to implement the teleport feature on the left hand controller we
need to add the scene to the left hand:
![Teleport Setup]({{ site.url }}/assets/img/teleport/teleport_setup.png)

The teleporter will interact with the physics objects in your scene and will
allow the player to teleport to any flat surface that provides enough space for
the player to stand.

The functionality works out of the box but can be further configured:
![Teleport Configuration]({{ site.url }}/assets/img/teleport/teleport_config.png)

## Configuration

### XRToolsFunctionTeleport

| Property | Description |
| ---- | ------------ |
| Enabled                | When ticked the teleport function is enabled |
| Teleport Button Action | OpenXR Bool action to trigger teleport |
| Rotation Action        | OpenXR Vector2 action to trigger rotation |
| Can Teleport Color     | Teleport arc color when teleporting is valid |
| Cant Teleport Color    | Teleport arc color when teleporting is invalid |
| No Collision Color     | Teleport arc color when teleport arc has no collision |
| Strength               | Determines how far the teleport arc extends |
| Arc Texture            | Texture drawn on the teleport arc |
| Target Texture         | Texture drawn on the teleport target |
| Player Height          | Height of the player used for our collision shape |
| Player Radius          | Radius of the player used for our collisions shape |
| Player Scene           | Custom player scene |
| Player Material        | Custom player material (if scene not specified) |
| Max Slope              | Maximum angle from flat our surface can be for us to teleport onto it | 
| Collision Mask         | Physics collision mask for arc | 
| Valid Teleport Mask    | Physics mask for valid teleport targets | 
