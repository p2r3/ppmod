/*
  ppmod version 4
  author: PortalRunner
*/

if (!("Entities" in this)) {
  throw "ppmod: Tried to run in a scope without CEntities!";
}

if ("ppmod" in this) {
  printl("[ppmod] Warning: ppmod is already loaded!");
  return;
}

::ppmod <- {};

/********************/
// Global Utilities //
/********************/

// Returns the smallest of two values
::min <- function (a, b) return a > b ? b : a;
// Returns the largest of two values
::max <- function (a, b) return a < b ? b : a;
// Rounds the input float, optionally to a set precision
::round <- function (a, b = 0) {
  if (b == 0) return floor(a + 0.5);
  return floor(a * (b = pow(10, b)) + 0.5) / b;
}

// Extends the functionality of Squirrel arrays
class pparray {

  arr = null;

  constructor (size = 0, fill = null) {
    if (typeof size == "array") arr = size;
    else arr = array(size, fill);
  }

  // Overload operators to mimic a standard array
  function _typeof () return "array";
  function _get (idx) return arr[idx];
  function _set (idx, val) return arr[idx] = val;
  function _nexti (previdx) {
    if (previdx < 0 || previdx >= this.len()) return null;
    if (previdx == null) return 0;
    return previdx + 1;
  }
  // Returns a representation of the array values as a string
  function _tostring () {
    local str = "[";
    for (local i = 0; i < arr.len(); i ++) {
      if (typeof arr[i] == "string") str += "\"" + arr[i] + "\"";
      else str += arr[i];
      if (i != arr.len() - 1) str += ", ";
    }
    return str + "]";
  }
  // Compares two arrays by their elements
  function _cmp (other) {
    local shortest = min(arr.len(), other.len());
    for (local i = 0; i < shortest; i ++) {
      if (arr[i] < other[i]) return -1;
      else if (arr[i] > other[i]) return 1;
    }
    if (arr.len() < other.len()) return -1;
    if (arr.len() > other.len()) return 1;
    return 0;
  }

  // Implement standard Squirrel array methods
  function len () return arr.len();
  function append (val) return arr.append(val);
  function push (val) return arr.push(val);
  function extend (other) return arr.extend(other);
  function pop () return arr.pop();
  function top () return arr.top();
  function insert (idx, val) return arr.insert(idx, val);
  function remove (idx) return arr.remove(idx);
  function resize (size, fill = null) return arr.resize(size, fill);
  function sort (func = null) return func ? arr.sort(func) : arr.sort();
  function reverse () return arr.reverse();
  function slice (start, end = null) return pparray(arr.slice(start, end || arr.len()));
  function tostring () return _tostring();
  function clear () return arr.clear();

  // Implement additional methods to extend array functionality
  function shift () return arr.remove(0);
  function unshift (val) return arr.insert(0, val);
  // Joins the elements of the array into a string
  function join (separator = ",") {
    local str = "";
    for (local i = 0; i < arr.len(); i ++) {
      str += arr[i];
      if (i != arr.len() - 1) str += separator;
    }
    return str;
  }
  // Checks if the contents of the two arrays are identical
  function equals (other) {
    if (arr.len() != other.len()) return 0;
    for (local i = 0; i < arr.len(); i ++) {
      if (typeof arr[i] == "array") {
        if (arr[i].equals(other[i]) == 0) return 0;
      } else {
        if (arr[i] != other[i]) return 0;
      }
    }
    return 1;
  }
  // Returns the index of the first element to match the input value
  // Returns -1 if no such element is found
  function indexof (match, start = 0) {
    for (local i = start; i < arr.len(); i ++) {
      if (arr[i] == match) return i;
    }
    return -1;
  }
  // Returns the index of the first element to pass the compare function
  function find (match, start = 0) {
    for (local i = start; i < arr.len(); i ++) {
      if (match(arr[i])) return i;
    }
    return -1;
  }
  // Returns true if the array contains the element, false otherwise
  function includes (match, start = 0) {
    return indexof(match, start) != -1;
  }

}

// Implements the heap data type
class ppheap {

  arr = pparray([0]);
  size = 0;
  maxsize = 0;
  comp = null;

  constructor (maxs = 0, comparator = null) {
    maxsize = maxs;
    arr = pparray(maxsize * 4 + 1,0);
    if (comparator) {
      comp = comparator;
    } else {
      comp = function (a, b) { return a < b };
    }
  }

  // Returns true if the heap is empty, false otherwise
  function isempty () return size == 0;
  // Sifts down the element at the given index to its correct position in the heap
  function bubbledown (hole) {
    local temp = arr[hole];
    while (hole * 2 <= size) {
      local child = hole * 2;
      if (child != size && comp(arr[child + 1], arr[child])) child ++;
      if (comp(arr[child], temp)) {
        arr[hole] = arr[child]
      } else {
        break;
      }
      hole = child;
    }
    arr[hole] = temp;
  }
  // Removes the top element of the heap and returns it
  function remove () {
    if (isempty()) {
      throw "ppheap: Heap is empty";
    } else {
      local tmp = arr[1];
      arr[1] = arr[size--];
      bubbledown(1);
      return tmp;
    }
  }
  // Returns the top element of the heap
  function gettop () {
    if (isempty()) {
      throw "ppheap: Heap is empty";
    } else {
      return arr[1];
    }
  }
  // Insers the given element into the heap
  function insert (val) {
    if (size == maxsize) {
      throw "ppheap: Exceeded max heap size";
    }
    arr[0] = val;
    local hole = ++size;
    while (comp(val, arr[hole / 2])) {
      arr[hole] = arr[hole / 2];
      hole /= 2;
    }
    arr[hole] = val;
  }

}

// Extends the functionality of Squirrel strings
class ppstring {

  string = null;

  constructor (str = "") {
    string = str.tostring();
  }

  // Overload operators to mimic a standard string
  function _typeof () return "string";
  function _tostring () return string;
  function _add (other) return ppstring(string + other.tostring());
  function _get (idx) return string[idx];
  function _set (idx, val) return string = string.slice(0, idx) + val.tochar() + string.slice(idx + 1);
  function _cmp (other) {
    if (string == other.tostring()) return 0;
    if (string > other.tostring()) return 1;
    return -1;
  }

  // Implement standard Squirrel string methods
  function len () return string.len();
  function tointeger () return string.tointeger();
  function tofloat () return string.tofloat();
  function tostring () return string;
  function slice (start, end = null) return ppstring(string.slice(start, end || string.len()));
  function find (substr, start = 0) return string.find(substr, start);
  function tolower () return ppstring(string.tolower());
  function toupper () return ppstring(string.toupper());
  function strip () return ppstring(::strip(string));
  function lstrip () return ppstring(::lstrip(string));
  function rstrip () return ppstring(::rstrip(string));

  // Returns a string which replaces all occurrences of one substring with another
  function replace (substr, rep) {
    local out = "", prev = 0, idx = 0;
    while ((idx = string.find(substr, prev)) != null) {
      out += string.slice(prev, idx);
      out += rep;
      prev = idx + substr.len();
    }
    return out + string.slice(prev);
  }
  // Returns a Squirrel array representing the string split up by a substring
  function split (substr) {
    local arr = [], curr = 0, prev = 0;
    while ((curr = string.find(substr, curr)) != null) {
      curr = max(curr, prev + 1);
      arr.push(string.slice(prev, curr));
      prev = curr += substr.len();
    }
    arr.push(string.slice(prev));
    return arr;
  }
  // Returns true if the string includes the given substring
  function includes (substr, start = 0) {
    return string.find(substr, start) != null;
  }

}

/**
 * Because of a bug in how objects are restored from Portal 2 save files,
 * using a class for ppromise causes crashes on save load. Instead, we
 * mimic a class structure by returning a table from a function.
 */

// Methods for the ppromise prototypal class
local ppromise_methods = {

  // Attaches a function to be executed when the promise fullfils
  then = function (onthen, oncatch = function (x) { throw x }) {
    if (typeof onthen != "function" || typeof oncatch != "function") {
      throw "ppromise: Invalid arguments for .then handler";
    }

    // Run the function immediately if the promise has already fulfilled
    if (state == "fulfilled") { onthen(value); return this }
    if (state == "rejected") { oncatch(value); return this }

    onfulfill.push(onthen);
    onreject.push(oncatch);

    return this;
  },
  // Attaches a function to be executed when the promise is rejected
  except = function (oncatch) {
    if (typeof oncatch != "function") {
      throw "ppromise: Invalid argument for .except handler";
    }

    // Run the function immediately if the promise has already rejected
    if (state == "rejected") return oncatch(value);
    onreject.push(oncatch);

    return this;
  },
  // Attaches a function to be executed when the promise resolves
  finally = function (onfinally) {
    if (typeof finally != "function") {
      throw "ppromise: Invalid argument for .finally handler";
    }

    // Run the function immediately if the promise has already resolved
    if (state != "pending") return onfinally(value);
    onresolve.push(onfinally);

    return this;
  },
  // Fulfills the given ppromise instance with the given value
  resolve = function (inst, val) {
    // If the promise has already been resolved, do nothing
    if (inst.state != "pending") return;

    // Update the promise state and value
    inst.state = "fulfilled";
    inst.value = val;

    // Call all relevant functions attached to the promise
    for (local i = 0; i < inst.onfulfill.len(); i ++) inst.onfulfill[i](val);
    for (local i = 0; i < inst.onresolve.len(); i ++) inst.onresolve[i]();
  },
  // Rejects the given ppromise instance with the given value
  reject = function (inst, err) {
    // If the promise has already been resolved, do nothing
    if (inst.state != "pending") return;

    // Update the promise state and value
    inst.state = "rejected";
    inst.value = err;

    // If no error handler has been attached, throw the error
    if (inst.onreject.len() == 0) throw err;

    // Call all relevant functions attached to the promise
    for (local i = 0; i < inst.onreject.len(); i ++) inst.onreject[i](err);
    for (local i = 0; i < inst.onresolve.len(); i ++) inst.onresolve[i]();
  }

}

// Constructor for the ppromise prototypal class
::ppromise <- function (func):(ppromise_methods) {

  // Create a table to act as the class instance
  local inst = {

    onresolve = [],
    onfulfill = [],
    onreject = [],

    state = "pending",
    value = null,

    then = ppromise_methods.then,
    except = ppromise_methods.except,
    finally = ppromise_methods.finally

    resolve = null,
    reject = null

  };

  // Wrappers for the resolve/reject handlers, capturing this instance
  inst.resolve = function (val = null):(ppromise_methods, inst) {
    ppromise_methods.resolve(inst, val);
  };
  inst.reject = function (err = null):(ppromise_methods, inst) {
    ppromise_methods.reject(inst, err);
  };

  // Run the input function
  try { func(inst.resolve, inst.reject) }
  catch (e) { inst.reject(e) }
  // Return the table representing a ppromise class instance
  return inst;

}

/**
 * Asynchronous functions are implemented using Squirrel generators.
 * Since a generator is essentially a function that can return some output
 * without exiting, we can use this property to suspend code execution
 * until another procedure is done processing the returned (yielded)
 * output, at which point the generator is told to resume.
 */

// Holds generators used for async functions
::ppmod.asyncgen <- [];
// Holds the value of the last ppromise yielded from an async function
::yielded <- null;

