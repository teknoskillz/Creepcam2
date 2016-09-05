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

void () RandomMonster;
void() SUB_Null = {};

void() SUB_Remove = {remove(self);};


/*QuakeEd only writes a single float for angles (bad idea), so up and down are
just constant angles.*/
void() SetMovedir =
{
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';

	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';

	else
	{
		makevectors2 (self.angles);
		self.movedir = v_forward;
	}
	
	self.angles = '0 0 0';
};

/*
================
InitTrigger
================
*/
void() InitTrigger =
{
	// trigger angles are used for one-way touches.  An angle of 0 is assumed
	// to mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0')
		SetMovedir ();

	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = string_null;
};

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt =
{
	local entity	stemp;
	stemp = self;
	self = ent;

	SUB_CalcMove (tdest, tspeed, func);
	self = stemp;
};

void(vector tdest, float tspeed, void() func) SUB_CalcMove =
{
	local vector	vdestdelta;
	local float		len, traveltime;

	if (!tspeed)
		objerror("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
		
	// set destdelta to the vector needed to move
	vdestdelta = tdest - self.origin;
	
	// calculate length of vector
	len = vlen (vdestdelta);
	
	// divide by speed to get time to reach dest
	traveltime = len / tspeed;

	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
	
	// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;

	// scale the destdelta vector by the time spent traveling to get velocity
	self.velocity = vdestdelta * (1/traveltime);	// qcc won't take vec/float	
};

/*
============
After moving, set origin to exact final destination
============
*/
void()  SUB_CalcMoveDone =
{
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;

	if (self.think1)
		self.think1();
};


/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating 

The calling function should make sure self.think is valid
===============
*/
void(entity ent, vector destangle, float tspeed, void() func) SUB_CalcAngleMoveEnt =
{
	local entity		stemp;
	stemp = self;
	self = ent;
	SUB_CalcAngleMove (destangle, tspeed, func);
	self = stemp;
};

void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove =
{
	local vector	destdelta;
	local float		len, traveltime;

	if (!tspeed)
		objerror("No speed is defined!");
		
	// set destdelta to the vector needed to move
	destdelta = destangle - self.angles;
	
	// calculate length of vector
	len = vlen (destdelta);
	
	// divide by speed to get time to reach dest
	traveltime = len / tspeed;

	// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;

	// scale the destdelta vector by the time spent traveling to get velocity
	self.avelocity = destdelta * (1 / traveltime);
	
	self.think1 = func;
	self.finalangle = destangle;
	self.think = SUB_CalcAngleMoveDone;
};

/*
============
After rotating, set angle to exact final angle
============
*/
void() SUB_CalcAngleMoveDone =
{
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;

	if (self.think1)
		self.think1();
};


//=============================================================================

void() DelayThink =
{
	activator = self.enemy;
	SUB_UseTargets ();
	remove(self);
};

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void() SUB_UseTargets =
{
	local entity t, act, stemp, otemp;

//
// check for a delay
//
	if (self.delay)
	{
		// create a temp object to fire at a later time
		t = spawn();
		t.classname = "DelayedUse";
		t.nextthink = time + self.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = self.message;
		t.killtarget = self.killtarget;
		t.target = self.target;

		return;
	}
	
	
//
// print the message
//
	if (activator.classname == "player" && self.message != string_null)
	{
		centerprint (activator, self.message);

		if (!self.noise)
			sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
	}

//
// kill the killtagets
//
	if (self.killtarget != string_null)
	{
		t = world;

		do
		{
			t = find (t, targetname, self.killtarget);

			if (!t)
				return;

			remove (t);
		} while ( 1 );
	}
	
//
// fire targets
//
	if (self.target != string_null)
	{
		act = activator;
		t = world;

		do
		{
			t = find (t, targetname, self.target);
			if (!t)
			{
				return;
			}

			stemp = self;
			otemp = other;
			self = t;
			other = stemp;

			if (self.use != SUB_Null)
			{
				if (self.use)
					self.use ();
			}
			self = stemp;
			other = otemp;
			activator = act;
		} while ( 1 );
	}	

};

/*in nightmare mode, all attack_finished times become 0
some monsters refire twice automatically*/

void(float normal) SUB_AttackFinished =
{
	self.cnt = 0;		// refire count for nightmare

	if (skill != 3)
		self.attack_finished = time + normal;
};

float (entity targ) visible;

void (void() thinkst) SUB_CheckRefire =
{
	if (skill != 3)
		return;

	if (self.cnt == 1)
		return;

	if (!visible (self.enemy))
		return;

	self.cnt = 1;
	self.think = thinkst;
};

// Cobalt, borrowed from Frikbot
vector(entity ent) realorigin =
{
// even more simplified...
	return (ent.absmin + ent.absmax) * 0.5;
};
// PRIME
float(vector veca, vector vecb) crossproduct =
{
	local float result;

	result = (veca_x * vecb_y) - (vecb_x * veca_y);
	return result;
};


void(entity ent) slope_angles =
{
   local vector org, org2, ang, pitchdir, rolldir, norm;
   local float pitch_sin, roll_sin, pitch, roll;

// ent is an observer or not initialized yet
   if (ent.movetype == MOVETYPE_NOCLIP)
      return;

//   if (ent.size == VEC_0)   // not initialized
//   if (ent.origin == VEC_0)
//      return;

// hack to avoid traceline runaways for ents placed upside down 
   if (ent.angles_x > 90 || ent.angles_x < -90)
      return;

   if (ent.angles_z > 90 || ent.angles_z < -90)
      return;

// trace line downwards and try to hit a ground plane
   org = ent.origin;


   org2 = org + '0 0 -16';   // use small dist to account for thin walkways and such 
   traceline(org, org2, MOVE_NOMONSTERS, ent);

// if unsuccessful, then increment and trace again
   while ((trace_fraction == 1) && (org_z - org2_z >= ent.mins_z))   
   {
      org2 = org2 + '0 0 -8';
      traceline(org, org2, MOVE_NOMONSTERS, ent);

      if (org2_z <= -1024)   // prevent runaways
         break;
   }

   norm = trace_plane_normal;

   if (checkbottom(ent) &&      // on ground
       (trace_fraction != 1) &&    // touching the ground
       (norm_x || norm_y))      // ground plane is a slope
   {
      if (!(ent.owner.flags & FL_CLIENT))
      ang = ent.owner.angles;
      else 
      {          
      ang = ent.owner.v_angle;
         ang_x = 0;
         ang_z = 0;
      }
      if (ent.owner.flags & FL_CLIENT)
         ang_z = 0;   // no roll, for client rollangle
   
      makevectors(ang);
   
      pitchdir = vreverse(v_forward);
      rolldir = v_right;
   
      pitch_sin = pitchdir_x*norm_x + pitchdir_y*norm_y + pitchdir_z*norm_z;
      pitch = RAD2DEG*asin(pitch_sin);
      roll_sin = rolldir_x*norm_x + rolldir_y*norm_y + rolldir_z*norm_z;
      roll = RAD2DEG*asin(roll_sin);
   
      if (ent.owner.flags & FL_CLIENT)
      {
         ent.angles_x = pitch;
         ent.angles_z = roll;
         return;
      }
   
      if (ent.owner.flags & FL_MONSTER)
      {
         if (ent.enemy == world)   // currently not eyeing somebody
         {
            ent.idealpitch = pitch/3;
            changepitch(ent);
         }
         ent.idealroll = roll/3;
         changeroll(self);
         return;
      }
   
      if (ent.owner.flags & FL_CLIENT)
      {
         ent.angles_x = ent.angles_x + pitch/3;
         ent.angles_z = ent.angles_z + roll/3;
      }
   }
   else if (ent.owner.flags & FL_MONSTER)   // not on a slope, so adjust back to normal
   {
      if (ent.enemy == world)
      {   
         ent.idealpitch = 0;
         changepitch(ent);
      }
      ent.idealroll = 0;
      changeroll(self);
   }
};

// For player model only for now
void (entity this) MatchSurfaceAngles =
{
local vector c1,c2,c3, ofs;
ofs = '0 0 10';
c1 = this.absmax;
c1_z = this.absmin_z; // opposite corner (hypotenuse line)

c2 = c1 - '0 32 0'; // forward corner from absmin
c3 = c1 - '32 0 0'; // left corner from absmin

traceline (c1, c1 - ofs, TRUE, this);


traceline (c2 , c2 - ofs, TRUE, this);

traceline (c3, c3 - ofs, TRUE, this);

traceline (this.absmin, this.absmin - ofs, TRUE, this);

};

void (entity what, entity scr, float val) SUB_InfoBar =
{
          

          if (val == 0 || (!(scr.flags & FL_CLIENT))) return;
      
      
   local string txt,tag,sgn;
   local entity ast;
   local float bonus;
   
    if ((what.flags & FL_MONSTER) && what.health < what.deadflag)
    {
           if (what.axhitme > time)
           tag = strcat (what.netname, " ^1AXE-GIB^7");
           else
           tag = strcat (what.netname, " ^1GIBBED^7");
    }           
   else tag = what.netname;
   if (val > 0)
   sgn = "+";
   else sgn = "-";
   if ((what.flags & FL_MONSTER) && what.health > 0)
   tag = strcat ("KILLED BY ",what.netname);
   else if (what.solid == world.solid || (what.owner != world && (!(what.th_die))))
   if (scr.watertype < 0)
   tag = scr.deathtype;         
  
      if (val < 0)
      val = 0 - val;

        
    if (what.flags & FL_CLIENT)
    {
              soundpitch (scr, CHAN_AUTO, "enforcer/death1.wav", 1, ATTN_IDLE, ((val * 1.5) - val));
              scr.dmg_take = val + scr.frags;
    }
    
   if (what == scr) 
             tag = "^1Self-Kill^7";
               if (what.flags & FL_MONSTER)
   {
    ast = what.enemy;
    if (ast.flags & FL_CLIENT)
    if (ast != scr && ast.health > 0 && ast.dmg_inflictor == what)              
    if ((ceil (vlen (what.origin - ast.origin))) < 325)
    {
    tag = strcat (what.netname, " ^2TEAMWORK^7");
    tag = strcat (tag, " ");
    tag = strcat (tag, "(");
    tag = strcat (tag, ast.netname);
    tag = strcat (tag, ")");
     bonus = (100 - ast.health) * (skill + 1);
     if (bonus > 0) val = val + bonus;
    }              
   }
   
          
          txt = strcat (sgn,(ftos (val)));
          txt = strcat (txt," ");
          txt = strcat (txt,tag);
            
   
           
             if (scr.killstring)
             {
             scr.killstring = strcat (scr.killstring," ");
             scr.killstring = strcat (scr.killstring,txt);
             txt = scr.killstring;
             }
             local float t;
             t = strlennocol (txt);
             if (t < 6) t = 6;
             if (t > 12) t = 12;
             stuffcmd (scr, "infobar ");
             stuffcmd (scr, (ftos(t)));

             stuffcmd (scr, " \"");
              stuffcmd (scr, txt);
              stuffcmd (scr, "\"");
		stuffcmd (scr, "\n");
                    
      
             if (bonus > 0)
             {
             soundpitch (self, CHAN_AUTO, "misc/secret.wav", 1, ATTN_IDLE, 30);
             scr.frags = scr.frags + bonus;          
             }
                
              scr.wait = time + 2.5;
       scr.killstring = strzone (txt);
          
          
};

void () VelocityPhysics = 
{



local entity r;
local vector ctr, low, high, small, large;

r = find (world, classname, "plat");
	while (r.velocity_z != 0)
	{
	

	//bprint ("Plat ");
	//bprint (r.model);
	//bprint (" Is moving...waterlevel is ");
	//bprint (ftos (r.waterlevel));
	//PrintNL ();
	
	ctr = ((r.absmax + r.absmin) * 0.5);

	//if (r.state == STATE_DOWN)
	if ((pointcontents (r.absmax + '0 0 5') == CONTENT_EMPTY && pointcontents (r.absmax) == CONTENT_WATER))
	{
	pointsound (ctr, "misc/h2ohit1.wav", 1, 1);   
	//drip(r.absmax ,WATERCOLOR);
       r.velocity =  r.velocity * 0.95;
	}
/*
	
	if ((pointcontents (ctr + '0 0 -5') == CONTENT_WATER))
	bprint ("Plat in water\n");
	if ((pointcontents (r.absmax + '0 0 5') == CONTENT_EMPTY))
          bprint ("Plat near surface\n");
	   */
		r = find (r, classname, "plat");
		
	}





                    r = TTRAIN;
            if (time > 5 && r.model == "progs/teleport.mdl" && r.deadflag < time)
          {
                    r.effects = 2;

          
          if (random () * (skill + 1) < skill)
          {
          local entity newm;
          newm = spawn ();
          setorigin (newm, r.origin);
          r.aiment = newm;
          local entity os;
          os = self;
          self = r.aiment;
          RandomMonster();
          self = os;
          }
          r.deadflag = time + 3;
          }
		
	


};

void(string s, entity annc) SUB_TellAll = 
{
	local entity p;
          local string tel;
          tel = "tell # ";
	p = world;
	while (p = find(p, classname, "player")) 
          {
          if (p != annc)
          {
          tel = strcat (tel, (ftos(p.colormap)));
          tel = strcat (tel, " ");
          tel = strcat (tel, s);
          tel = strcat (tel, "\n");
	stuffcmd(annc, tel);
	}
          }
};

void (float lv, vector col, float sty, entity point) SUB_CastLight =
{

          local vector lite;
          lite = '9 9 9';
          if (point.classname != "light_fluoro")
          lite = getlight (point.origin);
          else
          point.angles = GetRandomVector ();
	
       if (lite == VEC_ORIGIN)
	point.effects = point.effects | EF_FULLBRIGHT;
	
point.light_lev = lv; //150;
point.color = col; //'1 1 1'; // color (does not affect radius), typical value '1 1 1' (bright white), can be up to '255 255 255' (nuclear blast)
point.style = sty; //12; //rint (random () * 10) + 1; // light style (like normal light entities, flickering torches or switchable, etc)
point.pflags = 128;
//p.angles = '45 10 -50';


};

void (float flag) SUB_BlinkRune =
{

//  bprint("blink rune\n");

if (self.items2 & flag)
self.items2 = 0;
else
self.items2 = flag;
return;
};

void () SUB_ShowMapAuthor =
{
if (self == world)
{          
local string aut;
if (mapname == "dm3" || mapname == "start" || mapname == "e1m1"|| mapname == "e2m1" || mapname == "e2m2" || mapname == "e2m3" || mapname == "e2m4" || mapname == "e2m5" || mapname == "e2m6" || mapname == "e3m1" || mapname == "end")
aut = ". By John Romero";
else if (mapname == "dm1" || mapname == "e1m2" || mapname == "e1m3" || mapname == "e1m4" || mapname == "e1m5" || mapname == "e2m7" || mapname == "e3m5" || mapname == "e4m1")
aut = ". By Tim Willits";   
else if (mapname == "dm6" || mapname == "dm5" || mapname == "dm4" || mapname == "dm2" || mapname == "e1m8" || mapname == "e1m6" || mapname == "e1m7" || mapname == "e3m2" || mapname == "e3m4" || mapname == "e3m7")
aut = ". By American McGee"; 
else if (mapname == "e3m6")
aut = ". By American McGee & Tim Willits\n";
else if (mapname == "e4m2" || mapname == "e4m3" || mapname == "e4m5" || mapname == "e4m6" || mapname == "e4m7" || mapname == "e4m8")
aut = ". By Sandy Petersen";  
else return;
local string ms;
ms = world.message;
aut = strzone (strcat (ms, aut));
mtitle = aut;

} 
};
void () SUB_PrintUpTime =
{


          local float mtime,stime,htime,dtime;
          uptime = (gettime (3));
         // days = num_seconds / (60 * 60 * 24);
         // num_seconds -= days * (60 * 60 * 24);
         // hours = num_seconds / (60 * 60);
         // num_seconds -= hours * (60 * 60);
          
          mtime = rint(floor(uptime / 60));
          if (mtime > 59)
          mtime = 0;
          
          
          htime = rint(floor(uptime / (3600)));
          if (htime > 23)
          {
          htime = 0;
          dtime = (rint(floor(uptime / (3600)))) * 24;
          }
          
          if (uptime < 60)
          stime = rint(uptime);
	else
          {
          if (mtime && !htime)
          stime = floor (uptime - (mtime * 60));
          else if (htime && !mtime)
          stime = floor (uptime - (htime * 3600));     
          else if (mtime && htime)
          stime = floor (uptime - ((mtime * 60) + (htime * 3600)));     
          }          

          bprint ("Total Quake server uptime ");
	if (stime < 60 && (!mtime && !htime))
	{
	bprint (ftos(stime));
	bprint (" Seconds.\n");
	}
	else
	{
	  if (dtime > 0)
          {                    
	bprint (ftos(dtime));
          if (dtime != 1)
	bprint (" Days ");
          else
              bprint (" Day ");
           if (!mtime && !stime && !htime)
                    bprint (".\n");    
	}	
		
          if (htime > 0)
          {                    
	bprint (ftos(htime));
          if (htime != 1)
	bprint (" Hours ");
          else
              bprint (" Hour ");
           if (!mtime && !stime)
                    bprint (".\n");    
	}
	if (mtime > 0)
          {                    
	bprint (ftos(mtime));
          if (mtime != 1)
	bprint (" Minutes ");
          else
          bprint (" Minute ");
          if (!stime)
                    bprint (".\n");
	}
          if (stime > 0)
          {
	bprint (ftos(stime));
	bprint (" Seconds.\n");
	}
       }
          
          
};

 