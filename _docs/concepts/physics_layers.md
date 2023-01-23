---
title: Physics Layers
permalink: /docs/physics_layers/
---


## Introduction
Godot uses physics layers to control physical interactions and area detections.
Incorrect physics layer settings are often observed as:
 - The player falling through objects or the world
 - The player being pushed backwards by held objects
 - The player being unable to pick up objects or insert them into snap-zones
 - Objects passing through each other

 
## Recommended Physics Layers
The following are the recommended physics layers:
 - [1] Static World - for fixed scenery objects that never move
 - [2] Dynamic World - for scenery objects which may move
 - [3] Pickable Objects - for [pickable]({{ site.url }}/docs/pickable/) objects
 - [4] Wall Walking Surface - for objects the player can [wall walk]({{ site.url }}/docs/wall_walk/) on
 - [17] Held Objects - for [pickable]({{ site.url }}/docs/pickable/) objects held by the player
 - [18] Player Hand - for the players [physical hand]({{ site.url }}/docs/hand_models/) bones
 - [20] Player Body - for the players [body]({{ site.url }}/docs/player_body/)
 - [21] Pointable - for objects the player can interact with using the [pointer]({{ site.url }}/docs/pointer/)
 - [22] Hand Pose Area - for areas enforcing hand poses

![Physics Layers]({{ site.url }}/assets/img/physics_layers/physics_layers_config.png)


## Node Configurations
The following are recommendations for configuring physics layers for different 
types of nodes.


### Player Body
By default the player [body]({{ site.url }}/docs/player_body/) is located on 
layer [20], and will collide with any objects on layers [1 - 10].

![Player Body]({{ site.url }}/assets/img/player_body/player_body_config.png)


### Pickable Objects
[Pickable]({{ site.url }}/docs/pickable/) objects have different layer settings
based on whether or not they are held by the player.

When not held by the player, the pickable objects must:
 - Be on a layer the players [pickup]({{ site.url }}/docs/pickup/) function
   has in its mask, otherwise the player will be unable to pick it up.
 - Have a collision mask that prevents it from falling through the world or 
   other objects.
   
When held by the player, the pickable objects must:
 - Be on a layer that collides with any compatible snap-zones, so the snap-zones can
   detect when the held object enters their area of influence
 - *NOT* be on a layer that collides with the player body, or the player will collide
   with the held object and fly backwards.


![Pickable Layers]({{ site.url }}/assets/img/physics_layers/pickable_layers_config.png)

This pickable object has been configured to:
 - Reside on layer '[17] Held Objects' when held.
 - Reside on layer '[3] Pickable Objects' when not held.
 - Collide with layers '[1] Static World' and '[2] Dynamic World' so it doesn't
   fall through the world when dropped.
 - Collide with layer '[3] Pickable Objects' so it won't fall through other 
   pickable objects.
 - Collide with layer '[17] Held Objects' so it can be pushed around by other
   objects the player is holding.
 - Collide with layer '[18] Player Hand' so it can be pushed around by the hand
   bones of a players physics hand.
   

### Snap Zones
[Snap Zones]({{ site.url }}/docs/snap_zone) must:
 - Be on a layer the players [pickup]({{ site.url }}/docs/pickup/) function
   has in its mask, otherwise the player will be unable to pick items out of
   the snap zone.
 - Have a collision mask that detects pickable objects held by the player, so
   it can detect when those objects are dropped in its area of influence.
 - Have a collision mask that detects pickable objects not held by the player
   in case the objects fall into the snap-zone area of influence


![Snap Zone]({{ site.url }}/assets/img/snap_zone/snap_zone_config.png)

This snap zone has been configured to:
 - Reside on layer '[3] Pickable Objects' so the player can grab items out
   of it.
 - Collide with layer '[3] Pickable Objects' so it can detect objects falling
   into its area of influence.
 - Collide with layer '[17] Held Objects' so it can detect when held objects
   in its area of influence are dropped.