// Runs an async generator over and over until end of scope is reached
::ppmod.asyncrun <- function (id, resolve, reject):(ppromise_methods) {

  // Holds the yielded/returned value of the generator
  local next;
  try { next = resume ppmod.asyncgen[id] }
  catch (e) { return reject(e) }

  // If the generator has finished running, resolve the async function
  if (ppmod.asyncgen[id].getstatus() == "dead") {
    ppmod.asyncgen[id] = null;
    return resolve(next);
  }

  // Ensure we're handling a ppromise instance
  if (next.then != ppromise_methods.then) {
    throw "async: Function did not yield a ppromise";
  }
  // Resume the generator when the promise resolves
  next.then(function (val):(id, resolve, reject) {
    ::yielded <- val;
    ppmod.asyncrun(id, resolve, reject);
  });

}

// Converts a function to one that returns a ppromise
::async <- function (func) {
  return function (...):(func) {

    // Extract the arguments and format them for acall()
    local args = array(vargc + 1);
    for (local i = 0; i < vargc; i ++) args[i + 1] = vargv[i];
    args[0] = this;

    // Create a ppromise which runs the input function as a generator
    return ppromise(function (resolve, reject):(func, args) {
      // Find a free spot in ppmod.asyncgen to insert this function
      for (local i = 0; i < ppmod.asyncgen.len(); i ++) {
        if (ppmod.asyncgen[i] == null) {
          ppmod.asyncgen[i] = func.acall(args);
          ppmod.asyncrun(i, resolve, reject);
          return;
        }
      }
      // If no free space was found, extend the array by pushing to it
      ppmod.asyncgen.push(func.acall(args));
      ppmod.asyncrun(ppmod.asyncgen.len() - 1, resolve, reject);
    });

  };
}

// Extend Vector class functionality
try {
  // Implement multiplication with other Vectors
  function Vector::_mul (other) {
    if (typeof other == "Vector") {
      return Vector(this.x * other.x, this.y * other.y, this.z * other.z);
    } else {
      return Vector(this.x * other, this.y * other, this.z * other);
    }
  }
  // Implement component-wise division with numbers and Vectors
  function Vector::_div (other) {
    if (typeof other == "Vector") {
      return Vector(this.x / other.x, this.y / other.y, this.z / other.z);
    } else {
      return Vector(this.x / other, this.y / other, this.z / other);
    }
  }
  // Implement unary minus
  function Vector::_unm () {
    return Vector() - this;
  }
  // Returns true if the components of the two vectors are identical, false otherwise
  function Vector::equals (other) {
    if (this.x == other.x && this.y == other.y && this.z == other.z) return true;
    return false;
  }
  // Returns a string representation of the Vector as a Vector constructor
  function Vector::_tostring () {
    return "Vector(" + this.x + ", " + this.y + ", " + this.z + ")";
  }
  // Fixes the built-in ToKVString function by reimplementing it
  function Vector::ToKVString () {
    return this.x + " " + this.y + " " + this.z;
  }
  // Normalizes the vector and returns it
  function Vector::Normalize() {
    this.Norm();
    return this;
  }
  // Normalizes the vector along just the X/Y axis and returns it
  function Vector::Normalize2D() {
    this.z = 0.0;
    this.Norm();
    return this;
  }
} catch (e) {
  printl("[ppmod] Warning: failed to modify Vector class: " + e);
}

/*********************/
// Entity management //
/*********************/

// Finds an entity which matches the given parameters
::ppmod.get <- function (arg1, arg2 = null, arg3 = null, arg4 = null) {

  // Entity iterator
  local curr = null;

  // The type of the first argument determines the operation
  switch (typeof arg1) {

    case "string": {
      // Try to first find a match by targetname
      if (curr = Entities.FindByName(arg2, arg1)) return curr;
      // Fall back to a match by classname
      if (curr = Entities.FindByClassname(arg2, arg1)) return curr;
      // Fall back to a match by model name
      return Entities.FindByModel(arg2, arg1);
    }

    case "Vector": {
      // The second argument is the radius, 32u by default
      if (arg2 == null) arg2 = 32.0;

      // The filter argument is optional, and thus the starting entity
      // may be in either the third or fourth position. This makes sure
      // that it is always in arg4.
      if (typeof arg3 == "instance" && arg3 instanceof CBaseEntity) {
        arg4 = arg3;
      }

      // Validate the starting entity (fourth argument)
      if (arg4 != null && !(typeof arg4 == "instance" && arg4 instanceof CBaseEntity)) {
        throw "get: Invalid starting entity";
      }

      // If no valid filter was provided, get the first entity in the radius
      if (typeof arg3 != "string") {
        return Entities.FindInSphere(arg4, arg1, arg2);
      }

      // If a filter was provided, find an entity in the radius that matches it
      while (arg4 = Entities.FindInSphere(arg4, arg1, arg2)) {
        if (!arg4.IsValid()) continue;
        if (arg4.GetName() == arg3 || arg4.GetClassname() == arg3 || arg4.GetModelName() == arg3) {
          return arg4;
        }
      }
      // Return null if nothing was found
      return null;
    }

    case "integer": {
      // Iterate through all entities to find a matching entindex
      while (curr = Entities.Next(curr)) {
        if (!curr.IsValid()) continue;
        if (curr.entindex() == arg1) return curr;
      }
      // Return null if no such entity exists
      return null;
    }

    case "instance": {
      // If provided an entity, echo it back
      if (arg1 instanceof CBaseEntity) return ent;
    }

    default:
      throw "get: Invalid first argument";

  }

}

// Returns true if the input is a valid entity handle, false otherwise
::ppmod.validate <- function (ent) {
  // Entity handles must be of type "instance"
  if (typeof ent != "instance") return false;
  // Entity handles must be instances of CBaseEntity
  if (ent instanceof CBaseEntity) return ent.IsValid();
  return false;
}

// Iterates through all entities that match the given criteria
::ppmod.forent <- function (args, callback) {

  // Convert the input to an array if it isn't already
  if (typeof args != "array") args = [args];
  // If the last argument is not a valid starting entity, push null
  local last = args.len() - 1;
  if (!ppmod.validate(args[last]) && args[last] != null) {
    args.push(null);
    last ++;
  }
  // Prepare args for use with acall()
  args.insert(0, this);

  // Iterate through entities, running the callback on each valid one
  while (args[last] = ppmod.get.acall(args)) {
    if (!args[last].IsValid()) continue;
    callback(args[last]);
  }

}

// Iterates over entities backwards using ppmod.get
::ppmod.prev <- function (...) {

  // Set up entity iterators
  local start = null, curr = null, prev = null;

  // If the last argument is a valid starting entity, assign it
  if (ppmod.validate(vargv[vargc - 1])) {
    start = vargv[vargc - 1];
    curr = start;
  }

  do {
    // Keep track of the entity from the previous iteration
    prev = curr;
    // Because vargv isn't a typical array, we can't use acall() here
    if (vargc < 3) curr = ppmod.get(vargv[0], curr);
    else if (vargc == 3) curr = ppmod.get(vargv[0], vargv[1], curr);
    else curr = ppmod.get(vargv[0], vargv[1], vargv[2], curr);
    // Run until we end up where we started
  } while (curr != start);

  // Return the entity from the last iteration
  return prev;

}

// Calls an input on an entity with optional default arguments
::ppmod.fire <- function (ent, action = "Use", value = "", delay = 0.0, activator = null, caller = null) {

  // If a string was provided, use DoEntFire
  if (typeof ent == "string") {
    return DoEntFire(ent, action, value.tostring(), delay, activator, caller);
  }
  // If an entity handle was provided, use EntFireByHandle
  if (typeof ent == "instance" && ent instanceof CBaseEntity) {
    if (!ent.IsValid()) throw "fire: Invalid entity handle";
    return EntFireByHandle(ent, action, value.tostring(), delay, activator, caller);
  }
  // If any other argument was provided, use ppmod.forent to search for handles
  ppmod.forent(ent, function (curr):(action, value, delay, activator, caller) {
    ppmod.fire(curr, action, value, delay, activator, caller);
  });

}

// Sets an entity keyvalue by automatically determining input type
::ppmod.keyval <- function (ent, key, val) {

  // Validate the key argument
  if (typeof key != "string") throw "keyval: Invalid key argument";

  // If not provided with an entity handle, use ppmod.forent to search for handles
  if (!ppmod.validate(ent)) {
    return ppmod.forent(ent, function (curr):(key, val) {
      ppmod.keyval(curr, key, val);
    });
  }

  // Use the appropriate method based on input type
  switch (typeof val) {

    case "integer":
    case "bool":
      ent.__KeyValueFromInt(key, val.tointeger());
      break;
    case "float":
      ent.__KeyValueFromFloat(key, val);
      break;
    case "Vector":
      ent.__KeyValueFromVector(key, val);
      break;
    default:
      ent.__KeyValueFromString(key, val.tostring());

  }

}

// Sets entity spawn flags from the argument list
::ppmod.flags <- function (ent, ...) {

  // Sum up all entries in vargv
  local sum = 0;
  for (local i = 0; i < vargc; i ++) {
    sum += vargv[i];
  }

  // Call ppmod.keyval to apply the SpawnFlags keyvalue
  ppmod.keyval(ent, "SpawnFlags", sum);

}

// Creates an output to fire on the specified target with optional default arguments
::ppmod.addoutput <- function (ent, output, target, input = "Use", value = "", delay = 0, max = -1) {

  // If the target is not a string, wrap a ppmod.fire call inside of
  // ppmod.addscript to simulate an output whose target is a ppmod.forent argument.
  if (typeof target != "string") {
    return ppmod.addscript(ent, output, function ():(target, input, value) {
      ppmod.fire(target, input, value, 0.0, activator, caller);
    }, delay, max, false);
  }
  // Otherwise, assign the output as a keyvalue separated by x1B characters.
  // This seems to be how entity outputs are represented internally, and
  // should in theory be faster and safer than using the AddOutput input.
  ppmod.keyval(ent, output, target+"\x1B"+input+"\x1B"+value+"\x1B"+delay+"\x1B"+max);

}

// Keep track of a "script queue" for inline functions
// This is used to keep global references to functions for use as callbacks
::ppmod.scrq <- [];

// Adds a function to the script queue, returns its script queue index
::ppmod.scrq_add <- function (scr, max = -1) {

  // If the input is a string, compile it into a function
  if (typeof scr == "string") scr = compilestring(scr);
  // Validate the input script argument
  if (typeof scr != "function") throw "scrq_add: Invalid script argument";

  // Look for an free space in the script queue array
  for (local i = 0; i < ppmod.scrq.len(); i ++) {
    if (ppmod.scrq[i] == null) {
      ppmod.scrq[i] = [scr, max];
      return i;
    }
  }
  // If no free space was found, push it to the end of the array
  ppmod.scrq.push([scr, max]);
  return ppmod.scrq.len() - 1;

}

// Retrieves a function from the script queue, deleting it if needed
::ppmod.scrq_get <- function (idx) {

  // Validate the input script index
  if (!(idx in ppmod.scrq)) throw "scrq_get: Invalid script index";
  if (ppmod.scrq[idx] == null) throw "scrq_get: Invalid script index";

  // Retrieve the function from the queue
  local scr = ppmod.scrq[idx][0];

  // Clear the script queue index if the max amount of retrievals has been reached
  if (ppmod.scrq[idx][1] > 0 && --ppmod.scrq[idx][1] == 0) {
    ppmod.scrq[idx] = null;
  }

  // Return the script queue function
  return scr;

}

