# ppmod
VScript library for rapid prototyping of Portal 2 mods.

The focus of this project is to provide tools that assist in developing Portal 2 VScript mods faster and much more comfortably than through vanilla VScript. This involves employing various hacks and adding missing features or fixing broken ones through entities often specific to Portal 2. While ppmod strives to be performant, this does not come at the cost of ease of use.

## Installation
Since ppmod4, the environment is expected to be as clean as possible, without any instantiated entities or vectors. This can be achieved by placing the script file in `scripts/vscripts` and calling it at the very top of `mapspawn.nut`, after making sure that the current scope has server-side control:
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return; // Quit if the script is being loaded client-side
  IncludeScript("ppmod4"); // Include ppmod4 as early as possible
```
Including ppmod4 in an already populated environment will still work at the cost of additional vector metamethods and entity method abstractions. This will get logged to the console as a warning, but is technically harmless if these features are unused.

## Getting started
Setting up and working with an environment like this for the first time can be overwhelming, so here's some boilerplate to help you get started. This script will spawn a red cube in front of the player's head, and make it print to the console once it gets fizzled. This should provide a solid example that you can then play around with to get an idea of what it's like to work with ppmod.
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return;
  IncludeScript("ppmod4");

  // This function is called whenever a map is fully loaded
  // We wrap it in async() to make it more comfortable to use asynchronous functions inline
  ppmod.onauto(async(function () {

    // Provides us with additional player info, like eye position and angles
    yield ppmod.player(GetPlayer());
    local pplayer = ::syncnext;

    // Props cannot be created with the CreateByClassname method, so we use ppmod.create instead
    yield ppmod.create("prop_weighted_cube");
    local cube = ::syncnext;

    // Teleports the new cube to 64 units in front of the player's eyes
    local pos = pplayer.eyes.GetOrigin() + pplayer.eyes.GetForwardVector() * 64;
    cube.SetOrigin(pos);
    // Colors the cube red with the "Color" input
    ppmod.fire(cube, "Color", "255 0 0");
    // Connects a script function to the cube's "OnFizzled" output
    ppmod.addscript(cube, "OnFizzled", function () {
      printl("The red cube has been fizzled!");
    });

  }));
```

## Global utilities
These are essential utility functions, classes and methods that Portal 2's implementation of Squirrel and VScript should (arguably) have by default. This includes abstractions and shorthands of already existing features.

### min / max
Returns the smallest / largest of two values.
```squirrel
  min(0.5, 2) // Returns 0.5
  max(0.5, 2) // Returns 2 
```

### round
Rounds a number to the specified precision in digits after decimal point, 0 by default.
```squirrel
  round(1.2345) // Returns 1.0
  round(1.2345, 2) // Returns 1.23
  round(5.5) // Returns 6 
```

### Vector methods
#### Component-wise multiplication
```squirrel
  Vector(1, 2, 3) * Vector(2, 4, 8) // Returns Vector(2, 8, 24)
  Vector(1, 2, 3) * 2 // Still returns Vector(2, 4, 6)
```
#### Component-wise division
```squirrel
  Vector(1, 2, 3) / Vector(2, 4, 8) // Returns Vector(0.5, 0.5, 0.375)
  Vector(1, 2, 3) / 2 // Still returns Vector(0.5, 1, 1.5)
```
#### Equality check
```squirrel
  Vector(1, 2, 3).equals(Vector(1, 2, 3)) // Returns true
  Vector(1, 2, 3).equals(Vector(4, 5, 6)) // Returns false
```
#### More useful string output
```squirrel
  "The vector is: " + Vector(1, 2, 3) // Returns "The vector is: Vector(1, 2, 3)"
```
#### Fixed KV string output
```squirrel
  "The vector values are: " + Vector(1, 2, 3).ToKVString() // Returns "The vector values are: 1 2 3"
```

