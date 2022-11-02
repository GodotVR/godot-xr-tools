---
title: Glide
permalink: /docs/glide/
---


## Introduction
Glide movement allows the player to glide when falling by extending their arms
in a T-pose.

## Setup
The glide movement is implemented as a movement scene that needs to be added
to the ARVROrigin node. This will add a PlayerBody if necessary.

The following shows a player configuration including gliding:
![Glide Movement Setup]({{ site.url }}/assets/img/glide/glide_setup.png)

The functionality works out of the box but can be further configured:
![Glide Movement Configuration]({{ site.url }}/assets/img/glide/glide_config.png)

## Configuration

### XRToolsMovementGlide

| Property              | Description                                                     |
| --------------------- | --------------------------------------------------------------- |
| Enabled               | When ticked the movement function is enabled.                   |
| Order                 | The order in which this movement is applied when multiple movement functions are used.  |
| Glide Detect Distance | T-pose controller distance to trigger gliding. |
| Glide Min Fall Speed  | Minimum player Z/fall speed to trigger gliding. |
| Glide Fall Speed      | Target Z/fall speed when gliding. |
| Glide Forward Speed   | Target forward speed when gliding.  |
| Horizontal Slew Rate  | Rate at which gliding player horizontal speed changes to target forward speed. |
| Vertical Slew Rate    | Rate at which gliding player vertical speed changes to target Z/fall speed. |