// Adds a script as an output to an entity with optional default arguments
::ppmod.addscript <- function (ent, output, scr = "", delay = 0, max = -1, passthrough = false) {

  // If a function was provided, add it to the script queue
  if (typeof scr == "function") {
    // Pass the activator and caller handles to the function if necessary
    if (passthrough) scr = "ppmod.scrq_get(" + ppmod.scrq_add(scr, max) + ")(activator, caller)";
    else scr = "ppmod.scrq_get(" + ppmod.scrq_add(scr, max) + ")()";
  }
  // Attach the output as a keyvalue, similar to how ppmod.addoutput does it
  // The script is targeted to worldspawn, as that makes activator and caller available
  ppmod.keyval(ent, output, "worldspawn\x001BRunScriptCode\x1B"+scr+"\x1B"+delay+"\x1B"+max);

}

// Runs the specified script in the entity's script scope
::ppmod.runscript <- function (ent, scr) {

  // If a function was provided, add it to the script queue
  if (typeof scr == "function") {
    scr = "ppmod.scrq_get(" + ppmod.scrq_add(scr, 1) + ")()";
  }
  // Fire the RunScriptCode output on the input entity
  ppmod.fire(ent, "RunScriptCode", scr);

}

// Assigns or clears the movement parent of an entity
::ppmod.setparent <- function (child, _parent) {

  // If the new parent value is falsy, clear the parent
  if (!_parent) return ppmod.fire(child, "ClearParent");
  // Validate the parent handle
  if (!ppmod.validate(_parent)) throw "setparent: Invalid parent handle";
  // If a valid parent handle was provided, assign the parent
  return ppmod.fire(child, "SetParent", "!activator", 0, _parent);

}

// Hooks an entity input, running a test function each time it's fired
::ppmod.hook <- function (ent, input, scr, max = -1) {

  // If a valid entity handle was not provided, find handles with ppmod.forent
  if (!ppmod.validate(ent)) {
    return ppmod.forent(ent, function (curr):(input, scr, max) {
      ppmod.hook(curr, input, scr, max);
    });
  }
  // Ensure a script scope exists for the entity
  if (!ent.ValidateScriptScope()) {
    throw "hook: Could not validate entity script scope";
  }
  // If the new script is null, clear the hook
  if (scr == null) delete ent.GetScriptScope()["Input"+input];
  // Otherwise, assign a new hook function
  else ent.GetScriptScope()["Input"+input] <- ppmod.scrq_get(ppmod.scrq_add(scr, max));

}

// Implement shorthands of the above functions into the entities as methods
local entclasses = [CBaseEntity, CBaseAnimating, CBaseFlex, CBasePlayer, CEnvEntityMaker, CLinkedPortalDoor, CPortal_Player, CPropLinkedPortalDoor, CSceneEntity, CTriggerCamera];
for (local i = 0; i < entclasses.len(); i ++) {
  try {
    // Allows for setting keyvalues as if they were object properties
    entclasses[i]._set <- function (key, val) {
      // This is mostly identical to ppmod.keyval
      // However, having this be separate is slightly more performant
      if (typeof key != "string") throw "Invalid slot name";
      switch (typeof val) {
        case "integer":
        case "bool":
          this.__KeyValueFromInt(key, val.tointeger());
          break;
        case "float":
          this.__KeyValueFromFloat(key, val);
          break;
        case "Vector":
          this.__KeyValueFromVector(key, val);
          break;
        default:
          this.__KeyValueFromString(key, val.tostring());
      }
      return val;
    }
    // Allows for firing inputs as if they were object methods
    entclasses[i]._get <- function (key) {
      return function (value = "", delay = 0.0, activator = null, caller = null):(key) {
        return ::EntFireByHandle(this, key, value.tostring(), delay, activator, caller);
      }
    }
    // Self-explanatory wrappers for ppmod functions
    entclasses[i].Fire <- function (action = "Use", value = "", delay = 0.0, activator = null, caller = null) {
      return ::EntFireByHandle(this, action, value.tostring(), delay, activator, caller);
    }
    entclasses[i].AddOutput <- function (output, target, input = "Use", value = "", delay = 0, max = -1) {
      return ::ppmod.addoutput(this, output, target, input, value, delay, max);
    }
    entclasses[i].AddScript <- function (output, scr = "", delay = 0, max = -1, passthrough = false) {
      return ::ppmod.addscript(this, output, scr, delay, max, passthrough);
    }
    entclasses[i].RunScript <- function (scr) {
      return ::ppmod.runscript(this, scr);
    }
    entclasses[i].SetMoveParent <- function (_parent) {
      return ::ppmod.setparent(this, _parent);
    }
    entclasses[i].SetHook <- function (input, scr, max = -1) {
      return ::ppmod.hook(this, input, scr, max);
    }
    // Overwrite GetScriptScope to first create/validate the scope
    // This makes it safer and more comfortable to to access script scopes
    entclasses[i].DoGetScriptScope <- entclasses[i].GetScriptScope;
    entclasses[i].GetScriptScope <- function () {
      if (!this.ValidateScriptScope()) throw "Could not validate entity script scope";
      return this.DoGetScriptScope();
    }
  } catch (e) {
    // Classes may fail to be modified if they've already been instantiated
    // First, obtain the name of the class as a string
    local classname;
    switch (entclasses[i]) {
      case CBaseEntity: classname = "CBaseEntity"; break;
      case CBaseAnimating: classname = "CBaseAnimating"; break;
      case CBaseFlex: classname = "CBaseFlex"; break;
      case CBasePlayer: classname = "CBasePlayer"; break;
      case CEnvEntityMaker: classname = "CEnvEntityMaker"; break;
      case CLinkedPortalDoor: classname = "CLinkedPortalDoor"; break;
      case CPortal_Player: classname = "CPortal_Player"; break;
      case CPropLinkedPortalDoor: classname = "CPropLinkedPortalDoor"; break;
      case CSceneEntity: classname = "CSceneEntity"; break;
      case CTriggerCamera: classname = "CTriggerCamera"; break;
    }
    // Then, print a warning to the console
    printl("[ppmod] Warning: failed to modify " + classname + " class: " + e);
  }
}

/****************/
// Control flow //
/****************/

// Creates a logic_relay to use as a timer for calling the input script
::ppmod.wait <- function (scr, sec, name = "") {

  // Create an optionally named logic_relay
  local relay = Entities.CreateByClassname("logic_relay");
  if (name) relay.__KeyValueFromString("Targetname", name);

  // Use ppmod.addscript to attach the callback script
  ppmod.addscript(relay, "OnTrigger", scr, 0, 1);
  // Trigger and destroy the relay after the specified amount of seconds
  EntFireByHandle(relay, "Trigger", "", sec, null, null);
  relay.__KeyValueFromInt("SpawnFlags", 1);

  // Return the relay handle
  return relay;

}

// Creates a logic_timer to use as a loop for the input script
::ppmod.interval <- function (scr, sec = 0.0, name = "") {

  // Create an optionally named logic_timer
  local timer = Entities.CreateByClassname("logic_timer");
  if (name) timer.__KeyValueFromString("Targetname", name);

  // Use ppmod.addscript to attach the callback script
  ppmod.addscript(timer, "OnTimer", scr);
  // Configure the timer to run on the specified interval
  EntFireByHandle(timer, "RefireTime", sec.tostring(), 0.0, null, null);
  EntFireByHandle(timer, "Enable", "", 0.0, null, null);

  // Return the timer handle
  return timer;

}

// Time the execution of the input script using console ticks
::ppmod.ontick <- function (scr, pause = true, timeout = -1) {

  // If the input is a string, compile it into a function
  if (typeof scr == "string") scr = compilestring(scr);
  // Validate the input script argument
  if (typeof scr != "function") throw "ontick: Invalid script argument";

  // Add the input to the script queue
  if (timeout == -1) scr = "ppmod.scrq_get(" + ppmod.scrq_add(scr, -1) + ")()";
  else scr = "ppmod.scrq_get(" + ppmod.scrq_add(scr, 1) + ")()";

  // If the game is paused and pause == true, recurse on the next tick and exit
  if (pause && FrameTime() == 0.0) {
    SendToConsole("script ppmod.ontick(\"" + scr + "\", true, " + timeout + ")");
    return;
  }

  // A timeout of -1 indicates that the script should run on every tick, indefinitely
  if (timeout == -1) {
    SendToConsole("script " + scr + ";script ppmod.ontick(\"" + scr + "\", " + pause + ")");
    return;
  }
  // If timeout has reached 0, call the attached script and exit
  if (timeout == 0) return SendToConsole("script " + scr);
  // Otherwise, recurse on the next tick with a decremented timeout
  SendToConsole("script ppmod.ontick(\"" + scr + "\", " + pause + ", " + (timeout - 1) + ")");

}

// Runs the input script on map start or save load
::ppmod.onauto <- function (scr, onload = false) {

  // Create a logic_auto for listening to events on which to run the script
  local auto = Entities.CreateByClassname("logic_auto");

  // In online multiplayer games, we delay spawning until both players are ready
  if (IsMultiplayer()) scr = function ():(scr) {

    // Create a table to allow for accessing the interval from within itself
    local ref = { interval = null };

    // Set up an interval to wait for blue (the host) to spawn
    ref.interval = ppmod.interval(function ():(scr, ref) {

      // Find the host player, typically the first entity named "blue"
      local blue = Entities.FindByName(null, "blue");
      // Fall back to the first player handle if "blue" wasn't found
      if (!blue || !blue.IsValid() || blue.GetClassname() != "player") {
        blue = Entities.FindByClassname(null, "player");
      }
      // If no host player was found, continue
      if (!blue || !blue.IsValid()) return;

      // Host was found, stop the interval
      ref.interval.Destroy();

      // If on split-screen, we're done, run the script
      if (IsLocalSplitScreen()) {
        if (typeof scr == "string") return compilestring(scr)();
        return scr();
      }

      // Find the lowest significant point of the world's bounding box estimate
      local ent = null, lowest = 0, curr;
      while (ent = Entities.Next(ent)) {
        // Skip invalid handles
        if (!ent.IsValid()) continue;
        // Keep track of the lowest point in the map
        curr = ent.GetOrigin().z + ent.GetBoundingMins().z;
        if (curr < lowest) lowest = curr;
      }
      // Additional decrement just to make sure we're below anything significant
      lowest -= 1024.0;

      // We move the host below the map and wait until they are teleported back up
      // This happens once both players finish connecting in networked games
      blue.SetOrigin(Vector(0, 0, lowest));

      // Set up an interval to wait for orange (the second player) to spawn
      ref.interval = ppmod.interval(function ():(blue, lowest, scr, ref) {

        // Find the second player, typically the first entity named "red"
        local red = Entities.FindByClassname(null, "red");
        // Fall back to the player handle after the host's if "red" wasn't found
        if (!red || !red.IsValid() || red.GetClassname() != "player") {
          red = Entities.FindByClassname(blue, "player");
        }
        // If red was not found, or blue is still under the map, continue
        if (!red || !red.IsValid() || blue.GetOrigin().z <= lowest) return;

        // Run the input script
        if (typeof scr == "string") compilestring(scr)();
        else scr();
        // Red was found, stop the interval
        ref.interval.Destroy();

      });

    });

  };

  // Attach the script to map start events
  ppmod.addscript(auto, "OnNewGame", scr);
  ppmod.addscript(auto, "OnMapTransition", scr);
  // Optionally, attach to save load events
  if (onload) ppmod.addscript(auto, "OnLoadGame", scr);
  // Return the logic_auto
  return auto;

}

