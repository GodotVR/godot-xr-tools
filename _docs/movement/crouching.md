---
title: Crouching
permalink: /docs/crouching/
---


## Introduction
Crouching allows the user to override the players height to a fixed value and
ignoring the actual height of the headset in the play-space.

## Setup
Add the MovementCrouch under the appropriate controllers. This will add a 
PlayerBody if necessary.

The setup should now look like:
![Crouch Setup]({{ site.url }}/assets/img/crouching/crouch_setup.png)

Next select the MovementCrouch node and configure:
![Crouch Configuration]({{ site.url }}/assets/img/crouching/crouch_config.png)

## Configuration

### XRToolsMovementCrouch

| Property      | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| Enabled       | When ticked this node will control the players movement.       |
| Order         | The order in which this movement is processed in case multiple movement functions are active.  |
| Crouch Height | The height forced on the player when crouching.  |
| Crouch Button | Which button triggers crouching.  |
| Crouch Type   | Crouch control type - either "Hold to Crouch" or "Toggle Crouch".  |
