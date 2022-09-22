#pragma semicolon 1
#pragma newdecls required

void Event_Init()
{
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public Action Event_RoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			UpdateClientSlot(iClient, iSlot);
			ApplyToClientSlot(iClient, iSlot);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue || g_cvRerollDeath.IntValue <= 0)
		return Plugin_Continue;
		
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	bool bDeadRinger = (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) != 0;
	
	if (!bDeadRinger && ((0 < iAttacker <= MaxClients && IsClientInGame(iAttacker) && iClient != iAttacker) || g_cvRerollDeath.IntValue >= 2))
	{
		for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			UpdateClientSlot(iClient, iSlot);
			ApplyToClientSlot(iClient, iSlot);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PostInventoryApplication(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
	// Forcefully remove attributes if in the wrong team while the only-allow-team convar is enabled, but only once
	if (g_nActiveTeam > TFTeam_Spectator && g_nActiveTeam != TF2_GetClientTeam(iClient) && g_bCanRemoveAttributes[iClient])
	{
		for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
			
			if (iWeapon > MaxClients)
			{
				TF2Attrib_RemoveAll(iWeapon);
				TF2Attrib_ClearCache(iWeapon);
			}
		}
		
		g_bCanRemoveAttributes[iClient] = false;
	}
	
	RequestFrame(Frame_DisplayClientAttributes, iClient);
	
	return Plugin_Continue;
}