# ppmod
VScript library for developing Portal 2 mods quickly.

The focus of this project is to provide tools that assist in developing Portal 2 VScript mods under tight time constraints. The goal is not to replace existing tools and SDKs, but rather to make prototyping complicated VScript projects much more comfortable by including lots of common functions for interacting with the world, player and engine.

## Installation

To use ppmod in your project, include the script file before calling any ppmod functions:
```
  IncludeScript("ppmod3.nut");
```
Make sure to do this in an environment that has access to `CEntities`; otherwise, most game-related functions will not work.
You can do this at the start of your script by checking if the instance `Entities` exists within `this`:
```squirrel
  if(!("Entities") in this) return; //halts the script if it can't be found
  IncludeScript("ppmod3.nut");
  ...
```

## Functions
### ppmod.fire

More convenient alternative to `EntFire`, `DoEntFire` or `EntFireByHandle`. Most arguments are optional, containing default values similar to the ent_fire console command. This makes entity inputs much shorter and cleaner in code.


```
  ppmod.fire (entity, action = "Use", value = "", delay = 0, activator = null, caller = null)
```

The first argument is the entity to send an input to. This can be either an entity handle or a string. Next is the action, "Use" by default. Then the value, empty by default, the delay in seconds, 0 by default, and finally, entity handles for the activator and caller, both null by default. Please note that the caller is only set if the entity is provided as a handle.

### ppmod.addoutput

More versatile alternative to `ConnectOutput` or `EntFire AddOutput`. Other than the entity, its output and the target entity, every other argument is optional, with a common default placeholder value.

```
  ppmod.addoutput (entity, output, target, input = "Use", value = "", delay = 0, max = -1)
```

Since this function uses ppmod.keyval internally, the entity can be specified with a string or handle. Similarly, the target entity can also be a string or handle. However, when provided a handle, its targetname is used instead. If no targetname is set, one gets randomly generated and applied to the entity. The output is read as a string. The following arguments match their counterparts in `ppmod.fire`, with the exception being max, which sets the total amount of times this output will fire before being exhausted. Setting it to -1 (default) removes this limit.

### ppmod.addscript

Similar to `ppmod.addoutput`, used as a cleaner and more powerful way of attaching VScript code to entity outputs.

```
  ppmod.addscript (entity, output, script, delay = 0, max = -1, del = false)
```

The arguments are almost the same as the ones in `ppmod.addoutput`, except instead of specifying a target entity and input values, a script is required instead. This can be code within either a string or a function. An additional boolean argument is supported. If set to true and the script is provided as a function, this will delete the attached function after the output has fired. Below is an example of attaching a local function to an entity output:

```squirrel
  ppmod.addscript("prop_button", "OnPressed", function() {
    printl("Button pressed!");
  });
```

### ppmod.keyval

Shorter, more convenient alternative to `__KeyValueFrom...` functions. Automatically selects the appropriate function for the specified entity and keyvalue type. Guaranteed to run synchronously regardless of the input.

```
  ppmod.keyval (entity, key, value)
```

The entity can be provided as a handle or string. The key is expected to be a string, while the value may be an integer, boolean, float, string or Vector.

### ppmod.wait

Simple way of delaying the execution of a function. Creates a dummy `logic_relay` entity with an attached script. The timing is achieved by using a delayed EntFire.

```
  ppmod.wait (script, delay, name = null)
```

The first argument is the script to run, either as a string or function. The second argument is the delay in seconds. The third argument sets the targetname for the `logic_relay` entity. Returns a handle to the `logic_relay` entity in case the timer needs to be aborted by destroying this entity. After the script is executed, the `logic_relay` is automatically destroyed.

### ppmod.interval

Runs the specified script at regular intervals. Creates a `logic_timer` entity and configures it to run the script at an interval.

```
  ppmod.interval (script, delay = 0, name = null)
```

