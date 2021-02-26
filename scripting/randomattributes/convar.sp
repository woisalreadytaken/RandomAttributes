void ConVar_Init()
{
	g_cvEnabled = CreateConVar("sm_ra_enabled", "1", "Is Random Attributes enabled?", _, true, 0.0, true, 1.0);
	g_cvEnabled.AddChangeHook(ConVar_EnableChanged);
	g_cvApplyOnWeaponCreation = CreateConVar("sm_ra_applyonweaponcreation", "0", "Should attributes be applied when a weapon is created?\n0: No, only apply when inventory is refreshed. Meant for vanilla gamemodes or custom gamemodes that only give weapons upon spawning/inventory update (such as Randomizer)\n1: Yes. This option makes this plugin compatible with custom gamemodes/plugins that can give you custom weapons mid-round (such as Super Zombie Fortress) but has the side effect of applying attributes twice if weapons are given on player spawn", _, true, 0.0, true, 1.0);
	g_cvAttributesPerWeapon = CreateConVar("sm_ra_amount", "8", "Amount of random attributes to roll per weapon.", _, true, 1.0, true, 20.0);
	g_cvAttributesPerWeapon.AddChangeHook(ConVar_AmountChanged);
	g_cvAttributesPerWeaponUpdate = CreateConVar("sm_ra_amountupdate", "0", "Should attributes be rerolled the moment sm_ra_amount is changed?\n0: No, update when it otherwise would\n1: Yes", _, true, 0.0, true, 1.0);
	g_cvRerollSlot = CreateConVar("sm_ra_rerollslot", "0", "Should attributes be rerolled when a weapon in a slot is changed?\nNote: if sm_ra_rerolldeath is set to 0, this setting will still work if players choose to switch weapons (or are forced to, such as in the Randomizer gamemode)!", _, true, 0.0, true, 1.0);
	g_cvRerollDeath = CreateConVar("sm_ra_rerolldeath", "1", "Should attributes be rerolled when a player dies?\n0: No, only roll once per round\n1: Yes, excluding suicides\n2: Always", _, true, 0.0, true, 2.0);
}

void ConVar_EnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	switch (StringToInt(newValue))
	{
		case 0: Disable();
		default: Enable();
	}
}

void ConVar_AmountChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_cvEnabled.BoolValue || !g_cvAttributesPerWeaponUpdate.BoolValue)
		return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		UpdateClient(iClient);
		{
			for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
				ApplyToClientSlot(iClient, iSlot);
		}
	}
}