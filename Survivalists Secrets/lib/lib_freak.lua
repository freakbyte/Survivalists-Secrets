-- freakbyte 2014
-- http://freakbyte.me
-- Feel free to do whatever you want with this code as long as you give credit where credit is due.
-- lib_freak 0.1

require "unicode";
require "table";
require "math";
require "string";
require "utf8";
require "lib/lib_InterfaceOptions";
require "lib/lib_Callback2"
require "lib/lib_EventDispatcher"
require "lib/lib_MapMarker";
require "lib/lib_Slash";

Freak = {

	Addon = {
		name = "Unknown",
		version = "Unknown",
		author = "Unknown",
		dbg = false,
		ready = false,
		enabled = false,
		saveVersion = nil,
		heartbeat = nil;
	},
	
	Init = function(name, version, author, dbg)
	
		Freak.Addon.name = name or "Unknown";
		Freak.Addon.version = version or "Unknown";
		Freak.Addon.author = author or "Unknown";	
		Freak.Addon.debug = dbg or false;	
		
		Freak.Event:AddHandler("ON_COMPONENT_LOAD", Freak.IsReady);
		Freak.Event:AddHandler("ON_PLAYER_READY", Freak.IsReady);
		Freak.Event:AddHandler("ON_STREAM_PROGRESS", Freak.IsReady);
		
		Freak.Event:AddHandler("ON_UI_ENTITY_AVAILABLE", Freak.LoadingBuffer);
		Freak.Event:AddHandler("ON_UI_ENTITY_LOST", Freak.LoadingBuffer);
		Freak.Event:AddHandler("ON_ITEM_SEARCH_COMPLETED", Freak._ItemSearchComplete);
		
		Freak.Event:AddHandler("ON_UI_ENTITY_FOCUS", function(e) Freak.Player._TargetId = e.entityId end);			
		
	end,
	_OnReady = function()
		Freak.Event:RemoveHandler("ON_UI_ENTITY_AVAILABLE", Freak.LoadingBuffer);
		Freak.Event:RemoveHandler("ON_UI_ENTITY_LOST", Freak.LoadingBuffer);		
		Freak.OnReady();
	end,
	OnReady = function() end,
	IsReady = function()
		if Freak.Addon.ready then return true; end		
		if not Game or not Player then return false end;
		
		if Game.GetLoadingProgress() == 1 and Player.IsReady() and not Freak.Addon.ready then	
			Freak.Addon.ready = true;					
			callback(function() Freak._OnReady(); Freak.Event:DispatchEvent("ON_READY"); end, nil, 0.5);
			return true;
		else
			return false;
		end
	end,
	
	OnAllEvents = function() end,

}