The first argument is the script to run, either as a string or function. The second argument is the interval of the loop in seconds. When set to 0 (default), the function is called once every tick. The third argument sets the targetname for the `logic_timer` entity. Returns a handle to the `logic_timer` entity, which can then be used to stop or modify the loop.

### ppmod.once

Ensures that the specified script is run only once, even if this function is called multiple times. Creates a dummy `logic_relay` entity and uses its targetname as a reference for duplicates. Or, if no name is provided, uses the script itself as a name.

```
  ppmod.once (script, name = null)
```

The first argument is the script to run, either as a string or function. The second argument is the targetname of the `logic_relay` entity. If no name is provided and the script is in the form of a string, the entire script gets used as a name. If the script provided is a function, it uses a pointer to the function as a name.

### ppmod.get

More convenient way of getting entity handles, replacing `CEntities` methods like `FindByName` or `FindByClassnameNearest`, instead automatically searching using multiple of these methods back to back. Also provides a way to get entities by their entity ID.

```
  ppmod.get (key, entity = null, argument = 1)
```

The first argument accepts a string, Vector, integer or instance. Different searches are performed depending on the type of key provided:
- If a string is provided, the function first searches for an entity with a matching targetname, then a matching classname, and finally a matching model. This is probably the most common type of search.
- If a vector is provided and the second argument is a string, the function attempts to find an entity with a matching classname around the vector's coordinates within the radius set by the third argument.
- If a vector is provided and the second argument isn't a string, the function returns an entity near the given vector in a radius set by the third argument.
- If an integer is provided, the function iterates through all entities, searching for an entity with an ID that matches the integer.
- If an instance is provided, the next entity in the list of entities is returned, similar to `Entities.Next`.

Please note that, if used excessively, this function may impact performance more than the native `CEntities` methods.

### ppmod.prev

Reverses iteration over a list of entities, finding the previous entity to match the given criteria. Similar to `ppmod.get`, but in reverse.

```
  ppmod.prev (key, entity = null, argument = 1)
```

The arguments and types of searches are nearly identical to ppmod.get, with the only exception being no support for a radius search by classname. Reversed iteration is performed by iterating forwards, then returning the last entity to not match the second argument. Because of the complexity and performance impact, this is not an efficient way of iterating backwards in most cases. Rather, iterate through your search once and use a table to then traverse backwards in. This function can, however, be used for conveniently finding the last matching element of a search if the second argument is set to null.

### ppmod.player

Provides more information about the player, as well as new ways of listening to the player's actions. Things like eye angles and jump, land, duck and unduck outputs are included.

```
  ppmod.player {
    enable   (function)
    eyes
    eyes_vec ()
    holding  (function)
    jump     (script)
    land     (script)
    duck     (script)
    unduck   (script)
    input    (string, script)
  }
```

#### ppmod.player.enable

Calling this function creates the entities required for most other `ppmod.player` functions to work. Please note that, in most cases, this is performed asynchronously. Therefore a callback function may be provided as the only argument. Be aware that calling this function more than once per map may cause unexpected behavior.

#### ppmod.player.eyes

Entity handle for a `logic_measure_movement` entity set to track the player's eyes. Using methods like `GetAngles` or `GetOrigin` lets you retrieve the player's eye angles and position.

```squirrel
  ppmod.player.enable(function() {

    printl( ppmod.player.eyes.GetAngles() );
    printl( ppmod.player.eyes.GetOrigin() );

  });
```

However, for getting the position, it is suggested to use the native `CBaseEntity` method `EyePosition()` instead, as the position of `ppmod.eyes` might not always be accurate.

#### ppmod.player.eyes_vec

Returns a unit vector pointing in the direction that the player is looking in. Accepts no arguments.

```squirrel
  ppmod.player.enable(function() {
    printl( ppmod.player.eyes_vec() );
  });
```

When combined with `ppmod.ray`, for example, this vector can be used for things like simulating weapon hitscan:

