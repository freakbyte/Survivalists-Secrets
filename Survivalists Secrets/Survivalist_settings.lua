survivalist = {
	enabled = false,
	criticalHealth = 70,
	criticalAmmo = 25,
	maxMarkerCount = 3,
	health = {},
	ammo = {},
	superCriticalHealth = 50,
	superCriticalAmmo = 10
};
thanks = {
	enabled = false,
	text = "Thanks {doc}! You're my hero!",
	channel = 1,
	emote="wave",
	squad = false,
	squadText = "<3",
	duel = false,
	duelText = "You just got lucky, I was out of ammo.",
};
misc = {
	enabled = false,
	sonic = false,
	hammer = false,
	lastScan = 0,
	thumper = {};
	glow = false,
	energy = false,
	energyInfo = {max=100, current=100, percent = 100},
	slot = 4,
	hud = false,
	freq = 0.3,
	slotChange = function() end;
};

function BuildUIOptions()
	
	-- survivalist options
	UI.StartGroup({label="Survivalists secrets", id="SURVIVALIST", checkbox=true, default=false}, function(v) survivalist.enabled = v; Survivalist(v); end);
	UI.AddSlider({id="SURVIVALIST_HEALTH", label="Find health packs if health drops below", default=70, min=0, max=99, inc=1, suffix="%"}, function(v) survivalist.criticalHealth = v; end);
	UI.AddSlider({id="SURVIVALIST_AMMO", label="Find ammo packs if ammo drops below", default=25, min=0, max=99, inc=1, suffix="%"}, function(v) survivalist.criticalAmmo = v; end);
	UI.AddSlider({id="SURVIVALIST_COUNT", label="How many markers can be shown at once?", default=3, min=0, max=10, inc=1, suffix=" "}, function(v) survivalist.maxMarkerCount = v; end);

	UI.AddSlider({id="SURVIVALIST_A_HEALTH", label="Auto equip health pack if health drops below", default=50, min=0, max=99, inc=1, suffix="%"}, function(v) survivalist.superCriticalHealth = v; end);
	UI.AddSlider({id="SURVIVALIST_A_AMMO", label="Auto equip ammo pack if ammo drops below", default=10, min=0, max=99, inc=1, suffix="%"}, function(v) survivalist.superCriticalAmmo = v; end);


	UI.AddSlider({id="SURVIVALIST_SLOT", label="What slot should be used for auto equipping", default=8, min=5, max=8, inc=1, suffix=""}, function(v) misc.slot = v-4; misc.slotChange(); end);	
	UI.AddSlider({id="SURVIVALIST_FREQUENCY", label="Update frequency (default=0.3s lower=faster)", default=0.3, min=0.1, max=0.5, inc=0.1, suffix="s"}, function(v) misc.freq = v; end);	
	UI.AddCheckBox({id="SURVIVALIST_AUTO_AMMO", label="Auto equip ammo packs?", default = false}, function(v) survivalist.ammo = v; end);
	Freak.ButtonSelector("SURVIVALIST_AUTO_HEALTH", "Auto equip health pack:", HEALTH_NAMES, {"health", "stim", "gesundheitspack", "trousse"}, true, function(v) survivalist.health = v; end);
	UI.StopGroup()

	UI.StartGroup({label="Miscellaneous", id="MISC", checkbox=true, default=false}, function(v) misc.enabled = v; end);
	UI.AddCheckBox({id="MISC_HUD", label="Show cooldown indicator", default = false}, function(v) misc.hud = v; end);
	UI.AddCheckBox({id="MISC_GLOW", label="Make player glow when auto equipping", default = false}, function(v) misc.glow = v; end);
	UI.AddCheckBox({id="MISC_SONIC", label="Auto equip sonic detonators", default = false}, function(v) misc.sonic = v; end);
	UI.AddCheckBox({id="MISC_ENERGY", label="Auto equip energy packs", default = false}, function(v) misc.energy = v; end);
	UI.AddCheckBox({id="MISC_HAMMER", label="Auto equip scan hammer (look at your feet)", default = false}, function(v) misc.hammer = v; end);
	Freak.ButtonSelector("MISC_THUMPER", "Auto equip thumper after scan:", THUMPER_NAMES, {"thumper"}, true, function(v) misc.thumper = v; end);
	UI.StopGroup();
	
	-- thanks doc  options
	UI.StartGroup({label="Thanks doc!", id="THANKS", checkbox=true, default=false}, function(v) thanks.enabled = v; end);
	UI.AddTextInput({id="THANKS_TEXT", label="What should we say?  {doc} = your saviour", default=thanks.text}, function(v) thanks.text  = v; end);
	UI.AddTextInput({id="THANKS_EMOTE", label="What emote should we play?  blank = none", default=thanks.emote}, function(v) thanks.emote  = v; end);
	Freak.ButtonSelector("THANKS_CHANNEL", "Default channel to use: ", {"Local", "Zone", "Yell", "Whisper"}, nil, nil, function(v) thanks.channel = v.index; end);
	UI.StopGroup()
	
end