# Finger tracking Demo

This scene shows the use of the xr_interface.get_hand_joint_position()
functions and others which give direct access to the OpenXR module, and 
can be used to map to the fingers of a different mesh/skeleton.

An extremely simple locomotion is implemented by snapping the fingers of 
the left hand to apply an impulse to the CharacterBody.