Freak.InterfaceOptions = function(enableCheckbox, saveVersion)
	local self = {}
	self.components = {}
	self.values = {}
			
	self.OnEnabled = Freak.Util.Dummy;
	self.OnDisabled = Freak.Util.Dummy;
	
	self.OnOptionChange = function(id, val)
		if id == "ENABLED" then
			
			if not Freak.Addon.enabled  and val then
				Freak.IsReady();
				self.OnEnabled();
			elseif Freak.Addon.enabled  and not val then
				self.OnDisabled();
			end
			Freak.Addon.enabled = val				
			for k, v in pairs(self.components) do
				InterfaceOptions.DisableOption(k, not Freak.Addon.enabled);
			end
		else
			if self.components[id] then
				self.components[id](val);
			end
		end
		self.values[id] = val;
	end
			
	self.StartGroup = function(options, OnChange)
		self.components[options.id] =  OnChange or function() end;
		InterfaceOptions.StartGroup(options);		
	end
	self.StopGroup = function()
		InterfaceOptions.StopGroup();
	end	
	self.AddMultiArt = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddMultiArt(options);
	end
	self.AddButton = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddButton(options); 
	end
	self.AddCheckBox = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddCheckBox(options);
	end
	self.AddSlider = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddSlider(options); 
	end
	self.AddTextInput = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddTextInput(options);
	end
	self.AddColorPicker = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddColorPicker(options);
	end
	self.AddChoiceMenu = function(options, OnChange) 
		self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddChoiceMenu(options);
	end
	self.AddChoiceEntry = function(options, OnChange)
		--self.components[options.id] = OnChange or function() end;
		InterfaceOptions.AddChoiceEntry(options);
	end
	self.DisableOption = function(ID, bool)
		InterfaceOptions.DisableOption(ID, bool);
	end
	self.EnableOption = function(ID, bool)
		InterfaceOptions.EnableOption(ID, bool);
	end
	self.UpdateLabel = function(ID, label, key)
		InterfaceOptions.UpdateLabel(ID, label, key);
	end		
	self.AddMovableFrame = function(options) 
		self.components[options.frame] = nil;
		InterfaceOptions.AddMovableFrame(options);
	end
	self.ChangeFrameHeight = function(frame, val)
		InterfaceOptions.ChangeFrameHeight(frame, val);
	end
	self.ChangeFrameWidth = function(frame, val)
		InterfaceOptions.ChangeFrameWidth(frame, val);
	end
	self.UpdateMovableFrame = function(frame)
		InterfaceOptions.UpdateMovableFrame(frame);
	end 
	self.DisableFrameMobility = function(frame, bool)
		InterfaceOptions.DisableFrameMobility(frame, bool);
	end	
	self.GetValue = function(id)
		return self.values[id];
	end
	
	Freak.Addon.saveVersion = saveVersion or 1.0;		
	InterfaceOptions.SaveVersion(Freak.Addon.saveVersion);
	InterfaceOptions.NotifyOnDefaults(true);
	InterfaceOptions.SetCallbackFunc(self.OnOptionChange, Freak.Addon.name);
	
	if enableCheckbox == true then
		InterfaceOptions.AddCheckBox({id="ENABLED", label="Enabled", default=true});
	else
		self.OnOptionChange("ENABLED", true);
	end
	
	return self;
end

Freak.Dbg = function(message, always, sender)
	if Freak.Addon.debug or always then
		local split = Freak.Util.SplitLines(tostring(message));	
		local s = sender or "["..Freak.Addon.name.."]";
		for key,value in pairs(split) do
			Component.GenerateEvent("MY_SYSTEM_MESSAGE", {json=tostring({channel="whisper", text=s..": "..tostring(value)})})
		end		
	end
end

Freak.Util = {
	DeepCompare = function(t1,t2,ignore_mt)
		local ty1 = type(t1);
		local ty2 = type(t2);
		if ty1 ~= ty2 then return false; end
		if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2; end
		local mt = getmetatable(t1);
		if not ignore_mt and mt and mt.__eq then return t1 == t2; end				
		for k1,v1 in pairs(t1) do
			local v2 = t2[k1];
			if v2 == nil or not Freak.Util.DeepCompare(v1,v2) then return false; end
		end				
		for k2,v2 in pairs(t2) do
			local v1 = t1[k2];
			if v1 == nil or not Freak.Util.DeepCompare(v1,v2) then return false; end
		end			
		return true;
	end,
	
	SplitLines = function(str)
	  local t = {};
	  local function helper(line) table.insert(t, line); return ""; end
	  helper((str:gsub("(.-)\r?\n", helper)));
	  return t;
	end,
	
	Distance = function(x1, x2, y1, y2, z1, z2)		
		local dx = 0;
		local dy = 0;
		local dz = 0;	
		if x1 and x2 then dx = math.pow(x1 - x2, 2); end;
		if y1 and y2 then dy = math.pow(y1 - y2, 2); end;
		if z1 and z2 then dz = math.pow(z1 - z2, 2); end;		
		return math.sqrt(dx + dy + dz);
	end,
	
	Clamp = function(num, low, high)
		return math.min(math.max(num, low), high);
	end,
	
	PairsByKeys = function(t, f)
		local a = {};
		for n in pairs(t) do table.insert(a, n); end;
		table.sort(a, f);
		local i = 0;
		local iter = function ()
			i = i + 1;
			if a[i] == nil then return nil;
			else return a[i], t[a[i]];
			end
		end
		return iter;
    end,
	
	Dummy = function(a,b,c,d,e,f) end;
}