```squirrel
  ppmod.player.enable(function() {

    local dist = 2048;
    local start = ppmod.player.eyes.GetOrigin();
    local vec = ppmod.player.eyes_vec() * dist;
    local end = start + vec;

    local pfrac = ppmod.ray(start, end, "player", false);
    if (pfrac == 1.0) return;
    local wfrac = ppmod.ray(start, end);
    if (pfrac < wfrac) {
      printl( "Hit player at: " + (start + vec * frac) );
    }

  });
```

#### ppmod.player.holding

Calls the provided callback function with a boolean argument indicating whether or not the player is holding a prop. Does not require running `ppmod.player.enable`.

```squirrel
  ppmod.player.holding(function(state){
    if (state) printl( "Player is holding a prop!" );
    else printl( "Player is not holding a prop!" );
  }
```

#### ppmod.player.[jump, land, duck, unduck]

Set of functions for adding scripts to player movement actions. Accepts one argument - the script to attach, either a string or function.
- `ppmod.player.jump` triggers when the player performs the jump input. This is true even when the player is already in the air or crouching.
- `ppmod.player.land` triggers when the player changes the surface they're standing on. This will trigger when landing from previously being in the air, or when walking from, for example, a concrete surface to a metal one.
- `ppmod.player.duck` triggers when the player begins crouching. This will not fire if the player is unable to crouch, for example, when in the air following a jump.
- `ppmod.player.unduck` triggers when the player begins to uncrouch. This will fire regardless of how crouched the player was before beginning to stand up.

#### ppmod.player.input

Function for adding scripts to player inputs as returned by the `game_ui` entity. The first argument is the input to listen for, as seen in the developer console (e.g., "+forward"). The second argument is the script to attach to this input.

```squirrel
  ppmod.player.enable(function() {

    ppmod.player.input("+attack", "printl(\"Started shooting\")");
    ppmod.player.input("-attack", "printl(\"Stopped shooting\")");

  });
```

#### ppmod.player.movesim

Function for simulating player movement and physics, allowing for more control over gravity, friction, movement direction and speed.

```
  ppmod.player.movesim (move, frametime = null, acceleration = 10, friction = 0, ground = Vector(0, 0, -1), gravity = Vector(0, 0, -600), eyes = null)
```

##### Arguments

