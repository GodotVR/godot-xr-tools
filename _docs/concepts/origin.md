---
title: VR Origin
permalink: /docs/origin/
---


## Introduction
In XR games, there are some standard objects to consider:
 - XR Origin
 - XR Camera
 - XR Controllers

The XR Origin maps the players physical play area into the XR world.

The XR Camera corresponds to the VR headset and is a child of the XR Origin. When
the player moves around in their physical play area the XR Camera moves around
correspondingly in the XR Origin.

The XR Controllers correspond to the players controllers and are also children of
the XR Origin. When the player moves the controllers in their physical play area
the XR Controllers move around correspondingly in the XR Origin


## Understanding XR Origin
The XR Origin is a common area of confusion. Consider the following image of a
guardian space for a player in their physical play area:
![Guardian Space]({{ site.url }}/assets/img/origin/guardian_space.png)

The large R/G/B axis-point in the middle of the guardian space represents the
identity (0/0/0) transform of the XR Origin.

When the user puts on the VR headset, the global transform of the XR Origin will
map the players guardian space into the VR world:
![Origin in VR]({{ site.url }}/assets/img/origin/origin_in_vr.png)

Note that the smaller R/G/B axis-points on the character correspond to the 
camera and controller positions in the XR Origin space.

If the game wishes to rotate the player to face in a different direction, it may
seem that the only thing needed is to rotate the XR Origin; however that almost
never works. Consider the following where the XR Origin is simply rotated:
![Origin Rotation Only]({{ site.url }}/assets/img/origin/origin_rotation_only.png)

The center 0/0/0 of the XR Origin did not move. As player was not standing at 
the center of the XR Origin, they were moved when the origin rotated - similar to
standing on a rotating carousel. Correctly rotating the player to face in a 
different direction involves having to translate the XR Origin in such a way that
the global position of the player (the XR Camera) does not move:
![Origin Correct Rotation]({{ site.url }}/assets/img/origin/origin_correct_rotation.png)


## Godot XR Tools handling of the XR Origin
Godot XR Tools does most of the hard work in helping you with these calculations.

In XR Tools a PlayerBody node is added to the Origin node that contains all the 
logic to estimate where the players body must be. Currently this logic assumes the 
player is always facing the direction they are looking at and that the player is
standing up.

The various movement functions then use this location to perform movement around
the assumed player location.