Freak.Queue = function()
	local self = {}		
		self.q = {first = 0, last = -1}					
		self.PushLeft = function(value)
			self.q.first = self.q.first - 1;
			self.q[self.q.first] = value;
		end
		self.PushRight = function(value)
			self.q.last = self.q.last + 1;
			self.q[self.q.last] = value;
		end	
		self.PopLeft = function()			
			if self.IsEmpty() then return nil; end			
			local value = self.q[self.q.first];
			self.q[self.q.first] = nil;
			self.q.first = self.q.first + 1;
			return value;					
		end	
		self.PopRight = function()			
			if self.IsEmpty() then return nil; end			
			local value = self.q[self.q.last];
			self.q[self.q.last] = nil;
			self.q.last = self.q.last - 1;
			return value;					
		end								
		self.Contains = function(obj)					
			if self.IsEmpty() then return false; end
			for i = self.q.first, self.q.last do						
				if Freak.DeepCompare(obj, self.Peek(i), false) then return true; end													
			end
			return false;
		end				
		self.Peek = function(entry)
			if entry < self.GetStart() or entry > self.GetEnd() then return nil; end
			return self.q[entry];
		end					
		self.GetStart = function()
			return self.q.first;
		end
		self.GetEnd = function()
			return self.q.last;
		end					
		self.IsEmpty = function()
			return self.q.first > self.q.last;
		end
		self.Replace = function(entry, obj)
			if entry and self.q[entry] and obj then
				self.q[entry] = obj;
			end
		end
	return self;
end

Freak.Http = function()
	local self = {};
		self._q = Freak.Queue();		
		self._c = function(a, e)
			if not self._q.IsEmpty() then
				_r = self._q.PopRight();
				self.Request(_r.url, _r.callback, _r.data);
			end			
		end
		self.Request = function(url, callback, data)
			if url and callback then
				if not HTTP.IsRequestPending(url) then
					HTTP.IssueRequest(url, (data == nil and 'get' or 'post'), data, function(a, e) self._c(a, e); callback(a, e); end);
				else
					_r = {};
					_r.url = url;
					_r.callback = callback;
					_r.data = data;
					self._q.PushLeft(_r);
				end				
			end
		end		
	return self;
end

Freak.Socket = function()
	local self = {};
	
	self._web = Component.GetFrame("WebFrame");
	self._url = "";	
	self._connect = false;
	self._connected = false;
	self._ready = false;
	
	self._callbacks = {};
	self._permanent = {};
	self._callback_id = 1;
	self._callback = function(id, arg1, arg2)
		if self._callbacks[id] ~= nil then
			self._callbacks[id](arg1, arg2);	
			if self._permanent[id] == nil then
				self._callbacks[id] = nil;
			end
		end	
	end
	
	self._AddCallback = function(cb, permanent)
		local id = 0;	
		for i=1,100000 do
			if self._callbacks[i] == nil then
				id = i;
				if permanent then
					self._permanent[i] = true;
				end
				break;
			end
		end
		self._callbacks[id] = cb;
		return id;
	end
	
	self.Connect = function(url)
		self._connect = true;
		self._url = url;
		self._web:AddWebCallback("callback", self._callback);
		self._web:AddWebCallback("connect", function(msg) self._connected = true; self.OnConnect(msg) end);
		self._web:AddWebCallback("disconnect", function(msg) self._connected = false; self.OnDisconnect(msg) end);
	    self._web:SetUrlFilters("*");
		self._web:LoadUrl(url);
		self._web:Show(true);		
	end
	
	self.Disconnect = function(url)
		self._connect = false;
		self._url = "";
		self._web:LoadUrl("about:blank");
	end
	
	self.IsConnected = function()
		return self._connected;
	end
	
	self.OnConnect = function(msg) end
	self.OnDisconnect = function(msg) end
	self.OnReady = function() end
	
	self.On = function(eventIdentity, cb)			
		self._web:CallWebFunc("On", eventIdentity, self._AddCallback(cb, true));	
	end
	
	self.Get = function(url, data, cb)			
		self._web:CallWebFunc("Get", url, data, self._AddCallback(cb));	
	end
	
	self.Post = function(url, data, cb)			
		self._web:CallWebFunc("Post", url, data, self._AddCallback(cb));	
	end
	
	self._web:BindEvent("OnNavigationFinished", function(e)
		if self._connect then
			if not self._ready then
				self._ready = true;
				self.OnReady();
			end;
		else
			self.OnDicsonnect();
		end	
	end);
	
	return self;
