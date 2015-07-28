-- freakbyte 2014
-- http://freakbyte.me

require "./lib/lib_freak";
require "./Survivalist_strings";
require "./Survivalist_settings";
require './lib/lib_glow';

-- init
Freak.Init("Survivalists Secrets", "0.25", "freakbyte", false);
UI = Freak.InterfaceOptions();

Glow = LibGlow({
	addon = 'Survivalists Secrets',
	actions = {
		{
			action = 'health',
			color = 110,
			fallbackColor = 9,
			transition = 'fade',
			description = 'Health pack equipped'
		},
		{
			action = 'ammo',
			color = 37,
			fallbackColor = 7,
			transition = 'fade',
			description = 'Ammo pack equipped'
		},
		{
			action = 'sonic',
			color = 170,
			fallbackColor = 2,
			transition = 'fade',
			description = 'Sonic detonator equipped'
		},
		{
			action = 'energy',
			color = 220,
			fallbackColor = 4,
			transition = 'fade',
			description = 'Energy pack equipped'
		},
		{
			action = 'hammer',
			color = 335,
			fallbackColor = 5,
			transition = 'fade',
			description = 'Scan hammer equipped'
		},
		{
			action = 'thumper',
			color = 280,
			fallbackColor = 5,
			transition = 'fade',
			description = 'Thumper equipped'
		},
	},
	onColorChange = function(action, color)
		if action == 'health' then
			statusHealth.SetColor(color.Hex());
		elseif action == 'ammo' then
			statusAmmo.SetColor(color.Hex());
		elseif action == 'energy' then
			statusEnergy.SetColor(color.Hex());
		elseif action == 'sonic' then
			statusSonic.SetColor(color.Hex());
		elseif action == 'hammer' then
			statusHammer.SetColor(color.Hex());
		elseif action == 'thumper' then
			statusThumper.SetColor(color.Hex());
		end
	end,
	onReady = function(modInstalled)
		
	end
});

function StatusMarker(name, color, disabledChar)
	local self = {};
	
	self.enabled = false;
	self.charged = true;
	self.keep = false;
	self.name = name;
	self.widget = Component.GetWidget(name);
	self.x = 0;
	self.y = 0;
	self.color = color;
	
	self.Show = function(bool)
		if bool ~= self.enabled then
			self.enabled = bool;
			self.Update();
		end	
	end
	
	self.SetCharged = function(bool, keep)
		if bool ~= self.charged then
			self.keep = (keep == true);
			self.charged = bool;
			self.Update();
		end
	end
	self.SetPos = function(x, y)
		self.x = x;
		self.y = y;
		self.Update();
	end	
	self.Update = function()
		if misc.enabled and self.enabled then
			if self.charged then
				self.widget:SetText("•");
				self.widget:SetTextColor("FF"..self.color);
				self.widget:MoveTo("top: "..self.y.."; left: "..self.x..";", 0.1)
			else		
				local x = 0;
				local y = 0;
				local t =  "•";
				if not self.keep then x = 1 end
				if not self.keep then y = 6 end
				if not self.keep then t = "º"; end
				
				self.widget:SetText(t);
				self.widget:SetTextColor("77"..self.color);
				self.widget:MoveTo("top: "..(self.y + y).."; left: "..(self.x + x)..";", 0.1)
			end
		else
			self.widget:SetText("");
		end
	end
	
	self.SetColor = function(hex)
		if hex ~= nil then
			hex = hex:gsub("#","");
			self.color = hex;
			self.Update();
		end
	end
	
	self.Update();
	return self;
end

function ValidateAmmo(entity)

	return true;
end

function ValidateHealth(entity)
	out = Game.GetTargetInfo(entity._id);
	--Freak.Dbg(out);
	return true;
end

healthMarkers = Freak.MultiMarker("icons", "aid", "#00FFCC", "HEALTH", "Get Some!", true, true, true);
ammoMarkers = Freak.MultiMarker("icons", "armory", "#FFD414", "AMMO", "Get Some!", true, true, true);
healthTracker = Freak.EntityTracker(nil, {"health", "healing"}, ValidateHealth);
ammoTracker = Freak.EntityTracker(nil, {"ammo"}, ValidateAmmo);

