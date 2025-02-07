---
title: Pickable Objects
permalink: /docs/pickable/
---


## Introduction
The user can pick up pickable objects if the player is configured with
[Pickup]({{ site.url }}/docs/pickup/) functions on the controllers.

## Setup
Pickable objects should be constructed by creating a new inherited scene from
objects/pickable.tscn; however its possible to make existing RigidBody objects
pickable by adding the XRToolsPickable script to them.

The following shows a pickable teacup:
![Pickable Setup]({{ site.url }}/assets/img/pickable/pickable_setup.png)

Pickable objects generally consist of:
* The RidigBody (usually inherited from objects/pickable.tscn)
* The CollisionShape (usually inherited from objects/pickable.tscn)
* A mesh to render the object
* Some number of [Grab Points]({{ site.url }}/docs/grab_point/)

The pickable object has many configuration parameters, including important 
ones inherited from RigidBody which must be configured appropriately:
![Pickable Configuration]({{ site.url }}/assets/img/pickable/pickable_config.png)

The most important settings include:
* Picked Up Layer: Physics layer of the object when held
* Release Mode: Physics mode of the object when released
* Collision Layer: Physics layer of the object when not held
* Collision Mask: Which layers the object collides with

> A common bug is to specify a Picked Up Layer which can collide with the players 
> body. When this mistake occurs, and the player brings the picked up object close
> to them, the object will push the player back, but the object is held by the
> player, so the player will rapidly accelerate away from the held object.

A common pickup configuration is:
* Picked Up Layer: Leave blank so the held object does not collide with anything.
* Release Mode: Original - restoring the object to the same state it had before pickup.
* Collision Layer: A standard layer for dynamic objects in the scene.
* Collision Mask: Layers for the world and other objects (so it doesn't fall through the floor), and also matching the [Pickup]({{ site.url }}/docs/pickup/) collision mask so it can be picked up.

See [Physics Layers]({{ site.url }}/docs/physics_layers/) for recommendations on
how to configure physics layers for Godot XR Tools.


## Configuration

### XRToolsPickable

| Signal | Description |
| ---- | ------------ |
| picked_up(pickable: XRToolsPickable) | Signal emitted when this object is picked up (held by a player or snap-zone) |
| dropped(pickable: XRToolsPickable) | Signal emitted when this object is dropped |
| grabbed(pickable: XRToolsPickable, by: Node3D) | Signal emitted when this object is grabbed |
| action_pressed(pickable: XRToolsPickable) | Signal emitted when the user presses the action button while holding this object |
| highlight_updated(pickable: XRToolsPickable, enable: bool) | Signal emitted when the highlight state changes |

| Property | Description |
| ---- | ------------ |
| Enabled            | If true, the object can be picked up |
| Press To Hold      | If true, the user must hold down the grab button specified in the pickup |
| Picked Up Layer    | Physics layer of the object while being held |
| Release Mode       | Mode to set when the object is released |
| Ranged Grab Method | Method used for ranged-grabbing of the object |
| Second Hand Grab   | How a second hand grab affects the pickable object |
| Ranged Grab Speed  | Speed to perform ranged-grabbing |
| Picked By Exclude  | Optional name of a group this object refuses to be picked up by |
| Picked By Require  | Optional name of a group this object requires being picked up by |
| Collision Layer    | Physics layers this object exists on when not held |
| Collision Mask     | Physics layers this object collides with |

> Note: Disabling pickup functionality via the Enabled property of an
  XRToolsPickable only affects whether it can be picked up. The object
  will still interact with the world by the rules of the RigidBody3D
  settings.

| Method | Description |
| ---- | ------------ |
| can_pick_up(by: Node3D) -> bool                 | Test if this object can be picked up |
| is_picked_up() -> bool                          | Test if this object is picked up |
| request_highlight(from : Node, on : bool = true) -> void | Toggles highlight on or off for this object if there are any outstanding highlight requests |
| drop() -> void                                  | Drop this pickable |
| drop_and_free() -> void                         | Drop and deletes this pickable |
| pick_up(by: Node3D) -> void                     | Pick up this object with another object |
| let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void  | Drop this object with a certain velocity |
| get_picked_up_by() -> Node3D                    | Get the node currently holding this object |
| get_picked_up_by_controller() -> XRController3D | Get the controller currently holding this object |
| get_active_grab_point() -> XRToolsGrabPoint     | Get the active grab-point this object is held by |
| switch_active_grab_point(grab_point : XRToolsGrabPoint) | Switch the active grab-point for this object |


## Additional Resources

The following videos show the creation of a basic XR Player with hands and picking up objects:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
* [Pickable Grab Points](https://youtu.be/46Mp8PxcNXs)