### Extended array class
The `pparray` class implements some additional array features not present in Portal 2's version of Squirrel. It can be initialized by either providing a size for a new array (and optionally a value to fill it with) or an existing array.
```squirrel
  local arr = pparray([1, 2, 3]);
```
#### More useful string output
```squirrel
  printl(arr) // Prints "[1, 2, 3]"
```
#### pparray.join
```squirrel
  arr.join(" - ") // Returns "1 - 2 - 3"
```
#### pparray.find
```squirrel
  arr.find(2) // Returns 1, which is the index of the first element with value 2.
```

### Extended string class
The `ppstring` class implements some additional string features not present in Portal 2's version of Squirrel. It can be initialized without arguments or by providing an existing string.
```squirrel
  local str = ppstring("Hello world!");
```
#### str.split
```squirrel
  str.split(" ") // Returns ["Hello", "world!"]
```
#### str.replace
```squirrel
  str.replace("l", "L") // Returns "HeLLo worLd!"
```

### ppromise
Implements a JavaScript-like "promise" system for working with asynchronous operations.
```squirrel
  ppromise(func)
```
In Portal 2, there are numerous mutually unsyncronised threads, which can be a hassle to work with. Namely, console commands and entity actions are the most common offenders in generating asynchronous code. Historically, ppmod has used callback functions to accomodate for this, but since ppmod4, a "thenable" system was established for clarity and consistency.

Setting up a basic ppromise means wrapping a function with the `ppromise` constructor, which returns a ppromise instance. (Internally, these aren't actually classes or objects due to a workaround for a bug in Portal 2's Squirrel runtime.) Here is an example of a simple promise that resolves in 5 seconds:
```squirrel
  local wait = ppromise(function (resolve, reject) {
    ppmod.wait(function ():(resolve) {
      resolve("5 seconds have passed");
    }, 5);
  });
```

There are several ways of obtaining the result of a ppromise. The simplest by far is to attach a script to the `then`, `except`, or `finally` methods:
```squirrel
  // Prints "5 seconds have passed".
  wait.then(function (result) {
    printl(result);
  });

  // Prints either the value given to reject(), or any errors caught by the ppromise.
  wait.except(function (err) {
    printl(err);
  });

  // Prints either the value of resolve() or reject(), whichever came first.
  wait.finally(function (value) {
    printl(value);
  });
```
Note that only one function can be attached to each output, and only one of `then` or `except` gets called (whichever is encountered first), while `finally` gets called regardless.

You can also get the value and state of a ppromise directly:
```squirrrel
  wait.state // One of "pending", "fulfilled", or "rejected"
  wait.value // The value passed to either resolve() or reject()
```

Lastly, the value of a ppromise can be resolved inline via async functions.

### async
To improve code clarity and reduce nesting, ppmod implements JavaScript-like `async` functions, which can resolve `ppromise`s inline using the `yield` keyword, which in this case works similarly to JavaScript's `await`.
```squirrel
  async(func)
```

The simplest way of declaring such a function is to wrap it in `async()`. Here is an example of such a function that waits for `ppmod.create` to spawn an entity:
```squirrel
  local createCube = async(function () {

    yield ppmod.create("prop_weighted_cube");
    local cube = ::syncnext;

    cube.SetOrigin(Vector(...));
    ...

  });

  // Can be called like a normal function
  createCube(); 
```
There are some important things to note here. Firstly, for context, here `ppmod.create` returns a `ppromise` that resolves to the created entity's handle. Secondly, `yield` on its own does not return this value. These `async` functions work by exploiting Squirrel's generators, which leads to admittedly hacky syntax. The value of the last `yield`ed `ppromise` is instead stored in the `syncnext` global.

Due to a bug in how Portal 2 handles restoring the script scope from save files, saving before an `async` function has finished running can lead to game freezes or crashes. It is therefore not recommended to use `async` functions in tick loops, and instead reserve them for one-time events like map loads or entity outputs.