statusFrame = Component.GetFrame("statusFrame");
statusCooldown = Component.GetWidget("cooldown");

UI.AddMovableFrame({
	frame = statusFrame,
	label = "Survivalists Secrets",
	scalable = true,
});

statusHealth = StatusMarker("health", "00FF00");
statusAmmo = StatusMarker("ammo", "FFD414");
statusEnergy = StatusMarker("energy", "00C3FF");
statusSonic = StatusMarker("sonic", "FFFFFF", "•");
statusHammer = StatusMarker("hammer", "FFOOOO");
statusThumper = StatusMarker("thumper", "FF00CC");


autoSlot = Freak.AutoSlot(4);

misc.slotChange = function() autoSlot.ChangeSlot(misc.slot); end;

priority = {};
priority.health = 999;
priority.ammo = 998;
priority.sonic = 3;
priority.energy = 2;
priority.scanthump = 1;

--health
autoSlot.AddItem(function()
	local data = {};
	data.priority = priority.health;
	data.itemId = survivalist.health.itemId;
	if misc.glow then data.playerGlow = 'health'; end
	data.isReady = false;
	if data.itemId then
		local itemInfo = Game.GetItemInfoByType(data.itemId);
		if itemInfo and itemInfo.abilityId then
			data.isReady = Player.GetAbilityState(itemInfo.abilityId).isReady;
		end
	end
			
	data.show = (survivalist.enabled and survivalist.health.index ~= 1 and Freak.Player.HealthPercent() <= survivalist.superCriticalHealth and data.isReady);
	statusHealth.Show(data.itemId ~= nil);
	statusHealth.SetCharged(data.isReady);
	
	Glow('health', data.show);
	return data;
end);

--ammo
autoSlot.AddItem(function()

	local reusable = 30745;
	local crafted = 30298;
	local data = {};
	
	if misc.glow then data.playerGlow = 'ammo'; end
	data.priority = priority.ammo;
	data.itemId = crafted;
	data.show = false;
	data.isReady = Freak.Player.ItemReady(reusable);
	
	if survivalist.enabled and survivalist.ammo and Freak.Player.AmmoPercent() <= survivalist.superCriticalAmmo then 
		if Freak.Player.ItemReady(reusable) then
			data.itemId = reusable;
			data.isReady = true;
			data.show = true;
		elseif Freak.Player.ItemReady(data.itemId) then
			data.isReady = true;
			data.show = true;
		end
	end
	
	statusAmmo.Show(survivalist.ammo);
	statusAmmo.SetCharged(data.isReady, Freak.Player.ItemReady(crafted));
	
	Glow('ammo', data.show);
	return data;
end);

--energy packs
autoSlot.AddItem(function()

	local data = {};
	if misc.glow then data.playerGlow = 'energy'; end
	data.priority = priority.energy;
	data.itemId = 85535;
	data.show = false;
	data.isReady = Freak.Player.ItemReady(data.itemId);
	data.show = false;
	
	if misc.enabled and misc.energy and misc.energyInfo.percent < 50 and data.isReady then 
		data.show = true;
	end
	
	statusEnergy.Show(misc.energy);
	statusEnergy.SetCharged(data.isReady);
	
	Glow('energy', data.show);	
	return data;
end);

--scanhammer / thumpers
autoSlot.AddItem(function()

	local scanhammer = 56811;
	local thumper = 56811;
	local data = {};
	
	local hReady =  Freak.Player.ItemReady(scanhammer);
	local tReady = Freak.Player.ItemReady(misc.thumper.itemId);
	
	data.priority = priority.scanthump;
	data.itemId = scanhammer;
	data.show = false;
	data.isReady = false;
	data.show = false;
	
	if misc.enabled then 
		if misc.hammer and hReady then	
			if Player.GetAim() < -1.2 and Freak.Player.AimDistance() < 1.2 then
				if misc.glow then data.playerGlow = 'hammer'; end
				data.show = true;
			end
		else
			if tReady and not hReady then
				if misc.lastScan and System.GetElapsedUnixTime(misc.lastScan) < 6 then
					if misc.glow then data.playerGlow = 'thumper'; end
					data.itemId = misc.thumper.itemId;
					data.show = true;
				else
					if misc.glow then data.playerGlow = 'hammer'; end
					data.show = true;
				end	
			end
		end
		Glow('hammer', data.show and data.playerGlow == 'hammer');
		Glow('thumper', data.show and data.playerGlow == 'thumper');
	end
	
	statusHammer.Show(misc.hammer);
	statusHammer.SetCharged(hReady);
	statusThumper.Show(misc.thumper.itemId ~= nil);
	statusThumper.SetCharged(tReady);
	
	return data;
end);

