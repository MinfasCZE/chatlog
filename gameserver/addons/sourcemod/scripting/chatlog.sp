#include <sourcemod>

bool g_bFullyConnected;

Database g_hDatabase = null;

public Plugin myinfo = {
	name		= "Chat Log",
	author		= "venus, MINFAS",
	description	= "Save all user messages in database",
	version		= "1.0",
	url			= "https://github.com/ivenuss"
};

public void OnConfigsExecuted()
{
	if (!g_hDatabase)
	{
		Database.Connect(SQL_Connection, "default");
	}
}

public void OnPluginStart()
{
	PrintToChatAll("[ivenuss Chat Log] \x04Enabled");
}

public void OnPluginEnd()
{
	PrintToChatAll("[ivenuss Chat Log] \x02Disabled");
}

public void SQL_Connection(Database database, const char[] error, int data)
{
	if (database == null)
		SetFailState(error);
	else
	{
		g_hDatabase = database;

		g_hDatabase.SetCharset("utf8mb4");

		g_hDatabase.Query(SQL_CreateCallback, "\
		CREATE TABLE IF NOT EXISTs`sm_chatlog` ( \
			`id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, \
			`timestamp` DATETIME NULL DEFAULT NULL, \
			`map` VARCHAR(128) NOT NULL COLLATE 'utf8_general_ci', \
			`steamid` VARCHAR(21) NOT NULL COLLATE 'utf8_general_ci', \
			`name` VARCHAR(128) NOT NULL COLLATE 'utf8_general_ci', \
			`message_style` TINYINT(2) NULL DEFAULT 0, \
			`dead` TINYINT(2) NULL DEFAULT 0, \
			`message` VARCHAR(126) NOT NULL COLLATE 'utf8_general_ci', \
			PRIMARY KEY (`id`) USING BTREE \
		) \
		DEFAULT CHARSET='utf8' \
		ENGINE=InnoDB \
		;");
	}
}

public void SQL_CreateCallback(Database database, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		SetFailState(error);
	}
		
	g_bFullyConnected = true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (g_bFullyConnected && !IsFakeClient(client))
	{
		if (strlen(szArgs) > 0)
		{
			int iMsgStyle, iDead;
			int iTimestamp = GetTime();
			char szQuery[512], szMap[128], szSteamId[21];

			if (StrContains(command, "_", false) != -1)
			{
				iMsgStyle = 1; //Team chat
			}

			else
			{
				iMsgStyle = 0; //General chat
			}

			if(IsPlayerAlive(client))
			{
				iDead = 0;
			}
			else
			{
				iDead = 1;
			}

			GetCurrentMap(szMap, sizeof(szMap));

			if(!GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId)))
			{
				LogError("Player %N's steamid couldn't be fetched", client);
				return;
			}

			g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO sm_chatlog (timestamp, map, steamid, name, message_style, dead, message) VALUES ('%i', '%s', '%s', '%N', '%i', '%i', '%s')", iTimestamp, szMap, szSteamId, client, iMsgStyle, iDead, szArgs);
			
			g_hDatabase.Query(SQL_Error, szQuery);
		}
	}
}

public void SQL_Error(Database database, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		SetFailState(error);
	}
}