void() FoundTarget;
void() RespawnTimer = // CC_2
{
 local float ret;
    
    if (CC_RESPAWN && self.respawn_time > time) 
    {
    
       local string secs;

	secs = (ftos (ceil(self.respawn_time - time)));
	secs = strcat (secs," seconds.");	
	secs = strcat("\n\n\n\n\n\n\n\n\n\nRespawn ready in: ",secs);
	centerprint(self, secs);
          self.ltime = time + 15;
          return;
    }
    
    if (self.button2 || self.button1 || self.button0)  ret = 1;
    
   if (self.respawn_time < time)
	{
              if (time < self.ltime)
              centerprint2 (self, "\nPress Jump or Fire to respawn", " ", "", "  ", "");          
        if (ret)     
        {                  
          self.clientcamera = self;	
	CC_RequestNotCam();
          self.respawncam = 0;
        }
	
	}
};

void(entity killer, entity victim) CC_PlayerKilledPlayer = 
{
	local entity cam;
	local entity l;
	if (killer == victim)
	{
		return;
	}
	cam = victim.clink;
	if (cam)
	{
		if ((cam.style & FIRST_GUY_KILLED) == 0)
		{
			cam.style = cam.style | FIRST_GUY_KILLED;
			cam.autoswitch = killer;
			if (cam.state == 0 || cam.movetarget != killer)
			{
				traceline(victim.filmpos, killer.filmpos, 1, world);
				if (trace_fraction == 1)
				{
					cam.movetarget = killer;
					cam.state = FL_SWIM;
					CC_StartCamTransition(cam);
				}
			}
			if (cam.nextthink < time)
			{
				cam.think = CC_AutoSwitchCamThink;
				cam.nextthink = time + AUTOSWITCH_DELAY;
			}
		}
	}
	l = playerlist;
	while (l)
	{
		cam = l.clink;
		if (cam)
		{
			if (cam.state > 0 && cam.movetarget == victim)
			{
				cam.style = cam.style | SECOND_GUY_KILLED;
				if (cam.nextthink < time)
				{
					cam.think = CC_AutoSwitchCamThink;
					cam.nextthink = time + AUTOSWITCH_DELAY;
				}
			}
		}
		l = l.tless;
	}
};

void(entity deadguy) CC_DeadGuyRespawning = 
{
	local entity cam;
	local entity l;
	
	
	cam = deadguy.clink;
	if (cam)
	{
		if (cam.style & FIRST_GUY_KILLED)
		{
			cam.style = cam.style | VIEW_FIXED_POINT;
			cam.dest = deadguy.filmpos;
		}
	}
	l = playerlist;
	while (l)
	{
		cam = l.clink;
		if (cam)
		{
			if (cam.style & SECOND_GUY_KILLED && cam.movetarget == deadguy)
			{
				cam.style = cam.style - SECOND_GUY_KILLED;
				cam.state = 0;
				CC_StartCamTransition(cam);
				if (!(cam.autoswitch))
				{
					cam.autoswitch = deadguy;
					cam.style = cam.style | FIND_DIFFERENT_GUY;
				}
			}
		}
		l = l.tless;
	}
};

float() CC_ClientConnect = 
{
	self.creepflags = 0;
	self.spam_time = 0;

	CC_SendAliases(self);
   if (self.netname == "camera")
	{
      parm9 = CF_STAYASCAM;
      bprint("^3spectator ");
      bprint(self.netname);
      bprint(" ^2entered the game\n");
      return 1;
	}
   else
      numplayers = numplayers + 1;
return 0;
};

void() CC_ClientDisconnect = 
{
	if (self.camtype > 0)
	{
		c_count = c_count - 1;
	}
   else
      numplayers = numplayers - 1;

	CC_StopCamOrPlayer(self);
};