## Entity management
These functions help with the Source entity input/output system. They mostly consist of streamlined versions of existing essential functions.

### ppmod.get
Searches for an entity by various criteria and returns its handle. Searches can be done by:
- Targetname
- Classname
- Model
- Entity index
- Position (more on that later)

Here are some examples of finding the first laser cube on `sp_a2_triple_laser`:
```squirrel
  ppmod.get("new_box") // By targetname
  ppmod.get("prop_weighted_cube") // By classname
  ppmod.get("models/props/reflection_cube.mdl") // By model
  ppmod.get(51) // By entity index (not recommended)
```

Iterating over entities can be done by providing the previous entity's handle as the second argument:
```squirrel
  local first = ppmod.get("prop_testchamber_door"); // First chamber door (usually entrance)
  local second = ppmod.get("prop_testchamber_door", first); // Second chamber door (usually exit)
```

Or, to iterate over every cube in a map:
```squirrel
  local cube = null;
  while (cube = ppmod.get("prop_weighted_cube", cube)) {
    printl("Cube found at: " + cube.GetOrigin());
  }
```

As mentioned before, searches can also be performed by position:
```squirrel
  ppmod.get(Vector(7687, -5863, 18)) // Starting position of the first cube on sp_a2_triple_laser
  ppmod.get(Vector(7687, -5863, 18), 8) // Same search, but narrowed down to a 8 unit radius (default is 32)
```

You can also apply a filter containing any of the previously mentioned search criteria to narrow down a position search:
```squirrel
  local playerPos = GetPlayer().GetOrigin();
  local radius = 1024;

  // Search for a chamber door within 1024 units of the player
  ppmod.get(playerPos, radius, "prop_testchamber_door");
```

### ppmod.getall
Runs a callback function for every entity that matches the search. Mostly intended for use internally. First argument is an array of `ppmod.get` arguments, the second argument is the callback function, which is provided each iteration's respective entity.
```squirrel
  ppmod.getall(["prop_weighted_cube"], function (cube) {
    printl("Cube found at: " + cube.GetOrigin());
  });
```

### ppmod.prev
Performs a `ppmod.get` search in reverse. Useful for finding the last entity of a sequence.
```squirrel
  ppmod.prev("prop_testchamber_door") // Gets the last door in the map
```

### ppmod.fire
Fires an input to an entity, either by classname, targetname or entity handle.
```squirrel
  ppmod.fire(target, action, value, delay, activator, caller)
```
This functions very similarly to methods like `DoEntFire` or `EntFireByHandle`, with some additional quality-of-life changes:
- The `target` may be either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Every argument other than the `target` holds a default placeholder value.
- The `value` is automatically converted to a string.

This means that `ppmod.fire` can be used as a universal shorthand for firing inputs to entities. All of the following examples are valid:
```squirrel
  ppmod.fire("prop_weighted_cube", "Dissolve", "", 2, null, null); // Fizzle all cubes in 2 seconds
  ppmod.fire("named_cube", "Dissolve"); // Fizzle a specific cube
  ppmod.fire([Vector(...), 128, "prop_weighted_cube"], "Dissolve"); // Find all cubes within a 128u radius and fizzle them
```

### ppmod.keyval
Sets a keyvalue for an entity provided by either classname, targetname or handle.
```squirrel
  ppmod.keyval(entity, key, value)
```
This functions similarly to `__KeyValueFrom...` methods, or the keyvalue format of the `AddOutput` input. The differences are:
- The `entity` may be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Value types are detected and converted automatically.
- The keyvalue is applied instantly, skipping the entity I/O queue.

Similarly to `ppmod.fire`, this functions as a universal shorthand for keyvalues. Here are some valid examples:
```squirrel
  ppmod.keyval("prop_weighted_cube", "RenderColor", "255 0 0"); // Colors all cubes red
  ppmod.keyval("cube1", "Targetname", "cube2"); // Changes the name of "cube1" to "cube2"
  ppmod.keyval("weapon_portalgun", "CanFirePortal1", false); // Disables the portal gun's blue portal
  ppmod.keyval([Vector(...), 128], "angles", Vector(-90, 0, 0)); // Rotates entities within a 128u radius to face directly upwards
```

