---
title: Vignette
permalink: /docs/vignette/
---

One of the great things about VR is the sense of immersion while you look and walk around a virtual world. Accurate tracking of your heads position allows for your physical movements through a space to be completely mirrored to your movements in the virtual space. This is key to your brain accepting the virtual world as real.

But even for those VR enthousiasts who are lucky enough to be able to dedicate a large space in their room to freely roam around in, you quickly run into boundaries in movement. This likely contributed to the success of games such as Beat Saber and Space Pirate Trainer where the player can stay within these boundaries.

In order to move around a larger world we need to implement movement systems that move the player that are not based on the physical movement of the player. Features such as our Direct movement and Teleport functions.

However when the player moves through the virtual world while being stationary in the real world, we do not only risk breaking immersion, we run the risk of inducing motion sickness within the player as physical sensations no longer match up with what is happening in the virtual world. There are many techniques that combat this, which techniques are most effective vary from person to person.

The vignette is one such technique which works by blocking out the players peripheral vision when they move without moving.
![Vignette]({{ site.url }}/assets/img/player_body/vignette_view.png)

Our vignette implementation has both an automatic mode, where we track the players movement through space and react as best we can, and a manual mode where you as a developer can control how much is being blacked out based on how you are controlling the players character.

> Note on the automatic logic. When turned on, movement of the player will cause the vignette to close, the faster the movement, the more it closes. It then opens back up on an automatic fade out. You can limit the logic to react to just rotation or just velocity by setting the other option to 0.

## Setup

The vignette effect is implemented as an effects scene and can simply be added as a child of your XRCamera node:
![XR vignette]({{ site.url }}/assets/img/player_body/xr_vignette.png)

## Configuration

### XRToolsVignette

| Property               | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| Radius                 | Inner radius of the vignette, 0.0 is closed, 1.0 is fully open (not visible), note that this property is controlled by the attached script if auto adjust is ticked.  |
| Fade                   | Size of the fade ring at the inner edge of the vignette.  |
| Steps                  | Controlls the number of sections the vignette is broken up in, the higher, the smoother the inner ring.  |
| Auto Adjust            | If ticked the script controls the radius depending on user movement.  |
| Auto Inner Radius      | The smallest size of the inner radius when the user moves.  |
| Auto Fade Out Factor   | Duration in seconds that the vignette fades back to fully open from fully closed.  |
| Auto Fade Delay        | The delay in seconds before the vignette opens back up.  |
| Auto Rotation Limit    | The limit of rotation in degrees per second that causes the vignette to close fully. Any rotation rate below this amount will progressively close the vignette. Setting this to 0 turns this feature off.  |
| Auto Velocity Limit    | The limit of velocity in meters per second that causes the vignette to close fully. Any velocity below this amount will progressively close the vignette. Setting this to 0 turns this feature off.  |
