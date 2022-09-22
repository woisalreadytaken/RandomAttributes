void Command_Init()
{
	RegAdminCmd("sm_ra_refresh", Command_RefreshConfigs, ADMFLAG_RCON, "Refreshes Random Attributes' configs.");
}

public Action Command_RefreshConfigs(int iClient, int iArgs)
{
	Config_RefreshAttributes();
	Config_RefreshSettings();
	
	// Server already gets a message about this, so make it show to clients only
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
		ReplyToCommand(iClient, "Refreshed Random Attributes' attributes. It now sees %d attributes.", g_aAttributes.Length);
	
	return Plugin_Handled;
}