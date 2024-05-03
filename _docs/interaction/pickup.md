---
title: Pickup Function
permalink: /docs/pickup/
---


## Introduction
A common feature in VR is picking up objects. This is usually combined with
adding hand models to the player's controllers to make pickup feel more 
natural.

## Setup
Adding support for object pickup involves adding XRToolsFunctionPickup instances as children
to the controllers of both hands. The pickup function can be found in `addons/godot-xr-tools/functions/function_pickup.tscn`

The following shows a player configuration including pickups:
![Pickup Setup]({{ site.url }}/assets/img/pickup/pickup_setup.png)

The functionality works out of the box but can be further configured in the inspector:
![Pickup Configuration]({{ site.url }}/assets/img/pickup/pickup_config.png)

The two common types of objects that XRToolsFunctionPickup can interact with are:
* [Pickable]({{ site.url }}/docs/pickable/) objects
* [Climbable]({{ site.url }}/docs/climbable/) when combined with the [Climbing]({{ site.url }}/docs/climbing/) movement provider

See [Physics Layers]({{ site.url }}/docs/physics_layers/) for recommendations on
how to configure physics layers for Godot XR Tools.


## Configuration

### XRToolsFunctionPickup

| Property | Description |
| ---- | ------------ |
| Enabled               | When enabled, the pickup is capable of picking up objects |
| Pickup Axis Action    | OpenXR Bool action to trigger gripping (usually the Grip axis) |
| Action Button Action  | OpenXR Bool action to trigger the default action (if any) on the held object |
| Grab Distance         | Distance that regular pickups can be performed |
| Grab Collision Mask   | Collision mask to detect pickable objects |
| Ranged Enable         | When enabled, the pickup is capable of picking up objects from a distance |
| Ranged Distance       | Distance that ranged-grabs can be performed. |
| Ranged Angle          | Angle (from controller-forward) that ranged grabs can be performed |
| Ranged Collision Mask | Collision mask to detect ranged-pickable objects |
| Impulse Factor        | Velocity scale to apply to thrown objects |
| Velocity Samples      | How many averages to perform on held objects to detect velocity (for throwing) |


## Additional Resources

The following videos show the creation of a basic XR Player with hands and picking up objects:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
* [Pickable Grab Points](https://youtu.be/46Mp8PxcNXs)