### ppmod.flags
Sets an entity's spawnflags. This is really just an abstraction of the "SpawnFlags" keyvalue.
```squirrel
  local trigger = ppmod.get(Vector(...), 32, "trigger_once");
  ppmod.flags(trigger, 1, 2, 8); // Makes a trigger react to clients, NPCs and physics props
```
The flags are provided as a variable number of arguments and are summed up to create the value set as the SpawnFlags keyvalue.

### ppmod.addoutput
Connects an entity output to another entity's input. For more info on entity I/O, [see here](https://developer.valvesoftware.com/wiki/Inputs_and_Outputs).
```squirrel
  ppmod.addoutput(entity, output, target, input, value, delay, max);
```
The arguments of this function are identical to those used in Hammer or those passed to the `AddOutput` input. Note that:
- The `entity` and `target` may be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Outputs are added instantly, skipping the entity I/O queue.
- Quotes and special characters are safe to use, with the exception of `\x1B`.

### ppmod.addscript
Similar to its sister function `ppmod.addoutput`, but instead of firing an input when an output is received, a script function is called.
```squirrel
  ppmod.addscript(entity, output, script, delay, max, passthrough)
```
The arguments here are similar to those in `ppmod.addoutput`, except:
- The `script` may be either a string of single-line Squirrel code, or a function.
- Setting `passthrough` to `true` provides the given function with the output's `activator` and `caller` as arguments.

### ppmod.runscript
Runs a script as the specified entity. Nearly identical to `ppmod.fire(entity, "RunScriptCode", script)`, with the exception that the script can be either a string or a script function.
```squirrel
  ppmod.runscript(entity, script)
```

### ppmod.setparent
Sets the parent of the given child entity to a parent entity, joining their movement together.
```squirrel
  ppmod.setparent(child, parent)
```
Both the parent and the child can be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`. Setting the parent to a falsy value like `null` will remove any parent from the child. This acts as a cleaner alternative to the `SetParent` and `ClearParent` entity inputs.

### ppmod.hook
Sets an entity's [input hook](https://developer.valvesoftware.com/wiki/VScript_Fundamentals#Input_Hooks).
```squirrel
  ppmod.hook(entity, input, script, max)
```
The given script function gets called whenever the entity receives the specified input. If this function returns `false`, the input is discarded. Otherwise, it gets executed as per usual. This can be used to make specific inputs conditional, or to disable them outright. Note that input names are case sensitive, and use the CamelCase format.

## Shorthands for entity management
Many of the functions documented above are also implemented as methods in most entity classes (assuming that ppmod was included before entities were instantiated). This provides some syntactic sugar that makes entity code shorter and cleaner.

### Keyvalue assignment
Keyvalues can be assigned as a property of an entity's handle.
```squirrel
  local pgun = ppmod.get("weapon_portalgun");
  pgun.CanFirePortal1 = false; // Disables the portal gun's blue portal
```
Note that you cannot retrieve keyvalues this way.

### Firing inputs
Inputs can be fired by calling them as a method of an entity's handle. All arguments remain optional, and are ordered just like in `ppmod.fire`.
```squirrel
  local cube = ppmod.get("prop_weighted_cube");
  cube.Color("255 0 0", 2.5); // Colors the cube red after 2.5 seconds
```
Alternatively, you can fire inputs by calling the `Fire` method of the handle.
```squirrel
  cube.Fire("Dissolve"); // Fizzles the cube
```

### Adding outputs
Outputs can be added via the `AddOutput` method of an entity's handle. Arguments remain the same as with `ppmod.addoutput`.
```squirrel
  ent.AddOutput(output, target, input, value, delay, max)
