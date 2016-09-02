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
void() movetarget_f;
void() t_movetarget;
void() knight_walk1;
void() knight_bow6;
void() knight_bow1;
void(entity etemp, entity stemp, entity stemp, float dmg) T_Damage;
/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.hunt_time
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/


//
// globals
//

//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity	sight_entity;
float	sight_entity_time;

//pitch (angles_x) is inverted in quake due to a bug
	//use makevectors2 for monsters with nonzero pitch
//anyone encountering this comment with a better understanding should update the comment to be more informative and useful to modders --gnounc
void makevectors2(vector ang) = 
{
	ang_x *= -1;
	makevectors(ang);
};



/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/


void() movetarget_f =
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");
		
	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');
	
};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner =
{
	movetarget_f ();
};


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
	local entity	temp;

	if (other.movetarget != self)
		return;
	
	if (other.enemy)
		return;		// fighting, not following a path

	temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound

//dprint ("t_movetarget\n");
	self.goalentity = self.movetarget = find (world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
	}
};



//============================================================================

/*
=============
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
=============
*/
float(entity targ) range =
{
	local vector	spot1, spot2;
	local float		r;	
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	
	r = vlen (spot1 - spot2);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ) visible =
{
	local vector	spot1, spot2;
	
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	traceline (spot1, spot2, TRUE, self);	// see through other monsters
	
	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	if (trace_fraction == 1)
		return TRUE;
	return FALSE;
};


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float(entity targ) infront =
{
	local vector	vec;
	local float		dot;
	
	makevectors2 (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;
	
	if ( dot > 0.3)
	{
		return TRUE;
	}
	return FALSE;
};

//============================================================================

void() HuntTarget =
{
	self.goalentity = self.enemy;
	if (self.enemy.classname == "camera")
	{
	self.think = self.th_walk;
	self.enemy = world;
	    return;
	}	
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1);	// wait a while before first attack
};

void() FoundTarget =
{
    if (self.enemy.classname == "camera")
	{
	    self.enemy = world;
	    return;
	}	
	if (self.enemy.classname == "player")
	{	// let other monsters see this monster for a while
		sight_entity = self;
		sight_entity_time = time;
	}
	
	self.show_hostile = time + 1;		// wake up other monsters

	//gnounc
	if(self.classname == "enforcer")
	{
		local float rsnd;
                    if (!self.p_adj) self.p_adj = 100;

		rsnd = rint(random() * 3);			
		if (rsnd == 1)
			soundpitch (self, CHAN_VOICE, self.noise, 1, ATTN_NORM, self.p_adj);
		else if (rsnd == 2)
			soundpitch (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM, self.p_adj);
		else if (rsnd == 0)
			soundpitch (self, CHAN_VOICE, self.noise2, 1, ATTN_NORM, self.p_adj);
		else
			soundpitch (self, CHAN_VOICE, self.noise4, 1, ATTN_NORM, self.p_adj);
	}
	else
			soundpitch (self, CHAN_VOICE, self.noise, 1, ATTN_NORM, self.p_adj);

	HuntTarget ();
};

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float() FindTarget =
{
	local entity	client;
	local float		r;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry

// spawnflags & 3 is a big hack, because zombie crucified used the first
// spawn flag prior to the ambush flag, and I forgot about it, so the second
// spawn flag works as well
	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) )
	{
		client = sight_entity;
		if (client.enemy == self.enemy)
			return TRUE;
	}
	else
	{
		client = checkclient ();
		if (!client)
			return FALSE;	// current check entity isn't in PVS
		if (client.classname == "camera")
		    return FALSE;	
	}

	if (client.classname == "camera")
	{
		   self.enemy = world;
			return FALSE;
    }			
			
	if (client == self.enemy)
		return FALSE;

	if (client.flags & FL_NOTARGET)
		return FALSE;

	if (client.items & IT_INVISIBILITY)
		return FALSE;

	r = range (client);
	if (r == RANGE_FAR)
		return FALSE;
		
	if (!visible (client))
		return FALSE;

	if (r == RANGE_NEAR)
	{
		if (client.show_hostile < time && !infront (client))
			return FALSE;
	}

	else if (r == RANGE_MID)
	{
		if ( /* client.show_hostile < time || */ !infront (client))
			return FALSE;
	}
	
