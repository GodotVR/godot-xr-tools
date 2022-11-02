---
title: Direct Movement
permalink: /docs/direct/
---


## Introduction
Direct movement allows the user to move using controller input, it uses either
the joystick or thumbpad that can be found on many XR controllers. 

It uses the 'PlayerBody' node to support collisions with the environment. This
node will be added automatically to your scene if it doesn't exist yet.

The main issue with direct movement is that it can easily result in dizzyness
on the part of the player. Especially rotating the player leads to many players
getting nauseated.

We combat this in three ways:
- direction of movement is always in relation to the direction the player is
  looking. 
- it is possible to configure a step value for the rotation. Instead of smoothly
  rotating around the player the direction the player is looking will rotate a
  fixes number of degrees at a fixed pace. While this looks jerky it is a very
  efficient way to combat nausia. 
- you can add a Vignette that blacks out the players peripheral vision.

## Setup
The direct movement is implemented as a function scene that needs to be added
to the controller node whose input we are using.

So if we want to implement the direct movement feature on the right hand
controller we need to add the scene to the right hand:
![Direct Movement Setup]({{ site.url }}/assets/img/direct/direct_setup.png)

> Note that we recommend adding the ability to your game for the user to configure
  the movement controls. This can be achieved by modigying the MovementDirect 
  configuration such as enabling or disabling.

The functionality works out of the box but can be further configured:
![Direct Movement Configuration]({{ site.url }}/assets/img/direct/direct_config.png)

## Configuration

### XRToolsMovementDirect

| Property      | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| Enabled       | When ticked the movement function is enabled.                   |
| Order         | The order in which this movement is applied when multiple movement functions are used.  |
| Max Speed     | The maximum speed at which we can move, note that this is never reached depending on the drag factor configured on the player body.  |
| Strafe        | Enables left/right control of strafing. |