```
Similarly, scripts can be added via the `AddScript` method.
```squirrel
  ent.AddScript(output, scr, delay, max, passthrough)
```

### Running scripts
The `RunScript` method acts as a shorthand of `ppmod.runscript`.
```squirrel
  ent.RunScript(script)
```

### Parenting
Entities can be parented via the `SetMoveParent` method. Behavior is the same as with `ppmod.setparent`.
```squirrel
  ent.SetMoveParent(parent)
```
Note that the method `GetMoveParent` exists in Portal 2 by default, and can be used to retrieve the parent entity handle.

### Hooking inputs
Hook functions can be added to inputs via the `SetHook` method. Arguments remain the same as with `ppmod.hook`.
```squirrel
  ent.SetHook(input, script, max)
```

## Control flow
These functions implement additional features to VScript's program control flow, like timers and intervals, essential for game programming.

### ppmod.wait
Runs the given script after the specified time.
```squirrel
  ppmod.wait(script, seconds, name)
```
The script may be provided as either a string of single-line VScript or a function. The time is to be provided in seconds, and can be either an integer or a float. The `name` argument is optional. If set, it names the underlying `logic_relay` entity, which can then be found and destroyed, aborting the timer.

Here is an example of using this function to fizzle a cube in 2 seconds, unless the player picks it up before then:
```squirrel
  local cube = ppmod.get("prop_weighted_cube");

  ppmod.wait(function ():(cube) {
    cube.Dissolve();
  }, 2.0, "wait_dissolve");

  ppmod.addoutput(cube, "OnPlayerPickup", "wait_dissolve", "Kill");
```
Note that this function returns a handle for the `logic_relay` entity, which can also be used to destroy the timer without having to give it a name:
```squirrel
  local timer = ppmod.wait(...);
  if (condition) timer.Destroy();
```

### ppmod.interval
Runs the given script repeatedly in the specified time interval.
```squirrel
  ppmod.interval(script, seconds, name)
```
The arguments for this function are nearly identical to those used for `ppmod.wait`, with the only exception being that the time is optional. If the interval time is not set (or if set to 0), the script will get called on every entity tick.

Here is an example of a script that hurts the player every 0.5 seconds if they aren't standing on a cube:
```squirrel
  local player = GetPlayer();

  ppmod.interval(function ():(player) {

    local feetpos = player.GetOrigin() - Vector(0, 0, 18);
    local cube = ppmod.get(feetpos, 8, "prop_weighted_cube");

    if (!cube) {
      player.SetHealth(player.GetHealth() - 20);
    }

  }, 0.5);
```

### ppmod.ontick
Runs the given script for every console tick, or waits the specified amount of ticks to run a script.
```squirrel
  ppmod.ontick(script, pause, timeout)
```
The `script` may be provided as either a string of single-line VScript, or a function. If `pause` is set to `true` (default), the loop will not run while the game is paused. If `timeout` is set to `-1` (default), the loop will run indefinitely for every tick. Otherwise, this function acts as a timer, and will wait for the specified amount of ticks to pass before running the script once.

Here is a simple example that will print "Hello Portal 2!" to the console every tick, even when the game is paused.
```squirrel
  ppmod.ontick(function () {
    printl("Hello Portal 2!");
  }, false);
```
Note that it is generally recommended to use `ppmod.interval` or `ppmod.wait` instead, where applicable. This function will not preserve its ticks through save files, and large scale use of `ppmod.ontick` loops can theoretically cause console buffer overruns. The only recommended usecase for this function is for keeping time during game pauses.

### ppmod.once
Ensures that a script is called only once on the current map.
```squirrel
  ppmod.once(script, name)
