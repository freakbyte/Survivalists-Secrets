require 'lib/lib_table';
require "lib/lib_math";

local __INSTANCE = nil;

function LibGlow(options)
	local self = __INSTANCE or {};
	
	if __INSTANCE == nil then
	
		self._ready = false;
		self._addon = options.addon or 'UNKNOWN';
		self._actions = {};
		self._tries = 0;
		self._onColorChange = function() end;
		self._onReady = function() end;
		self._playerId = 0;
		self._defaultColors = {
			c1 = 'a0a0a0', 	-- grey
			c2 = 'ffffff',		-- white
			c3 = '70d15e',	-- lime green
			c4 = '4499ff',	-- light blue
			c5 = 'a830ed',	-- purple
			c6 = 'a830ed',	-- orange
			c7 = 'ffff7f',		-- yellow
			c8 = 'ff3f3f',		-- red
			c9 = '00ff7f',		-- green
		};
			
		if type(options.onColorChange) == 'function' then
			self._onColorChange = options.onColorChange;
		end
		
		if type(options.onReady) == 'function' then
			self._onReady = options.onReady;
		end
			
		self._announce = function()
			if not self._ready and self._tries < 10 then
				callback(function()
					if Component ~= nil then		
						if Player ~= nil and self._playerId == 0 then
							self._playerId = Player.GetTargetId();
						end
						self._tries = self._tries + 1;
						Component.GenerateEvent("LIBGLOW_ANNOUNCE", {addon=self._addon, type='heartbeat'});
					end
					self._announce();		
				end, nil, 0.1);
			end;
			
			if self._tries == 10 then
				if not self._ready then
					for k, v in pairs(self._actions) do 
						self._onColorChange(v.action, __color(self._defaultColors['c'..tostring(v.fallbackColor)]) or 0);
					end
				end
				self._onReady(false);
			end
			
		end
		
		self._event = function(event)
			if event.type == 'announce' then
				Component.GenerateEvent("LIBGLOW_ANNOUNCE", {addon=self._addon, type='full', actions=tostring(self._actions)});
				self._ready = true;
				self._onReady(true);
			elseif event.type == 'colorchange' then		
				self._onColorChange(event.action, __color(event.color));						
			end
		end
		
		if type(options.actions) == 'table' then
			for k, v in pairs(options.actions) do
				table.insert(self._actions, {
					action = v.action or 'UNKNOWN_'..k,
					color = __color(v.color).Hue() or 0,
					fallbackColor = v.fallbackColor or 0,
					transition = v.transition or 'fade',
					description = v.description or 'Missing description',
					priority = k
				});
			end
		end
		
		self._func = function(key, ignite)	
			if type(ignite) == 'number' and not self._ready then
				if ignite > 0 and ignite < 10 then
					for k, v in pairs(__INSTANCE._actions) do
						if v.action == key then
							__INSTANCE._actions[key].fallbackColor = ignite;
							self._onColorChange(v.action, __color(self._defaultColors['c'..tostring(v.fallbackColor)]) or 0);
							break;
						end
					end
				end
			else
				for k, v in pairs(__INSTANCE._actions) do
					if v.action == key then
						if v.ignite ~= (ignite == true) then
							__INSTANCE._actions[k].ignite = (ignite == true);
							if self._ready then
								Component.GenerateEvent("LIBGLOW_IGNITE", {addon=__INSTANCE._addon, action = v.action, ignite = (ignite == true)});
							else
								self._glow();
							end
						end			
						break;
					end
				end	
			end				
		end
		
		self._glow = function()
			local ignite = nil;
			for k, v in pairs(__INSTANCE._actions) do
				if v.ignite and (ignite == nil or v.priority < ignite.priority) then
					ignite = v;
				end
			end
			if ignite ~= nil then
				Game.HighlightEntity(self._playerId, ignite.fallbackColor);
			else
				Game.HighlightEntity(self._playerId, 0);
			end	
		end
		
		self._announce();
		__INSTANCE = self;
	end
	return __INSTANCE._func;
end

function libglow(event)
	if __INSTANCE ~= nil then
		if event.addon == __INSTANCE._addon then
			__INSTANCE._event(event);
		end
	end
end

function __color(color)
	local self =	{};
	if type(color) == 'number' then
		self._hue = color;
		self.Hue = function() return self._hue; end;
		self.Hex = function() if self._hex == nil then self._hex = HueToHex(self._hue); end return self._hex; end;
		self.RGB = function() if self._rgb == nil then self._rgb = HueToRGB(self._hue); end return self._rgb; end;
	elseif type(color) == 'table' then
		self._rgb = color;
		self.Hue = function() if self._hue == nil then self._hue = RGBToHue(self._rgb); end return self._hue; end;
		self.Hex = function() if self._hex == nil then self._hex = RGBToHex(self._rgb); end return self._hex; end;
		self.RGB = function() return self._rgb; end;			
	else
		self._hex = color;
		self.Hue = function() if self._hue == nil then self._hue = HexToHue(self._hex); end return self._hue; end;
		self.Hex = function() return self._hex; end;		
		self.RGB = function() if self._rgb == nil then self._rgb = HexToRGB(self._hex); end return self._rgb; end;
	end
	return self;
end

function out(_string)
	Component.GenerateEvent("MY_SYSTEM_MESSAGE", {channel="whisper", text=tostring(_string)});
end

function HueToRGB(hue)
	function hue2rgb(t)
		if t < 0   then t = t + 1 end
		if t > 1   then t = t - 1 end
		if t < 1/6 then return 6 * t end
		if t < 1/2 then return 1 end
		if t < 2/3 then return (2/3 - t) * 6 end
		return 0
	end
	
	local h = hue / 360;
    return
	{
		r = hue2rgb(h + 1/3),
		g = hue2rgb(h),
		b = hue2rgb(h - 1/3)
	}
end

function HueToHex(hue)
	return RGBToHex(HueToRGB(hue));
end

function RGBToHue(rgb)

	if rgb.r == rgb.g and rgb.g == rgb.b then
		return 0;
	end
	
    local _min = math.min(math.min(rgb.r, rgb.g), rgb.b);
    local _max = math.max(math.max(rgb.r, rgb.g), rgb.b);
    local hue = 0;
	
	if _max == rgb.r then 
		hue = (rgb.g - rgb.b) / (_max - _min);
	elseif _max == rgb.g then 
		hue = 2 + (rgb.b - rgb.r) / (_max - _min);
	else 
		hue = 4 + (rgb.r - rgb.g) / (_max - _min);
	end

    hue = hue * 60;
    if hue < 0 then
		hue = hue + 360;
	end
    return math.floor(hue + 0.5);
end

function RGBToHex(rgb)
	return string.upper('#' .. PadRight(_math.Base10ToBaseN(math.floor((rgb.r*255) + 0.5), 16), 2, '0') .. PadRight(_math.Base10ToBaseN(math.floor((rgb.g*255) + 0.5), 16), 2, '0') .. PadRight(_math.Base10ToBaseN(math.floor((rgb.b*255) + 0.5), 16), 2, '0'));
end

function HexToRGB(hex)
	hex = string.lower(hex:gsub("#",""));
	return {
		r =  _math.BaseNToBase10(hex:sub(1,2), 16) / 255,
		g =  _math.BaseNToBase10(hex:sub(3,4), 16) / 255,
		b =  _math.BaseNToBase10(hex:sub(5,6), 16) / 255
	}
end

function HexToHue(hex)
	return RGBToHue(HexToRGB(hex));
end

function PadLeft(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

function PadRight(str, len, char)
    if char == nil then char = ' ' end
    return string.rep(char, len - #str) .. str
end