// Works around script timeouts by catching the exception they throw
::ppmod.detach <- function (scr, args, stack = null) {

  // Validate the callback argument
  if (typeof scr != "function") throw "detach: Invalid callback argument";
  // Retrieve a stack trace to the line on which ppmod.detach was called
  if (stack == null) stack = getstackinfos(2);

  // Run the input function in a try/catch block
  try { scr(args) }
  catch (e) {

    // If the exception is caused by SQQuerySuspend, recurse
    if (e == "Script terminated by SQQuerySuspend") {
      return ppmod.detach(scr, args, stack);
    }
    // Otherwise, mimic error output using the stack trace
    printl("\nAN ERROR HAS OCCURED [" + e + "]");
    printl("Caught within ppmod.detach in file " + stack.src + " on line " + stack.line + "\n");

  }

}

/********************/
// Player interface //
/********************/

// Constructor for the pplayer prototypal class
// This returns a ppromise, which is why it can't be an actual class
::ppmod.player <- function (player) {

  // Validate the input entity handle
  if (!ppmod.validate(player)) throw "player: Invalid entity handle";
  if (!(player instanceof CBasePlayer)) throw "player: Entity is not a player";
  if (!player.ValidateScriptScope()) throw "player: Could not validate entity script scope";

  // If the given player already has a pplayer instance, return that
  local scope = player.GetScriptScope();
  if ("pplayer" in scope) return scope.pplayer;

  // Create the prototypal ppmod.player instance
  local pplayer = {
    // Keep track of the underlying player handle
    ent = player,
    // Store the logic_playerproxy (assigned later)
    proxy = null,
    // Create a logic_measure_movement for getting player eye angles
    eyes = Entities.CreateByClassname("logic_measure_movement"),
    // Create a game_ui for listening to player movement inputs
    gameui = Entities.CreateByClassname("game_ui"),
    // Keep track of whether the player is grounded
    groundstate = false
  };
  // Assign this new instance to the player's script scope
  scope.pplayer <- pplayer;

  // One logic_playerproxy is required for registering jumping and ducking
  // This breaks if more than one is created, so we use an existing one if available
  pplayer.proxy = Entities.FindByClassname(null, "logic_playerproxy");
  if (!pplayer.proxy) pplayer.proxy = Entities.CreateByClassname("logic_playerproxy");

  // Set up the logic_measure_movement entity for more accurate view angles
  // Generate a unique name for the entity
  local eyename = "pplayer_eyes_" + Time();
  // Set MeasureType to measure eye position
  pplayer.eyes.__KeyValueFromInt("MeasureType", 1);
  // Point the entity back at itself
  pplayer.eyes.__KeyValueFromString("Targetname", eyename);
  pplayer.eyes.__KeyValueFromString("TargetReference", eyename);
  pplayer.eyes.__KeyValueFromString("Target", eyename);
  // The MeasureReference doesn't update unless set with the input
  EntFireByHandle(pplayer.eyes, "SetMeasureReference", eyename, 0.0, null, null);

  /**
   * The properties of logic_measure_movement seem to search for entities by
   * targetname exclusively. This function sets the player's name to a unique
   * string for just long enough to update MeasureTarget, and then sets it
   * back to what it was right away.
   */
  local targeteyes = function ():(pplayer) {

    // Store the current player name and generate a unique temporary name
    local oldname = pplayer.ent.GetName()
    local newname = "pplayer_ent_" + Time();

    /**
     * Push these inputs to the entity I/O queue back to back, one by one.
     * This ensures that we're changing the name for only as long as is
     * necessary, and doesn't let any other inputs get in between these.
     */
    EntFireByHandle(pplayer.ent, "AddOutput", "Targetname " + newname, 0.0, null, null);
    EntFireByHandle(pplayer.eyes, "SetMeasureTarget", newname, 0.0, null, null);
    // Use the script queue to reset the player's targetname
    // This retains full accuracy, as to not drop any special characters
    local scrqidx = ppmod.scrq_add(function (self):(oldname) { self.__KeyValueFromString("Targetname", oldname) }, 1);
    EntFireByHandle(pplayer.ent, "RunScriptCode", "ppmod.scrq_get("+ scrqidx +")(self)", 0.0, null, null);

  };

  // The MeasureTarget must be updated on each game load
  targeteyes();
  local auto = Entities.CreateByClassname("logic_auto");
  auto.__KeyValueFromString("OnMapSpawn", "!self\x001BRunScriptCode\x001Bppmod.scrq_get(" + ppmod.scrq_add(targeteyes, -1) + ")()\x001B0\x001B-1");

  // Enable the logic_measure_movement entity
  EntFireByHandle(pplayer.eyes, "Enable", "", 0.0, null, null);

  // Set the roll angle of pplayer.eyes to a silly value
  // This lets us later wait for the entity to be fully initialized
  pplayer.eyes.SetAngles(0.0, 0.0, 370.0);

  // Set up and activate the game_ui entity
  pplayer.gameui.__KeyValueFromInt("FieldOfView", -1);
  EntFireByHandle(pplayer.gameui, "Activate", "", 0.0, player, null);

  // Create a table for internal values
  local internal = {
    velprev = 0,
    gravtrig = null,
    landscr = [],
    interval = null
  };

  // Set up a simple loop for watching if the player is grounded
  ppmod.interval(function ():(pplayer, internal) {

    // Get the player's velocity along the Z axis
    local vel = pplayer.ent.GetVelocity().z;

    // If the velocity has been non-zero for two ticks, consider the player ungrounded
    if (internal.velprev != 0.0 && vel != 0.0) pplayer.groundstate = false;
    // If the player was just moving down and has now stopped, consider them grounded
    else if (internal.velprev <= 0.0 && vel == 0.0 && !pplayer.groundstate) {
      pplayer.groundstate = true;
      // Run each attached pplayer.land handler
      for (local i = 0; i < internal.landscr.len(); i ++) internal.landscr[i]();
    }

    // Update the velocity of the previous tick
    internal.velprev = vel;

  });

  // Set up a trigger_gravity for modifying the player's local gravity
  ppmod.trigger(player.GetOrigin() + Vector(0, 0, 36.5), Vector(16, 16, 36), "trigger_gravity", Vector(), true).then(function (trigger):(player, internal) {

    // Disable the trigger by default
    trigger.__KeyValueFromFloat("Gravity", 1.0);
    EntFireByHandle(trigger, "Disable", "", 0.0, null, null);
    // Store the trigger in the internal table for later verification
    internal.gravtrig = trigger;

    // Update the trigger position on an interval
    // If simply parented, the trigger won't have any effect
    ppmod.interval(function ():(trigger, player) {
      trigger.SetAbsOrigin(player.GetCenter());
    });

  });

  // Checks if the player is holding a physics prop
  pplayer.holding <- function ():(player) {

    /**
     * When a player picks up a prop, a player_pickup entity is created
     * and attached to the player. If we can find such an entity, that
     * means the player is holding something.
     */
    local ent = null;
    while (ent = Entities.FindByClassname(ent, "player_pickup")) {
      if (ent.GetMoveParent() == player) return true;
    }
    return false;

  };

  // Attaches a function to the event of the player using the jump input
  pplayer.jump <- function (scr):(pplayer) {
    local scrqstr = "ppmod.scrq_get(" + ppmod.scrq_add(scr) + ")()";
    ppmod.addoutput(pplayer.proxy, "OnJump", pplayer.ent, "RunScriptCode", "if(self==activator)" + scrqstr);
  };
  // Attaches a function to the event of the player landing on solid ground
  pplayer.land <- function (scr):(internal) {
    // Validate the input script argument
    if (typeof scr == "string") scr = compilestring(scr);
    if (typeof scr != "function") throw "pplayer.land: Invalid script argument";
    // Push the script to the array of landing handlers
    internal.landscr.push(scr);
  };
  // Attaches a function to the event of the player finishing the crouching animation
  pplayer.ducked <- function (scr):(pplayer) {
    local scrqstr = "ppmod.scrq_get(" + ppmod.scrq_add(scr) + ")()";
    ppmod.addoutput(pplayer.proxy, "OnDuck", pplayer.ent, "RunScriptCode", "if(self==activator)" + scrqstr);
  };
  // Attaches a function to the event of the player finishing the uncrouching animation
  pplayer.unduck <- function (scr):(pplayer) {
    local scrqstr = "ppmod.scrq_get(" + ppmod.scrq_add(scr) + ")()";
    ppmod.addoutput(pplayer.proxy, "OnUnDuck", pplayer.ent, "RunScriptCode", "if(self==activator)" + scrqstr);
  };
  // Returns true if the player is in the process of ducking/unducking, false otherwise
  pplayer.ducking <- function ():(player) {
    return player.EyePosition().z - player.GetOrigin().z < 63.999;
  };
  // Returns true if the player is on the ground, false otherwise
  pplayer.grounded <- function ():(pplayer) {
    return pplayer.groundstate;
  };
  // Attaches a function to the event of the player giving a certain action input
  pplayer.input <- function (str, scr):(pplayer) {
    if (str[0] == '+') str = "pressed" + str.slice(1);
    else str = "unpressed" + str.slice(1);
    ppmod.addscript(pplayer.gameui, str, scr);
  };
  // Sets the player's gravity scale to the given value
  pplayer.gravity <- function (gravity):(internal) {
    // Disable the trigger if gravity is 1.0 (default), enable otherwise
    if (gravity == 1.0) EntFireByHandle(internal.gravtrig, "Disable", "", 0.0, null, null);
    else EntFireByHandle(internal.gravtrig, "Enable", "", 0.0, null, null);
    // Zero values have no effect, this is hacky but works well enough
    if (gravity == 0.0) internal.gravtrig.__KeyValueFromString("Gravity", "0.0000000000000001");
    else internal.gravtrig.__KeyValueFromFloat("Gravity", gravity);
  };

  // Recalculates the player's friction for the current tick
  pplayer.friction <- function (fric, ftime = null, grounded = null):(pplayer) {

    // Don't touch velocity if the player isn't grounded
    if (grounded == false) return;
    // If no grounded parameter was provided, use pplayer.groundstate
    if (grounded == null && !pplayer.groundstate) return;

    // If no frame time parameter was provided, use FrameTime()
    if (ftime == null) ftime = FrameTime();

    // Obtain the player's velocity, its normal vector and amplitude
    local vel = pplayer.ent.GetVelocity();
    local veldir = vel + Vector();
    local absvel = veldir.Norm();

    // Cancel out existing friction calculations
    if (absvel >= 100.0) {
      vel *= 1.0 / (1.0 - ftime * 4.0);
    } else {
      vel += veldir * (ftime * 400.0);
    }

    // Simulate our own friction
    if (absvel >= 100.0) {
      vel *= 1.0 - ftime * fric;
    } else if (fric > 0.0) {
      if (fric / 0.6 < absvel) {
        vel -= veldir * (ftime * 400.0);
      } else if (absvel != 0.0) {
        vel.x = 0.0;
        vel.y = 0.0;
      }
    }

    // Apply calculated velocity
    pplayer.ent.SetVelocity(vel);

  };

  // Simulates player movement for one time step using Source engine movement physics
  pplayer.movesim <- function (move, accel = 10.0, fric = 0.0, sfric = 0.25, grav = null, ftime = null, eyes = null, grounded = null):(player, pplayer) {

    // Set default values for unset parameters
    if (grav == null) grav = Vector(0, 0, -600);
    if (ftime == null) ftime = FrameTime();
    if (eyes == null) eyes = pplayer.eyes;
    if (grounded == null) grounded = pplayer.grounded();

    // If in the air, scale down all acceleration by the "surface friction" parameter
    if (!grounded) accel *= sfric;

    // Obtain the player velocity in full form and along just the X/Y axis
    local vel = player.GetVelocity();
    local horizvel = Vector(vel.x, vel.y);

    // If necessary, calculate friction
    if (fric != 0.0 && grounded) {
      // Obtain the normal vector and amplitude of the player's horizontal velocity
      // This avoids issues when grounded == true but the player isn't actually grounded
      local veldir = horizvel + Vector();
      local absvel = veldir.Norm();
      // Calculate friction for this time step
      if (absvel >= 100.0) {
        vel *= 1.0 - ftime * fric;
      } else if (fric / 0.6 < absvel) {
        vel -= veldir * (ftime * 400.0);
      } else if (absvel != 0.0) {
        vel.x = 0.0;
        vel.y = 0.0;
      }
    }

    // Obtain the forward and left vectors, with the Z axis removed
    local forward = eyes.GetForwardVector().Normalize2D();
    local left = eyes.GetLeftVector().Normalize2D();

    // Calculate the direction and speed in which the player "wishes" to move
    local wishvel = Vector();
    wishvel.x = forward.x * move.y + left.x * move.x;
    wishvel.y = forward.y * move.y + left.y * move.x;
    local wishspeed = wishvel.Norm();

    // Calculate how much to accelerate the player by
    local currspeed = horizvel.Dot(wishvel);
    local addspeed = wishspeed - currspeed;
    local accelspeed = accel * ftime * wishspeed;
    if (accelspeed > addspeed) accelspeed = addspeed;

    // Calculate and apply the final player velocity
    player.SetVelocity(vel + wishvel * accelspeed + grav * ftime);

  };

  /**
   * Resolve the ppromise once pplayer.eyes returns a valid roll angle and
   * once a trigger_gravity has been created. These are the only asynchronous
   * operations, hence why we're checking for these in particular.
   */
  return ppromise(function (resolve, reject):(pplayer, internal) {

    internal.interval = ppmod.interval(function ():(resolve, pplayer, internal) {
      // Check for proper setup of pplayer.eyes and gravtrig
      if (pplayer.eyes.GetAngles().z == 370.0) return;
      if (!internal.gravtrig) return;
      // Stop the interval and resolve with the pplayer instance
      internal.interval.Destroy();
      resolve(pplayer);
    });

  });

}