//
// got one
//
	self.enemy = client;
	if (self.enemy.classname != "player")
	{
		self.enemy = self.enemy.enemy;
		if (self.enemy.classname != "player")
		{
			self.enemy = world;
			return FALSE;
		}
	}
	
	FoundTarget ();

	return TRUE;
};


//=============================================================================

void(float dist) ai_forward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
	walkmove ( (self.angles_y+180), dist);
};


/*
=============
ai_pain

stagger back a bit
=============
*/
void(float dist) ai_pain =
{
	ai_back (dist);
};

/*
=============
ai_painforward

stagger back a bit
=============
*/
void(float dist) ai_painforward =
{
	walkmove (self.ideal_yaw, dist);
};

/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(float dist) ai_walk =
{	
	movedist = dist;
	
	// check for noticing a player
	if (FindTarget ())
		return;

	movetogoal (dist);
          
          // Cobalt, stagger walk thinks depending on skill so monsters dont all look like they are marching together
          // added bonus, monsters will also notice players slightly more often on higher skill settings          
          if (random () < 0.15) 
          self.nextthink = self.nextthink - (frametime * cvar("skill"));
};


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() ai_stand =
{
	if (FindTarget ())
		return;
	
	if (time > self.pausetime)
	{
		self.th_walk ();
		return;
	}
	
// change angle slightly

};

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void() ai_turn =
{
	if (FindTarget ())
		return;
	
	ChangeYaw ();
};

//=============================================================================

/*
=============
ChooseTurn
=============
*/
void(vector dest3) ChooseTurn =
{
	local vector	dir, newdir;
	
	dir = self.origin - dest3;

	newdir_x = trace_plane_normal_y;
	newdir_y = 0 - trace_plane_normal_x;
	newdir_z = 0;
	
	if (dir * newdir > 0)
	{
		dir_x = 0 - trace_plane_normal_y;
		dir_y = trace_plane_normal_x;
	}
	else
	{
		dir_x = trace_plane_normal_y;
		dir_y = 0 - trace_plane_normal_x;
	}

	dir_z = 0;
	self.ideal_yaw = vectoyaw(dir);	
};