end

Freak.EntityTracker = function(_type, search, filter)
	local self = {};
	
	self._searching = false;
	self._entities = {};
	self._type = _type;
	self._search = search;
	
	self._available = function(event)
		local entity = Game.GetTargetInfo(event.entityId);
		local foundName = true;
		local foundType = true;
		local name = "";
		if entity then 
			if entity.name ~= nil then
				name = string.lower(entity.name);
			elseif entity.deployableType ~= nil then
				name = string.lower(entity.deployableType);
			else
				return;
			end		
			if self._type ~= nil and type(self._type) == "table" then
				foundType = false;
				for i = 1,  #self._type do
					if entity.type == self._type[i] then
							foundType = true;
							break;
					end	
				end
				if foundType == false then
					return;
				end
			end		
			if self._search ~= nil and type(self._search) == "table" then
				foundName = false;
				for i = 1,  #self._search do
					if string.find(name, self._search[i]) then
							foundName = true;
							break;
					end	
				end
				if foundName == false then
					return;
				end
			end				
			if foundType and foundName then
				entity.lname = name;
				self._entities[tostring(event.entityId)] = entity;
				self.OnAvailable(entity);
			end			
		end
	end	
	self._lost = function(event)
		if self.IsTracking(event.entityId) then
			local entity = self._entities[event.entityId];
			self._entities[tostring(event.entityId)] = nil;
			self.OnLost(entity);
		end
	end	
	
	self.IsTracking = function(entityId)
		return self._entities[entityId] ~= nil;
	end		
	self.GetClosest = function(num)
		num = num or 1;
		local closest = {};
		local pPos = Player.GetPosition();
		for id, entity in pairs(self._entities) do
			if id == "" then break end;						
			local ePos = Game.GetTargetBounds(id);		
			if(ePos ~= nil) then			
				local distance = math.floor(Freak.Util.Distance(pPos.x, ePos.x, pPos.y, ePos.y, pPos.z, ePos.z));					
				entity._id = id;
				if filter == nil or filter(entity) then
					closest[distance] = {};
					closest[distance][1] = id;
					closest[distance][2] = distance;
					closest[distance][3] = ePos;
				end
			end
		end
		local count = 0;	
		local ret = {};

		for k,v in Freak.Util.PairsByKeys(closest) do	
			count = count + 1;
			if count > num then break end;
			ret[v[1]] = v;
		end	
		return ret;
	end
	self.Start = function()
		if self._searching == true then
			Freak.Dbg("EntityTracker is already running.");
		else
			if (self._type ~= nil and self._type ~= {}) or (self._search ~= nil  and self._search ~= {}) then
				Freak.Event:AddHandler("ON_UI_ENTITY_AVAILABLE", self._available);
				Freak.Event:AddHandler("ON_UI_ENTITY_LOST", self._lost);			
			else
				Freak.Dbg("EntityTracker needs at least a type or a search-string to start tracking.");
			end
		end
	end
	self.Stop = function()
		if self._searching == false then
		else			
			Freak.Event:RemoveHandler("ON_UI_ENTITY_AVAILABLE", self._available);
			Freak.Event:RemoveHandler("ON_UI_ENTITY_LOST", self._lost);
			self._entities = {};
		end
	end
	self.OnAvailable = function() end
	self.OnLost = function() end	
		
	local i;
	for i = 1, #Freak._LoadingBuffer  do			
		local _tmp = Freak._LoadingBuffer[i];			
		if _tmp.event == "on_ui_entity_available" then
			self._available(_tmp);
		else
			self._lost(_tmp);
		end
	end			
	
	self.Start();
	
	return self;
end