// Constructor for the ppmod.portal prototypal class
// Provides utilities for working with portals
::ppmod.portal <- function (portal) {

  // Most properties are stored in the portal entity's script scope
  if (!portal.ValidateScriptScope()) throw "portal: Could not validate script scope";
  local scope = portal.GetScriptScope();
  // If an instance already exists in the script scope, return that
  if ("ppmod_portal" in scope) return scope.ppmod_portal;

  // Create a trigger for detecting collisions with the portal
  local trigger = Entities.CreateByClassname("trigger_multiple");

  // Position and scale the trigger to submerge the portal
  trigger.SetAbsOrigin(portal.GetOrigin());
  trigger.SetForwardVector(portal.GetForwardVector());
  trigger.SetSize(Vector(-8, -32, -56), Vector(0, 32, 56));
  // Parent the trigger to the portal
  EntFireByHandle(trigger, "SetParent", "!activator", 0.0, portal, null);
  // Make the trigger non-solid and activated by clients, NPCs, and props
  trigger.__KeyValueFromInt("Solid", 3);
  trigger.__KeyValueFromInt("CollisionGroup", 10);
  trigger.__KeyValueFromInt("SpawnFlags", 11);
  // Enable the trigger
  EntFireByHandle(trigger, "Enable", "", 0.0, null, null);

  // Keeps track of when the last teleport occurred
  scope.ppmod_portal.tptime <- 0.0;
  // Stores all attached OnTeleport functions
  scope.ppmod_portal.tpfunc <- [];

  // Manages trigger OnEndTouch events (something leaving the trigger volume)
  local scrq_idx = ppmod.scrq_add(function (ent):(scope) {
    // Using runscript lets us push this to the end of the entity I/O queue
    ppmod.runscript("worldspawn", function ():(ent, scope) {

      /**
       * Whenever an entity teleports through a portal, the
       * OnEntityTeleportFromMe output updates tptime with the current
       * server time. We can compare this to when the trigger fires
       * OnEndTouch, and if they're the same, we must be looking at the
       * same entity. This lets us retrieve it as the activator.
       */
      local ticks_now = (Time() / FrameTime()).tointeger();
      local ticks_tp = (scope.ppmod_portal.tptime / FrameTime()).tointeger();

      // Check if the two time reports match
      // Currently allows for a 1 tick tolerance, ideally 0 one day
      if (ticks_now - ticks_tp > 1) return;

      // If it did, something must've teleported - call attached functions
      for (local i = 0; i < scope.ppmod_portal.tpfunc.len(); i ++) {
        scope.ppmod_portal.tpfunc[i](ent);
      }

    });
  }, -1);

  // Attach OnEndTouch and OnEntityTeleportFromMe outputs to the trigger and portal, respectively
  trigger.__KeyValueFromString("OnEndTouch", "worldspawn\x001BRunScriptCode\x001Bppmod.scrq_get(" + scrq_idx + ")(activator)\x001B0\x001B-1");
  portal.__KeyValueFromString("OnEntityTeleportFromMe", "!self\x001BRunScriptCode\x001Bself.GetScriptScope().ppmod_portal.tptime<-Time()\x001B0\x001B-1");

  // Attaches a function to the event of a portal teleporting something
  scope.ppmod_portal.OnTeleport <- function (func):(scope) {
    scope.ppmod_portal.tpfunc.push(func);
  };

  // Internal utility function - sets up a new func_portal_detector
  local new_detector = function (allids):(portal) {

    // Create the func_portal_detector entity
    local detector = Entities.CreateByClassname("func_portal_detector");

    // Place it at the portal's origin with a minimal bounding box
    detector.__KeyValueFromInt("Solid", 3);
    detector.__KeyValueFromInt("CollisionGroup", 10);
    detector.SetAbsOrigin(portal.GetOrigin());
    detector.SetSize(Vector(-0.1, -0.1, -0.1), Vector(0.1, 0.1, 0.1));
    // Whether to match for all portal linkage IDs
    detector.__KeyValueFromInt("CheckAllIDs", allids);

    // Enable and return the detector entity
    EntFireByHandle(detector, "Enable", "", 0.0, null, null);
    return detector;

  };

  // Returns a ppromise that resolves to the portal's color index
  scope.ppmod_portal.GetColor <- function ():(new_detector) {
    return ppromise(function (resolve, reject):(new_detector) {
      // Add the resolve callback to the script queue
      local scrq_idx = ppmod.scrq_add(resolve, 1);
      // Create a detector and listen for its OnStartTouchPortalX inputs
      local detector = new_detector(1);
      detector.__KeyValueFromString("OnStartTouchPortal1", "!self\x001BRunScriptCode\x001Bppmod.scrq_get(" + scrq_idx + ")(1);self.Destroy()\x001B0\x001B1");
      detector.__KeyValueFromString("OnStartTouchPortal2", "!self\x001BRunScriptCode\x001Bppmod.scrq_get(" + scrq_idx + ")(2);self.Destroy()\x001B0\x001B1");
    });
  };

  // Returns a ppromise that resolves to true if the portal is active, false otherwise
  scope.ppmod_portal.GetActivatedState <- function ():(new_detector) {
    return ppromise(function (resolve, reject):(new_detector) {
      // Add the resolve callback to the script queue
      local scrq_idx = ppmod.scrq_add(resolve, 1);
      // Create a detector and listen for its OnStartTouchLinkedPortal output
      local detector = new_detector(1);
      detector.__KeyValueFromString("OnStartTouchLinkedPortal", "!self\x001BRunScriptCode\x001Bppmod.scrq_get(" + scrq_idx + ")(true);self.Destroy()\x001B0\x001B1");
      // Connect OnUser1 to resolve(false)
      detector.__KeyValueFromString("OnUser1", "!self\x001BRunScriptCode\x001Bif(self.IsValid())ppmod.scrq_get(" + scrq_idx + ")(false)\x001B0\x001B1");
      detector.__KeyValueFromString("OnUser1", "!self\x001BKill\x001B\x001B0\x001B1");
      // Call FireUser1, which sets up a sort of race condition
      // If OnStartTouchLinkedPortal gets there first, this won't do anything
      EntFireByHandle(detector, "FireUser1", "", 0.0, null, null);
    });
  };

  // Returns a ppromise that resolves to the linkage group ID of the portal
  scope.ppmod_portal.GetLinkageGroupID <- function ():(new_detector) {
    return ppromise(function (resolve, reject):(new_detector) {

      // Create a detector that activates only for a specific linkage group
      local detector = new_detector(0);
      // Keep track of the currently observed linkage group
      local params = { id = 0 };

      // Checks whether the portal is of the currently observed linkage group
      local check = function ():(detector, params) {
        // If the detector has been deleted, we're done
        if (!detector.IsValid()) return;
        // Update the detector's target linkage group ID
        detector.__KeyValueFromInt("LinkageGroupID", ++params.id);
        // Update the detector's position and re-enable it to get outputs to refire
        detector.SetAbsOrigin(detector.GetOrigin());
        EntFireByHandle(detector, "Enable", "", 0.0, null, null);
        // Call FireUser1 to recurse this check
        EntFireByHandle(detector, "FireUser1", "", 0.0, null, null);
      };

      // Store all relevant parameters in the script queue
      local scrq_idx_resolve = ppmod.scrq_add(resolve, 1);
      local scrq_idx_params = ppmod.scrq_add(params, 1);
      local scrq_idx_check = ppmod.scrq_add(check, -1);

      /**
       * If the detector outputs OnStartTouchPortal, we resolve with the
       * currently observed linkage ID, clean up the script queue, and kill
       * the detector. Otherwise, if OnUser1 is outputted first, we
       * continue iterating until the right linkage ID is found.
       */
      detector.__KeyValueFromString("OnStartTouchPortal", "!self\x001BRunScriptCode\x001Bppmod.scrq_get(" + scrq_idx_resolve + ")(ppmod.scrq_get(" + scrq_idx_params + ").id);ppmod.scrq[" + scrq_idx_check + "] = null;self.Destroy()\x001B0\x001B1");
      detector.__KeyValueFromString("OnUser1", "!self\x001BRunScriptCode\x001Bif(self.IsValid())ppmod.scrq_get(" + scrq_idx_check + ")()\x001B0\x001B-1");

      // Call FireUser1 to start iterating through linkage IDs
      EntFireByHandle(detector, "FireUser1", "", 0.0, null, null);

    });
  };

  // Returns a ppromise that resolves to a handle of this portal's active linked partner
  scope.ppmod_portal.GetPartnerInstance <- function ():(portal, GetLinkageGroupID) {
    return ppromise(function (resolve, reject):(portal, GetLinkageGroupID) {
      // First, obtain the linkage group ID of this portal
      GetLinkageGroupID().then(function (id):(resolve, portal) {

        // Create a recursive function for finding the other portal
        local param = { next = null };
        param.next = function (curr):(id, resolve, portal, param) {

          // Get the handle of the next portal
          curr = Entities.FindByClassname(curr, "prop_portal");
          // If we've wrapped around to null, no partner was found
          if (curr == null) return resolve(null);
          // If we've encountered the same portal we started with, continue
          if (curr == portal) return param.next(curr);

          // Obtain a ppmod.portal instance of the current portal
          local pportal = ppmod.portal(curr);
          // Obtain the linkage group ID of the current portal
          pportal.GetLinkageGroupID().then(function (currid):(resolve, param, curr, pportal, id) {

            // If the linkage IDs do not match, continue
            if (currid != id) return param.next(curr);

            // If the current portal is active, we've found it. Otherwise, continue.
            pportal.GetActivatedState().then(function (state):(resolve, param, curr) {
              if (state) return resolve(curr);
              return param.next(curr);
            });

          });

        };
        // Start the recursion
        param.next(null);

      });
    });
  };

  // Return the ppmod.portal prototypal class instance
  return scope.ppmod_portal;

}

