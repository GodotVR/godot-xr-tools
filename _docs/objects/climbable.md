---
title: Climbable Objects
permalink: /docs/climbable/
---


## Introduction
The user can climb on climbable object when the player is configured with a
[Climbing]({{ site.url }}/docs/climbing/) movement provider.

## Setup
Climbable objects should be constructed by creating a new inherited scene from
objects/climbable.tscn; however its possible to make existing static objects
climbable by adding the XRToolsClimbable script to them.

The following shows a climbable platform:
![Climbable Setup]({{ site.url }}/assets/img/climbable/climbable_setup.png)

The climbable script has no configuration; however the basic StaticBody
collision layer should match the [Pickup]({{ site.url }}/docs/pickup/) grab
collision mask to allow the pickup to grab hold of the climbing object.


