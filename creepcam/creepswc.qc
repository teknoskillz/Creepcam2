void (entity c) CC_ShowRec;

void (entity c) CC_StopBlink;

void (entity c) CC_ChangeToAnyCam;

void(entity c) CC_StopCamOrPlayer =
{
	local entity l;
	local entity l2;
	if (c.camtype == 0)
	{
		return;
	}
	if (c.camtype < 0)
	{
		c.camtype = 0;
		if (playerlist == c)
		{
			playerlist = c.tless;
		}
		else
		{
			l = playerlist;
			while (l)
			{
				if (l.tless == c)
				{
					l.tless = c.tless;
					l = world;
				}
				else
				{
					l = l.tless;
				}
			}
		}
		l = c.clink;
		while (l != world)
		{
			l2 = l.clink;
			CC_ChangeToAnyCam(l);
			l = l2;
		}
		c.nextthink = 0;
	}
	else
	{
		c.camtype = 0;
		if (c.owner != world && c.clink != world && c.owner.clink == c)
		{
			l = c.clink;
			l.cangles = c.cangles;
			l.lefty = c.lefty;
			l.filmpos = c.filmpos;
			l.predpos = c.predpos;
			l.movetarget = c.movetarget;
			l.oldenemy = c.oldenemy;
			l.state = c.state;
			l.style = c.style;
			l.dest = c.dest;
			l.autoswitch = c.autoswitch;
			l.slack1 = c.slack1;
			l.slack2 = c.slack2;
			l.think = c.think;
			l.nextthink = c.nextthink;
			l.search_time = c.search_time;
			l.light_lev = c.light_lev;
		}
		c.nextthink = 0;
		l = c.owner;
		if (!l)
		{
			if (freecamlist == c)
			{
				freecamlist = c.clink;
				return;
			}
			else
			{
				l = freecamlist;
			}
		}
		else
		{
			if (!(l.clink.clink))
			{
				CC_StopBlink(l);
				l.clink = world;
				return;
			}
		}
		while (l.clink != world)
		{
			if (l.clink == c)
			{
				l.clink = c.clink;
				return;
			}
			l = l.clink;
		}
	}
};

void(entity c) CC_ChangeToWorldCam = 
{
	//local entity l;
	CC_StopCamOrPlayer(c);
	c.camtype = 1;
	c.owner = world;
	c.clink = freecamlist;
	freecamlist = c;
};

void(entity c, entity targ) CC_ChangeToFollowCam = 
{
	local entity l;
	CC_StopCamOrPlayer(c);
	c.camtype = 1;
	c.owner = targ;
	c.watch = targ.colormap; // PRIME CC_2 Addition for entity watch to be same as target colormap
	c.clink = world;
	if (!(targ.clink))
	{
		CC_ShowRec(targ);
		targ.clink = c;
		c.movetarget = world;
		c.oldenemy = world;
		c.state = 0;
		c.style = 0;
		
		if (c.owner.waterlevel == 2) // PRIME CC_2 waterlevel view fix
              c.view_pitch = -1;
              else
              c.view_pitch = 1;
              c.cangles_x = (VIEWING_PITCH * c.view_pitch);
		//c.cangles_x = VIEWING_PITCH;
		c.cangles_z = 0;
		c.cangles_y = vectoyaw(targ.velocity);
		makevectors(c.cangles);
		c.filmpos = v_forward;
		c.predpos = c.filmpos;
		c.search_time = CONTENT_EMPTY;
		c.light_lev = 1;
		c.autoswitch = world;
	}
	else
	{
		l = targ.clink;
		while (l.clink != world)
		{
			l = l.clink;
		}
		l.clink = c;
	}
	if ((c.creepflags & CF_DOINGLONGMESSAGE) == 0)
	{
		centerprint(c, targ.netname);
	}
};

void(entity c) CC_ChangeToPlayer = 
{
	local entity l;
	CC_StopCamOrPlayer(c);
	if (self.classname != "player")
	{
		c.camtype = CONTENT_SOLID;
	}
	else
	{
		c.camtype = CONTENT_EMPTY;
	}
	c.filmlip = FILM_HI_LIP;
	c.filmpos = c.origin;
	c.filmpos_z = c.filmpos_z + FILM_HI_LIP;
	c.predpos = c.filmpos;
	c.clink = world;
	l = freecamlist;
	while (l != world)
	{
		if (l.camtype == 1)
		{
			CC_ChangeToFollowCam(l, c);
		}
		l = l.clink;
	}
	c.tless = playerlist;
	playerlist = c;
};

void () CC_WaitingCamThink;

