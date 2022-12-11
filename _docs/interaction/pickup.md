---
title: Pickup Function
permalink: /docs/pickup/
---


## Introduction
A common feature in VR is picking up objects. This is usually combined with
adding hand models to the players controllers to make pickup feel more 
natural.

## Setup
Adding support for object pickup involves adding XRToolsFunctionPickup instances
to the controllers of both hands.

The following shows a player configuration including pickups:
![Pickup Setup]({{ site.url }}/assets/img/pickup/pickup_setup.png)

The functionality works out of the box but can be further configured:
![Pickup Configuration]({{ site.url }}/assets/img/pickup/pickup_config.png)

The two common types of objects that XRToolsFunctionPickup can interact with are:
* [Pickable]({{ site.url }}/docs/pickable/) objects
* [Climbable]({{ site.url }}/docs/climbable/) when combined with the [Climbing]({{ site.url }}/docs/climbing/) movement provider


## Configuration

### XRToolsFunctionPickup

| Property              | Description                                                     |
| --------------------- | --------------------------------------------------------------- |
| Enabled               | When enabled, the pickup is capable of picking up objects. |
| Pickup Axis ID        | The axis to trigger gripping (usually the Grip axis).  |
| Action Button ID      | The button to trigger the default action (if any) on the held object. |
| Smooth Turn Speed     | Smooth turn speed in radians per second. |
| Grab Distance         | Distance that regular pickups can be performed. |
| Grab Collision Mask   | Collision mask to detect pickable objects. |
| Ranged Enable         | When enabled, the pickup is capable of picking up objects from a distance. |
| Ranged Distance       | Distance that ranged-grabs can be performed. |
| Ranged Angle          | Angle (from controller-forward) that ranged grabs can be performed. |
| Ranged Collision Mask | Collision mask to detect ranged-pickable objects. |
| Impulse Factor        | Velocity scale to apply to thrown objects. |
| Velocity Samples      | How many averages to perform on held objects to detect veliocity (for throwing). |