```
The `script` may be provided as either a string of single-line VScript, or a function. The `name` argument is optional, and can be used to rename and later remove the underlying dummy entity, which allows the script to be run again. Note that this function also returns a handle for said entity. If a name is not provided, the entity is instead named after the given script or reference to the given function. Because of this, functions created inline can't be governed with this function.

It is hard to find a use for this function nowadays, and it is generally considered deprecated. It used to be helpful in older versions of ppmod, before callback functions were supported.

### ppmod.onauto
Runs the given script once the map has fully loaded.
```squirrel
  ppmod.onauto(script, onload)
```
The `script` may be provided as either a string of single-line VScript, or a function. The `onload` argument is optional (`false` by default), and when set to `true`, calls the provided script on not only the initial map load, but also any save file loads.

This function is essential for almost any gameplay modding, and will often appear at the top of many ppmod scripts, as most entities are not accessible until the map has fully loaded. In single-player, this means waiting for the `logic_auto` entity to fire. In networked co-op games, this function also waits for the remote player (P-body) to fully connect before calling the script.

### ppmod.detach
Works around script timeouts by catching the exception they throw.
```squirrel
  ppmod.detach(script, args)
```
In Portal 2's implementation of Squirrel, scripts (queries) are given a limited time to run, so that a simple `while (true)` loop doesn't hang the game. For compute-intensive operations, this can mean that the script is aborted before calculations are finished. When this happens, the VM throws a `Script terminated by SQQuerySuspend` exception. This function catches that exception, and calls the given function again, passing it the arguments from the previous run. If a different exception is caught, ppmod traces it back to the line on which `ppmod.detach` was called. Note that some of the trace data is unfortunately lost this way.

The `script` argument expects a function which is passed one argument - a table. The `args` argument is this table, which is passed back to the function every time it is called. Here is an example of using this function to call a for loop which increments an integer until it overflows:
```squirrel
  ppmod.detach(function (args) {

    while (args.i >= 0) args.i ++;
    printl("i overflowed to " + args.i);

  }, { i = 0 });
```
Note that this will most likely take some time to run, during which the game will freeze. Be careful not to leave infinite loops running like this, since the only other safeguard is, theoretically, a stack overflow.

## Player interface
Provides more information about and ways to interact with a player.
```squirrel
  ppmod.player(player)
```
This function acts as a constructor and expects one argument - the entity handle of a player. It returns a `ppromise` which resolves to a `pplayer` instance (in reality just a table) which contains methods that allow for more control over the player than vanilla VScript provides.

### pplayer.eyes
Provides accurate eye position and angles.
```squirrel
  pplayer.eyes.GetOrigin() // Eye position
  pplayer.eyes.GetAngles() // Eye angles
  pplayer.eyes.GetForwardVector() // Eye facing vector
```
In Portal 2, retrieving the player's angles directly will return the rotation of the player model, which differs significantly from the player's view angles. Instead, `pplayer.eyes` creates and returns a `logic_measure_movement` entity, which can be referenced for accurate eye position.

### pplayer.holding
Determines whether the player is holding a prop.
```squirrel
  pplayer.holding().then(function (state) {

    if (state) {
      // ... is holding a prop
    } else {
      // ... is not holding a prop 
    }

  });
```
This function returns a `ppromise` that resolves to a single boolean for whether or not the player is holding something. Optionally, `pplayer.holding` can be passed one argument - an array of entity classes to check. By default, every entity class that can be picked up in Portal 2 is checked. Checking only for specific classes can improve performance.

### Event listeners
Allows for listening to player actions. Each of these functions expects one argument - a function to attach. Multiple functions can be attached to one event.
- `pplayer.jump` - Fired when the player issues a jump input.
- `pplayer.land` - Fired when the player lands from a jump or fall.
- `pplayer.duck` - Fired when the player finishes the crouching animation.
- `pplayer.unduck` - Fired when the player finishes the uncrouching animation.

Here is an example of using `pplayer.jump` to listen for jumps:
```squirrel
  ppmod.player(GetPlayer()).then(function (pplayer) {

    // Note: this will fire for every jump input, including those issued mid-air
    pplayer.jump(function () {
      printl("The player has jumped!");
    });

  });