void(entity c) CC_ChangeToAnyCam = 
{

local entity watcher;
    if (WATCHING) // Below Used for when the camera first spawns in and changes to player they last specced
        {
                watcher = findfloat(world, colormap, c.watch);
                while(watcher)
                {
                CC_ChangeToFollowCam(c, watcher);
                WATCHING = 0; // Turn this off so it only happens once unless you always want it to go to last specced entity
                watcher = findfloat(watcher, colormap, c.watch);
                }
        }


	if (!playerlist)
	{
		CC_ChangeToWorldCam(c);
		self.state = 0;
		c.think = CC_WaitingCamThink;
		c.nextthink = time + 0.010000;
	}
	else
	CC_ChangeToFollowCam(c, playerlist);
	
};

void() CC_WaitingCamThink = 
{

local entity pos;
	self.state = self.state + 1;
	if (self.state == 1)
	{
		pos = find(self.movetarget, classname, "info_intermission");
		if (pos.classname != "info_intermission")
		{
			pos = find(world, classname, "info_intermission");
		}
		setorigin(self, pos.origin);
		self.filmpos = pos.origin;
		self.cangles = pos.mangle;
		self.movetarget = pos;
		self.nextthink = time + 1.5;
		self.v_angle = self.cangles;
		self.angles = self.cangles;
		self.fixangle = 1;
	}
	else
	{
		if ((self.creepflags & CF_DOINGLONGMESSAGE) == 0)
		{
			centerprint(self, "\n\n\n\n\n\n\n\n\n\n\n^1Waiting for players...");
		}
		if (self.state < MOVETYPE_WALK)
		{
			self.nextthink = time + 1;
		}
		else
		{
			self.state = 0;
			self.nextthink = time + 7.5;
		}
	}
};

void() CC_IntroCamThink = 
{
	local entity pos;
	self.state = self.state + 1;
	if (self.state == 1)
	{
		pos = find(world, classname, "info_intermission");
		self.movetarget = pos;
		setorigin(self, pos.origin);
		self.filmpos = pos.origin;
		self.cangles = pos.mangle;
		self.v_angle = self.cangles;
		self.angles = self.cangles;
		self.fixangle = 1;
		self.nextthink = time + 0.8;
	}
	else
	{
		if (self.state == FL_SWIM)
		{
			stuffcmd(self, "bf\n");
			if ((self.creepflags & CF_DOINGLONGMESSAGE) == 0)
			{
				centerprint(self, "^2MonsterCam\n\n^2… ^2activated …");
			}
			self.nextthink = time + MOVETYPE_WALK;
		}
		else
		{
			CC_StopCamOrPlayer(self);
			CC_ChangeToAnyCam(self);
		}
	}
};

void() CC_IntroCamThink2 = 
{
	local entity pos;
	self.state = self.state + 1;
	if (self.state == 1)
	{
		pos = find(world, classname, "info_intermission");
		self.movetarget = pos;
		setorigin(self, pos.origin);
		self.filmpos = pos.origin;
		self.cangles = pos.mangle;
		self.v_angle = self.cangles;
		self.angles = self.cangles;
		self.fixangle = 1;
		self.nextthink = time + 0.8;
	}
	else
	{
		if (self.state == FL_SWIM)
		{
			stuffcmd(self, "bf\n");
			self.nextthink = time + MOVETYPE_WALK;
		}
		else
		{
			CC_StopCamOrPlayer(self);
			CC_ChangeToAnyCam(self);
		}
	}
};


void() CC_ConfigureCamera = 
{
	local float hack;
	self.classname = "camera";
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	//Cobalt - Optional, gives better viewpos, stays in world origin a bit better, but will give an unstick entity message in console if unstickentities is set
	self.movetype = MOVETYPE_BOUNCEMISSILE;
	self.attack_finished = self.effects = 0;  // Cobalt turn off any previous effects
	self.autoswitch = world;
	self.velocity = VEC_ORIGIN;
	self.flags = FL_NOTARGET | FL_CLIENT;
	self.show_hostile = -1;
	self.frags = 0;
	setmodel(self, "progs/player.mdl");
	hack = self.modelindex;
	setmodel(self, string_null);
	self.modelindex = hack;
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	self.weaponmodel = string_null;
	self.view_ofs = VEC_ORIGIN;
	self.currentammo = 0;
	self.items = 0;
	self.health = 100;
	self.armorvalue = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
//   stuffcmd(self, "viewsize 120\n");
	stuffcmd(self, "crosshair 0\n");
//   stuffcmd(self, "fov 100\n");
	CC_ClearCamNamesForAll();
};

entity () FindIntermission;

void (entity e) CC_AntiSpamAction;

void() CC_BeginIntroCam = 
{
	//local entity pos;
	CC_StopCamOrPlayer(self);
	CC_ConfigureCamera();
	CC_ChangeToWorldCam(self);
	self.cangles = self.angles;
	self.camtype = FL_SWIM;
	self.state = 0;
	self.style = 0;
	self.think = CC_IntroCamThink;
	self.nextthink = time;
	CC_AntiSpamAction(self);
};

