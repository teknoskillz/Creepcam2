/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/
/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// };


/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void() monster_use =
{
	if (self.enemy)
		return;

	if (self.health <= 0)
		return;

	if (activator.items & IT_INVISIBILITY)
		return;

	if (activator.flags & FL_NOTARGET)
		return;

	if (activator.classname != "player")
		return;
	
	// delay reaction so if the monster is teleported, its sound is still heard
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
};

/*
================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
================
*/
void() monster_death_use =
{
	// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;

	if (!self.target)
		return;

	activator = self.enemy;
	SUB_UseTargets ();
};


//============================================================================




void() walkmonster_start_go =
{
          if (cvar("nomonsters"))
          {
                    total_monsters -= 1;
                    remove (self);
                    return;
          }
	self.origin_z = self.origin_z + 1;	// raise off floor a bit
	droptofloor();
	
	if (!walkmove(0,0))
	{
                   setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
                   T_Damage (self, self, self, 50000);
		dprint ("walkmonster in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}
	
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';

	if (!self.yaw_speed)
		self.yaw_speed = 20;

	self.view_ofs = '0 0 25';
	self.use = monster_use;
	
	self.flags = self.flags | FL_MONSTER;
	
	if (self.target != string_null)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);

		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
	// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();

		else
			self.pausetime = 99999999;
			self.th_walk ();
	}

	else
	{
		self.pausetime = 99999999;
		self.th_walk ();
	}




	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + frametime + random()*0.5;
};






void() walkmonster_start =
{
	// delay drop to floor to make sure all doors have been spawned
	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + frametime + random()*0.5;  // Cobalt added a buffer precaution, frametime
	self.think = walkmonster_start_go;
	total_monsters = total_monsters + 1;
          
          if (!self.p_adj && random () < (2/5))
          {
            if (random () < 0.5 || self.netname == "Shambler")
          self.p_adj = 85 + (random () * 20) - (vlen(self.maxs) * 0.75);
          else self.p_adj = 95 + (random () * vlen(self.mins)) ;
          }
};



void() flymonster_start_go =
{
            if (cvar("nomonsters"))
          {
                    total_monsters -= 1;
                    remove (self);
                    return;
          }
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';

	if (!self.yaw_speed)
		self.yaw_speed = 10;

	self.view_ofs = '0 0 25';
	self.use = monster_use;

          self.flags = self.flags | FL_FLY | FL_MONSTER;
	
          if (!self.p_adj && random () < (2/3))
          {
            if (random () < 0.5)
          self.p_adj = 65 + (random () * 20);
          else self.p_adj = 115 + (random () * 20);
          }

	if (!walkmove(0,0))
	{
                    setsize (self, VEC_ORIGIN, VEC_ORIGIN);
                    T_Damage (self, self, self, 50000);
		dprint ("flymonster in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	if (self.target != string_null)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);

		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
		// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();

		else
			self.pausetime = 99999999;
			self.th_walk ();
	}

	else
	{
		self.pausetime = 99999999;
		self.th_walk ();
	}
	
	
	};

void() flymonster_start =
{
	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + frametime + random()*0.5;
	self.think = flymonster_start_go;
	total_monsters = total_monsters + 1;
};


void() swimmonster_start_go =
{
            if (cvar("nomonsters"))
          {
                    total_monsters -= 1;
                    remove (self);
                    return;
          }
	if (deathmatch)
	{
		remove(self);
		return;
	}

	self.takedamage = DAMAGE_AIM;
	//	total_monsters = total_monsters + 1;	// gb, fish count bugfix

	self.ideal_yaw = self.angles * '0 1 0';

	if (!self.yaw_speed)
		self.yaw_speed = 10;

	self.view_ofs = '0 0 10';
	self.use = monster_use;
	
	self.flags = self.flags | FL_SWIM;
	self.flags = self.flags | FL_MONSTER;

	if (self.target != string_null)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);

		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
		// this used to be an objerror
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		self.th_walk ();
	}

	else
	{
		self.pausetime = 99999999;
		self.th_walk ();
	}

	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + frametime + random()*0.5;
};

void() swimmonster_start =
{
	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + frametime + random()*0.5;
	self.think = swimmonster_start_go;
	total_monsters = total_monsters + 1;
};
void () monster_hell_knight;
void () monster_enforcer;
void () monster_dog;
void () monster_ogre;
void () monster_knight;
void () monster_wizard;
void () monster_demon1;
void () monster_army;
void () monster_zombie;
void () monster_tarbaby;

void () RandomMonster = 
{
if (total_monsters > 254) return;
local float rn,type;

traceline (self.origin, self.origin - '0 0 500', 0, self);
if (pointcontents (trace_endpos) == CONTENT_LAVA)
          type = MOVETYPE_FLY;
 

rn = random ();


if (rn < 0.1 || type)
{
self.classname = "monster_wizard";
monster_wizard();
}
else if (rn < 0.2)
{
self.classname = "monster_ogre";
monster_ogre();
}
else if (rn < 0.3)
{
self.classname = "monster_knight";
monster_knight();
}
else if (rn < 0.4)
{
self.classname = "monster_dog";
monster_dog ();
}
else if (rn < 0.5)
{
self.classname = "monster_demon1";
monster_demon1();
}
else if (rn < 0.6)
{
self.classname = "monster_army";
monster_army();
}
else if (rn < 0.7)
{
self.classname = "monster_enforcer";
monster_enforcer();
}    
else if (rn < 0.8)
{
self.classname = "monster_zombie";
monster_zombie();
}
else if (rn < 0.9)
{
self.classname = "monster_hell_knight";
monster_hell_knight ();
}
else 
{
self.classname = "monster_tarbaby";
monster_tarbaby ();
}

total_monsters += 1;
spawn_tfog(self.origin);

          

};
 