#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <freerun>

#define PLUGIN_VERSION "1.35"

#pragma semicolon 1
#pragma newdecls required

ConVar g_hEnabled, g_hTime, g_hPrefix;

float g_fFreerunTime;
char g_sPrefixName[128];

int g_bEnabled;
bool g_bFreerun = false;
bool g_bFreerunTime = false;

Handle g_hFreerun, g_hOnFreerun;

public Plugin myinfo =
{
	name = "Freerun!",
	author = "Cruze",
	description = "Freerun plugin for deathrun mod because freerun is freerun! ok?",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnFreerun = CreateGlobalForward("FR_OnFreerun", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hEnabled          = CreateConVar("sm_freerun_enable", "1", 												"Whether to enable plugin. 1 to enable, 0 to disable.");
	g_hPrefix         	 = CreateConVar("sm_freerun_prefix", "[{purple}♚ {green}FreeRun {purple}♚{default}] ", "Prefix of the plugin. Leave blank for no prefix.");
	g_hTime             = CreateConVar("sm_freerun_time", "120.0", 											"The time during which T can enter the command. 120.0 = ✔. 120 = ✖");
   
	HookEvent("round_start", OnFreerunRoundStart);
   
	RegConsoleCmd("sm_fr", CMD_Freerun);
	RegConsoleCmd("sm_freerun", CMD_Freerun);
   
	AutoExecConfig(true, "dr_freerun");
	LoadTranslations("cruze_freerun.phrases");
	
	HookConVarChange(g_hEnabled, OnSettingChanged);
	HookConVarChange(g_hTime, OnSettingChanged);
	HookConVarChange(g_hPrefix, OnSettingChanged);
}
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue, true))
        return;

	bool iNewValue = !!StringToInt(newValue);

	if(convar == g_hEnabled)
	{
		g_bEnabled = (iNewValue);
	}
	else if (convar == g_hTime)
	{
		g_fFreerunTime = StringToFloat(newValue);
	}
	else if (convar == g_hPrefix)
	{
		Format(g_sPrefixName, sizeof(g_sPrefixName), newValue);
	}
}
public void OnMapStart()
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fFreerunTime	= GetConVarFloat(g_hTime);
	
	GetConVarString(g_hPrefix, g_sPrefixName, sizeof(g_sPrefixName));
	
	g_hFreerun = null;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_button")) SDKHook(entity, SDKHook_Use, OnButtonUse);
}
public void OnFreerunRoundStart(Handle event, char[] name, bool dbc)
{
	g_bFreerun = false;
	g_bFreerunTime = true;
	delete g_hFreerun;
	g_hFreerun = CreateTimer(GetConVarFloat(g_hTime), freeruntime, _, TIMER_FLAG_NO_MAPCHANGE);
	for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2)
        {
			
			if (g_bEnabled)
				//CPrintToChat(i,"%s Type {green}!fr{default} to give {blue}Counter-Terrorists {default}a {green}freerun!", g_sPrefixName);
				CPrintToChat(i,"%s%t", g_sPrefixName, "RoundStart Message");
        }
    }
}
 
public Action freeruntime(Handle timer)
{
	g_hFreerun = null;
	g_bFreerunTime = false;
}
 
public Action CMD_Freerun(int client, int args)
{
	if (g_bEnabled)
	{
		if (IsPlayerAlive(client))
		{
			if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) 
			{
				//CPrintToChat(client, "%s You need to be {orange}Terrorist {default}in order have access to this command!", g_sPrefixName);
				CPrintToChat(client, "%s%t", g_sPrefixName, "You need to be T");
				return Plugin_Handled;
			}
			if (g_bFreerunTime)
			{
				Call_StartForward(g_hOnFreerun);
				Call_PushCell(client);
				Call_Finish();
				
				g_bFreerun = true;
				for(int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if(IsClientInGame(iClient) && GetClientTeam(iClient) == 3)
					{
						//CPrintToChat(iClient, "%s{orange}Terrorist{default} can no longer press trap buttons!", g_sPrefixName);
						CPrintToChat(iClient, "%s%t", g_sPrefixName, "FreerunCTMsg");
					}
				}
				//CPrintToChatAll("%s The {orange}Terrorist {default}decided to give a {green}FREERUN {default}to everyone this round, {green}RUN! {default}:D", g_sPrefixName);
				CPrintToChatAll("%s%t", g_sPrefixName, "g_bFreerun!");
				PrintHintTextToAll("%t", "g_bFreerun Hint!");
				//PrintHintTextToAll("<b>Its <font color='#00ff00'>FREERUN!</font></b>");
			}
			else if (g_bFreerun) 
			{
				//CPrintToChat(client, "%s You have already used this command!", g_sPrefixName);
				CPrintToChat(client, "%s%t", g_sPrefixName, "Already Used");
			}
			else
			{
				int frTime = RoundToFloor(g_fFreerunTime);
				//CPrintToChat(client, "%s You can use this command in first {darkred}%d {default}seconds only!", g_sPrefixName, frTime);
				CPrintToChat(client, "%s%t", g_sPrefixName, "Too Late", frTime);
			}
		}
		else
		{
			//CPrintToChat(client, "You need to be alive to use this command!", g_sPrefixName);
			CPrintToChat(client, "%s%t", g_sPrefixName, "You need to be alive");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (strcmp(sArgs, "fr", false) == 0 || strcmp(sArgs, "freerun", false) == 0)
	{
		CMD_Freerun(client, 0);
	}
}

public Action OnButtonUse(int entity, int activator, int client, UseType type, float value)
{
	if(client == 0 || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	if(g_bFreerun)
	{ 
		if(GetClientTeam(client) == 2)
		{
			//CPrintToChat(client, "%s {lightgreen}You can not activate any {darkred}Traps{lightgreen} as you decided to give freerun. {darkred}Deal {green}with {blue}it.{default}", g_sPrefixName);
			CPrintToChat(client, "%s%t", g_sPrefixName, "You cannot activate"); 
			return Plugin_Handled;
		}
		else if(GetClientTeam(client) == 3)
		{
			//CPrintToChat(client, "{lightgreen}You can not activate any {darkred}Traps{lightgreen} as {orange}Terrorist{lightgreen} gave {blue}Counter-Terrorists{lightgreen} a freerun.", g_sPrefixName, "You cannot activate CT");
			CPrintToChat(client, "%s%t", g_sPrefixName, "You cannot activate CT");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
