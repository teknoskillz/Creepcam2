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

/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
	remove(self);
};

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};

//============================================================================

float START_OFF = 1;

void() light_use =
{
	if (self.spawnflags & START_OFF)
	{
		lightstyle(self.style, "m");
		self.spawnflags = self.spawnflags - START_OFF;
	}

	else
	{
		lightstyle(self.style, "a");
		self.spawnflags = self.spawnflags + START_OFF;
	}
};

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() light =
{
	if (!self.targetname)
	{	// inert light
		remove(self);
		return;
	}
	
	if (self.style >= 32)
	{
		self.use = light_use;

		if (self.spawnflags & START_OFF)
			lightstyle(self.style, "a");

		else
			lightstyle(self.style, "m");
	}
};

/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void() light_fluoro =
{
	if (self.style >= 32)
	{
		self.use = light_use;

		if (self.spawnflags & START_OFF)
			lightstyle(self.style, "a");

		else
			lightstyle(self.style, "m");
	}
	
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
	precache_model ("progs/s_light.spr");
	setmodel (self, "progs/s_light.spr");
	makestatic (self);
};

void() FireAmbient =
{
	precache_sound ("ambience/fire1.wav");

	// attenuate fast
	ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0*/
void() light_torch_small_walltorch =
{
	precache_model ("progs/flame.mdl");
	setmodel (self, "progs/flame.mdl");
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball*/
void() light_flame_large_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	self.frame = 1;
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball*/
void() light_flame_small_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball*/
void() light_flame_small_white =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

//============================================================================


/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls*/

void() fire_fly;
void() fire_touch;
void() misc_fireball =
{	
	precache_model ("progs/lavaball.mdl");
	self.classname = "fireball";
	self.nextthink = time + (random() * 5);
	self.think = fire_fly;

	//gnounc
	self.netname = "lava_ball";
	self.killstring = " ate a lavaball\n";
          if (mapname == "e1m8") 
          {
          if (random () < 0.5)
          self.effects = EF_FLAME;
 
          }
	if (!self.speed)
		self.speed = 1000;
};

void() fire_fly =
{
	local entity	fireball;

	fireball = spawn();
	fireball.solid = SOLID_TRIGGER;
	fireball.movetype = MOVETYPE_TOSS;
	fireball.velocity = '0 0 1000';
	fireball.velocity_x = (random() * 100) - 50;
	fireball.velocity_y = (random() * 100) - 50;
	fireball.velocity_z = self.speed + (random() * 200);
	fireball.classname = "fireball";
	setmodel (fireball, "progs/lavaball.mdl");
	setsize (fireball, '0 0 0', '0 0 0');
	setorigin (fireball, self.origin);
	fireball.nextthink = time + 5;
	fireball.think = SUB_Remove;
	fireball.touch = fire_touch;
          fireball.avelocity = vectoangles (fireball.velocity);
	//gnounc
	self.netname = "lava_ball";
	self.killstring = " ate a lavaball\n";
	
	self.nextthink = time + (random() * 5) + 3;
	self.think = fire_fly;
           if (mapname == "e1m8") 
          {
          if (random () < 0.5)
          fireball.gravity = random ();
          if (random () < 0.5)
          fireball.effects = EF_FLAME;
          if (random () < 0.5)
          fireball.modelflags += 1;
          if (random () < 0.5)
          fireball.modelflags += 2;
           if (random () < 0.5)
          fireball.modelflags += 64;
          }
          fireball.dmg = (15 * (skill + 1));
          if (fireball.effects & EF_FLAME)
                    fireball.dmg *= 1.25;
          
};


void() fire_touch =
{
	T_Damage (other, self, self, self.dmg);
	remove(self);
};
/*
=======================================================================
Title                   : BoxFix
Date Finished           :  9 - 14 - 1997
Author                  : Patrick Martin
Email Address           : cmarti39@icon.net
Misc. Author Info       : I like Doom][ and QUAKE.
Description:
     Ever since I have played around with my Buster patch,
I noticed a bug with the barrels in Quake:  Whenever a
radius attack destroys a barrel, that radius attack is
negated and the explosion of the barrel's takes its place.

     Since nothing in normal Quake (other than lightning
discharge underwater) had the explosive power of an exploding
barrel, this bug had very little if any effect in regular
Quake.  However, custom weapons which produce large, damaging
explosions, such as those that recreate the effects of a nuke,
could have their damaging effects spoiled if a barrel is
destroyed by the explosion.

     Below is some code that will fix this bug.  What it
does is delay the barrel explosion for a frame (0.1 sec.),
which will let *your* weapon do the damage first without
interference; then the barrel explodes immediately afterward.

     Feel free to cut-and-paste this code into your projects.


MISC.QC
(Go down to

	void() barrel_explode =

 and erase the *entire* function.

 Then insert the following two functions where
 the original void() barrel_explode used to be...)


//-------------------------------------------------------- Code Change -----
//  This fixes a bug in which barrel explosions cancel other explosions.
//  Here, the barrel explosion is delayed for one frame so that other
//  explosions can occur without interference from the barrel.
//--------------------------------------------------------------------------
*/
void() barrel_damage =
{

          // Cobalt - modified less dmg for smaller box, change self.enemy to self so obit works 
	if (self.health == 20)
	T_RadiusDamage (self, self, 120, world);
	else
	T_RadiusDamage (self, self, 160, world);
           if (random () < 0.5)
	setorigin (self, self.absmax); // Cobalt - experiment....
	else if (random () < 0.5)
	setorigin (self, self.absmin); // Cobalt - experiment....
        self.effects = self.effects | EF_BRIGHTFIELD;
	BecomeExplosion ();
};

void() barrel_explode =
{
	self.takedamage = DAMAGE_NO;
	self.classname = "explo_box";
        sound (self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);
        particle (self.origin + '0 0 32', '0 0 0', 75, 255);
        self.nextthink = time + 0.1;
        self.effects = EF_BRIGHTLIGHT;
        self.think = barrel_damage;
};
//---------------------------------------------------------------- END -----


/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING*/

void() misc_explobox =
{
	local float	oldz;
	
	self.solid = SOLID_SLIDEBOX; // Cobalt, was BBOX for some reason?
	self.movetype = MOVETYPE_NONE;
	precache_model ("maps/b_explob.bsp");
	setmodel (self, "maps/b_explob.bsp");
	precache_sound ("weapons/r_exp3.wav");
	self.health = 20;
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;

	//gnounc
	self.netname = "exploding barrel";
	self.killstring = " blew up.\n";

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor();

	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
	}
};




/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY*/

void() misc_explobox2 =
{
	local float	oldz;
	
	self.solid = SOLID_SLIDEBOX; // Cobalt, was BBOX for some reason?
	self.movetype = MOVETYPE_NONE;
	precache_model2 ("maps/b_exbox2.bsp");
	setmodel (self, "maps/b_exbox2.bsp");
	precache_sound ("weapons/r_exp3.wav");
	self.health = 15; // Cobalt smaller box, less health
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;

	//gnounc
	self.netname = "exploding_barrel";
	self.killstring = " exploded.\n";

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor();

	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
	}
};