--sonic detonators
autoSlot.AddItem(function()
	local crafted = 54003;
	local reusable = 85511;
	local data = {};
	
	if misc.glow then data.playerGlow = 'sonic'; end
	data.priority = priority.sonic;
	data.itemId = crafted;
	data.show = false;
	data.isReady = Freak.Player.ItemReady(reusable);
	data.show = false;
	
	if misc.enabled and misc.sonic then 
		local target = Freak.Player.Target();
		if target and target.name ~= nil and string.find(target.name, "Surface Deposit") then	
			if data.isReady then	
				data.itemId = reusable;	
			end
			data.show = true;
		end
	end
	
	statusSonic.Show(misc.sonic);
	statusSonic.SetCharged(data.isReady, Freak.Player.ItemReady(crafted));
	
	Glow('sonic', data.show);
	return data;
end);

BuildUIOptions();

Freak.OnReady = function()
	UpdateHealth();
	UpdateAmmo();
	Timer();
end

function Survivalist(enable)
	if enable then
		healthTracker.Start();
		ammoTracker.Start();
	else
		healthTracker.Stop();
		ammoTracker.Stop();
		healthMarkers.Clear();
		ammoMarkers.Clear();
	end
end

function UpdateAmmo()
	if survivalist.enabled then
		if Freak.Player.AmmoPercent() <= survivalist.criticalAmmo then
			local closest = ammoTracker.GetClosest(survivalist.maxMarkerCount);
			local exept = {};

			for k, v in pairs(closest) do
				exept[v[1]] = ammoMarkers.Has(v[1]);
			end
			
			ammoMarkers.Clear(exept);
			
			for k,v in pairs(closest) do
				ammoMarkers.Add(v[1], v[3]);
			end		
		else
			ammoMarkers.Clear();
		end
	end
end
function UpdateHealth()
	if survivalist.enabled then		
		if Freak.Player.HealthPercent() <= survivalist.criticalHealth then
			local closest = healthTracker.GetClosest(survivalist.maxMarkerCount);
			local exept = {};

			for k, v in pairs(closest) do
				exept[v[1]] = healthMarkers.Has(v[1]);
			end
			
			healthMarkers.Clear(exept);
			
			for k,v in pairs(closest) do
				healthMarkers.Add(v[1], v[3]);
			end				
		else
			healthMarkers.Clear();
		end
	end
end
function OnReviveEnd(e)
	if thanks.enabled then	
		if e.percent == 100 then 
		
			local text = string.gsub(thanks.text, "{doc}", e.name);
			local emote = string.gsub(thanks.emote, "/", "");
		
			if CHANNELS[thanks.channel] == "whisper" then
				Chat.SendWhisperText(e.name, text);
				Freak.Dbg(text, true, e.name);
			else
				Chat.SendChannelText(CHANNELS[thanks.channel], text);
			end
			
			if emote ~= "" and emote ~=nil then
				callback(function() Game.SlashCommand(emote); end, nil, 0.1);
			end
		end
	end
end

oldCooldownChecks = {};
oldName = "";
oldCooldownsEnable = false;
showHUD = false;

