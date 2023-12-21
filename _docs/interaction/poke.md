---
title: Poke
permalink: /docs/poke/
---


## Introduction
Poke nodes are attached to finger-tips and allow the player to interact
with UI elements as well as providing basic physics for pushing objects.

## Setup
The poke nodes must be attached to finger-tip bones of hands using
BoneAttachment3D nodes. This is done by:
- Enabling "Editable Children" on a hands
- Adding a BoneAttachment3D as a child of the hand Skeleton3D node
- Picking the Bone Name (often `Index_Tip_L` or `Index_Tip_R`)
- Adding a child `/addons/godot-xr-tools/player/poke/poke.tscn`

The following shows a poke attached to the index finger of the left hand:
![Poke Setup]({{ site.url }}/assets/img/poke/poke_setup.png)

The functionality works out of the box but can be further configured:
![Poke Configuration]({{ site.url }}/assets/img/poke/poke_config.png)

## Configuration

### XRToolsPoke

| Property | Description |
| ---- | ------------ |
| Enabled           | When enabled the poke is functional |
| Radius            | Radius in meters of the poke 'sphere' |
| Color             | Color of the poke mesh |
| Teleport Distance | How far the poke will be blocked before teleporting back to the finger-tip |
| Collision Layer   | Layer the poke resides on (usually [18] Player Hands)
| Collision Mask    | Layers the poke interacts wit (usually [1-16] and [23] UI Objects)
| Push Bodies       | When enabled the poke will apply pushing force to RigidBody3D objects |
| Stiffness         | Force to apply (relative to poke displacement from the finger-tip) |
| Maximum Force     | Maximum force to apply (on each physics frame) |