//============================================================================

float SPAWNFLAG_SUPERSPIKE	= 1;
float SPAWNFLAG_LASER = 2;

void(vector org, vector vec) LaunchLaser;

void() spikeshooter_use =
{
          sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	if (self.spawnflags & SPAWNFLAG_LASER)
          {
                    self.netname = "Laser Sentry";
                    if (framecount & 1)
            self.killstring =" got zapped.\n"; // Cobalt for laser traps
          else self.killstring =" was killed by a laserbeam.\n"; 
	LaunchLaser (self.origin, self.movedir);                    
          }
          else
	{

		launch_spike (self.origin, self.movedir);
		newmis.velocity = self.movedir * 500;
		self.killstring =" was spiked.\n"; // Cobalt, moved here
                    self.netname = "Spike Trap";
		if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
		{
                    self.netname = "Superspike Trap";
		newmis.touch = superspike_touch;
		self.killstring =" was crucified.\n"; // Cobalt for lsuperspike death
                    }
               }		
	
	
};

void() shooter_think =
{
	spikeshooter_use ();
	self.nextthink = time + self.wait;
	newmis.velocity = self.movedir * 500;
};


/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.*/

void() trap_spikeshooter =
{
	SetMovedir ();
	self.use = spikeshooter_use;
	
	//gnounc
	self.netname = "spike_trap";
	

	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		precache_model2 ("progs/laser.mdl");
		precache_sound2 ("enforcer/enfire.wav");
		precache_sound2 ("enforcer/enfstop.wav");
                    self.noise1 = "enforcer/enfire.wav";
		
	}

	else
          {
		precache_sound ("weapons/spike2.wav");
                    self.noise1 = "weapons/spike2.wav";
          }
};


