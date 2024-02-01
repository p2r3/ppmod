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
