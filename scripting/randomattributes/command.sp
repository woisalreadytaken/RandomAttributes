void Command_Init()
{
	RegAdminCmd("sm_ra_refresh", Command_RefreshConfig, ADMFLAG_CHANGEMAP, "Refreshes Random Attributes' config.");
}

public Action Command_RefreshConfig(int iClient, int iArgs)
{
	Config_Refresh();
	
	//Server already gets a message about this, so make it show to clients only
	if (iClient > 0 && IsClientInGame(iClient))
		ReplyToCommand(iClient, "Refreshed Random Attributes' config. It now sees %d attributes.", g_iAttributeAmount);
}