Freak.MultiMarker = function (texture, textureRegion, color, titleText, bodyText, showOnWorldMap, showOnRadar, showOnHud)
	local self = {}		
		self.markers = {};
		self.index = {};
		
		self.count = 1;
		self.settings = {texture = texture, textureRegion = textureRegion, color = color, titleText = titleText, bodyText = bodyText, showOnWorldMap = showOnWorldMap, showOnRadar = showOnRadar, showOnHud = showOnHud};			
		self._Add = function()
			local marker = MapMarker.Create();
			marker:GetIcon():SetTexture(self.settings.texture, self.settings.textureRegion);
			marker:GetIcon():SetParam("tint", self.settings.color)
			marker:SetThemeColor(self.settings.color)
			marker:ShowOnWorldMap(false)
			marker:ShowOnRadar(false)
			marker:ShowOnHud(false);
			self.markers[self.count] = marker;
			self.index[self.count] = false;
			self.count = self.count + 1;
		end
	
		self._GetFree = function()
			for k, v in pairs(self.index) do
				if v == false then
					return k;
				end
			end
			self._Add();
			return self._GetFree();
		end
		
		self._GetById = function(id)
			for k, v in pairs(self.index) do
				if v == id then
					return k;
				end
			end
		end
		
		self.Add = function(id, pos, title, body)		
		
			local x = self._GetById(id);			
			if x == nil then
				x = self._GetFree();
			end
			
			self.markers[x]:SetTitle(title or self.settings.titleText)
			self.markers[x]:SetBodyText(body or self.settings.bodyText)
			self.markers[x]:BindToPosition(pos)
			self.markers[x]:ShowOnWorldMap(self.settings.showOnWorldMap)
			self.markers[x]:ShowOnRadar(self.settings.showOnRadar)
			self.markers[x]:ShowOnHud(self.settings.showOnHud);
			self.index[x] = id;
			
		end
		self.Remove = function(id)
			local x = self._GetById(id);			
			if x ~= nil then		
				self.markers[x]:ShowOnWorldMap(false)
				self.markers[x]:ShowOnRadar(false)
				self.markers[x]:ShowOnHud(false);
			end
			
			for k, v in pairs(self.index) do
				if v == id then
					v = false;
				end
			end
		end		
		
		self.Clear = function(exept)
			
			exept = exept or {};
		
			for k, v in pairs(self.index) do
				if v and not exept[v] then
					self.Remove(v);
				end
			end
		end		
		self.Has = function(id)
			return self._GetById(id) ~= nil;
		end		
	return self;
end

Freak._ItemSearchCallbacks = {};
Freak._ItemSearchComplete = function(e)
	if Freak._ItemSearchCallbacks[e.search_id] then
		Freak._ItemSearchCallbacks[e.search_id](e.tokens);
		Freak._ItemSearchCallbacks[e.search_id] = nil;
	end
end

Freak.ItemSearch = function(search, callback)
	Freak._ItemSearchCallbacks[Game.StartItemSearch({
		item_type="any",
		match_string=search,
	})] = callback;
end


Freak.InventorySearch = function(search)
	search = search or {};
	local items, resources = Player.GetInventory();
	local ret = {};
	local split = {};
	local found = false;
	
	for ik, iv in pairs(items) do
		found = false;
		for sk, sv in pairs(search) do
			if string.find(string.lower(iv.name), sv) then
				found = true;
				break;
			end
		end
		
		if found then
			table.insert(ret, iv);
		end
	end
	
	return ret;	
end

