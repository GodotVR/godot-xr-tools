---
title: World Grab
permalink: /docs/world_grab/
---


## Introduction
World-grab movement allows the player to move by grabbing hold of the world
and pulling themselves around. The player can grab the world with both hands
allowing for rotation as well as growing and shrinking.

## Setup
The world-grab movement is implemented as a function scene that needs to be added
to the XROrigin3D node. This will add a PlayerBody if necessary. Additionally the
player needs to have grab functions on both hands to grab hold of world-grab
areas.

The following shows a player configuration including world-grab:
![World-Grab Movement Setup]({{ site.url }}/assets/img/world_grab/world_grab_setup.png)

The functionality works out of the box but can be further configured:
![World-Grab Movement Configuration]({{ site.url }}/assets/img/world_grab/world_grab_config.png)

## World Grab areas
In order to move, the player has to grab hold of a world-grab area. This is
done by adding an instance of objects/world_grab_area.tscn to the scene
and giving it a CollisionShape3D representing the grab area.
![World-Grab Aera Setup]({{ site.url }}/assets/img/world_grab/world_grab_area_setup.png)

The area can also be configured to turn off local gravity by applying a
gravity space override and setting the gravity to 0 m/s²
![World-Grab Aera Configuration]({{ site.url }}/assets/img/world_grab/world_grab_area_config.png)


## Configuration

### XRToolsMovementWorldGrab

| Property | Description |
| ---- | ------------ |
| Enabled         | When ticked the movement function is enabled |
| Order           | The order in which this movement is applied when multiple movement functions are used |
| World Scale Min | Minimum world-scale when sizing through grabbing |
| World Scale Max | Maximum world-scale when sizing through grabbing |