function UpdateCooldowns()
	
	if misc.enabled and misc.hud and Freak.Player.HealthPercent() > 0 and not Player.IsInVehicle() and not Player.IsInCinamaticMode() and showHUD then
		if oldCooldownsEnable == false then
			statusFrame:Show(true);
			oldCooldownsEnable = true;
		end	
	else
		if oldCooldownsEnable == true then
			statusFrame:Show(false);
			oldCooldownsEnable = false;
		end	
	end

	if misc.enabled and misc.hud then
		
		local check = {};
		local cool = {cd = 1000, name};
		local count = 0;
		local each = 0;
		local current = 0;
		
	    function NextPos()			
			current = current + 1;
			return (current*each) - (each/2);
		end
		
		
		if survivalist.enabled and survivalist.health.itemId ~= nil then check.health = survivalist.health.itemId; end
		if survivalist.enabled and survivalist.ammo then check.ammo = 30298; end
		if misc.enabled and misc.energy then check.energy = 85535; end
		if misc.enabled and misc.hammer then check.hammer = 56811; end
		if misc.enabled and misc.sonic then check.sonic = 85511; end
		if misc.enabled and misc.thumper.itemId~= nil then check.thumper = misc.thumper.itemId; end
		
		if not Freak.Util.DeepCompare(check, oldCooldownChecks) then 
			oldCooldownChecks = check;
			for k, v  in pairs(check) do count = count +1; end
			
			if count > 0 then
				each = 88 / count;
			end

			if check.energy ~= nil then statusEnergy.SetPos(NextPos(), 0); end
			if check.health ~= nil then statusHealth.SetPos(NextPos(), 0); end
			if check.sonic ~= nil then statusSonic.SetPos(NextPos(), 0); end
			if check.ammo ~= nil then statusAmmo.SetPos(NextPos(), 0); end
			if check.hammer ~= nil then statusHammer.SetPos(NextPos(), 0); end
			if check.thumper ~= nil then statusThumper.SetPos(NextPos(), 0); end
		end
		
		for k, v in pairs(check) do
			if k == 'ammo' then
				local n = Game.GetItemInfoByType(30298).name;
				local s = Freak.InventorySearch({string.lower(n)});			
				if table.getn(s) > 0 then
					local t = Freak.Player.ItemCooldown(30298);
					if t > 0 and t + 1 < cool.cd then
						cool.cd = t;
						cool.name = k;
					end
				else
					local t = Freak.Player.ItemCooldown(30745);
					if t > 0 and t + 1 < cool.cd then
						cool.cd = t;
						cool.name = k;
					end
				end	
			else 
				local t = Freak.Player.ItemCooldown(v);
				if t > 0 and t + 1 < cool.cd then
					cool.cd = t;
					cool.name = k;
				end
			end
		end
		
		if cool.cd > 3 and cool.cd < 999 then
			oldName = cool.name or "";
			if cool.name then statusCooldown:SetText(oldName .. " • " .. math.floor(cool.cd+0.5)) end;
		elseif oldName ~= "" then
			if cool.name and cool.cd < 999 then
				statusCooldown:SetText(oldName .. " • " .. math.floor(cool.cd+0.5));
			else
				oldName = "";
				statusCooldown:SetText(" ");
			end
		end
	end
end

function Timer()
	UpdateCooldowns();
	autoSlot.Update();
	callback(function() Timer(); end, nil, misc.freq);
end

-- register event handlers
Freak.Event:AddHandler("ON_REVIVE_END", OnReviveEnd);
Freak.Event:AddHandler("ON_HEALTH_CHANGED", UpdateHealth);
Freak.Event:AddHandler("ON_WEAPON_STATE_CHANGED", UpdateAmmo);
Freak.Event:AddHandler("MY_HUD_SHOW", function(e) showHUD = e.show; UpdateCooldowns(); end);

Freak.Event:AddHandler("ON_RESOURCE_SCAN_REPORT", function(e) misc.lastScan = System.GetLocalUnixTime(); end);
Freak.Event:AddHandler("ON_RESOURCE_SCAN_FAILED", function(e) misc.lastScan = nil; end);

Freak.Event:AddHandler("ON_ENERGY_CHANGED", function(e) 

	local currentEnergy, maxEnergy, rateEnergy = Player.GetEnergy();
	local dur = 0.1;
	local eta = 0;
	local delta = currentEnergy - misc.energyInfo.current;
	if (rateEnergy > 0) then
		eta = (maxEnergy - currentEnergy) / rateEnergy;
	elseif (rateEnergy < 0) then
		eta = -currentEnergy / rateEnergy;
	end
	local curPercent = 0
	if maxEnergy > 0 then
		misc.energyInfo.percent = math.min(100, 100 * currentEnergy / maxEnergy);
	end
	misc.energyInfo.max = maxEnergy;
	misc.energyInfo.current = currentEnergy;
	
 end);