/*
============
FacingIdeal

============
*/
float() FacingIdeal =
{
	local	float	delta;
	
	delta = anglemod(self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return FALSE;
	return TRUE;
};


//=============================================================================

float()	WizardCheckAttack;
float()	DogCheckAttack;

float() CheckAnyAttack =
{
	if (!enemy_vis)
		return FALSE;
	if (self.classname == "monster_army")
		return SoldierCheckAttack ();
	if (self.classname == "monster_ogre")
		return OgreCheckAttack ();
	if (self.classname == "monster_shambler")
		return ShamCheckAttack ();
	if (self.classname == "monster_demon1")
		return DemonCheckAttack ();
	if (self.classname == "monster_dog")
		return DogCheckAttack ();
	if (self.classname == "monster_wizard")
		return WizardCheckAttack ();
	return CheckAttack ();
};


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void() ai_run_melee =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();

	if (FacingIdeal())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void() ai_run_missile =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void() ai_run_slide =
{
	local float	ofs;
	
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;
	
	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;
		
	self.lefty = 1 - self.lefty;
	
	walkmove (self.ideal_yaw - ofs, movedist);
};

float(vector org, float radius) MonsterInRange =
{
   local entity head;
   local float yes;
   
   head = findradius(org, radius); // finds entities wihthin a specified radius
   while (head) // while 'head' is not world...
   {
      if (head.health > 0) // it must be alive
      if (head.flags & FL_MONSTER) // must be a monster
      if (head != self.enemy) // must not be the ogre's enemy (he may get mad at another monster...
      {
         traceline (org, head.origin + head.view_ofs, TRUE, self); // see if he can 'see' his enemy from his grenade launcher instead of his eyes
         if (trace_fraction == 1.0) // trace_fraction of 1 means he can see it
            yes = TRUE; // set yes to TRUE
      }
      head = head.chain; // go for next entity in the chain
   }
   
   return yes; // returns 'yes' value, TRUE or FALSE
};

float() crandom; // crandom() is declared on weapons.qc, which is compiled after ai.qc, so we have to redeclare it here
vector(entity e, vector spot1, vector spot2) CheckToss =
{
   local vector midpoint, apex, vel;
   local float grav, dist1, dist2, time1, time2, timeinv;
   
   grav = cvar("sv_gravity"); // get sv_gravity value and store it on a float
   
   if (spot2_z - spot1_z > 500)
      return '0 0 0';   // if the enemy is too high above the ogre, do nothing, as the grenade can't reach there, and return '0 0 0'
   
   makevectors (e.angles); // gets forward, right and up vectors for assigned entitty (e)
   
// these two lines will spread a little bit to left-right and forward-back the position where the grenade is launched. crandom() returns between -1 to 1, 
// and here we multiply it by 8 and 16
   spot2 = spot2 + v_right * (crandom()*8 + crandom()*16);
   spot2 = spot2 + v_forward * (crandom()*8 + crandom()*16);
   
   midpoint = spot1 + (spot2 - spot1) * 0.5; // detects midpoint of grenade trajectory with a simple calculation
   traceline (midpoint, midpoint + '0 0 500', TRUE, e); // traces a line 500 units above the midpoint, ignoring monsters and other entities, and the ogre 
// himself
   
   midpoint = trace_endpos; // set midpoint to the end position of the traceline() (may be a ceiling)
   midpoint_z = midpoint_z - 15; // subtract midpoint down to 15 units
   
   if (midpoint_z < spot1_z || midpoint_z < spot2_z)
      return '0 0 0'; // if the midpoint height (z means up-down value) is lower than 'spot1' (the ogre's origin) OR lower than 'spot2' 
// (the ogre's enemy origin), then don't launch a grenade
   
   dist1 = midpoint_z - spot1_z; // get distance between midpoint and ogre
   dist2 = midpoint_z - spot2_z; // get distance between midpoint and the enemy (usually the player)
   
   time1 = sqrt(dist1 / (0.5 * grav)); // calculate time it takes for grenade to reach the ogre (in seconds), use sqrt of dist1, divided by sv_gravity 
// multiplied by half
   time2 = sqrt(dist2 / (0.5 * grav)); // same as above, but this gets time to reach the enemy
   
   if (time1 < 0.1)
      return '0 0 0';   // if it takes less than a tenth of a second from midpoint to the ogre, don't shoot
   
   timeinv = 1 / (time1 + time2); // inverts time1 + time2 (not negative)
   
   vel = (spot2 - spot1) * timeinv; // calculates velocity based on distance from the enemy to the ogre, multiplied by the inverted time
   vel_z = grav * time1; // calculate upwards velocity of the grenade, which is sv_gravity multiplied by the time it takes to reach from the ogre 
// to the midpoint
   
   apex = spot1 + vel * time1; // now, we calculate the apex of the shot, adding the ogre's origin to the grenade's velocity and multiplying by the time 
// it takes to reach the midpoint from the ogre
   apex_z = midpoint_z; // the apex's height is the same as the midpoint height, so the grenade will hit the ceiling as less as possible
   
   traceline (spot1, apex, FALSE, e); // trace a line between the ogre and the apex, and don't ignore monsters
   if (trace_fraction != 1.0)
      return '0 0 0';   // if there's something blocking the grenade's path, don't shoot!
   
   traceline (spot2, apex, TRUE, e); // trace a line between the ogre's enemy and the apex, but ignore monsters
   if (trace_fraction != 1.0)
      return '0 0 0';   // if there's a wall blocking the enemy's path, don't shoot!
   
   return vel; // return the grenade's velocity
};

float(vector src) CheckThrowGrenade =
{
   local vector vec, dist2d, toss;
   
   if (time < self.grenade_time)
      return FALSE; // if ogre has previously checked or lobbed a grenade, do nothing and return FALSE
   
   if (!(self.enemy.flags & FL_ONGROUND) && self.last_enemy_origin_z > self.absmax_z)
      return FALSE; // if the enemy is not on the ground, and the point where we last seen our enemy is above the top of the ogre's bounding box, 
// do nothing

   if (random() <= 0.5)   // find feet, 50% chance
   {   // magically know where they are
      vec = self.enemy.origin; // this will throw a  grenade at the enemy's feet
      vec_z = self.enemy.absmin_z;
   }
   else
      vec = self.last_enemy_origin; // toss it to where you last saw them
   
   if (MonsterInRange(vec, 256)) // if there's another monster nearby, don't shoot!
   {
      self.grenade_time = time + 1; // check again in 1 second
      return FALSE;
   }
   
   dist2d = vec - src; // calculate distance...
   dist2d_z = 0; // ...without regarding height
   if (vlen(dist2d) <= 256) // if length is less than or equal to 256 units...
   {
      self.grenade_time = time + 1; // again delay 1 second, do nothing after
      return FALSE;
   }
   
   if (vlen(dist2d) > 1000) // if 2d distance is over 1000 units...
   {
      self.grenade_time = time + 1; // same as above, too far away
      return FALSE;
   }
   
   toss = CheckToss(self, src, vec); // call CheckToss()... for the ogre, the ogre's origin (src), and the enemy's origin (vec)
   if (toss != '0 0 0') // if 'toss' doesn't return '0 0 0'...
   {
      self.grenade_velocity = toss; // assing self.grenade_velocity to returned 'toss' vector
      self.grenade_time = time + 0.3; // check again in the next third of a second
      return TRUE; // return TRUE, this menas he can shoot a grenade at your cover!
   }
   
   self.grenade_time = time + 1; // if all above fails, delay 1 second, return FALSE, meaning it can't shoot :(
   return FALSE;
};


void() ogre_gren1;


/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
void(float dist) ai_run =
{
	
	movedist = dist;
// see if the enemy is dead
	if ((self.enemy.health <= 0) || (self.enemy.classname == "camera"))
	{
		self.enemy = world;
	// FIXME: look all around for other targets
		if ((self.oldenemy.health > 0) && (!(self.oldenemy.classname == "camera")))
		{
			self.enemy = self.oldenemy;
			HuntTarget ();
		}
		else
		{
			if (self.movetarget)
				self.th_walk ();
			else
				self.th_walk ();
			return;
		}
	}

	self.show_hostile = time + 1;		// wake up other monsters

// check knowledge of enemy
	enemy_vis = visible(self.enemy);
	if (enemy_vis)
{
        self.last_enemy_origin = self.enemy.origin;
   self.search_time = time + 5;
}

//	if (enemy_vis)
//		self.search_time = time + 5;

// look for other coop players
	if (coop && self.search_time < time)
	{
		if (FindTarget ())
			return;
	}

	enemy_infront = infront(self.enemy);
	enemy_range = range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);
	
	if (self.attack_state == AS_MISSILE)
	{
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		ai_run_melee ();
		return;
	}

	if (!enemy_vis && (self.classname == "monster_ogre" || self.classname == "monster_ogre_marksman") && skill > 0)
{
   if (CheckThrowGrenade(self.origin))
   {
      self.grenade_time = time + 6;
      ogre_gren1 ();
      return;
   }
}

	
	
	if (CheckAnyAttack ())
		return;					// beginning an attack
		
	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}
		
// head straight in
	movetogoal (dist);		// done in C code...
};

