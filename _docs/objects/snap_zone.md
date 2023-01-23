---
title: Snap Zone
permalink: /docs/snap_zone/
---


## Introduction
Snap zones can hold [Pickable]({{ site.url }}/docs/pickable/) objects, and the
player can pull items out of them, and put items into them.


## Setup
Snap zones should be constructed by creating a new inherited scene from
objects/snap_zone.tscn.

The following shows an object with a snap-zone:
![Snap Zone Setup]({{ site.url }}/assets/img/snap_zone/snap_zone_setup.png)

The snap zone should be configured with the appropriate physics layers and
filters to ensure only supported objects are snapped:
![Snap Zone Configuration]({{ site.url }}/assets/img/snap_zone/snap_zone_config.png)

See [Physics Layers]({{ site.url }}/docs/physics_layers/) for recommendations on
how to configure physics layers for Godot XR Tools.


## Configuration

### XRToolsSnapZone

| Property              | Description                                                     |
| --------------------- | --------------------------------------------------------------- |
| Enabled               | When enabled, the snap zone can be interacted with. |
| Grab Distance         | Radius of snap zone sensitivity to objects being dropped.  |
| Snap Mode             | How objects are snapped into the snap-zone [Dropped or Range]. |
| Snap Require          | Pickable object group required for snapping. |
| Snap Exclude          | Pickable object group which prevents snapping. |
| Grab Collision Mask   | Collision mask to detect pickable objects. |
| Grab Require          | Pickup function group required for removing snapped item. |
| Grab Exclude          | Pickup function group which prevents removing snapped item. |
| Initial Object        | Optional object to snap into zone at scene start. |
| Collision Layer       | Snap area layer (must match pickup mask to support removing snapped items). |
| Collision Mask        | Snap area mask (must match pickable and held layers to support snapping items). |
