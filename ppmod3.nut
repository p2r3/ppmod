if(!("Entities" in this)) return;
if(!("ppmod" in this)) {
	::ppmod <- {};
	::min <- function(a, b) {if(a > b) return b; return a}
	::max <- function(a, b) {if(a < b) return b; return a}
	::round <- function(a) return floor(a + 0.5);
	ppmod.debug <- false;
}

ppmod.fire <- function(ent, action = "Use", value = "", delay = 0, activator = null, caller = null) {
	if(typeof ent == "string") EntFire(ent, action, value, delay, activator);
	else EntFireByHandle(ent, action, value.tostring(), delay, activator, caller);
}

ppmod.addoutput <- function(ent, output, target, input = "", parameter = "", delay = 0, max = -1) {
	if(typeof target == "instance") {
		if(!target.GetName().len()) ppmod.keyval(target, "Targetname", UniqueString("noname"));
		target = target.GetName();
	}
	ppmod.fire(ent, "AddOutput", output+" "+target+":"+input+":"+parameter+":"+delay+":"+max);
}

ppmod.scrq <- {};
ppmod.scrq_add <- function(scr) {
	local qid = UniqueString();
	if(typeof scr == "string") scr = compilestring(scr);
	ppmod.scrq[qid] <- scr;
	return { id = qid, name = "ppmod.scrq[\"" + qid + "\"]" };
}

ppmod.addscript <- function(ent, output, scr, delay = 0, max = -1) {
	if(typeof scr == "function") scr = ppmod.scrq_add(scr).name + "()";
	ppmod.addoutput(ent, output, "!self", "RunScriptCode", scr, delay, max);
}

ppmod.keyval <- function(ent, key, val) {
	if(typeof ent == "string") {
		EntFire(ent, "AddOutput", key + " " + val);
	} else switch (typeof val) {
		case "integer":
		case "bool":
			ent.__KeyValueFromInt(key, val);
			break;
		case "float":
			ent.__KeyValueFromFloat(key, val);
			break;
		case "string":
			ent.__KeyValueFromString(key, val);
			break;
		case "Vector":
			ent.__KeyValueFromVector(key, val);
			break;
		default:
			printl("Invalid keyvalue type for " + ent);
			printl(key + " " + val + " (" + typeof val + ")");
	}
}

ppmod.wait <- function(scr, sec) {
	local relay = Entities.CreateByClassname("logic_relay");
	if(typeof scr == "function") scr = ppmod.scrq_add(scr).name + "()";
	ppmod.fire(relay, "RunScriptCode", scr, sec);
	ppmod.keyval(relay, "SpawnFlags", 1);
	return relay;
}

ppmod.interval <- function(scr, sec = 0, name = null) {
	if(!name) name = scr.tostring();
	if(Entities.FindByName(null, name)) return;
	local timer = Entities.CreateByClassname("logic_timer");
	ppmod.keyval(timer, "Targetname", name);
	ppmod.fire(timer, "RefireTime", sec);
	ppmod.addscript(timer, "OnTimer", scr);
	ppmod.fire(timer, "Enable");
	return timer;
}

ppmod.once <- function(scr, name = null) {
	if(!name) name = scr.tostring();
	if(Entities.FindByName(null, name)) return;
	local relay = Entities.CreateByClassname("logic_relay");
	ppmod.keyval(relay, "Targetname", name);
	if(typeof scr == "function") scr = ppmod.scrq_add(scr).name + "()";
	ppmod.fire(relay, "RunScriptCode", str);
	return relay;
}

ppmod.get <- function(key, ent = null, arg = 1) {
	switch (typeof key) {
		case "string":
			if(arg = Entities.FindByName(ent, key)) return arg;
			if(arg = Entities.FindByClassname(ent, key)) return arg;
			return Entities.FindByModel(ent, key);
		case "Vector":
			if(typeof ent != "string") return Entities.FindInSphere(ent, key, arg);
			return Entities.FindByClassnameNearest(ent, key, arg);
		case "integer":
			while((ent = Entities.Next(ent)).entindex() != key);
			return ent;
		case "instance":
			return Entities.Next(key);
		default: return null;
	}
}

ppmod.prev <- function(key, ent = null, arg = 1) {
	local curr = null, prev = null;
	while((curr = ppmod.get(key, curr, arg)) != ent) prev = curr;
	return prev;
}