Freak.ButtonSelector = function(saveName, label, options, inventorySearch, showCount, callback)
	if not saveName then return nil; end;
	if not type(options) == "table" or #options < 1 then return nil; end;
	
	local self = {};
	
		self.index = 1;
		self.saveName = saveName;
		self.label = label or "";
		self.options = options or {};
		self.search = inventorySearch;
		self.inventory = {};
		self.callback = callback;
		
		UI.AddButton({id=self.saveName, label=self.label}, function(v) self.Next(); self.UpdateLabel(); end);
		
		if showCount then
			self.showCount = true;
		else
			self.showCount = false;
		end
		
		self._callback = function()
			if callback and type(callback) == "function" then
				callback({index = self.index, name = self.GetIndexName(), itemId = self.GetItemId()});
			end
		end
		
		self.OnReady = function()
			if self.search then
				self.inventory = Freak.InventorySearch(self.search);
			end	
			self.index = Component.GetSetting(saveName) or 1;
			self.UpdateLabel();		
			self._callback();
		end	
					
		self.Next = function()
			
			if table.getn(self.options) > 0 then		
				self.index = self.index + 1;
				if self.index > table.getn(self.options) then self.index = 1; end
			else
				self.index = 1;
			end	
			
			if self.search then
				self.inventory = Freak.InventorySearch(self.search);
				
				has = false;			
				for k, v in pairs(self.inventory) do	
					if v.name == self.options[self.index] then
						has = true;
						break;	
					end
				end	
							
				if has or self.index == 1 then
					Component.SaveSetting(saveName, self.index);
					self._callback();
				else
					self.Next();
				end
				
			else
				Component.SaveSetting(saveName, self.index);
				self._callback();
			end		
		end
		
		self.UpdateLabel = function()
			UI.UpdateLabel(self.saveName, self.label .. " " .. self.GetIndexName(), false);
		end
		
		self.GetIndex = function()
			return self.index;
		end
		
		self.GetIndexName = function()
			
			local quantity = "";
			if self.showCount then					
				local item = self.GetItem();					
				if item and item.quantity  > 0 then
					quantity =  " (".. item.quantity .. ")";
				end					
			end
			
			return self.options[self.index] .. quantity;
		end
		
		self.GetItem = function()
			for k, v in pairs(self.inventory) do
				if v.name == self.options[self.index] then
					return v;
				end
			end	
		end
		
		self.GetItemId = function()
			local item = self.GetItem();					
			if item and item.item_sdb_id then
				return item.item_sdb_id;
			end		
		end
		
	Freak.Event:AddHandler("ON_READY", self.OnReady);	
	return self;
end

Freak.AutoSlot = function(slotNum)
	local self = {};
		self.slot = Freak.Util.Clamp(slotNum, 1, 4);
		self.default = {};
		self.items = {};
		self.show = {};
		self.old = {};
		self.ignore = false;
		self.ready = false;
		self._Glow = function() end;
		
		self.SetDefaultItemId = function(index, sdb_id)
			self.default[index] = sdb_id;
		end;
		
		self.AddItem = function(dataFunction)
			local item = {};
				item.dataFunction = dataFunction;
				item.Update = function()
					local data = dataFunction();
					item.priority = data.priority;
					item.itemId = data.itemId;
					item.show = data.show;
					item.playerGlow = data.playerGlow;
				end;	
				item.Destroy = function()
					item = nil;
				end;
	
			if type(dataFunction) == "function" then
				table.insert(self.items, item);
			end		
		end;
		
		self.Update = function(clear, force)
			if self.ready then
				self.show = nil;
				for k, item in pairs(self.items) do
					item.Update();
					if item and item.show then			
						if not self.show or item.priority > self.show.priority then					
							self.show = item;		
						end			
					end
				end;
					
				if self.show and not clear then	
					if self.show.itemId ~= self.old[self.slot] or force then		
						self.ignore = true;						
						Player.SlotTech(nil, self.show.itemId, self.slot);			
						self.old[self.slot] = self.show.itemId;
						self._Glow(self.show.playerGlow);
					end
				else
					if self.default[self.slot] ~= self.old[self.slot] or clear then	
						self.ignore  = false;					
						Player.SlotTech(nil, self.default[self.slot], self.slot);
						self.old[self.slot] = self.default[self.slot];
						self._Glow(0);
					end
				end
			end
		end;
		
		self.ChangeSlot = function(slot)
			self.Update(true);
			self.slot = Freak.Util.Clamp(slot, 1, 4);
			self.Update();
		end
		
		self._OnAbilitiesChange = function(e)			
			if not self.ignore and self.ready then
			local as = Freak.Player.CurrentActionSet();
				for k, v in pairs(as) do
					if self.default[k] ~= v and self.old[k] ~= v  then
						self.default[k] = v;
						Component.SaveSetting('ss.defaultAction'..k, v);
					end
				end
			elseif self.ignore  then		
				--self.ignore = self.ignore - 1;		
			end
		end
		
		self._OnReady = function()
			local as = Freak.Player.CurrentActionSet();
			self.default[1] = Component.GetSetting('ss.defaultAction1') or as[1];
			self.default[2] = Component.GetSetting('ss.defaultAction2') or as[2];
			self.default[3] = Component.GetSetting('ss.defaultAction3') or as[3];
			self.default[4] = Component.GetSetting('ss.defaultAction4') or as[4];
			self.ready = true;
		end,
		
		Freak.Event:AddHandler("ON_ABILITIES_CHANGED", self._OnAbilitiesChange);
		Freak.Event:AddHandler("ON_READY", self._OnReady);
	return self;
