void Command_Init()
{
	RegAdminCmd("sm_ra_refresh", Command_RefreshConfigs, ADMFLAG_CHANGEMAP, "Refreshes both Random Attributes configs.");
	RegAdminCmd("sm_ra_refreshattributes", Command_RefreshAttributesConfig, ADMFLAG_CHANGEMAP, "Refreshes Random Attributes' attributes config.");
	RegAdminCmd("sm_ra_refreshsettings", Command_RefreshSettingsConfig, ADMFLAG_CHANGEMAP, "Refreshes Random Attributes' map settings config.");
}

public Action Command_RefreshAttributesConfig(int iClient, int iArgs)
{
	Config_RefreshAttributes();
	
	//Server already gets a message about this, so make it show to clients only
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
		ReplyToCommand(iClient, "Refreshed Random Attributes' attributes. It now sees %d attributes.", g_iAttributeAmount);
}

public Action Command_RefreshSettingsConfig(int iClient, int iArgs)
{
	Config_RefreshSettings();
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
		ReplyToCommand(iClient, "Attempted to refresh Random Attributes' map settings config.");

public Action Command_RefreshConfigs(int iClient, int iArgs)
{
	Command_RefreshAttributesConfig(iClient, iArgs);
	Command_RefreshSettingsConfig(iClient, iArgs);
}