ppmod.player <- {
	surface = function(e = null) {
		if(e == null) {
			EntFire("ppmod_surface", "Kill");
			ppmod.create("env_player_surface_trigger", ppmod.player.surface);
		} else {
			ppmod.fire(ppmod.player.landrl, "Trigger");
			ppmod.keyval(e, "GameMaterial", 0);
			ppmod.keyval(e, "Targetname", "ppmod_surface");
			ppmod.addscript(e, "OnSurfaceChangedFromTarget", "ppmod.player.surface()");
		}
	}
	enable = function() {
		proxy <- Entities.FindByClassname(null, "logic_playerproxy");
		if(!proxy) proxy = Entities.CreateByClassname("logic_playerproxy");
		eyes <- Entities.CreateByClassname("logic_measure_movement");
		ppmod.keyval(eyes, "MeasureType", 1);
		ppmod.keyval(eyes, "Targetname", "ppmod_eyes");
		ppmod.keyval(eyes, "TargetReference", "ppmod_eyes");
		ppmod.keyval(eyes, "Target", "ppmod_eyes");
		ppmod.fire(eyes, "SetMeasureReference", "ppmod_eyes");
		ppmod.fire(eyes, "SetMeasureTarget", "!player");
		ppmod.fire(eyes, "Enable");
		eyes_vec <- function() {
			local ang = (eyes.GetAngles()) * (PI / 180);
			return Vector(cos(ang.y) * cos(ang.x), sin(ang.y) * cos(ang.x), -sin(ang.x));
		}
		landrl <- Entities.CreateByClassname("logic_relay");
		ppmod.player.surface();
	}
	jump = function(str) { ppmod.addscript(proxy, "OnJump", str) }
	land = function(str) { ppmod.addscript(landrl, "OnTrigger", str) }
	duck = function(str) { ppmod.addscript(proxy, "OnDuck", str) }
	unduck = function(str) { ppmod.addscript(proxy, "OnUnDuck", str) }
}

ppmod.brush <- function(pos, size, type = "func_brush", ang = Vector()) {
	local brush = Entities.CreateByClassname(type);
	brush.SetOrigin(pos);
	brush.SetAngles(ang.x, ang.y, ang.z);
	brush.SetSize(Vector() - size, size);
	ppmod.keyval(brush, "Solid", 3);
	return brush;
}

ppmod.trigger <- function(pos, size, type = "once", ang = Vector()) {
	local trigger = ppmod.brush(pos, size, "trigger_"+type, ang);
	ppmod.keyval(trigger, "CollisionGroup", 1);
	ppmod.keyval(trigger, "SpawnFlags", 1);
	if(type == "once") ppmod.addoutput(trigger, "OnStartTouch", "!self", "Kill");
	ppmod.fire(trigger, "Enable");
	return trigger;
}

ppmod.texture <- function(tex = "", pos = Vector(), ang = Vector(90), simple = 1, far = 16) {
	local texture = Entities.CreateByClassname("env_projectedtexture");
	texture.SetOrigin(pos);
	texture.SetAngles(ang.x, ang.y, ang.z);
	ppmod.keyval(texture, "FarZ", far);
	ppmod.keyval(texture, "SimpleProjection", simple.tointeger());
	ppmod.keyval(texture, "TextureName", tex);
	return texture;
}

ppmod.decal <- function(tex = "", pos = Vector(), ang = Vector(90)) {
	local decal = Entities.CreateByClassname("infodecal");
	decal.SetOrigin(pos);
	decal.SetAngles(ang.x, ang.y, ang.z);
	ppmod.keyval(decal, "Texture", tex);
	ppmod.keyval(decal, "LowPriority", 0);
	ppmod.fire(decal, "Activate");
	return decal;
}

ppmod.create <- function(cmd, func, key = null) {
	if(!key) switch (cmd.slice(0, min(cmd.len(), 17))) {
		case "ent_create_portal": key = "cube"; break;
		case "ent_create_paint_": key = "prop_paint_bomb"; break;
		default:
			if(cmd.find(" ")) key = cmd.slice(cmd.find(" ")+1);
			else if(cmd.slice(-4) == ".mdl") key = cmd, cmd = "prop_dynamic_create " + cmd;
			else key = cmd, cmd = "ent_create " + cmd;
	}
	SendToConsole(cmd);
	if(key.slice(-4) == ".mdl") key = "models/" + key;
	local getstr = "ppmod.prev(\"" + key + "\")";
	local qstr = scrq_add(func).name;
	SendToConsole("script " + qstr + "(" + getstr + ")");
	SendToConsole("script delete " + qstr);
}

ppmod.text <- function(text, x = -1, y = -1, func = function(e){}) {
	ppmod.create("game_text", function(ent, text = text, x = x, y = y, func = func) {
		ppmod.keyval(ent, "Message", text);
		ppmod.keyval(ent, "X", x);
		ppmod.keyval(ent, "Y", y);
		ppmod.keyval(ent, "Effect", 0);
		ppmod.keyval(ent, "Color", "255 255 255");
		ppmod.keyval(ent, "HoldTime", FrameTime());
		ppmod.keyval(ent, "Channel", 5);
		func(ent);
		ppmod.fire(ent, "Display");
	});
}