void() CC_BeginIntroCam2 = 
{
	//local entity pos;
	CC_StopCamOrPlayer(self);
	CC_ConfigureCamera();
	CC_ChangeToWorldCam(self);
	self.cangles = self.angles;
	self.camtype = FL_SWIM;
	self.state = 0;
	self.style = 0;
	self.think = CC_IntroCamThink2;
	self.nextthink = time;
	CC_AntiSpamAction(self);
};

void() CC_BeginNoCrapCam = 
{
	CC_StopCamOrPlayer(self);
	CC_ConfigureCamera();
	CC_ChangeToAnyCam(self);
	CC_AntiSpamAction(self);
};

void() CC_AutoSwitchCamThink = 
{
	local entity targ;
	local entity old;
	local entity l;
	local entity bestl;
	if (self.style & FIRST_GUY_KILLED)
	{
		self.style = self.style - (self.style & EITHER_GUY_KILLED);
		
                    if (self.autoswitch.camtype != -2)
		targ = self.autoswitch;
		else if (playerlist != world && playerlist != self)
		targ = playerlist;
                    else 
                    {
                      bprint("Picking random cam...\n");
                      targ = RANDOMCAM;                     
                    }
                    
		self.autoswitch = world;
		old = self.owner;
		if (!targ)
		{
			while (old.clink != world)
			CC_ChangeToWorldCam(old.clink);
			
		}
		else
		{
			bestl = old.clink;
			while (bestl)
			{
				bestl = world;
				l = old.clink;
				while (l)
				{
					if ((l.creepflags & CF_NOAUTOSWITCH) == 0)
					{
						bestl = l;
					}
					l = l.clink;
				}
				if (bestl)
				{
					CC_ChangeToFollowCam(bestl, targ);
				}
			}
			l = old.clink;
			if (l)
			{
				if (l.style & VIEW_FIXED_POINT)
				{
					l.style = l.style - VIEW_FIXED_POINT;
					l.state = 0;
					l.style = 0;
				}
			}
		}
	}
	else
	{
		if (self.style & SECOND_GUY_KILLED)
		{
			self.style = self.style - SECOND_GUY_KILLED;
			if (self.state > 0)
			{
				self.state = 0;
				CC_StartCamTransition(self);
			}
		}
	}
};

void (vector org) spawn_tfog;

float() CC_RequestNoCrapCam = 
{
	if (self.camtype > 0)
	{
		return 1;
	}
   if (c_count >= c_max)
	{
		stuffcmd(self, "bf\n");
		CC_LongMessage(self, 0, "^1Sorry, this server will not allow\n^1any more spectators.");
		return 0;
	}
	
	c_count = c_count + 1;
	self.think = CC_BeginNoCrapCam;
	self.nextthink = time;
	return 1;
};



void() CC_DeathCam = 
{
	if (self.camtype > 0) return;
	
	c_count = c_count + 1;
   numplayers = numplayers - 1;
   self.classname = "camera";
	self.think = CC_BeginIntroCam2;
	self.nextthink = time;
};


void() CC_RequestCam = 
{
	if (self.camtype > 0)
	{
		return;
	}
   
   if (c_count >= c_max)
	{
		stuffcmd(self, "bf\n");
		CC_LongMessage(self, 0, "^1Sorry, this server will not allow\n^1any more spectators.");
		return;
	}
	bprint(self.netname);
	bprint(" ^3became a spectator\n");
	spawn_tfog(self.origin);
	c_count = c_count + 1;
   numplayers = numplayers - 1;
   self.classname = "camera";
	self.think = CC_BeginIntroCam;
	self.nextthink = time;

};

void(float cmap) CC_SwitchToPlayer = 
{
	local entity targ;
	if (self.camtype <= 0)
	{
		return;
	}
	targ = CC_GetPlayerIndexedBy(cmap);
	if (targ != world && targ != self.owner)
	{
		CC_ChangeToFollowCam(self, targ);
	}
};

void() CC_SwitchToNextPlayer = 
{
	local entity next;
	if (!(self.owner))
	{
		return;
	}
	next = self.owner.tless;
	if (!next)
	{
		next = playerlist;
		if (next == self.owner)
		{
			return;
		}
	}
	CC_ChangeToFollowCam(self, next);
};

void() CC_RequestNotCam = 
{
	if (self.camtype <= 0) return;
	
    
	//bprint(self.netname);
	//bprint(" ^3\n");
	
	c_count = c_count - 1;
   numplayers = numplayers + 1;
	CC_ChangeToPlayer(self);
   stuffcmd(self,"crosshair 5\n");
	if ((self.creepflags & CF_DOINGLONGMESSAGE) == 0)
	centerprint(self, string_null);
	
	stuffcmd(self, "-showscores\n");

	CC_ShowNameForAll(self);
   self.owner = world;
 
	self.think = PutClientInServer;
	self.nextthink = time + frametime + (frametime * random(5));
		if (!coop)
	SetNewParms();
	else
	CC_Spawnparms ();
	CC_AntiSpamAction(self);
};

 