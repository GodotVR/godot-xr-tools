---
title: Climbing
permalink: /docs/climbing/
---


## Introduction
Climbing in games has been a staple for decades, with modern games like uncharted
or tomb raider having the player scaling mountains making death defying jumps
trying to reach treasure.

None of those however compare to the experience of climbing in VR. It is so good
that some of the best selling VR games such as The Climb use it is their primary
mechanic. Danging hundreds of meters above the ground hanging off a cliff face is
as close as you can get in gaming to the real thing. The sense of vertigo real
enough to give the player a real fear of letting go, yet without the tiring of
arms and the risk of actual injury.

The climbing mechanic in VR is also one of the few where moving the player through
the world, while the player in reality is standing still in their room waving their
arms around, tricks the brain enough to fight off motion sickness.

The climbing system in XR tools is very versatile but as it combines a few objects
together does take a bit more setup then some of the other movement functions. It
can also be combined with the other movement functions so you can use direct movement
to walk up to a wall, and then use the climbing function to scale the wall.

## Setup
As mentioned setting up the climbing system requires a few more steps.

First, the climbing function uses our [pickup function]({{ site.url }}/docs/pickable/) from the Pickup and throw 
system. You thus need to add the Pickup functions to both hands.

Next you need to add the Climb movement function as a child to the XROrigin3D node,
note that as with other movement functions this will add a PlayerBody node to your
XROrigin3D node if it doesn't already exist.

Your setup should now look like this:
![ARVR Climb Movement]({{ site.url }}/assets/img/climbing/arvr_climb_movement.png)

Now that our player is able to climb, we need to define the things they can climb
on. This is accomplished by inheriting the `objects/climbable.tscn` scene, 
simply open the Scene menu, select New Inherited Scene... and select the 
climbable.tscn scene from the xr tools library. This scene sets up a static
body with a collision shape and a script that allows you to grab that static body. 
When the player grabs the static body moving your hand will cause the player to 
move instead of the hand.

You can create small objects to create climbing anchors that the player must grab
and create an experience where the player needs to be very precise, or you can just
create one big collision shape the player can climb on without caring much where
the player holds the shape.

We're taking the later as an example, the screenshot below sets up a scene, I've
renamed the root node, added a MeshInstance with a box, and then added a collision
shape to the CollisionShape node giving it the same size as the block:
![ARVR Climbing Block]({{ site.url }}/assets/img/climbing/arvr_climbing_block.png)

Now save the scene and add it to your main scene and your player can climb the block.

> See [Climbable]({{ site.url }}/docs/climbable/) objects for more details.


## Configuration

### XRToolsMovementClimb

| Property      | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| Enabled       | When ticked this node will controll the players movement.       |
| Order         | The order in which this movement is processed in case multiple movement functions are active.  |
| Forward Push  | When the player lets go they are pushed away from the object they were holding by this force  |
| Fling Multiplier  | If the player lets go their current momentum is multiplied by this amount allowing the player to "fling" themselves off a wall.  |
| Velocity Averages  | The number of velocity samples to take to determine the players velocity when they let go.  |


## Additional Resources

The following videos show the creation of a basic XR Player with movement including climbing:
* [Getting Started](https://youtu.be/VrpySdMcdyw)
* [Advanced Movement](https://youtu.be/tTdaU57M-0s)
