---
title: Hand Poses
permalink: /docs/hand_poses/
---


## Introduction
The XRToolsHand models support hand poses and blending between them using the
grip and trigger inputs. Hand Poses are configured using the 
XRToolsHandPoseSettings resource:
![Hand Pose Config]({{ site.url }}/assets/img/hand_poses/hand_pose_config.png)

## Poses
The following table shows all the standard hand poses.

| Pose         | Top      | Side     | Perspective |
| ------------ | -------- | -------- | ----------- |
| Cup          | ![Cup Top]({{ site.url }}/assets/img/hand_poses/pose_cup_top.png) | ![Cup Side]({{ site.url }}/assets/img/hand_poses/pose_cup_side.png) | ![Cup Perspective]({{ site.url }}/assets/img/hand_poses/pose_cup_perspective.png) |
| Default      | ![Default Top]({{ site.url }}/assets/img/hand_poses/pose_default_top.png) | ![Default Side]({{ site.url }}/assets/img/hand_poses/pose_default_side.png) | ![Default Perspective]({{ site.url }}/assets/img/hand_poses/pose_default_perspective.png) |
| Grip 1       | ![Grip 1 Top]({{ site.url }}/assets/img/hand_poses/pose_grip1_top.png) | ![Grip 1 Side]({{ site.url }}/assets/img/hand_poses/pose_grip1_side.png) | ![Grip 1 Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip1_perspective.png) |
| Grip 2       | ![Grip 2 Top]({{ site.url }}/assets/img/hand_poses/pose_grip2_top.png) | ![Grip 2 Side]({{ site.url }}/assets/img/hand_poses/pose_grip2_side.png) | ![Grip 2 Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip2_perspective.png) |
| Grip 3       | ![Grip 3 Top]({{ site.url }}/assets/img/hand_poses/pose_grip3_top.png) | ![Grip 3 Side]({{ site.url }}/assets/img/hand_poses/pose_grip3_side.png) | ![Grip 3 Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip3_perspective.png) |
| Grip 4       | ![Grip 4 Top]({{ site.url }}/assets/img/hand_poses/pose_grip4_top.png) | ![Grip 4 Side]({{ site.url }}/assets/img/hand_poses/pose_grip4_side.png) | ![Grip 4 Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip4_perspective.png) |
| Grip 5       | ![Grip 5 Top]({{ site.url }}/assets/img/hand_poses/pose_grip5_top.png) | ![Grip 5 Side]({{ site.url }}/assets/img/hand_poses/pose_grip5_side.png) | ![Grip 5 Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip5_perspective.png) |
| Grip Shaft   | ![Grip Shaft Top]({{ site.url }}/assets/img/hand_poses/pose_gripshaft_top.png) | ![Grip Shaft Side]({{ site.url }}/assets/img/hand_poses/pose_gripshaft_side.png) | ![Grip Shaft Perspective]({{ site.url }}/assets/img/hand_poses/pose_gripshaft_perspective.png) |
| Grip         | ![Grip Top]({{ site.url }}/assets/img/hand_poses/pose_grip_top.png) | ![Grip Side]({{ site.url }}/assets/img/hand_poses/pose_grip_side.png) | ![Grip Perspective]({{ site.url }}/assets/img/hand_poses/pose_grip_perspective.png) |
| Hold         | ![Hold Top]({{ site.url }}/assets/img/hand_poses/pose_hold_top.png) | ![Hold Side]({{ site.url }}/assets/img/hand_poses/pose_hold_side.png) | ![Hold Perspective]({{ site.url }}/assets/img/hand_poses/pose_hold_perspective.png) |
| Horns        | ![Horns Top]({{ site.url }}/assets/img/hand_poses/pose_horns_top.png) | ![Horns Side]({{ site.url }}/assets/img/hand_poses/pose_horns_side.png) | ![Horns Perspective]({{ site.url }}/assets/img/hand_poses/pose_horns_perspective.png) |
| Metal        | ![Metal Top]({{ site.url }}/assets/img/hand_poses/pose_metal_top.png) | ![Metal Side]({{ site.url }}/assets/img/hand_poses/pose_metal_side.png) | ![Metal Perspective]({{ site.url }}/assets/img/hand_poses/pose_metal_perspective.png) |
| Middle       | ![Middle Top]({{ site.url }}/assets/img/hand_poses/pose_middle_top.png) | ![Middle Side]({{ site.url }}/assets/img/hand_poses/pose_middle_side.png) | ![Middle Perspective]({{ site.url }}/assets/img/hand_poses/pose_middle_perspective.png) |
| OK           | ![OK Top]({{ site.url }}/assets/img/hand_poses/pose_ok_top.png) | ![OK Side]({{ site.url }}/assets/img/hand_poses/pose_ok_side.png) | ![OK Perspective]({{ site.url }}/assets/img/hand_poses/pose_ok_perspective.png) |
| Peace        | ![Peace Top]({{ site.url }}/assets/img/hand_poses/pose_peace_top.png) | ![Peace Side]({{ site.url }}/assets/img/hand_poses/pose_peace_side.png) | ![Peace Perspective]({{ site.url }}/assets/img/hand_poses/pose_peace_perspective.png) |
| Pinch Flat   | ![Pinch Flat Top]({{ site.url }}/assets/img/hand_poses/pose_pinchflat_top.png) | ![Pinch Flat Side]({{ site.url }}/assets/img/hand_poses/pose_pinchflat_side.png) | ![Pinch Flat Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchflat_perspective.png) |
| Pinch Large  | ![Pinch Large Top]({{ site.url }}/assets/img/hand_poses/pose_pinchlarge_top.png) | ![Pinch Large Side]({{ site.url }}/assets/img/hand_poses/pose_pinchlarge_side.png) | ![Pinch Large Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchlarge_perspective.png) |
| Pinch Middle | ![Pinch Middle Top]({{ site.url }}/assets/img/hand_poses/pose_pinchmiddle_top.png) | ![Pinch Middle Side]({{ site.url }}/assets/img/hand_poses/pose_pinchmiddle_side.png) | ![Pinch Middle Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchmiddle_perspective.png) |
| Pinch Ring   | ![Pinch Ring Top]({{ site.url }}/assets/img/hand_poses/pose_pinchring_top.png) | ![Pinch Ring Side]({{ site.url }}/assets/img/hand_poses/pose_pinchring_side.png) | ![Pinch Ring Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchring_perspective.png) |
| Pinch Tight  | ![Pinch Tight Top]({{ site.url }}/assets/img/hand_poses/pose_pinchtight_top.png) | ![Pinch Tight Side]({{ site.url }}/assets/img/hand_poses/pose_pinchtight_side.png) | ![Pinch Tight Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchtight_perspective.png) |
| Pinch Up     | ![Pinch Up Top]({{ site.url }}/assets/img/hand_poses/pose_pinchup_top.png) | ![Pinch Up Side]({{ site.url }}/assets/img/hand_poses/pose_pinchup_side.png) | ![Pinch Up Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinchup_perspective.png) |
| Ping Pong    | ![Ping Pong Top]({{ site.url }}/assets/img/hand_poses/pose_pingpong_top.png) | ![Ping Pong Side]({{ site.url }}/assets/img/hand_poses/pose_pingpong_side.png) | ![Ping Pong Perspective]({{ site.url }}/assets/img/hand_poses/pose_pingpong_perspective.png) |
| Pinky        | ![Pinky Top]({{ site.url }}/assets/img/hand_poses/pose_pinky_top.png) | ![Pinky Side]({{ site.url }}/assets/img/hand_poses/pose_pinky_side.png) | ![Pinky Perspective]({{ site.url }}/assets/img/hand_poses/pose_pinky_perspective.png) |
| Pistol       | ![Pistol Top]({{ site.url }}/assets/img/hand_poses/pose_pistol_top.png) | ![Pistol Side]({{ site.url }}/assets/img/hand_poses/pose_pistol_side.png) | ![Pistol Perspective]({{ site.url }}/assets/img/hand_poses/pose_pistol_perspective.png) |
| Ring         | ![Ring Top]({{ site.url }}/assets/img/hand_poses/pose_ring_top.png) | ![Ring Side]({{ site.url }}/assets/img/hand_poses/pose_ring_side.png) | ![Ring Perspective]({{ site.url }}/assets/img/hand_poses/pose_ring_perspective.png) |
| Rounded      | ![Rounded Top]({{ site.url }}/assets/img/hand_poses/pose_rounded_top.png) | ![Rounded Side]({{ site.url }}/assets/img/hand_poses/pose_rounded_side.png) | ![Rounded Perspective]({{ site.url }}/assets/img/hand_poses/pose_rounded_perspective.png) |
| Sign 1       | ![Sign 1 Top]({{ site.url }}/assets/img/hand_poses/pose_sign1_top.png) | ![Sign 1 Side]({{ site.url }}/assets/img/hand_poses/pose_sign1_side.png) | ![Sign 1 Perspective]({{ site.url }}/assets/img/hand_poses/pose_sign1_perspective.png) |
| Sign 2       | ![Sign 2 Top]({{ site.url }}/assets/img/hand_poses/pose_sign2_top.png) | ![Sign 2 Side]({{ site.url }}/assets/img/hand_poses/pose_sign2_side.png) | ![Sign 2 Perspective]({{ site.url }}/assets/img/hand_poses/pose_sign2_perspective.png) |
| Sign 3       | ![Sign 3 Top]({{ site.url }}/assets/img/hand_poses/pose_sign3_top.png) | ![Sign 3 Side]({{ site.url }}/assets/img/hand_poses/pose_sign3_side.png) | ![Sign 3 Perspective]({{ site.url }}/assets/img/hand_poses/pose_sign3_perspective.png) |
| Sign 4       | ![Sign 4 Top]({{ site.url }}/assets/img/hand_poses/pose_sign4_top.png) | ![Sign 4 Side]({{ site.url }}/assets/img/hand_poses/pose_sign4_side.png) | ![Sign 4 Perspective]({{ site.url }}/assets/img/hand_poses/pose_sign4_perspective.png) |
| Sign 5       | ![Sign 5 Top]({{ site.url }}/assets/img/hand_poses/pose_sign5_top.png) | ![Sign 5 Side]({{ site.url }}/assets/img/hand_poses/pose_sign5_side.png) | ![Sign 5 Perspective]({{ site.url }}/assets/img/hand_poses/pose_sign5_perspective.png) |
| Sign Point   | ![Sign Point Top]({{ site.url }}/assets/img/hand_poses/pose_signpoint_top.png) | ![Sign Point Side]({{ site.url }}/assets/img/hand_poses/pose_signpoint_side.png) | ![Sign Point Perspective]({{ site.url }}/assets/img/hand_poses/pose_signpoint_perspective.png) |
| Straight     | ![Straight Top]({{ site.url }}/assets/img/hand_poses/pose_straight_top.png) | ![Straight Side]({{ site.url }}/assets/img/hand_poses/pose_straight_side.png) | ![Straight Perspective]({{ site.url }}/assets/img/hand_poses/pose_straight_perspective.png) |
| Surfer       | ![Surfer Top]({{ site.url }}/assets/img/hand_poses/pose_surfer_top.png) | ![Surfer Side]({{ site.url }}/assets/img/hand_poses/pose_surfer_side.png) | ![Surfer Perspective]({{ site.url }}/assets/img/hand_poses/pose_surfer_perspective.png) |
| Thumb        | ![Thumb Top]({{ site.url }}/assets/img/hand_poses/pose_thumb_top.png) | ![Thumb Side]({{ site.url }}/assets/img/hand_poses/pose_thumb_side.png) | ![Thumb Perspective]({{ site.url }}/assets/img/hand_poses/pose_thumb_perspective.png) |
