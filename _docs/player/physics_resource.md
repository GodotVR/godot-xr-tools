---
title: Physics resource
permalink: /docs/physics_resource/
---

The XR tools library allows us to control how the player interacts with certain elements within the virtual world. While it applies sensible defaults these can be overriden. As these settings often need to be shared over multiple objects the XR tools library implements a physics settings resource that allows us to store these settings in.

## Setup

You can simply create a new resource of the type `XRToolsGroundPhysicsSettings`` using the resource inspector and then save your resource as a .tres file.

## Configuration

| Property               | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| Flags                  | Lets you select which settings will be applied.  |
| Move Drag              | The drag factor applied on movement to automatically slow the player down.  |
| Move Traction          | The traction factor that determines how fast the player speeds up.  |
| Move Max Slope         | Limits the players ability to move depending on the angle of the slope the player is standing on.  |
| Jump Max Slope         | Limits the players ability to jump depending on the angle of the slope the player is standing on.  |
| Jump Velocity          | The velocity in m/s the player is propelled upwards when jumping.  |