```

### pplayer.grounded
Returns `true` if the player is on the ground, `false` otherwise.
```squirrel
  pplayer.grounded() // Returns true or false
```

### pplayer.input
Allows for listening to player inputs.
```squirrel
  pplayer.input(input, script)
```
The `input` argument expects a string specifying the input command to listen for. The `script` argument can be either a function, or a string of single-line VScript code. Note that only the inputs provided by `game_ui` are supported, namely:
- `+moveleft` and `-moveleft`
- `+moveright` and `-moveright`
- `+forward` and `-forward`
- `+back` and `-back`
- `+attack` and `-attack`
- `+attack2` and `-attack2`

Here is an example of using `pplayer.input` to listen for when the player has attempted to shoot a portal:
```squirrel
  ppmod.player(GetPlayer()).then(function (pplayer) {

    // Note: this will fire for every +attack input, even if the player can't shoot portals
    pplayer.input("+attack", function () {
      printl("Portal shot attempted!");
    });

  });
```

### pplayer.gravity
Changes the player's gravity without affecting the gravity of other players or entities.
```squirrel
  pplayer.gravity(gravity)
```
One argument is expected - a multiplier for the strength of the player's gravity. A value of `1` will leave it unchanged, a value of `0` will disable gravity entirely, a value of `2` will make it twice as strong, and so on.

### pplayer.friction
Changes the player's friction without affecting the friction of other players or entities.
```squirrel
  pplayer.friction(friction, frametime, grounded)
```
This function is expected to be run in a tick loop. The `friction` argument holds the same meaning as the `sv_friction` console variable (hidden in Portal 2), the `frametime` argument (optional) specifies the interval at which this function will be called. If set to `null` (default), the value of the internal function `FrameTime()` will be assumed. The `grounded` argument (optional) is a boolean, specifying whether or not the player is on the ground. Setting this to `false` essentially skips running the function entirely. If set to `null` (default), the value of `pplayer.grounded()` is used.

Here is an example of setting the player's friction to 2, which is half of the default value:
```squirrel
  ppmod.player(GetPlayer()).then(function (pplayer) {

    // Note: this function calculates the friction for one tick at a time, so a tick loop is used
    ppmod.interval(function ():(pplayer) {
      pplayer.friction(2.0);
    });

  });
```
Note that the calculations performed expect the value of `sv_friction` to be `4`, which it is by default, and typically cannot be changed without unlocking the console variable via a plugin.

### pplayer.ent
Holds the entity handle that was used to instantiate this `pplayer` instance.
```squirrel
  ppmod.player(GetPlayer()).then(function (pplayer) {
    pplayer.ent == GetPlayer() // true
  });
```

## World interface
These functions provide ways to interact with the world and physical entities.

### ppmod.create
Creates an entity by running the given command and retrieves its handle.
```squirrel
  ppmod.create(command, key)
```
The `command` argument is the console command to run for creating the entity. Provided just an entity classname, the function uses the `ent_create` command. Providing a model path (any string ending with `.mdl`) will use `prop_dynamic_create`. The `key` argument is optional, and can be used to specify the exact criteria by which to search for the newly created entity. If not provided, the `key` is guessed from the input command. The function returns a `ppromise`, which resolves with the handle of the newly created entity.

In Portal 2, creating an entity with methods like `Entities.CreateByClassname` or `CreateProp` can be problematic, especially if the entity is complicated, is a physics prop, or isn't precached in some way. This is because these methods don't run initialization code often required for full functionality of many entities. Console commands are better in this regard, but pose a new issue - after an entity has been created, consistently getting a reference to it in VScript can be hard. This is why `ppmod.create` exists.

Here are a few examples of creating cubes with this function:
```squirrel
  // The simplest method, just providing the classname
  ppmod.create("prop_weighted_cube").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });

  // Using the game-specific command for spawning a companion cube
  ppmod.create("ent_create_portal_companion_cube").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });

  // Using prop_physics_create to spawn a generic physics prop with the reflection cube model
  ppmod.create("prop_physics_create props/reflection_cube.mdl").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });
