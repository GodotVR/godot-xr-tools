---
title: Crouching
permalink: /docs/crouching/
---


## Introduction
Crouching allows the user to override the player's height to a fixed value and
ignoring the actual height of the headset in the play-space.

## Setup
Add the MovementCrouch under the appropriate controllers. This will add a 
[PlayerBody](https://godotvr.github.io/godot-xr-tools/docs/player_body/) if necessary.

The setup should now look like:
![Crouch Setup]({{ site.url }}/assets/img/crouching/crouch_setup.png)

Next select the MovementCrouch node and configure:
![Crouch Configuration]({{ site.url }}/assets/img/crouching/crouch_config.png)


## Configuration

### XRToolsMovementCrouch

| Property | Description |
| ---- | ------------ |
| Order                | The order in which this movement is processed in case multiple movement functions are active |
| Crouch Height        | The height forced on the player when crouching |
| Crouch Button Action | OpenXR Bool action to trigger the crouch (usually `by_button` when using the default action map) |
| Crouch Type          | Crouch control type - either "Hold to Crouch" or "Toggle Crouch" |
| Enabled              | When ticked this node will control the players movement |


## Additional Resources

The following videos show the creation of a basic XR Player with hands and movement including crouching:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
* [Basic Movement](https://youtu.be/29qlCRw2TpE)
