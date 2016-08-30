

void(entity c) CC_AddtoList = 
{
	local entity l;
	CC_StopCamOrPlayer(c);
	c.camtype = CONTENT_EMPTY;
	c.filmlip = FILM_HI_LIP;
	c.filmpos = c.origin;
	c.filmpos_z = c.filmpos_z + FILM_HI_LIP;
	c.predpos = c.filmpos;
	c.clink = world;
	l = freecamlist;
	while (l != world)
	{
		if (l.camtype == 1)
	      CC_ChangeToFollowCam(l, c);
		
		l = l.clink;
	}
	c.tless = playerlist;
	playerlist = c;
};



void(entity e) CC_AntiSpamAction = 
{
	//local string s;
	if (time - e.spam_time > SPAM_TIMEINTERVAL)
	{
		e.spam_time = time;
		e.spam_count = 1;
	}
	else
	{
		e.spam_count = e.spam_count + 1;
		if (e.spam_count >= SPAM_ACTIONLIMIT)
		{
			bprint("^3Too much spamming from ");
			bprint(e.netname);
			bprint("\n");
			stuffcmd(e, "\ndisconnect\n");
		}
	}
};

void(entity e) CC_SendAliases = 
{
	stuffcmd(e, "alias creepcam \"impulse 120\"\n");
	stuffcmd(e, "alias myspecs \"impulse 150\"\n");
	stuffcmd(e, "alias allspecs \"impulse 151\"\n");
	stuffcmd(e, "alias spectate \"impulse 100\"\n");
	stuffcmd(e, "alias join \"impulse 101\"\n");
	stuffcmd(e, "alias showcam \"impulse 121\"\n");
	stuffcmd(e, "alias autoswitch \"impulse 122\"\n");
	stuffcmd(e, "alias playerlist \"impulse 152\"\n");
	// Cobalt removed respawntimer reference
	
          stuffcmd(e, "alias skill \"impulse 80\"\n");
	


	   stuffcmd(e, "cl_movement 0");
           stuffcmd (e, "cl_nolerp 0");
	};

void(entity e) CC_WriteHelpInfo = 
{
   local string msg;
   msg = strcat ("ç ^5Creeierpcam ", version);
   msg = strcat (msg, " commands^7:\n^2Spectate^7   ^3Watch Player^7\n^2Join^7       ^3Join the fight^7\n^2MySpecs^7    ^3Spectators Watching You^7\n^2AllSpecs^7   ^3List All Spectators^7\n^2ShowCam^7    ^3Toggle cam Display^7\n^2AutoSwitch^7 ^3Toggle AutoSwitch Mode^7\n^2PlayerList^7 ^3List All Players^7\n\n^5Use fire button to switch between players when spectating^7\n");
   sprint (e, msg);
   //sprint(e, "ç ^5Creeierpcam v 2.079 commands^7:\n^2Spectate^7   ^3Watch Player^7\n^2Join^7       ^3Join the fight^7\n^2MySpecs^7    ^3Spectators Watching You^7\n^2AllSpecs^7   ^3List All Spectators^7\n^2ShowCam^7    ^3Toggle cam Display^7\n^2AutoSwitch^7 ^3Toggle AutoSwitch Mode^7\n^2PlayerList^7 ^3List All Players^7\n\n^5Use fire button to switch between players when spectating^7\n");
};


void() CC_LongMessageThink =
{
	if (self.state == 0)
	{
                    stuffcmd (self.owner, "bf 0 0 0 5.5 0.75\n");
                    self.owner.flags = self.owner.flags | FL_NOTARGET;
		if (self.owner.creepflags & CF_DOINGLONGMESSAGE)
		{
			self.nextthink = time + 1;
			return;
		}
		self.state = 1;
		self.owner.creepflags = self.owner.creepflags + CF_DOINGLONGMESSAGE;
	}
	self.lefty = self.lefty - 1;
	if (self.lefty > 1)
	{
                    if (self.deathtype == "motd")
                    {
                    
                    local string ms;
                    ms = "^2Creepiercam^7 ";
                    ms = strcat (ms, version);
                    ms = strcat (ms, "\n\nby ^5PrimalLove ^7& ÄÉÖ√œ¬¡Ã‘ÖÉÇ^7\n");
                    ms = strcat (ms, "^3Based on Creepcam v1.1 Beta 5 by Jeff Preshing^7");
                    ms = strcat (ms, "\n\nType ^2creepcam^7 in the console\nfor more information.");
                    centerprint(self.owner,ms);                              
                    }
                    else
		centerprint(self.owner, self.deathtype);
		self.nextthink = time + 0.7;
	}
	else
	{
		if (self.lefty == 1)
		{
			self.nextthink = time + AUTOSWITCH_DELAY;
		}
		else
		{
			self.owner.creepflags = self.owner.creepflags - CF_DOINGLONGMESSAGE;
                              if (self.owner.flags & FL_NOTARGET)
                              self.owner.flags = self.owner.flags - FL_NOTARGET;
			remove(self);
		}
	}
};