The first argument is a two-dimensional Vector, where the X and Y components are the [forward and sideways movement speeds](https://www.jwchong.com/hl/player.html#fsu), respectively. The second argument is the frame time (or tick rate) that the function will assume for calculations. Leaving this at `null` will use the output of `FrameTime()`. The third argument is the simulated value of `sv_accelerate`, 10 by default. The fourth argument is the simulated value of `sv_friction`, 0 by default. The fifth argument is a unit Vector pointing to the floor. This determines the plane that player movement will be relative to. The sixth argument is the gravity Vector, which controls the direction and intensity of the player's gravity. The seventh argument is a handle for the entity whose angles will be used to determine where the player is looking. Leaving this at `null` will use `ppmod.player.eyes`.

##### Usage

This function is intended to be used for every frame in which player movement is to be simulated. To achieve constant simulation, `ppmod.interval` can be used. The function's `frametime` argument is the interval at which the function is repeated. For best results, repeating the function every `FrameTime()` seconds is recommended.

In Portal 2, the length of the movement Vector `move` is a constant 175 units by default, which is the default value of `cl_forwardspeed` and `cl_sidespeed`. A positive X component will move the player forward, and a positive Y component will move the player to the right. Negative components will move the player in the opposite direction.

The `acceleration` variable is the total amount of movement acceleration for any simulated frame where the player is moving. While on the ground, the default value of `sv_accelerate` can be used, which is 10. However, while in the air, Portal 2 applies a surface friction coefficient of 0.25 by default, leading to less air acceleration. To mimic this behavior, use an `acceleration` value of 2.5 while the player is above ground.

Similarly to acceleration, the `friction` variable is the total amount of friction applied to the player during any one simulated frame, not accounting for relative vertical velocity or collision with the floor. This is left at 0 by default due to currently not being able to override the existing friction.

The `ground` Vector determines the plane along which player movement will be simulated. By default, this is a unit vector pointing towards negative Z. Changing the direction of this vector can allow for simulating walking on walls or the ceiling, for example. Changing the length of this vector could lead to the vertical velocity or player pitch angle being improperly filtered out.

The purpose of the `gravity` Vector is similar to that of `sv_gravity`, with the key difference being that the direction can be changed. By default, this vector is pointing towards negative Z at a length of 600, which means that the player velocity will increase by `600 / frametime` towards negative Z for every simulated frame.

The `eyes` argument is used for getting the forward and left Vector that the player's movement is relative to. This can be any variable with a `GetForwardVector` and `GetLeftVector` method. However, `ppmod.player.eyes` can be used to replicate default behavior.

##### Example

Here is an example of using `ppmod.player.movesim` to simulate the player moving forward indefinitely:

```squirrel
  ppmod.player.enable(function() {
    ppmod.interval(function(){
      ppmod.player.movesim(Vector(175, 0));
    });
  });
```

### ppmod.create

Creates an entity using console commands and retrieves its handle. Some entities cannot be fully created with `Entities.CreateByClassname` alone, as this often leaves some crucial entity code unloaded. This function can also be used for preloading models through the `prop_dynamic_create` console command.

```
  ppmod.create (command, function, key = null)
```

The first argument is the command to run for creating the entity. This argument also accepts a model assuming the `models/` directory, in which case it is automatically prefaced by `prop_dynamic_create`. If an entity classname is provided, it is prefaced by `ent_create`. Portal-specific commands like `ent_create_portal_weighted_cube` are also supported.

The second argument is the function to run after the entity has been created and found. This function is provided with one argument - the handle of the created entity. The function can be provided as a string or as a local or global function. Keep in mind that instead of being referenced directly, this function is cloned and stored in a table so that it can be called by a console command.

The third argument is the key by which the entity is searched. This can be left unchanged in most cases, as the key will be generated automatically based on the command. Internally, this uses the `ppmod.prev` function to search for the last (therefore newest) entity with a matching key. Because of this, it is suggested to use as descriptive of a key as possible in order to avoid accidentally finding a different entity that was created at the same time on a different thread. For example, instead of using `prop_weighted_cube` as the command, use `ent_create_portal_weighted_cube` instead, as this gives the entity a distinct "cube" targetname.

Here is an example of using `ppmod.create` to spawn a red cube at the player's feet:

```squirrel
  ppmod.create("ent_create_portal_weighted_cube", function(cube) {

    cube.SetOrigin( GetPlayer().GetOrigin() );
    cube.SetAngles( 0, 0, 0 );

    ppmod.fire(cube, "Color", "255 0 0");

  });
```

### ppmod.brush

Creates a brush entity of the specified type and returns a handle to it.

```
  ppmod.brush (position, size, type = "func_brush", angles = Vector())
```

The first argument is a vector to the center of the brush entity. The second argument is a vector containing the half-width of the brush on each respective axis. The third argument is the classname for the brush entity, "func_brush" by default. The last argument is a vector of the entity's angles - pitch, yaw and roll, respectively. Textures cannot be set, so the brush will remain invisible. Due to the limitations of creating entities with `CEntities` methods, some brush entity types might not function properly. To work around this, you can try using `ppmod.create` for creating the entity, then handling it with a code snippet from the `ppmod.brush` function:

```squirrel
  ppmod.create("func_movelinear", function(brush) {

    brush.SetOrigin( Vector(0, 0, 0) );
    brush.SetSize( Vector(-10, -10, -10), Vector(10, 10, 10) );

    ppmod.keyval(brush, "Solid", 3);

  });
```

### ppmod.trigger

Creates a brush entity that acts as a trigger of the specified type and returns a handle to it.

```
  ppmod.trigger (position, size, type = "once", angles = Vector())
```

The arguments are nearly identical to those of `ppmod.brush`, with the only exception being type. This argument is automatically prefaced with "trigger_" and specifies the type of brush entity to create. If the type is set to "once" (default), the trigger is automatically given an output to destroy itself when touched.

To add outputs to this trigger, you can store the handle returned by the function to then use `ppmod.addoutput` or `ppmod.addscript` on it. Here is an example of using `ppmod.trigger` to create a field that makes you say "Hello World!" in chat:

```squirrel
  local trigger = ppmod.trigger(Vector(0, 0, 0), Vector(128, 128, 128), "multiple");

  ppmod.addscript(trigger, "OnStartTouch", function() {
    SendToConsole("say Hello World!");
  });
```

### ppmod.texture

Creates an `env_projectedtexture` entity for projecting textures onto existing brushes and entities. Returns this entity.

```
  ppmod.texture (texture = "", position = Vector(), angles = Vector(90), simple = true, farz = 16)
```

The first argument is the path to the texture to apply. The second argument is the position of the `env_projectedtexture` entity. If using the simple projection mode, it is recommended to set this to be a few units away from the brush you're applying the texture to. The third argument is the angle to project the texture towards, facing straight down by default. The fourth argument is a boolean value for whether to use the simple projection mode. Simple projections only project textures on the world, aligning themselves with the shape and orientation of the brush. Keep in mind that this often causes graphical glitches like flickering, especially with high shader detail. If a projection is not simple, it will work similarly to a flashlight, projecting and distorting the texture as if it were from a light source. The last argument is the FarZ keyvalue of the entity. This sets the furthest point that the projection can reach.

Every argument is optional. This is in case you need to create an `env_projectedtexture` for later use. Keep in mind that while Portal 2 claims to only support one projected texture at a time, a workaround exists. Since the game only checks for existing projected textures when one receives a `TurnOn` or `TurnOff` input, multiple can be active as long as they never receive such an input. One way to do this is by creating a new entity every time you wish to turn on the texture, then deleting it to turn it off.

Here is an example of using `ppmod.texture` to project a laser grid on the floor at the end of `sp_a1_intro3` using the simple projection mode:

```
  ppmod.texture("effects/laserplane", Vector(-1378, 3264, -310));
```

### ppmod.decal

Creates an `infodecal` entity for applying decals and textures onto the world, similar to the simple projection mode of `ppmod.texture`. Returns the decal entity.

```
  ppmod.decal (texture, position, angles = Vector(90))
```

The arguments are similar to those of `ppmod.texture`, except that texture and position are no longer optional. The benefits of using decals instead of simple projected textures are that decals cause fewer graphical glitches and stutters (as long as cvar `gpu_level` is under 2), and you can control the position of decals better. The main drawbacks are that decals cannot be moved, removed, or resized.

### ppmod.text

Creates a `game_text` entity for basic on-screen text and UI and provides functions for managing this entity.

```
  ppmod.text (text = "", x = -1, y = -1)
```

The first argument is the text to display. The second and third arguments set the X and Y position of the text, respectively. Setting these to -1 centers the text. Returns a table of functions for managing the entity:

- `GetEntity ()` returns a handle to the `game_text` entity.
- `SetPosition (x, y)` sets the position at which the text should appear. -1 centers the text.
- `SetText (string)` sets the string of text to display. Supports localized strings and the `\n` newline character.
- `SetChannel (channel)` sets the text channel. An integer from 0 to 5. This controls the text size and replaces existing text on the same channel.
- `SetColor (color1, color2 = null)` sets the foreground and background text colors, respectively.
- `SetFade (fadein, fadeout, scan = false)` sets the time it takes for the text to appear or disappear in seconds, respectively. If the third argument is `true`, the text will appear letter by letter instead of fading in.
- `Display (hold = null, player = null)` displays the text. The first argument is the time it should stay on-screen after fading in, in seconds. Setting this to `null` uses the output of `FrameTime()`. The second argument specifies a player to display the text for. Setting this to `null` displays it to everyone.

These functions set keyvalues or fire inputs to the entity. Here is an example of displaying the text "Hello World" centered and with the scan-in effect:

```squirrel
  local txt = ppmod.text("Hello World!");

  txt.SetColor("40 170 215", "255 154 0");
  txt.SetFade(0.1, 2, true);
  txt.Display(3);

```

### ppmod.ray

Given two points of a ray and one or more entities, returns a fraction along the ray that collides with the axis-aligned bounding boxes of the given entities and, optionally, world brushes and static models.

```
  ppmod.ray (start, end, entities = null, world = true)
```

The first two arguments are Vectors containing the start and end points of the ray, respectively. The third argument denotes the entities whose bounding boxes will be checked for collisions. This can be either an entity handle, a string (as used with `ppmod.get`) or an array of either. If an entity is not given, or the value is `null`, collision with entity bounding boxes will not be checked. The fourth argument is a boolean value. If set to true as it is by default, world brushes and static models will also be checked for collisions.

The returned value is a float, representing a fraction of the ray between the starting point and the collision nearest to it. If the ray does not collide with anything, the function will return `1.0`. If the starting point of the ray is inside one of the solids, the function will return `0`. Getting the point of intersection can be done by adding the starting point to the multiplication between the unit vector of the ray's direction, the total ray length and the returned fraction. In code, this might be:

```squirrel
  local frac = ppmod.ray(start, end, ...);
  local dir = end - start;
  local len = dir.Norm();
  local point = start + dir * len * frac;
```

Optimization note: The function accepts a fifth argument. This is an array of two elements - the length of the ray and an array representing a vector where each value is 1 divided by the respective coordinate of the normalized ray vector or, in other words, its direction. These values can be precalculated and used if a collision with the same ray is being checked multiple times. This optimization is used internally and therefore is not necessary if the function is only called once.

Here is an example of using `ppmod.player` and `ppmod.ray` to detect if the player is looking at a cube:

```squirrel
  ppmod.player.enable(function() {

    local start = ppmod.player.eyes.GetOrigin();
    local vec = ppmod.player.eyes_vec() * 8196;
    local end = start + vec;

    ppmod.interval(function(start = start, end = end) {

      local frac = ppmod.ray(start, end, "prop_weighted_cube", false);
      if(frac < 1) printl("Player is looking at a cube!");

    });

  });
```

### ppmod.replace

Replaces all occurences of a sub-string with a new string.

```
  ppmod.replace (string, substring, replacement)
```

The `string` argument must be provided, and the function returns a new string.
Example:

```squirrel
  printl(ppmod.replace("hello world", " world", ""));
  // prints "hello"
```

If no `replacement` or `substring` arguments are provided, the function will return the given `string`

This function should only be used for strings that you don't know the exact value of at runtime, otherwise you should use native string functions like `string.find` and `string.slice`.

Squirrel also implements regular expressions which are used for pattern matching and string manipulation. Regular expressions allow you to define search patterns using a combination of characters.
The documentation for regexp can be found [here.](http://squirrel-lang.org/squirreldoc/stdlib/stdstringlib.html#regexp)

### ppmod.split

Divides a string into an array of substrings based on a specified delimiter.

```
  ppmod.split (string, delimiter)
```

The `string` argument must be provided, and the function returns an array of strings.
Example:

```squirrel
  foreach (value in ppmod.split("hello world", " ")) {
    printl(value);
  }
  // prints "hello" and "world" separately
```

If no `delimiter` argument is provided, the function will return an array containing the given `string` argument.

Again, this function should only be used for strings that you don't know the exact value of at runtime, otherwise you should use native string functions like `string.find` and `string.slice`.