---
title: Hand Models
permalink: /docs/hand_models/
---


## Introduction
The player can have XRToolsHand based scenes attached to the XRController3D
nodes to provide hands for the player.


## Hand Scenes
Three hand model scenes have been provided:

The standard hand scenes works out of the box but can be further configured:
![Hand Configuration]({{ site.url }}/assets/img/hand_models/hand_config.png)

| Hand Scene   | Preview |
| ------------ | ------- |
| Hand         | ![Hand]({{ site.url }}/assets/img/hand_models/hand_default.png) |
| Full Glove   | ![Full Glove]({{ site.url }}/assets/img/hand_models/full_glove_default.png) |
| Tac Glove    | ![Tac Glove]({{ site.url }}/assets/img/hand_models/tac_glove_default.png) |

Note: There are actually 24 different hand scenes - variants of the three above but with:
 - Low or High polygon versions
 - Left or Right hand versions
 - Physics (with finger bone colliders) or normal mesh-only


## Material Overrides
The hand materials can be overridden, and the following materials have been provided:

| Material        | Preview |
| ------------ | ------- |
| African Hands | ![African Hands]({{ site.url }}/assets/img/hand_models/african_hands.png) |
| African Hands Realistic | ![African Hands Realistic]({{ site.url }}/assets/img/hand_models/african_hands_realistic.png) |
| Caucasian Hands | ![Caucasian Hands]({{ site.url }}/assets/img/hand_models/caucasian_hands.png) |
| Caucasian Hands Realistic | ![Caucasian Hands Realistic]({{ site.url }}/assets/img/hand_models/caucasian_hands_realistic.png) |
| Clean Glove | ![Clean Glove]({{ site.url }}/assets/img/hand_models/clean_glove.png) |
| Lab Glove | ![Clean Glove]({{ site.url }}/assets/img/hand_models/lab_glove.png) |
| Glove African Dark Camo | ![Glove African Dark Camo]({{ site.url }}/assets/img/hand_models/glove_african_dark_camo.png) |
| Glove African Green Camo | ![Glove African Green Camo]({{ site.url }}/assets/img/hand_models/glove_african_green_camo.png) |
| Glove Caucasian Dark Camo | ![Glove Caucasian Dark Camo]({{ site.url }}/assets/img/hand_models/glove_caucasian_dark_camo.png) |
| Glove Caucasian Green Camo | ![Glove Caucasian Green Camo]({{ site.url }}/assets/img/hand_models/glove_caucasian_green_camo.png) |


## Configuration

### XRToolsHand

| Property               | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| Hand Blend Tree        | Blend tree to define how the grip and trigger inputs control the fingers |
| Hand Material Override | Override material to apply to the hand mesh  |
| Default Pose           | Default XRToolsHandPoseSettings resource defining the pose |


## Additional Resources

The following video show the creation of a basic XR Player with hands:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