void(entity targ, float pauselen, string msg) CC_LongMessage = 
{
          
	local entity s;
	s = spawn();
	s.lefty = 9;
	s.deathtype = msg;        
          //strzone (s.deathtype);
	s.owner = targ;
	s.think = CC_LongMessageThink;
	s.nextthink = time + pauselen;
	s.state = 0;
};

void(entity c) CC_ClearNameForAll = 
{
           // Cobalt - Try to reduce net traffic by not blanking the scoreboard name when they are a respawn cam 
           // mostly for Nightmare skill with laggy players, long netnames can possibly overflow it
          if (!c.respawncam)
          {
	WriteByte(MSG_ALL, SVC_UPDATENAME);
	WriteByte(MSG_ALL, c.colormap - 1);
	WriteString(MSG_ALL, string_null);
          }
          
};

void(entity c) CC_ShowNameForAll = 
{
	WriteByte(MSG_ALL, SVC_UPDATENAME);
	WriteByte(MSG_ALL, c.colormap - 1);
	WriteString(MSG_ALL, c.netname);
};

void() CC_ClearCamNamesForAll = 
{
	local entity l;
	local entity c;
	l = playerlist;
	while (l != world)
	{
		c = l.clink;
		while (c != world)
		{
			CC_ClearNameForAll(c);
			c = c.clink;
		}
		l = l.tless;
	}
	c = freecamlist;
	while (c != world)
	{
		CC_ClearNameForAll(c);
		c = c.clink;
	}
};

float blinkstate /* = 0.000 */;
float scoreshowtime /* = 0.000 */;
float showflag /* = 0.000 */;

void(entity c) CC_ShowRec = 
{
	if ((c.flags & FL_CLIENT) == 0 || (c.creepflags & CF_NOSHOWREC))
	return;
	if (c.waterlevel > 2 && c.air_finished > time) return;
	if (c.creepflags & CF_DOINGLONGMESSAGE)
	return;
	


	if (blinkstate)
	centerprint(c, "\n\n\n\n\n\n\n\n\n\n\n                                 ^3CAM  ");
       else
	centerprint(c, "\n\n\n\n\n\n\n\n\n\n\n                                 ^3CAM ^1ã");
	
};

void(entity c) CC_StopBlink = 
{
	if ((c.flags & FL_CLIENT) == 0 || (c.creepflags & CF_NOSHOWREC))
	{
		return;
	}
	if (c.creepflags & CF_DOINGLONGMESSAGE)
	{
		return;
	}
	centerprint(c, string_null);
};

void(string s) CC_StuffToAllCams = 
{
	local entity c;
	c = world;
	while (c = find(c, classname, "camera")) 
	stuffcmd(c, s);
	
};

void() CC_BlinkThink = 
{
	local entity l;
	l = playerlist;
	while (l != world)
	{
		if (l.clink != world && (l.flags & FL_CLIENT))
		CC_ShowRec(l);
		
	     if (l.attack_finished > time && l.took_damage > time) // Cobalt - try to tag playerlist ents if fighting
		{

		fighter = l;

		}
		l = l.tless;
	}
	if (blinkstate)
	CC_ClearCamNamesForAll();
	
	blinkstate = 1 - blinkstate;
	self.nextthink = time + 1;
	if (time > scoreshowtime)
	{
		if (showflag)
		{
			CC_StuffToAllCams("+showscores\n");
                              scoreshowtime = time + 4;
		}
		else
		{
			CC_StuffToAllCams("-showscores\n");
                              scoreshowtime = time + 116;
		}
		showflag = !showflag;
	}
};

void() CC_SpawnBlinker = 
{
	local entity e;
	e = spawn();
	e.think = CC_BlinkThink;
	e.nextthink = time + 1;
};

