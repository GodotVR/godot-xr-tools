---
title: Flight
permalink: /docs/flight/
---


## Introduction
Flight movement allows the player to fly around the scene. Different flight
effects can be achieved by varying the flight configuration.

## Setup
The flight movement is implemented as a movement scene that needs to be added
to the ARVROrigin node. This will add a PlayerBody if necessary.

The following shows a player configuration including flying:
![Flight Movement Setup]({{ site.url }}/assets/img/flight/flight_setup.png)

The functionality works out of the box but can be further configured:
![Flight Movement Configuration]({{ site.url }}/assets/img/flight/flight_config.png)

## Configuration

### XRToolsMovementFlight

| Property           | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| Enabled            | When ticked the movement function is enabled.                   |
| Order              | The order in which this movement is applied when multiple movement functions are used.  |
| Controller         | Specifies which controller is used for flight input. |
| Flight Button      | Specifies the button (on the selected controller) to toggle flight control. |
| Pitch              | Selects whether pitch input comes from the controller or the players head. |
| Bearing            | Selects whether bearing input comes from the controller or the players head. |
| Speed Scale        | Specifies the speed driven by the flight control. |
| Speed Traction     | Specifies how much traction the controlled speed has on the player. |
| Acceleration Scale | Specifies the acceleration driven by the flight control. |
| Drag               | Specifies the drag on the players movement. |
| Guidance           | Specifies how much the players movement will be deflected by the control direction. |
| Exclusive          | Specifies whether flight movement prevents additional movement effects when active. |

### World Exploration
To implement world exploration (gentle movement around the world), the player
flight movement should just be at a gentle speed in the direction of the
controller. Use the following values to achieve this:
 - Speed Scale = 5 (gentle speed)
 - Speed Traction = 10 (quickly get up to controlled speed)
 - Acceleration Scale = 0 (don't continue to accelerate)
 - Guidance = 0 (no need for guidance as no acceleration)
 - Exclusive = True (ignore gravity)

### Rocket Pack
To implement rocket like physics, the player should experience acceleration
from the flight controller. Additionally the player may be able to guide/turn
the flight direction emulating guide fins. Use the following values to achieve this:
 - Speed Scale = 0 (no direct-speed contribution)
 - Speed Traction = 0 (no traction against the speed contribution)
 - Acceleration Scale = 20 (large enough that upwards thrust exceeds gravity)
 - Guidance = 1 (minor ability to steer current velocity)
 - Exclusive = False (allow gravity to affect flight)
