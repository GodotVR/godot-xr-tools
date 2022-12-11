---
title: Grab Points
permalink: /docs/grab_point/
---


## Introduction
Grab Points can be added to [Pickable]({{ site.url }}/docs/pickable/) objects
to control where the pickable object will be held by the players hands, or 
snapped into snap-zones.

## Setup
The following shows a teacup with grab points attached:
![Pickable Setup]({{ site.url }}/assets/img/pickable/pickable_setup.png)

The three types of grab-points supported are:
* GrabPointHandLeft - objects/grab_points/grab_point_hand_left.tscn
* GrabPointHandRight - objects/grab_points/grab_point_hand_right.tscn
* GrabPointSnap - objects/grab_points/grab_point_snap.tscn

## Hand Grab Points
Hand grab-points can be configured with custom hand poses, and the editor will
preview the hand in the open or closed pose to help the alignment process. To
view the hand toggle the visibility option in the scene tree for the hand grab
point.
![Hand Align]({{ site.url }}/assets/img/grab_point/grab_point_hand_align.png)

The following shows the hand grab-point configuration options:
![Hand Config]({{ site.url }}/assets/img/grab_point/grab_point_hand_config.png)
> Changing the Editor Preview Mode has no effect on the game and is just used to
> help the alignment process.

## Snap-Zone Grab Points
Snap-zone grab-points can be configured to control which snap-zones the object
can be snapped into, and the orientation when snapping. To view the snap-zone
alignment helper, toggle the visibility option in the scene tree for the
snap-zone grab point.
![Snap-Zone Align]({{ site.url }}/assets/img/grab_point/grab_point_snap_zone_align.png)

The following shows the snap-zone grab-point configuration options:
![Snap-Zone Config]({{ site.url }}/assets/img/grab_point/grab_point_snap_zone_config.png)

> The standard approach to controlling which snap-zone grab-points work with which 
> snap-zones is to use groups. The example above has a snap-zone grab-point which
> is supposed to be for the teacup stand. This is achieved by:
>  1. Add the teacup stand snap-zone to the "TeacupStand" group
>  2. Set the snap-zone grab-point require group to "TeacupStand".


## Configuration

### XRToolsGrabPointHand

| Property            | Description                                                     |
| ------------------- | --------------------------------------------------------------- |
| Enabled             | When enabled, the object can be picked up by this grab-point. |
| Hand                | Which hand this hand-grab-point is configured for. |
| Hand Pose           | XRToolsHandPoseSettings to apply when holding an object by this grab-point. |
| Editor Preview Mode | Mode for the preview hand in the editor. |


### XRToolsGrabPointSnap

| Property            | Description                                                     |
| ------------------- | --------------------------------------------------------------- |
| Enabled             | When enabled, the object can be snapped by this grab-point. |
| Require Group       | Optional name of a group the object requires the snap-zone to be in. |
| Exclude Group       | Optional name of a group the object refuses the snap-zone to be in. |
