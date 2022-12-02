---
title: Wind
permalink: /docs/wind/
---


## Introduction
Wind movement allows the player to be blown around by wind areas. This can be
combined with lower ground drag and traction settings to cause the player to
slide.

## Setup
The wind movement is implemented as a movement scene that needs to be added
to the ARVROrigin node. This will add a PlayerBody if necessary.

The following shows a player configuration including turning:
![Wind Movement Setup]({{ site.url }}/assets/img/wind/wind_setup.png)

The functionality works out of the box but can be further configured:
![Wind Movement Configuration]({{ site.url }}/assets/img/wind/wind_config.png)

Ground drag and traction settings are set on the surface the player is standing
on. This is achieved by adding a ground physics node as a child of the physics
body and setting the ground physics properties:
![Wind Physics Configuration]({{ site.url }}/assets/img/wind/wind_physics.png)

> It is also possible to set default ground physics in the PlayerBody node.

## Configuration

### XRToolsMovementWind

| Property        | Description                                                     |
| --------------- | --------------------------------------------------------------- |
| Enabled         | When ticked the movement function is enabled.                   |
| Order           | The order in which this movement is applied when multiple movement functions are used.  |
| Drag Multiplier | Drag coefficient for how much the wind affects the player. |
| Collision Mask  | Collision mask for detecting wind areas. |

### XRToolsGroundPhysicsSettings (for sliding)

| Property       | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| Move Drag      | Coefficient for how fast the player slows down when not trying to move. |
| Move Traction  | Coefficient for how much the player movement is affected by direct control. |

> Setting move drag and traction to zero simulates perfect frictionless ice - the 
player will slide without any movement control other than being blown around by
the wind.