```

Note that excessive back-to-back use of `ppmod.create` can cause the wrong handle to be returned. For cases where a large number of entities needs to be spawned, it is recommended to either spread the spawns across ticks in batches, or to use `CreateProp` where applicable, assuming that the model has been precached.

### ppmod.give
Creates a variable amount of entities under the player's feet.
```squirrel
  ppmod.give(classname, amount)
```
The `classname` argument expects the classname of the entity to spawn as a string. The `amount` argument is optional (1 by default) and denotes the amount of entities of the given classname to spawn at once. This function returns a `ppromise` which resolves to the last entity created by this function.

While this functions a lot like the `give` console command, no console commands are actually used. Instead, the `game_player_equip` entity is spawned temporarily. However, due to a bug in Portal 2, this entity seems to cause crashes when used in co-op.

Here is an example of spawning a cube at the player's feet with this function:
```squirrel
  ppmod.give("prop_weighted_cube").then(function (cube) {
    // ... do something with cube
  });
```

### ppmod.brush
Creates a solid, invisible brush entity.
```squirrel
  ppmod.brush(position, size, type, angles, create)
```
The `position` argument is a Vector to the center of the brush. The `size` argument is a Vector containing the half-width of the brush along each axis. The `type` argument is the classname of the brush entity as a string. The `angles` argument (optional) expects a Vector, with the properties being pitch, yaw and roll for X, Y and Z, respectively. Lastly, the `create` argument (optional) is a boolean, specifying whether or not to use `ppmod.create` for creating the brush instead of `Entities.CreateByClassname` to work around unloaded entity features. If `create` is `false` (default), this function returns a handle to the newly created brush entity. If `create` is `true`, it creates a `ppromise` which resolves to a handle for the brush entity.

Here is an example of creating an invisible, outlined box at the center of the `sp_a2_triple_laser` chamber:
```squirrel
  local brush = ppmod.brush(Vector(7808, -5629, 64), Vector(32, 32, 32), "func_brush");
  ppmod.keyval(brush, "Targetname", "test_brush");
  
  SendToConsole("developer 1");
  SendToConsole("ent_bbox test_brush");
```
Note that these brush entities cannot be assigned custom textures or complex shapes, as that requires a model for the brush to be precompiled into the map. Many brush entities may also not function as expected, even with `create` set to `true`.

### ppmod.trigger
Similar to `ppmod.brush`, creates a non-solid trigger volume entity.
```squirrel
  ppmod.trigger(position, size, type, angles, create)
```
The arguments and return values are the exact same as those used for `ppmod.brush`, refer to the documentation of that function.

The primary differences between this function and `ppmod.brush` are the output entity's spawn flags and the lack of collision. Every entity created via this function has its `SpawnFlags` keyvalue set to `1`, which in most cases means that only players can trigger it. This can, of course, later be changed to account for other entities and props. Another notable exception is that if a trigger's `type` is set to `trigger_once`, it will automatically remove itself after being touched.

Here is an example of creating an invisible, outlined trigger at the center of the `sp_a2_triple_laser` chamber, which spawns a cube once the player touches it:
```squirrel
  local trigger = ppmod.trigger(Vector(7808, -5629, 64), Vector(32, 32, 32), "trigger_once");
  ppmod.keyval(trigger, "Targetname", "test_trigger");

  ppmod.addscript(trigger, "OnStartTouch", function () {
    ppmod.create("prop_weighted_cube").then(function (cube) {
      cube.SetOrigin(Vector(7808, -5629, 128));
    });
  });

  SendToConsole("developer 1");
  SendToConsole("ent_bbox test_trigger");
```