// Stores all attached ppmod.onportal callback functions
local onportalfunc = [];
// Attaches a function to be called on every portal shot
::ppmod.onportal <- function (scr):(onportalfunc) {

  // If the input is a string, compile it into a function
  if (typeof scr == "string") scr = compilestring(scr);
  // Validate the input script argument
  if (typeof scr != "function") throw "onportal: Invalid script argument";

  // Push the function to the attached function array
  onportalfunc.push(scr);

  // Return if the setup has already been run before
  if (onportalfunc.len() != 1) return;

  // Handles portal OnPlacedSuccessfully outputs
  local scrq_idx = ppmod.scrq_add(function (portal, first):(onportalfunc) {
    // Using runscript lets us push this to the end of the entity I/O queue
    ppmod.runscript("worldspawn", function ():(portal, first, onportalfunc) {

      local pgun = null;
      local color = null;

      // Iterate through all weapon_portalgun entities
      while (pgun = Entities.FindByClassname(pgun, "weapon_portalgun")) {

        // Validate the entity and its script scope
        if (!pgun.IsValid()) continue;
        if (!pgun.ValidateScriptScope()) continue;
        // Retrieve the script scope
        local scope = pgun.GetScriptScope();

        /**
         * Determine the color of the portal by finding a portalgun which
         * fired one of its two portals at the same time as this check was
         * called. The input which matches the time marks the color index.
         */
        if (scope.ppmod_onportal_time1 == Time()) {
          color = 1;
          break;
        }
        if (scope.ppmod_onportal_time2 == Time()) {
          color = 2;
          break;
        }

      }

      // Construct a table with information about the portal placement
      local info = {
        portal = portal, // Portal entity handle
        weapon = pgun, // Portal gun handle (null if none)
        color = color, // Portal color index (1 or 2)
        first = first // Whether this is the first appearance of the portal
      };

      // Call each attached function, passing the table constructed above
      for (local i = 0; i < onportalfunc.len(); i ++) {
        onportalfunc[i](info);
      }

    });
  }, -1);

  // Check for new portals and portalguns on an interval
  ppmod.interval(function ():(scrq_idx) {

    // Entity iterator
    local curr = null;

    // Iterate through all new weapon_portalgun entities
    while (curr = Entities.FindByClassname(curr, "weapon_portalgun")) {
      // Validate the entity and its script scope
      if (!curr.IsValid()) continue;
      if (!curr.ValidateScriptScope()) continue;

      // Retrieve the script scope, continue if setup already performed
      local scope = curr.GetScriptScope();
      if ("ppmod_onportal_time1" in scope) continue;

      // Keep track of the time when each portal is fired
      scope.ppmod_onportal_time1 <- 0.0;
      scope.ppmod_onportal_time2 <- 0.0;

      // Attach the OnFiredPortalX functions for updating the time variables
      curr.__KeyValueFromString("OnFiredPortal1", "!self\x001BRunScriptCode\x001Bself.GetScriptScope().ppmod_onportal_time1<-Time()\x001B0\x001B-1");
      curr.__KeyValueFromString("OnFiredPortal2", "!self\x001BRunScriptCode\x001Bself.GetScriptScope().ppmod_onportal_time2<-Time()\x001B0\x001B-1");

    }

    // Iterate through all new prop_portal entities
    while (curr = Entities.FindByClassname(curr, "prop_portal")) {
      // Validate the entity and its script scope
      if (!curr.IsValid()) continue;
      if (!curr.ValidateScriptScope()) continue;

      // Retrieve the script scope, continue if setup already performed
      local scope = curr.GetScriptScope();
      if ("ppmod_onportal_flag" in scope) continue;

      // Call the check function each time this portal is placed
      curr.__KeyValueFromString("OnPlacedSuccessfully", "!self\x001BRunScriptCode\x001Bppmod.scrq_get("+ scrq_idx +")(self,false)\x001B0\x001B-1");
      // Call the check function now, indicating that this is the first encounter
      ppmod.scrq_get(scrq_idx)(curr, true);

      // Mark setup as complete
      scope.ppmod_onportal_flag <- true;

    }

  });

}

/*******************/
// World interface //
/*******************/

// Creates an entity using a console command, returns a promise that resolves to its handle
::ppmod.create <- function (cmd, key = null) {

  // Validate the input arguments
  if (typeof cmd != "string") throw "create: Invalid command argument";
  if (key != null && typeof key != "string") throw "create: Invalid key argument";

  // The key is the string used to look for the entity after spawning
  // If no key is provided, we guess it from the input command
  if (key == null) {
    // Get the first 17 characters (or less) of the command
    switch (cmd.slice(0, min(cmd.len(), 17))) {

      // These commands need to be handled separately
      case "ent_create_portal": key = "cube"; break;
      case "ent_create_paint_": key = "prop_paint_bomb"; break;

      default:
        // If the command has an argument, use that as the key
        if (cmd.find(" ") != null) {
          key = cmd.slice(cmd.find(" ") + 1);
          // If the argument is a model, prefix key with "models/"
          if (key.slice(-4) == ".mdl") key = "models/" + key;
          break;
        }
        // If provided only a model, assume we're using prop_dynamic_create
        if (cmd.slice(-4) == ".mdl") {
          key = "models/" + cmd;
          cmd = "prop_dynamic_create " + cmd;
          break;
        }
        // If all else fails, assume we're provided a classname, use ent_create
        key = cmd;
        cmd = "ent_create " + cmd;
        break;

    }
  }

  // Send the console command to create the entity
  SendToConsole(cmd);

  /**
   * Find the entity by passing the key to ppmod.prev. We send this as a
   * console command to take advantage of how console commands are executed
   * synchronously. This lets us make sure that the entity has spawned and
   * that we start looking for it as soon as we can.
   */
  return ppromise(function (resolve, reject):(cmd, key) {
    SendToConsole("script ppmod.scrq_get("+ ppmod.scrq_add(resolve, 1) +")(ppmod.prev(\""+ key +"\"))");
  });

}

// Creates entities in bulk using game_player_equip
// Returns a ppromise which resolves to a table of arrays with the created entities
::ppmod.give <- function (ents) {

  // Validate input table
  if (typeof ents != "table") throw "give: Invalid entity table";

  // This procedure requires a player handle, get the first available one
  local player = Entities.FindByClassname(null, "player");
  // Validate the player instance found to prevent game crashes
  if (!ppmod.validate(player)) throw "give: Failed to find valid player instance";
  // Create a temporary game_player_equip instance
  local equip = Entities.CreateByClassname("game_player_equip");

  // Assign keyvalues from the input table
  // game_player_equip uses keyvalue pairs to determine spawn quantities
  foreach (classname in ents) {
    equip.__KeyValueFromInt(classname, ents[clasname]);
  }

  // Spawn the items, then kill the entity
  EntFireByHandle(equip, "Use", "", 0.0, player, null);
  EntFireByHandle(equip, "Kill", "", 0.0, null, null);

  return ppromise(function (resolve, reject):(ents, amount) {
    // Use runscript to ensure we're retrieving the entities after creating them
    ppmod.runscript("worldspawn", function ():(resolve, ents, amount) {

      // Create an output table
      local output = {};
      // Entity iterator
      local ent = null;

      // Iterate over each spawned class to fetch the entities into an array
      foreach (classname in ents) {
        // Allocate an array for the entities
        output[classname] <- array(ents[classname]);
        // Iterate through all entities with a matching classname
        local i = 0;
        while (ent = Entities.FindByClassname(ent, classname)) {
          arr[i] = ent;
          /**
           * Overflow the pointer once we've reached the desired spawn amount.
           * This effectively makes it so that only the last entities of this
           * search remain in the array, albeit in no specific order.
           */
          if (++i == ents[classname]) i = 0;
        }
      }
      // Resolve the ppromise with the output table
      resolve(output);

    });
  });

}

// Creates a brush entity
::ppmod.brush <- function (pos, size, type = "func_brush", ang = Vector(), create = false) {

  // Validate input arguments
  if (typeof pos != "Vector") throw "brush: Invalid position argument";
  if (typeof size != "Vector") throw "brush: Invalid size argument";
  if (size.x < 0.0 || size.y < 0.0 || size.z < 0.0) throw "brush: Size must be positive on all axis";
  // The type argument may be either an entity handle or a string
  if (!ppmod.validate(type) && typeof type != "string") throw "brush: Invalid brush type argument";

  // If the create flag is set, use ppmod.create instead of CreateByClassname,
  // then call this same function again with the new brush and resolve with that.
  if (create) return ppromise(function (resolve, reject):(type, pos, size, ang) {
    ppmod.create(type).then(function (ent):(pos, size, ang, resolve) {
      resolve(ppmod.brush(pos, size, ent, ang));
    });
  });

  // If brush type was provided as a string, create a new brush
  // Otherwise, this will continue using `type` as a brush entity
  if (typeof type == "string") {
    type = Entities.CreateByClassname(type);
  }

  // Make the brush solid and rotatable
  type.__KeyValueFromInt("Solid", 3);
  // Set the position and angles of the brush
  type.SetAbsOrigin(pos);
  type.SetAngles(ang.x, ang.y, ang.z);
  // Scale the bounding box of the brush, centered on its origin
  type.SetSize(Vector() - size, size);

  // Return the entity handle of the new brush
  return type;

}

// Creates a brush entity with trigger properties
::ppmod.trigger <- function (pos, size, type = "trigger_once", ang = Vector(), create = false) {

  // If the create flag is set, call ppmod.brush with the create flag set
  // and await a response, then call this function again.
  if (create) return ppromise(function (resolve, reject):(pos, size, type, ang) {
    ppmod.brush(pos, size, type, ang, true).then(function (ent):(pos, size, ang, resolve) {
      resolve(ppmod.trigger(pos, size, ent, ang));
    });
  });

  // If trigger type was provided as a string, create a new brush
  // Otherwise, this will continue using `type` as a brush entity
  if (typeof type == "string") {
    type = ppmod.brush(pos, size, type, ang);
  }

  // Make the trigger non-solid
  type.__KeyValueFromInt("CollisionGroup", 10);
  // Turn on activation by clients by default
  type.__KeyValueFromInt("SpawnFlags", 1);
  // Enable the trigger
  EntFireByHandle(type, "Enable", "", 0.0, null, null);

  // If this is a trigger_once, make it disappear upon activation
  if (type.GetClassname() == "trigger_once") {
    type.__KeyValueFromString("OnStartTouch", "!self\x001BKill\x1B\x001B0\x001B1");
  }

  // Return the entity handle of the new trigger
  return type;

}

// Creates and sets up an env_projectedtexture
::ppmod.project <- function (material, pos, ang = Vector(90, 0, 0), simple = 0, far = 128.0) {

  // Validate input arguments
  if (typeof material != "string") throw "project: Invalid material argument";
  if (typeof pos != "Vector") throw "project: Invalid position argument";
  if (typeof ang != "Vector") throw "project: Invalid angles argument";
  if (typeof simple != "integer" && typeof simple != "boolean") throw "project: Invalid projection type";
  if (typeof far != "integer" && typeof far != "float") throw "project: Invalid projection distance";

  // Create the env_projectedtexture entity
  local texture = Entities.CreateByClassname("env_projectedtexture");

  // Set the texture position and projection angles
  texture.SetAbsOrigin(pos);
  texture.SetAngles(ang.x, ang.y, ang.z);
  // Set projection distance, projection type, and material name
  texture.__KeyValueFromFloat("FarZ", far);
  texture.__KeyValueFromInt("SimpleProjection", simple.tointeger());
  texture.__KeyValueFromString("TextureName", material);

  // Return a handle to the env_projectedtexture entity
  return texture;

}