float() CC_PlayerPostThink = 
{
	local vector d;
   //local entity e;
   //local string tempstring;

	if (self.camtype == 0)
	{
		return 1;
	}

   if(self.classname == "camera")
   {
      if(self.owner)
      {
         if(self.owner.health > 0)
            self.health = self.owner.health;
         else
            self.health = 1;
         self.weapon = self.owner.weapon;
      // self.weaponmodel = self.owner.weaponmodel;
         self.currentammo = self.owner.currentammo;
         self.ammo_shells = self.owner.ammo_shells;
         self.ammo_nails = self.owner.ammo_nails;
         self.ammo_rockets = self.owner.ammo_rockets;
         self.ammo_cells = self.owner.ammo_cells;
         self.items = self.owner.items;
         self.armortype = self.owner.armortype;
         self.armorvalue = self.owner.armorvalue;
      }
   else
      {
          self.health = 666;
         self.weapon = 1;
         self.currentammo = 0;
         self.ammo_shells = 0;
         self.ammo_nails = 0;
         self.ammo_rockets = 0;
         self.ammo_cells = 0;
         self.items = 524288 | 1048576 | IT_SUIT;
         self.armortype = 0;
         self.armorvalue = 0;
         if (!(self.creepflags & CF_SENTMOTD))
         self.creepflags = self.creepflags | CF_SENTMOTD;
         /*
         self.health = 100;
         self.weapon = IT_AXE;
         self.currentammo = 0;
         self.ammo_shells = 0;
         self.ammo_nails = 0;
         self.ammo_rockets = 0;
         self.ammo_cells = 0;
         self.items = 0;
         self.armortype = 0;
         self.armorvalue = 0;
      */
      }
                

         
      
   }
	if ((self.creepflags & CF_SENTALIASES) == 0)
	{
		CC_SendAliases(self);
		self.creepflags = self.creepflags | CF_SENTALIASES;
	}
	if (self.camtype < 0)
	{
		if (self.flags & FL_ONGROUND)
		{
			if (self.origin_z - self.oldorigin_z > self.velocity_z * frametime + 1)
			{
				d = self.origin - self.oldorigin;
				d_z = 0;
				if (vlen(d) < 300)
				{
					self.filmlip = self.filmlip - self.origin_z + self.oldorigin_z;
					if (self.filmlip < FILM_LO_LIP)
					{
						self.filmlip = FILM_LO_LIP;
					}
				}
			}
		}
		if (self.filmlip < FILM_HI_LIP)
		{
			self.filmlip = self.filmlip + STAIR_BLEND_RATE * frametime;
			if (self.filmlip > FILM_HI_LIP)
			{
				self.filmlip = FILM_HI_LIP;
			}
		}
		self.filmpos = self.origin;
		self.filmpos_z = self.filmpos_z + self.filmlip;
		traceline(self.filmpos, self.filmpos + PRED_TIME * self.velocity, 1, world);
		self.predpos = trace_endpos - CLIP_TIME * self.velocity;
		CC_PlayerImpulses();
		if (self.deadflag)
		{
			self.impulse = 0;
		}
		return 0;
	}
	self.flags = FL_NOTARGET | FL_CLIENT;
	if (self.button2)
	{
		if ((self.attack_finished & FL_SWIM) == 0)
		{
			self.attack_finished = self.attack_finished | FL_SWIM;
			if (self.owner)
			{
				centerprint(self, self.owner.netname);
			}
		}
	}
	else
	{
		if (self.attack_finished & FL_SWIM)
		{
			self.attack_finished = self.attack_finished - FL_SWIM;
		}
	}
	if (self.button0 || self.button2)
	{
		if ((self.attack_finished & 1) == 0)
		{
			self.attack_finished = self.attack_finished | 1;
			CC_SwitchToNextPlayer();
		}
	}
	else
	{
		if (self.attack_finished & 1)
		{
			self.attack_finished = self.attack_finished - 1;
		}
	}
   if (self.owner != world && !intermission_running)
	{
		if (self.owner.clink == self)
		{
			CC_DoCamAlgorithm(self);
		}
		else
		{
			setorigin(self, self.owner.clink.origin);
			self.v_angle = self.owner.clink.v_angle;
			self.angles = self.owner.clink.angles;
			self.fixangle = 1;
		}
	}
	CC_PlayerImpulses();
	if (self.impulse == 101)
	{
		CC_RequestNotCam();
	}
	if (self.impulse >= 201 && self.impulse < 216)
	{
		CC_SwitchToPlayer(self.impulse - 200);
	}
	if (self.impulse == 56)
	{
		CC_PlayerKilledPlayer(self.movetarget, self.owner);
	}
	self.impulse = 0;
         // self.nextthink = self.owner.nextthink;
	return 1;
};

float() CC_PutClientInServer = 
{
       
                    if (!self.spawns)
                    {
		self.creepflags = parm9;
		
                    self.levels = decode(parm4, HI8);
                    }
	if ((!(self.creepflags & CF_SENTMOTD)))
	{
		if ((self.creepflags & CF_STAYASCAM) == 0)
                    if (!self.levels)
                    CC_LongMessage(self, 0.5, "motd");
                    
                   // stuffcmd(self, "bind ` \"impulse 123;wait;wait;toggleconsole\"\n");
		self.creepflags = self.creepflags | CF_SENTMOTD;
	}
	if (self.creepflags & CF_STAYASCAM)
	{
		parm9 = parm9 - CF_STAYASCAM;
		WATCHING = 1;  // PRIME CC_2 Turn on watching only if you are a returning spectator.
		if (CC_RequestNoCrapCam()) return 1;
		
	}
	if (self.camtype == 0)
	CC_ChangeToPlayer(self);
	
	self.camtype = CONTENT_SOLID;
	return 0;
};

void() CC_WorldSpawn = 
{
   //local entity e;
          
	blinkstate = 0;
	c_count = 0;
	playerlist = world;
	freecamlist = world;
	CC_SpawnBlinker();
          cvar_set("sv_aim","1");

};