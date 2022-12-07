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
* Mode: Initial physics mode of the object
* Collision Layer: Physics layer of the object when not held
* Collision Mask: Which layers the object will collide with (when not held)

> A common bug is to specify a Picked Up Layer which can collide with the players 
> body. When this mistake occurs, and the player brings the picked up object close
> to them, the object will push the player back, but the object is held by the
> player, so the player will rapidly accelerate away from the held object.

A common pickup configuration is:
* Picked Up Layer: Leave blank so the held object does not collide with anything.
* Release Mode: Rigid - so the object can be thrown and bounce around the world.
* Mode: Static - so the object is stuck in place until initially picked up.
* Collision Layer: A standard layer for dynamic objects in the scene.
* Collision Mask: Layers for the world and other objects (so it doesn't fall through the floor), and also matching the [Pickup]({{ site.url }}/docs/pickup/) collision mask so it can be picked up.


## Configuration

### XRToolsPickable

| Property           | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| Press To Hold      | If true, the user must hold down the grab button specified in the pickup. |
| Picked Up Layer    | Physics layer of the object while being held. |
| Hold Method        | Method used to hold the object in the pickup. |
| Release Mode       | RigidBody mode to set when the object is released. |
| Ranged Grab Method | Method used for ranged-grabbing of the object. |
| Ranged Grab Speed  | Speed to perform ranged-grabbing. |
| Picked By Exclude  | Optional name of a group this object refuses to be picked up by. |
| Picked By Require  | Optional name of a group this object requires being picked up by. |