// Creates and applies a static decal on a nearby surface
::ppmod.decal <- function (material, pos, ang = Vector(90, 0, 0), far = 8.0) {

  // Validate input arguments
  if (typeof material != "string") throw "decal: Invalid material argument";
  if (typeof pos != "Vector") throw "decal: Invalid position argument";
  if (typeof ang != "Vector") throw "decal: Invalid angles argument";
  if (typeof far != "integer" && typeof far != "float") throw "decal: Invalid projection distance";

  // Create the info_projecteddecal entity, used for applying the decal
  local decal = Entities.CreateByClassname("info_projecteddecal");

  // Set the decal position and projection angles
  decal.SetAbsOrigin(pos);
  decal.SetAngles(ang.x, ang.y, ang.z);
  // Set the name of the texture to be applied, and the projection distance
  decal.__KeyValueFromString("Texture", material);
  decal.__KeyValueFromFloat("Distance", far);
  // Activate the entity, applying the decal and removing itself
  EntFireByHandle(decal, "Activate", "", 0.0, null, null);

}

// Set up some dummy entites for simplifying ray-through-portal calculations
ppmod.onauto(function () {
  local p_anchor = Entities.CreateByClassname("info_target");
  local r_anchor = Entities.CreateByClassname("info_target");

  p_anchor.__KeyValueFromString("Targetname", "ppmod_portals_p_anchor");
  r_anchor.__KeyValueFromString("Targetname", "ppmod_portals_r_anchor");

  EntFireByHandle(r_anchor, "SetParent", "ppmod_portals_p_anchor", 0.0, null, null);
});

::ppmod.ray <- function (start, end, ent = null, world = true, portals = null, ray = null) {

  local formatreturn = function (fraction, ray, hitent = null):(start, end, ent, world, portals) {

    if (world) fraction = min(fraction, TraceLine(start, end, null));
    local dirvec = end - start;

    local output = {
      fraction = fraction,
      point = start + dirvec * fraction,
      entity = hitent
    };

    if (!portals) return output;
    if (typeof portals != "array") return output;
    if (portals.len() < 2) return output;

    // Check if we're intersecting the bounding box of one of the provided portals
    local portal = Entities.FindByClassnameWithin(null, "prop_portal", output.point, 1.0);
    if (portal != portals[0] && portal != portals[1]) return output;

    // Determine which portal is the other portal
    local other = (portal == portals[0]) ? portals[1] : portals[0];

    local p_anchor = Entities.FindByName(null, "ppmod_portals_p_anchor");
    local r_anchor = Entities.FindByName(null, "ppmod_portals_r_anchor");

    // Set portal anchor facing the entry portal
    p_anchor.SetForwardVector(Vector() - portal.GetForwardVector());

    // Set positions of anchors to entry portal origin and ray endpoint, respectively
    p_anchor.SetAbsOrigin(portal.GetOrigin());
    r_anchor.SetAbsOrigin(output.point);

    // Translate both anchor points to exit portal (r_anchor is parented to p_anchor)
    p_anchor.SetAbsOrigin(other.GetOrigin());

    // Calculate angles from vector of ray direction
    // First, normalize the vector to get a unit vector
    local len = dirvec.Norm();

    // Then, calculate yaw, pitch and roll in degrees
    local yaw = atan2(dirvec.y, dirvec.x) / PI * 180;
    local pitch = asin(-dirvec.z) / PI * 180;
    local roll = atan2(dirvec.z, sqrt(dirvec.x * dirvec.x + dirvec.y * dirvec.y)) / PI * 180;

    // Due to being parented, r_anchor's angles are usually relative to p_anchor
    // The "angles" keyvalue, however, is absolute
    r_anchor.__KeyValueFromString("angles", pitch + " " + yaw + " " + roll);
    // Finally, rotate the portal anchor to get ray starting position and direction
    p_anchor.SetForwardVector(other.GetForwardVector());

    local newstart = r_anchor.GetOrigin();

    // Check if the new starting point is behind the exit portal
    local offset = newstart - other.GetOrigin();
    local epsilon = 0.000001; // Some flat walls are not flat...

    if (other.GetForwardVector().x > epsilon && offset.x < -epsilon) return output;
    if (other.GetForwardVector().x < -epsilon && offset.x > epsilon) return output;

    if (other.GetForwardVector().y > epsilon && offset.y < -epsilon) return output;
    if (other.GetForwardVector().y < -epsilon && offset.y > epsilon) return output;

    if (other.GetForwardVector().z > epsilon && offset.z < -epsilon) return output;
    if (other.GetForwardVector().z < -epsilon && offset.z > epsilon) return output;

    local newend = r_anchor.GetOrigin() + r_anchor.GetForwardVector() * (len * (1.0 - fraction));

    return ppmod.ray(newstart, newend, ent, world, portals);

  };

  if (!ent) return formatreturn( 1.0, ray );

  local len, div;
  if (!ray) {
    local dir = end - start;
    len = dir.Norm();
    div = [1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z];
  } else {
    len = ray[0];
    div = ray[1];
  }

  // Defines behavior when multiple valid entries are provided - returns the lowest fraction among them
  if (typeof ent == "array") {

    // If an array contains only two Vectors, treat those instead as the origin point and half-widths of an entity, respectively
    local isbbox = false;
    if (ent.len() == 2) if (typeof ent[0] == "Vector" && typeof ent[1] == "Vector") {

      local pos = ent[0], size = ent[1];

      ent = {
        GetOrigin = function ():(pos) { return pos },
        GetAngles = function () { return Vector() },
        GetBoundingMaxs = function ():(size) { return size },
        GetBoundingMins = function ():(size) { return Vector() - size },
      };

      isbbox = true;

    }

    // Squirrel sucks, we can't just have an 'else' here
    if (!isbbox) {

      local closest = ppmod.ray(start, end, ent[0], false, portals, [len, div]);
      for (local i = 1; i < ent.len(); i ++) {
        local curr = ppmod.ray(start, end, ent[i], false, portals, [len, div]);
        if (curr.fraction < closest.fraction) closest = curr;
      }
      return formatreturn( closest.fraction, [len, div], closest.entity );

    }

  } else if (typeof ent == "string") {

    local next = ppmod.get(ent);
    local closest = ppmod.ray(start, end, next, false, portals, [len, div]);
    while (next = ppmod.get(ent, next)) {
      local curr = ppmod.ray(start, end, next, false, portals, [len, div]);
      if (curr.fraction < closest.fraction) closest = curr;
    }
    return formatreturn( closest.fraction, [len, div], closest.entity );

  }

  local pos = ent.GetOrigin();

  local mins = ent.GetBoundingMins();
  local maxs = ent.GetBoundingMaxs();

  local minmin = min(mins.x, min(mins.y, mins.z));
  local maxmax = max(maxs.x, max(maxs.y, maxs.z));

  if (pos.x + minmin > max(start.x, end.x)) return formatreturn( 1.0, [len, div] );
  if (pos.x + maxmax < min(start.x, end.x)) return formatreturn( 1.0, [len, div] );

  if (pos.y + minmin > max(start.y, end.y)) return formatreturn( 1.0, [len, div] );
  if (pos.y + maxmax < min(start.y, end.y)) return formatreturn( 1.0, [len, div] );

  if (pos.z + minmin > max(start.z, end.z)) return formatreturn( 1.0, [len, div] );
  if (pos.z + maxmax < min(start.z, end.z)) return formatreturn( 1.0, [len, div] );

  local ang = ent.GetAngles() * (PI / 180.0);
  local c1 = cos(ang.z);
  local s1 = sin(ang.z);
  local c2 = cos(ang.x);
  local s2 = sin(ang.x);
  local c3 = cos(ang.y);
  local s3 = sin(ang.y);

  local matrix = [
    [c2 * c3, c3 * s1 * s2 - c1 * s3, s1 * s3 + c1 * c3 * s2],
    [c2 * s3, c1 * c3 + s1 * s2 * s3, c1 * s2 * s3 - c3 * s1],
    [-s2, c2 * s1, c1 * c2]
  ];

  mins = [mins.x, mins.y, mins.z];
  maxs = [maxs.x, maxs.y, maxs.z];

  local bmin = [pos.x, pos.y, pos.z];
  local bmax = [pos.x, pos.y, pos.z];
  local a, b;

  for (local i = 0; i < 3; i ++) {
    for (local j = 0; j < 3; j ++) {
      a = (matrix[i][j] * mins[j]);
      b = (matrix[i][j] * maxs[j]);
      if(a < b) {
        bmin[i] += a;
        bmax[i] += b;
      } else {
        bmin[i] += b;
        bmax[i] += a;
      }
    }
  }

  if (
    start.x > bmin[0] && start.x < bmax[0] &&
    start.y > bmin[1] && start.y < bmax[1] &&
    start.z > bmin[2] && start.z < bmax[2]
  ) return formatreturn( 0.0, [len, div], ent );

  start = [start.x, start.y, start.z];

  local tmin = [0.0, 0.0, 0.0];
  local tmax = [0.0, 0.0, 0.0];

  for (local i = 0; i < 3; i ++) {
    if (div[i] >= 0) {
      tmin[i] = (bmin[i] - start[i]) * div[i];
      tmax[i] = (bmax[i] - start[i]) * div[i];
    } else {
      tmin[i] = (bmax[i] - start[i]) * div[i];
      tmax[i] = (bmin[i] - start[i]) * div[i];
    }
    if (tmin[0] > tmax[i] || tmin[i] > tmax[0]) return formatreturn( 1.0, [len, div] );
    if (tmin[i] > tmin[0]) tmin[0] = tmin[i];
    if (tmax[i] < tmax[0]) tmax[0] = tmax[i];
  }

  if (tmin[0] < 0) tmin[0] = 1.0;
  else tmin[0] /= len;

  return formatreturn( tmin[0], [len, div], ent );

}

::ppmod.inbounds <- function (point) {

  if (TraceLine(point, point + Vector(65536, 0, 0), null) == 1.0) return false;
  if (TraceLine(point, point - Vector(65536, 0, 0), null) == 1.0) return false;
  if (TraceLine(point, point + Vector(0, 65536, 0), null) == 1.0) return false;
  if (TraceLine(point, point - Vector(0, 65536, 0), null) == 1.0) return false;
  if (TraceLine(point, point + Vector(0, 0, 65536), null) == 1.0) return false;
  if (TraceLine(point, point - Vector(0, 0, 65536), null) == 1.0) return false;

  return true;

}

::ppmod.visible <- function (eyes, dest, fov = 90.0) {

  local start = eyes.GetOrigin();
  local fvec = (dest - start).Normalize();

  // Check if the destination is within the field of view
  if (eyes.GetForwardVector().Dot(fvec) < cos(fov * PI / 360)) return false;

  local frac, point;
  do { // Casts a ray which passes through thin walls (glass, grates, etc.)

    frac = TraceLine(start, dest, null);
    if (frac == 1.0) break;

    point = start + (dest - start) * frac;
    start = point + fvec * 16.0;

  } while (TraceLine(point + fvec * 16.0, point + fvec * 8.0, null) != 0.0);

  // True if the ray didn't hit anything
  return frac == 1.0;

}

