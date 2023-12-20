---
title: Turn
permalink: /docs/turn/
---


## Introduction
Turn movement allows the player to turn around. Turning can be configured to be
either smooth or snap to limit motion sickness.

## Setup
The turn movement is implemented as a movement scene that needs to be added
to the controller node whose input we are using. This will add a PlayerBody if
necessary.

The following shows a player configuration including turning:
![Turn Movement Setup]({{ site.url }}/assets/img/turn/turn_setup.png)

The functionality works out of the box but can be further configured:
![Turn Movement Configuration]({{ site.url }}/assets/img/turn/turn_config.png)

The project can also be configured with default turn settings:
![Turn Movement Project Settings]({{ site.url }}/assets/img/turn/turn_project_settings.png)


## Configuration

### XRToolsMovementTurn

| Property | Description |
| ---- | ------------ |
| Enabled            | When ticked the movement function is enabled |
| Order              | The order in which this movement is applied when multiple movement functions are used |
| Turn Mode          | The type of turning to perform - Default, Snap, or Smooth |
| Smooth Turn Speed  | Smooth turn speed in radians per second |
| Step Turn Delay    | Maximum step turn repeat rate in seconds |
| Step Turn Angle    | Step turn angle in degrees |
| Input Action       | OpenXR Vector2 action to trigger turning (usually `primary` when using the default action map) |

### XRToolsUserSettings

This singleton is instanced by the XRTools plugin, and has the following turn settings:

| Property | Description |
| ---- | ------------ |
| Snap Turning | Defines the "Default" turn mode (true=snap, false=smooth) |


## Additional Resources

The following videos show the creation of a basic XR Player with hands and movement including turning:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
* [Basic Movement](https://youtu.be/29qlCRw2TpE)
