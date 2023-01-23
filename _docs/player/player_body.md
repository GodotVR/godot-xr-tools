---
title: Player Body
permalink: /docs/player_body/
---


## Introduction
Player movement and world interaction is performed using an XRToolsPlayerBody
node. This node is automatically added to the ARVROrigin whenever a movement
provider node is added.

The player body works out of the box but can be further configured:
![Player Body Configuration]({{ site.url }}/assets/img/player_body/player_body_config.png)

See [Physics Layers]({{ site.url }}/docs/physics_layers/) for recommendations on
how to configure physics layers for Godot XR Tools.


## Configuration

### XRToolsPlayerBody

| Property               | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| Enabled                | Enables player body movement |
| Player Radius          | Radius of the player body capsule  |
| Player Head Height     | Height of the player body capsule above the eyes |
| Player Height Min      | Minimum player height |
| Player Height Max      | Maximum player height |
| Eye Forward Offset     | How far the eyes are forwards from the center of the player body capsule (1.0 = full radius) |
| Push Rigid Bodies      | If true, the player movement can push rigid bodies around |
| Physics                | Default player physics settings |
| Collision Layer        | Physics layers the body is located on |
| Collision Mask         | Physics layers the body collides with |
