#pragma semicolon 1
#pragma newdecls required

void ConVar_Init()
{
	g_cvEnabled = CreateConVar("sm_ra_enabled", "1", "Is Random Attributes enabled?", _, true, 0.0, true, 1.0);
	g_cvEnabled.AddChangeHook(ConVar_EnableChanged);
	g_cvActiveOnlyMode = CreateConVar("sm_ra_activeonly", "0", "Forces the 'provide on active' attribute onto weapons, making (or at least trying its best to make) passive effects only work when a weapon with them is active.", _, true, 0.0, true, 1.0);
	g_cvAttributesPerWeapon = CreateConVar("sm_ra_amount", "20", "Amount of random attributes to roll per weapon.", _, true, 1.0, true, 20.0);
	g_cvAttributesPerWeapon.AddChangeHook(ConVar_AmountChanged);
	g_cvAttributesPerWeaponUpdate = CreateConVar("sm_ra_amountupdate", "0", "Should attributes be rerolled the moment sm_ra_amount is changed?\n0: No, update when it otherwise would\n1: Yes", _, true, 0.0, true, 1.0);
	g_cvOnlyAllowTeam = CreateConVar("sm_ra_onlyallowteam", "", "Only allows the specified team to make use of this plugin's functionality. Accepts 'red' and 'blu(e)', anything else means we'll assume you're fine with both teams.");
	g_cvOnlyAllowTeam.AddChangeHook(ConVar_OnlyAllowTeamChanged);
	g_cvRerollDeath = CreateConVar("sm_ra_rerolldeath", "1", "Should attributes be rerolled when a player dies?\n0: No, only roll once per round\n1: Yes, excluding suicides\n2: Always", _, true, 0.0, true, 2.0);
	g_cvRerollSlot = CreateConVar("sm_ra_rerollslot", "0", "Should attributes be rerolled when a weapon in a slot is changed?\nNote: if sm_ra_rerolldeath is set to 0, this setting will still work if players choose to switch weapons (or are forced to, such as in the Randomizer gamemode)!", _, true, 0.0, true, 1.0);
}

void ConVar_EnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	switch (StringToInt(newValue))
	{
		case 0: Disable();
		default:
		{
			Enable();
			
			// Refresh configs
			Config_RefreshAttributes();
			Config_RefreshSettings();
		}
	}
}

void ConVar_AmountChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_cvEnabled.BoolValue || !g_cvAttributesPerWeaponUpdate.BoolValue)
		return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		UpdateClient(iClient);
		
		for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
			ApplyToClientSlot(iClient, iSlot);
	}
}

void ConVar_OnlyAllowTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrContains(newValue, "red", false) != -1)
	{
		g_nActiveTeam = TFTeam_Red;
	}
	else if (StrContains(newValue, "blu", false) != -1)
	{
		g_nActiveTeam = TFTeam_Blue;
	}
	else
	{
		g_nActiveTeam = TFTeam_Unassigned;
	}
	
	if (!g_cvEnabled.BoolValue)
		return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && g_nActiveTeam > TFTeam_Spectator && g_nActiveTeam != TF2_GetClientTeam(iClient))
		{
			for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
			{
				int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
				
				if (iWeapon > MaxClients)
					TF2Attrib_RemoveAll(iWeapon);
			}
		}
	}
}