end

Freak.Player = {
	
	AmmoPercent = function()
		local info = Player.GetWeaponInfo();
		local state = Player.GetWeaponState();	
		if info and state then
			return (state.Ammo + state.Clip) / (info.MaxAmmo + info.ClipSize)*100;
		else
			return 100;
		end
	end,

	HealthPercent = function()
		local life = Player.GetLifeInfo()
		local health = life.Health / life.MaxHealth * 100;	
		if life.Health == nil then
			return 100;
		else
			return  health;
		end
	end,
	
	CurrentActionSet = function()
		local ab = Player.GetAbilities();
		local ret = {};
		ret[1] = tonumber(Player.GetAbilities()["action1"] and Player.GetAbilities()["action1"].itemTypeId);
		ret[2] = tonumber(Player.GetAbilities()["action2"] and Player.GetAbilities()["action2"].itemTypeId);
		ret[3] = tonumber(Player.GetAbilities()["action3"] and Player.GetAbilities()["action3"].itemTypeId);
		ret[4] = tonumber(Player.GetAbilities()["action4"] and Player.GetAbilities()["action4"].itemTypeId);
		return ret;
	end,
	
	ItemReady = function(itemId)
		local itemInfo = Game.GetItemInfoByType(itemId);
		if itemInfo and itemInfo.abilityId then
			if Player.GetItemCount(itemId) > 0 then
				return Freak.Player.AbilityReady(itemInfo.abilityId);
			else
				return false;
			end
		end
		return false;
	end,
	
	ItemCooldown = function(itemId)
		local itemInfo = Game.GetItemInfoByType(itemId);
		if itemInfo and itemInfo.abilityId then
			return Freak.Player.AbilityCooldown(itemInfo.abilityId);
		end
		return 0;
	end,
	
	AbilityReady = function(abilityId)
		local abilityState = Player.GetAbilityState(abilityId);
		if abilityState and abilityState.isReady or (abilityState.requirements and abilityState.requirements.remainingCooldown == nil)  then
			return true;
		end
		return false;		
	end,
	
	AbilityCooldown = function(abilityId)
		local abilityState = Player.GetAbilityState(abilityId);
		if abilityState.requirements then
			return abilityState.requirements.remainingCooldown or 0;
		end
		return 0;		
	end,
	
	
	_TargetId = nil;
	Target = function()
		if Freak.Player._TargetId then
			return Game.GetTargetInfo(Freak.Player._TargetId);
		end
	end,
	
	--1 = white
	--2 = thick white
	--3 = lime green
	--4 = light blue
	--5 = purple
	--6 = dirt orange
	--7 = light yellow
	--8 = red
	--9 = green
	Glow = function(color)
		local pid = Player.GetTargetId();
		if pid then
			Game.HighlightEntity(pid, color or 0);
		end
	end,
	
	AimDistance = function()
		local apos = Player.GetAimPosition();
		local pos = Player.GetPosition();
		return Freak.Util.Distance(apos.x, pos.x, apos.y, pos.y, apos.z, pos.z);
	end,
	
};
Freak.Event = {};
local __DISP = EventDispatcher.Create():Delegate(Freak.Event);
function freak(e) Freak.Event:DispatchEvent(string.upper(e.event), e);end

-- used by the entity trackers..
Freak._LoadingBuffer = {};
Freak.LoadingBuffer = function(event)Freak._LoadingBuffer[#Freak._LoadingBuffer+1] = event;end