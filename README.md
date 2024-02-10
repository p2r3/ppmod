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