::ppmod.button <- function (type, pos, ang = Vector()) {

  // Ensure that sounds are precached by creating a dummy entity
  ppmod.create(type).then(function (dummy) {
    dummy.Destroy();
  });

  local model;

  if (type == "prop_button") model = "props/switch001.mdl";
  if (type == "prop_under_button") model = "props_underground/underground_testchamber_button.mdl";
  if (type == "prop_floor_button") model = "props/portal_button.mdl";
  if (type == "prop_floor_cube_button") model = "props/box_socket.mdl";
  if (type == "prop_floor_ball_button") model = "props/ball_button.mdl";
  if (type == "prop_under_floor_button") model = "props_underground/underground_floor_button.mdl";

  return ppromise(function (resolve, reject):(type, pos, ang, model) {

    // First, create a prop_dynamic with the appropriate model
    ppmod.create(model).then(function (ent):(type, pos, ang, resolve) {

      ent.SetAbsOrigin(pos);
      ent.SetAngles(ang.x, ang.y, ang.z);

      // The floor buttons often come with additional phys_bone_followers
      while (ent.GetClassname() == "phys_bone_follower") {
        ent = ppmod.prev(ent.GetModelName(), ent);
        ent.SetAbsOrigin(pos);
        ent.SetAngles(ang.x, ang.y, ang.z);
      }

      if (type == "prop_button" || type == "prop_under_button") { // Handle pedestal buttons

        // func_button seems to be broken when spawned during runtime, hence the use of func_rot_button
        ppmod.brush(pos + (ent.GetUpVector() * 40), Vector(8, 8, 8), "func_rot_button", ang, true).then(function (button):(type, ent, resolve) {

          // Make the button box non-solid and activated with +use
          button.__KeyValueFromInt("CollisionGroup", 2);
          button.__KeyValueFromInt("SpawnFlags", 1024);
          ppmod.setparent(button, ent);

          // Properties are stored in the func_rot_button's script scope
          button.ValidateScriptScope();
          button.GetScriptScope()["button_delay"] <- 1.0;
          button.GetScriptScope()["button_timer"] <- false;
          button.GetScriptScope()["button_permanent"] <- false;

          ppmod.addscript(button, "OnPressed", function ():(type, ent, button) {

            // Underground buttons have different animation names
            // The additional sound effects for those are baked into the animation
            if (type == "prop_button") EntFireByHandle(ent, "SetAnimation", "down", 0.0, null, null);
            else EntFireByHandle(ent, "SetAnimation", "press", 0.0, null, null);
            button.EmitSound("Portal.button_down");

            // To disable the button while it's down, we clear its "+use activates" flag
            button.__KeyValueFromInt("SpawnFlags", 0);

            local timer = null; // Simulate the timer ticks
            if (button.GetScriptScope()["button_timer"]) {

              timer = Entities.CreateByClassname("logic_timer");

              ppmod.addscript(timer, "OnTimer", function ():(button) {
                button.EmitSound("Portal.room1_TickTock");
              });

              // Offset activation by one tick to prevent an extra tick upon release
              EntFireByHandle(timer, "RefireTime", "1", 0.0, null, null);
              EntFireByHandle(timer, "Enable", "", FrameTime(), null, null);

            }

            // If "permanent", skip the release code
            if (button.GetScriptScope()["button_permanent"]) return;

            ppmod.wait(function ():(ent, button, type, timer) {

              if (type == "prop_button") EntFireByHandle(ent, "SetAnimation", "up", 0.0, null, null);
              else EntFireByHandle(ent, "SetAnimation", "release", 0.0, null, null);
              button.EmitSound("Portal.button_up");

              button.__KeyValueFromInt("SpawnFlags", 1024);
              if (timer) timer.Destroy();

            }, button.GetScriptScope()["button_delay"]);

          });

          resolve({

            GetButton = function ():(button) { return button },
            GetProp = function ():(ent) { return ent },
            SetDelay = function (delay):(button) { button.GetScriptScope()["button_delay"] <- delay },
            SetTimer = function (enabled):(button) { button.GetScriptScope()["button_timer"] <- enabled },
            SetPermanent = function (enabled):(button) { button.GetScriptScope()["button_permanent"] <- enabled },
            OnPressed = function (scr):(button) { ppmod.addscript(button, "OnPressed", scr) },

          });

        });

      } else { // Handle floor buttons

        // This moves the phys_bone_followers into place
        EntFireByHandle(ent, "SetAnimation", "BindPose", 0.0, null, null);

        local trigger;
        if (type == "prop_under_floor_button") {
          trigger = ppmod.trigger(pos + Vector(0, 0, 8.5), Vector(30, 30, 8.5), "trigger_multiple", ang);
        } else {
          trigger = ppmod.trigger(pos + Vector(0, 0, 7), Vector(20, 20, 7), "trigger_multiple", ang);
        }

        // Activated by players and physics props
        trigger.__KeyValueFromInt("SpawnFlags", 9);

        trigger.ValidateScriptScope();
        trigger.GetScriptScope()["count"] <- 0;

        // Used for attaching output scripts to press and unpress events
        local pressrl = Entities.CreateByClassname("logic_relay");
        pressrl.__KeyValueFromInt("SpawnFlags", 2);
        local unpressrl = Entities.CreateByClassname("logic_relay");
        unpressrl.__KeyValueFromInt("SpawnFlags", 2);

        local press = function ():(type, trigger, ent, pressrl) {
          if (++trigger.GetScriptScope()["count"] == 1) {

            EntFireByHandle(pressrl, "Trigger", "", 0.0, null, null);

            if (type == "prop_under_floor_button") {
              EntFireByHandle(ent, "SetAnimation", "press", 0.0, null, null);
              ent.EmitSound("Portal.OGButtonDepress");
            } else {
              EntFireByHandle(ent, "SetAnimation", "down", 0.0, null, null);
              ent.EmitSound("Portal.ButtonDepress");
            }

          }
        };

        local unpress = function ():(type, trigger, ent, unpressrl) {
          if (--trigger.GetScriptScope()["count"] == 0) {

            EntFireByHandle(unpressrl, "Trigger", "", 0.0, null, null);

            if (type == "prop_under_floor_button") {
              EntFireByHandle(ent, "SetAnimation", "release", 0.0, null, null);
              ent.EmitSound("Portal.OGButtonRelease");
            } else {
              EntFireByHandle(ent, "SetAnimation", "up", 0.0, null, null);
              ent.EmitSound("Portal.ButtonRelease");
            }

          }
        };

        // Checks classnames and model names to filter the entities activating the button
        local strpress, strunpress;
        if (type == "prop_floor_button" || type == "prop_under_floor_button") {
          strpress = "if (self.GetClassname() == \"prop_weighted_cube\" || self.GetClassname() == \"player\") ppmod.scrq_get(" + ppmod.scrq_add(press) + ")()";
          strunpress = "if (self.GetClassname() == \"prop_weighted_cube\" || self.GetClassname() == \"player\") ppmod.scrq_get(" + ppmod.scrq_add(unpress) + ")()";
        } else if (type == "prop_floor_ball_button") {
          strpress = "if (self.GetClassname() == \"prop_weighted_cube\" && self.GetModelName() == \"models/props_gameplay/mp_ball.mdl\") ppmod.scrq_get(" + ppmod.scrq_add(press) + ")()";
          strunpress = "if (self.GetClassname() == \"prop_weighted_cube\" && self.GetModelName() == \"models/props_gameplay/mp_ball.mdl\") ppmod.scrq_get(" + ppmod.scrq_add(unpress) + ")()";
        } else {
          strpress = "if (self.GetClassname() == \"prop_weighted_cube\" && self.GetModelName() != \"models/props_gameplay/mp_ball.mdl\") ppmod.scrq_get(" + ppmod.scrq_add(press) + ")()";
          strunpress = "if (self.GetClassname() == \"prop_weighted_cube\" && self.GetModelName() != \"models/props_gameplay/mp_ball.mdl\") ppmod.scrq_get(" + ppmod.scrq_add(unpress) + ")()";
        }

        ppmod.addoutput(trigger, "OnStartTouch", "!activator", "RunScriptCode", strpress);
        ppmod.addoutput(trigger, "OnEndTouch", "!activator", "RunScriptCode", strunpress);

        resolve({

          GetTrigger = function ():(trigger) { return trigger },
          GetProp = function ():(ent) { return ent },
          GetCount = function ():(trigger) { return trigger.GetScriptScope()["count"] },
          OnPressed = function (scr):(pressrl) { ppmod.addscript(pressrl, "OnTrigger", scr) },
          OnUnpressed = function (scr):(unpressrl) { ppmod.addscript(unpressrl, "OnTrigger", scr) },

        });

      }

    });

  });

}

::ppmod.catapult <- function (ent, vec) {

  if (!(typeof ent == "instance" && ent instanceof CBaseEntity)) {
    ppmod.forent(ent, function (curr):(vec) {
      ppmod.catapult(curr, vec);
    });
    return;
  }

  local speed = vec.Norm();

  local trigger = Entities.CreateByClassname("trigger_catapult");
  trigger.__KeyValueFromInt("Solid", 3);
  trigger.SetAbsOrigin(ent.GetOrigin());
  trigger.SetForwardVector(vec);
  trigger.SetSize(Vector(-0.2, -0.2, -0.2), Vector(0.2, 0.2, 0.2));
  trigger.__KeyValueFromInt("CollisionGroup", 1);

  local ang = trigger.GetAngles();
  trigger.__KeyValueFromInt("SpawnFlags", 8);
  trigger.__KeyValueFromFloat("PhysicsSpeed", speed);
  trigger.__KeyValueFromString("LaunchDirection", ang.x+" "+ang.y+" "+ang.z);

  EntFireByHandle(trigger, "Enable", "", 0.0, null, null);
  EntFireByHandle(trigger, "Kill", "", 0.0, null, null);

}

/******************/
// Game interface //
/******************/

::ppmod.text <- class {

  ent = null;

  constructor (text = "", x = -1.0, y = -1.0) {
    this.ent = Entities.CreateByClassname("game_text");
    this.ent.__KeyValueFromString("Message", text);
    this.ent.__KeyValueFromString("Color", "255 255 255");
    this.ent.__KeyValueFromFloat("X", x);
    this.ent.__KeyValueFromFloat("Y", y);
  }

  function GetEntity () {
    return this.ent;
  }
  function SetPosition (x, y) {
    this.ent.__KeyValueFromFloat("X", x);
    this.ent.__KeyValueFromFloat("Y", y);
  }
  function SetText (text) {
    this.ent.__KeyValueFromString("Message", text);
  }
  function SetSize (size) {
    // Channels sorted from smallest to biggest font size
    this.ent.__KeyValueFromInt("Channel", [2, 1, 4, 0, 5, 3][size]);
  }
  function SetColor (c1, c2 = null) {
    this.ent.__KeyValueFromString("Color", c1);
    if (c2) this.ent.__KeyValueFromString("Color2", c2);
  }
  function SetFade (fin, fout, fx = false) {
    this.ent.__KeyValueFromFloat("FadeIn", fin);
    this.ent.__KeyValueFromFloat("FXTime", fin);
    this.ent.__KeyValueFromFloat("FadeOut", fout);
    if (fx) this.ent.__KeyValueFromInt("Effect", 2);
    else this.ent.__KeyValueFromInt("Effect", 0);
  }
  function Display (hold = null, player = null) {
    if (hold == null) hold = FrameTime();
    this.ent.__KeyValueFromFloat("HoldTime", hold);
    if (player) this.ent.__KeyValueFromInt("SpawnFlags", 0);
    else this.ent.__KeyValueFromInt("SpawnFlags", 1);
    EntFireByHandle(ent, "Display", "", 0.0, player, null);
  }

}
