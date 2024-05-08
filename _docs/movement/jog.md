---
title: Jog
permalink: /docs/jog/
---


## Introduction
Jog movement allows the player to move by swinging their arms.

## Setup
The jog movement is implemented as a function scene that needs to be added
to the [XROrigin3D](https://docs.godotengine.org/en/stable/classes/class_xrorigin3d.html) node. This will add a PlayerBody if necessary.

The following shows a player configuration including jogging:
![Jog Movement Setup]({{ site.url }}/assets/img/jog/jog_setup.png)

The functionality works out of the box but can be further configured:
![Jog Movement Configuration]({{ site.url }}/assets/img/jog/jog_config.png)

## Configuration

### XRToolsMovementJog

| Property | Description |
| ---- | ------------ |
| Enabled    | When ticked the movement function is enabled |
| Order      | The order in which this movement is applied when multiple movement functions are used |
| Slow Speed | Movement speed when swinging the arms slowly |
| Fast Speed | Movement speed when swinging the arms quickly |