/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
*/
void() trap_shooter =
{
	trap_spikeshooter ();
	
	if (self.wait == 0)
		self.wait = 1;

	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
};



/*
===============================================================================


===============================================================================
*/


void() make_bubbles;
void() bubble_remove;
void() bubble_bob;

/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
*/

void() air_bubbles =

{
	if (deathmatch)
	{
		remove (self);
		return;
	}

	precache_model ("progs/s_bubble.spr");
	self.nextthink = time + 1;
	self.think = make_bubbles;
};

void() make_bubbles =
{
	local entity	bubble;

	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + random() + 0.5;
	self.think = make_bubbles;
};

void() bubble_split =
{
	local entity	bubble;
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = self.velocity;
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 1;
	bubble.cnt = 10;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.frame = 1;
	self.cnt = 10;

	if (self.waterlevel != 3)
		remove (self);
};

void() bubble_remove =
{
	if (other.classname == self.classname)
		return;

	remove(self);
};

void() bubble_bob =
{
	local float		rnd1, rnd2, rnd3;

	self.cnt = self.cnt + 1;
	if (self.cnt == 4)
		bubble_split();

	if (self.cnt == 20)
		remove(self);

	rnd1 = self.velocity_x + (-10 + (random() * 20));
	rnd2 = self.velocity_y + (-10 + (random() * 20));
	rnd3 = self.velocity_z + 10 + random() * 10;

	if (rnd1 > 10)
		rnd1 = 5;
	
	if (rnd1 < -10)
		rnd1 = -5;
		
	if (rnd2 > 10)
		rnd2 = 5;
	
	if (rnd2 < -10)
		rnd2 = -5;
		
	if (rnd3 < 10)
		rnd3 = 15;
	
	if (rnd3 > 30)
		rnd3 = 25;
	
	self.velocity_x = rnd1;
	self.velocity_y = rnd2;
	self.velocity_z = rnd3;
		
	self.nextthink = time + 0.5;
	self.think = bubble_bob;
};

/*~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~*/

/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)

Just for the debugging level.  Don't use
*/

void() viewthing =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	precache_model ("progs/player.mdl");
	setmodel (self, "progs/player.mdl");
};


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{	// change to alternate textures
	self.frame = 1 - self.frame;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted*/
void() func_wall =
{
          if (mapname == "start" && self.model == "*48")
          {
           self.origin_x += -6;
           self.alpha = 0.92;
           self.wait = 10;
           self.lip = 8;
           self.health = 5;
           self.t_width = 0.01;
           self.t_length = 256;
           self.sounds = rint (random () * 3);
           self.angles = '-90 0 2';
           func_door_secret ();
           return;
          }
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};


/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.*/
void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	makestatic (self);
};

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.*/
void() func_episodegate =
{
	if (!(serverflags & self.spawnflags))
		return;			// can still enter episode

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.*/
void() func_bossgate =
{
	if ( (serverflags & 15) == 15)
		return;		// all episodes completed

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

//============================================================================
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_suck_wind =
{
	precache_sound ("ambience/suck1.wav");
	ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_drone =
{
	precache_sound ("ambience/drone6.wav");
	ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_flouro_buzz =
{
	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_drip =
{
	precache_sound ("ambience/drip1.wav");
	ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_comp_hum =
{
	precache_sound ("ambience/comp1.wav");
	ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_thunder =
{
	precache_sound ("ambience/thunder1.wav");
	ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_light_buzz =
{
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_swamp1 =
{
	precache_sound ("ambience/swamp1.wav");
	ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)*/
void() ambient_swamp2 =
{
	precache_sound ("ambience/swamp2.wav");
	ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};

//============================================================================

void() noise_think =
{
	self.nextthink = time + 0.5;
	sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
	sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
	sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
	sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
	sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
	sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
	sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
*/

void() misc_noisemaker =
{
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/idle1.wav");

	self.nextthink = time + 0.1 + random();
	self.think = noise_think;
};
 