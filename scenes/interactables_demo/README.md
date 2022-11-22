# Interactables Demo

This scene demonstrates interactable object using a 
[pickup function](https://godotvr.github.io/godot-xr-tools/docs/pickup/) on
each hand.

The pickup functions work with the different type of interactable objects, 
including:
 - Joystick (using XRToolsInteractableJoystick)
 - Slider (using XRToolsInteractableSlider)
 - Lever (using XRToolsInteractableHinge)
 - Wheel (using XRToolsInteractableHinge)
 - Button (using XRToolsInteractableAreaButton)

Additionally some hand-poses are set by:
 - Adding XRToolsFunctionPoseDetector instances as siblings of both hands
 - Adding XRToolsHandPoseArea to the appropriate areas
 - Setting XRToolsHandPoseSettings resources to the hand-pose areas