void(entity e) CC_ToggleShowRec = 
{
	if (e.creepflags & CF_NOSHOWREC)
	{
		sprint(e, "CAM ã Display ^2Enabled\n");
		e.creepflags = e.creepflags - CF_NOSHOWREC;
		if (e.camtype < 0 && e.clink != world)
		{
			CC_ShowRec(e);
		}
	}
	else
	{
		sprint(e, "CAM ã Display ^1Disabled\n");
		if (e.camtype < 0 && e.clink != world)
		{
			CC_StopBlink(e);
		}
		e.creepflags = e.creepflags + CF_NOSHOWREC;
	}
};

void(entity e) CC_ToggleAutoSwitch = 
{
	if (e.creepflags & CF_NOAUTOSWITCH)
	{
		sprint(e, "^3Camera Autoswitch ^2Enabled\n");
		e.creepflags = e.creepflags - CF_NOAUTOSWITCH;
	}
	else
	{
		sprint(e, "^3Camera Autoswitch ^1Disabled\n");
		e.creepflags = e.creepflags + CF_NOAUTOSWITCH;
	}
};

void(entity l) CC_WriteCameraList = 
{
	if (l)
	{
		sprint(self, l.netname);
		l = l.clink;
	}
	while (l)
	{
		sprint(self, ", ");
		sprint(self, l.netname);
		l = l.clink;
	}
	sprint(self, "\n");
};

void() CC_WhosFilmingMe = 
{
	if (self.camtype < 0)
	{
		if (!(self.clink))
		{
			sprint(self, "^1Nobody is watching you.\n");
		}
		else
		{
			sprint(self, "ç ^2People watching you: ");
			CC_WriteCameraList(self.clink);
		}
	}
	if (self.camtype > 0)
	{
		if (!(self.owner))
		{
			sprint(self, "^3You're not watching anyone.\n");
		}
		else
		{
			sprint(self, "ç ^5Watching ");
			sprint(self, self.owner.netname);
			sprint(self, ": ");
			CC_WriteCameraList(self.owner.clink);
		}
	}
};

void() CC_WritePlayerList = 
{
	local entity p;
	local string s;
	sprint(self, "ç ^5List of all players:\n");
	if (!playerlist)
	{
		sprint(self, "^1None!\n");
	}
	else
	{
		p = playerlist;
		while (p != world)
		{
			sprint(self, p.netname);
			sprint(self, " (");
			s = ftos(p.colormap);
			sprint(self, s);
			sprint(self, ")\n");
			p = p.tless;
		}
	}
};

void() CC_WhosFilmingWho = 
{
	local entity p;
	local string s;
	if (c_count == 0)
	{
		sprint(self, "^1Nobody^7 ^3is in spectator mode.\n^2The maximum is ");
		s = ftos(c_max);
		sprint(self, s);
		sprint(self, ".\n");
	}
	else
	{
		sprint(self, "ç ^3List of all spectators:\n");
		p = playerlist;
		while (p != world)
		{
			if (p.clink != world)
			{
				sprint(self, "^3Watching ");
				sprint(self, p.netname);
				sprint(self, ": ");
				CC_WriteCameraList(p.clink);
			}
			p = p.tless;
		}
		if (freecamlist != world)
		{
			sprint(self, "^3Not watching anyone: ");
			CC_WriteCameraList(freecamlist);
		}
		sprint(self, "^3Total ");
		s = ftos(c_count);
		sprint(self, s);
		sprint(self, " ^3spectator(s) out of ");
		s = ftos(c_max);
		sprint(self, s);
		sprint(self, " ^3maximum.\n");
	}
};

entity(float targ) CC_GetPlayerIndexedBy = 
{
	local entity l;
	l = playerlist;
	while (l)
	{
		if (l.colormap == targ)
		{
			return l;
		}
		l = l.tless;
	}
	return world;
};

void() CC_PlayerImpulses = 
{
	if (self.impulse == 100)
	{
		CC_RequestCam();
	}
	if (self.impulse == 120)
	{
		CC_WriteHelpInfo(self);
	}
	if (self.impulse == 121)
	{
		CC_ToggleShowRec(self);
	}
	if (self.impulse == 122)
	{
		CC_ToggleAutoSwitch(self);
	}
	if (self.impulse == 150)
	{
		CC_WhosFilmingMe();
	}
	if (self.impulse == 151)
	{
		CC_WhosFilmingWho();
	}
	if (self.impulse == 152)
	{
		CC_WritePlayerList();
	}
	   
       	   
};
 