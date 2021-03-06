/*
*********************************************************
mathlib.qc

Originally created by FrikaC
Some functions provided by Kashua & LordHavoc & Preach

Overview:
---------
This file provides arithmetic and trigonomic functions
to QuakeC. The common functions sqrt (Square root), cos
(cosine), pow (raise to power) are covered as well as 
more esoteric logic functions such as min, max, bound
and randomvec. The conveinance functions anglemod and
angcomp are also included. The mod() function is also
provided to emulate C's modulus (%) operator, kinda.

Support for engine acceleration of these functions is
also provided (See the bottom portion of the file). However
advanced engine features are NOT needed. To compile the
enhanced engine portion of this file you'll need a 
QuakeC compiler that supports the FrikQCC 'var' keyword.

Installation: 
-------------
Place mathlib.qc in progs.src above world.qc. If using
the ehanced engine option call MathlibCheckBuiltins();
from worldspawn in world.qc.

If you're not planning to use the enhanced engine option
prefix all your calls to the above mentioned functions
with mathlib_ (e.g. mathlib_pow(2,1)) and remove the
bottom portion of this file.

License:
--------
This file is public domain.

*********************************************************
*/

float pi = 3.14159265;

float HI8 = 1;        // s1 value of encode() call
float MID8 = 2;    // s2 value of encode() call
float LOW8 = 3;    // s3 value of encode() call

// You can set the accuracy of mathlib by changing this value.
// If unset, it defaults to 0.001
float mathlib_accuracy; //accuracy of sqrt & pow

/*
-----------------------------------------
square root

-----------------------------------------
*/
float(float num) mathlib_sqrt =
{
	local float apr;

	if(mathlib_accuracy <= 0)
		mathlib_accuracy = 0.001;   //this sets a level of accuracy, it's a global float

	if (num < mathlib_accuracy)
		return 0;
	if (num>1)
		apr = num;
	else
		apr = 1;
	do
	{
		apr = (num + (apr * apr)) / (2 * apr);
	}
	while (fabs((apr * apr) - num) > (num * mathlib_accuracy));
	return apr;
};

/*
-----------------------------------------
sine

-----------------------------------------
*/

float(float num) mathlib_sin =
{
	local vector ang,vf,vu,vr;
	
	vf = v_forward;
	vu = v_up;
	vr = v_right;
	
	ang = '0 1 0' * num;
	makevectors(ang);
	num = v_forward_y;
	
	v_forward = vf;
	v_up = vu;
	v_right = vr;
	
	return num;
};

/*
-----------------------------------------
cosine
-----------------------------------------
*/

float(float num) mathlib_cos =
{
	local vector ang,vf,vu,vr;
	
	vf = v_forward;
	vu = v_up;
	vr = v_right;
	
	ang = '0 1 0' * num;
	makevectors(ang);
	num = v_forward_x;
	
	v_forward = vf;
	v_up = vu;
	v_right = vr;
	
	return num;
};

/*
-----------------------------------------
pow

raise to a power

you ought not use this if the power you're raising to is constant
ie, just use r * r * r for cubing, it's a lot faster
-----------------------------------------
*/


float(float a, float b) mathlib_fast_pow =
{
	local float fb, n, bit, factor;
	
	fb = fabs(b);
	bit = 1;
	n = 1;
	factor = a;
	while (bit <= fb)
	{
		if (fb&bit)
			n = n * factor;
		factor = factor * factor;
		bit = bit * 2;
	}
	if (b < 0)
		return 1/n;
	else
		return n;
};

float(float a, float b) mathlib_pow =
{
	local float e1,e2,f,i;
	
	if (mathlib_accuracy <= 0)
		mathlib_accuracy = 0.001; 
	if (fabs(rint(b) - b) <= mathlib_accuracy)
		return mathlib_fast_pow(a, rint(b));
		
	f = (a - 1) / (a + 1);
	//this is the first trick
	//we're essentially doing exp(b*log(a))
	//but the power series for log (1+x) is only defined for small x
	//however log x = 2 * arctanh((x-1)/(x+1)) which will converge for any x we choose
	            
	e2 = 2 * f;
	i = 1;
	f = f * f;
	
	while(fabs(e2) > mathlib_accuracy)
	{
		e1 = e1 + e2;               //this calculates successive terms of arctanh
		e2 = e2 * f * ((2 * i) - 1) / ((2 * i) + 1);   //when the absolute value of a term drops
		i = i + 1;               //below accuracy we call it a day
	}                  //note that this doesn't actually mean
	//the output is accurate to 0.001, there's no
	//direct bound on accuracy
	f = e2 = e1 * b;
	e1 = 1;
	i = 1;
	while(fabs(e2) > mathlib_accuracy)            //same idea, this is the exponential function
	{                  //which has a nice power series
		e1 = e1 + e2;               //same comments about accuracy apply, except
		i = i + 1;               //the rapid decay of terms mean it's probably
		e2 = e2 * f / i;            //close to the true value of exp f, if not pow(a,b)
	}
	return e1;
} ;

/*
-----------------------------------------
Bitshift
-----------------------------------------
*/

float (float number, float exp) mathlib_bitshift =
{
	local float bit, fexp;
	bit = 1;
	fexp = fabs(exp);
	number = rint(number);
	
	while (bit <= fexp)
	{
		if (fexp & bit)
		{
			if (exp > 0)
				number = number * bit * 2;
			else
				number = floor(number / (bit * 2));
		}
		bit = bit * 2;
	}
	return number;
};
/*
-----------------------------------------
Remainder

Similar to C's % operator, but deals with
negative numbers differently.
-----------------------------------------
*/

float(float a, float b) mod =
{
	return a - (floor(a / b) * b);
};

/*
-----------------------------------------
mathlib_anglemod 

faster version of id's anglemod
-----------------------------------------
*/
float(float v) anglemod =
{
	return v - floor(v/360) * 360;
};

/*
-----------------------------------------
angcomp (part of FrikBot)

subtracts one angle from another
-----------------------------------------
*/
// DRS: Commented out because this already exists in FBX.
//
//float (float y1, float y2) angcomp =
//{
//    y1 = anglemod(y1);
//    y2 = anglemod(y2);
//
//    local float answer;
//    answer = y1 - y2;
//    if (answer > 180)
//        answer = answer - 360;
//    else if (answer < -180)
//        answer = answer + 360;
//    return answer;
//};

/*
-----------------------------------------
min

Returns the lesser of two (or more) numbers

-----------------------------------------
*/

float (float a, float b) mathlib_min =
{
	if (a<b)
		return a;
	else
		return b;
};
float (float a, float b, float c) mathlib_min3 =
{
	if (a<b)
	{
		if (c<a)
			return c;
		else
			return a;
	}
	else
	{
		if (c<b)
			return c;
		else
			return b;
	}
};

float (float a, float b, float c, float d) mathlib_min4 =
{
	return mathlib_min(mathlib_min3(a,b,c),d);
};
float (float a, float b, float c, float d, float e) mathlib_min5 =
{
	return mathlib_min3(mathlib_min3(a,b,c),d,e);
};
float (float a, float b, float c, float d, float e, float f) mathlib_min6 =
{
	return mathlib_min(mathlib_min3(a,b,c), mathlib_min3(d,e,f));
};
float (float a, float b, float c, float d, float e, float f, float g) mathlib_min7 =
{
	return mathlib_min3(mathlib_min3(a,b,c), mathlib_min3(d,e,f), g);
};
float (float a, float b, float c, float d, float e, float f, float g, float h) mathlib_min8 =
{
	return mathlib_min3(mathlib_min3(a,b,c), mathlib_min3(d,e,f), mathlib_min(g, h));
};

/*
-----------------------------------------
max

Returns the greater of two (or more) numbers
-----------------------------------------
*/

float (float a, float b) mathlib_max =
{
	if (a>b)
		return a;
	else
		return b;
};
float (float a, float b, float c) mathlib_max3 =
{
	if (a>b)
	{
		if (c>a)
			return c;
		else
			return a;
	}
	else
	{
		if (c>b)
			return c;
		else
			return b;
	}
};
float (float a, float b, float c, float d) mathlib_max4 =
{
	return mathlib_max(mathlib_max3(a,b,c),d);
};
float (float a, float b, float c, float d, float e) mathlib_max5 =
{
	return mathlib_max3(mathlib_max3(a,b,c),d,e);
};
float (float a, float b, float c, float d, float e, float f) mathlib_max6 =
{
	return mathlib_max(mathlib_max3(a,b,c), mathlib_max3(d,e,f));
};
float (float a, float b, float c, float d, float e, float f, float g) mathlib_max7 =
{
	return mathlib_max3(mathlib_max3(a,b,c), mathlib_max3(d,e,f), g);
};
float (float a, float b, float c, float d, float e, float f, float g, float h) mathlib_max8 =
{
	return mathlib_max3(mathlib_max3(a,b,c), mathlib_max3(d,e,f), mathlib_max(g, h));
};

/*
-----------------------------------------
bound

Returns a number bound to certain limits
-----------------------------------------
*/

float(float minimum, float val, float maximum) mathlib_bound =
{
	if (val<minimum)
		val=minimum;
	else if (val>minimum)
		val=maximum;
	return val;
};

/*
-----------------------------------------
randomvec
Returns a random vector of length < 1
-----------------------------------------
*/

vector () mathlib_randomvec =
{
	local vector v;
	do
	{
		v_x = random() * 2 - 1;
		v_y = random() * 2 - 1;
		v_z = random() * 2 - 1;
	}
	while(vlen(v) > 1);
	return v;
};

/*
-----------------------------------------
Radians <--> Degrees

Simple functions that convert radians to
degrees.
-----------------------------------------
*/

// for speed...
float OneEightyOverPi = 57.29577;
float PiOverOneEighty = 0.017453;

float (float num) rad2deg = { return num*OneEightyOverPi; };
float (float num) deg2rad = { return num*PiOverOneEighty; };

/*
*********************************************************

!!!FTEQCC or FrikQCC only code follows !!!

This code allows the engine to accelerate math functions

If not needed, you can simply delete the rest of the file
and call the mathlib functions above directly.

It checks for the extensions DP_QC_MINMAXBOUND,
DP_QC_RANDOMVEC, DP_QC_SINCOSSQRTPOW, EXT_BITSHIFT

*********************************************************
*/

var float (float num) sqrt;
var float (float num) sin;
var float (float num) cos;
var float (float num, float exp) pow;
var float (float number, float exp) bitshift;
var float (float a, float b) min;
var float (float a, float b, float c) min3;
var float (float a, float b, float c, float d) min4;
var float (float a, float b, float c, float d, float e) min5;
var float (float a, float b, float c, float d, float e, float f) min6;
var float (float a, float b, float c, float d, float e, float f, float g) min7;
var float (float a, float b, float c, float d, float e, float f, float g, float h) min8;
var float (float a, float b) max;
var float (float a, float b, float c) max3;
var float (float a, float b, float c, float d) max4;
var float (float a, float b, float c, float d, float e) max5;
var float (float a, float b, float c, float d, float e, float f) max6;
var float (float a, float b, float c, float d, float e, float f, float g) max7;
var float (float a, float b, float c, float d, float e, float f, float g, float h) max8;
var float (float minimum, float val, float maximum) bound;
var vector() randomvec;

float(float val) ext_sin = #60;
float(float val) ext_cos = #61;
float(float val) ext_sqrt = #62;
vector() ext_randomvec = #91;
float(float a, float b) ext_min = #94;
float(float a, float b, float c) ext_min3 = #94;
float(float a, float b, float c, float d) ext_min4 = #94;
float(float a, float b, float c, float d, float e) ext_min5 = #94;
float(float a, float b, float c, float d, float e, float f) ext_min6 = #94;
float(float a, float b, float c, float d, float e, float f, float g) ext_min7 = #94;
float(float a, float b, float c, float d, float e, float f, float g, float h) ext_min8 = #94;
float(float a, float b) ext_max = #95;
float(float a, float b, float c) ext_max3 = #95;
float(float a, float b, float c, float d) ext_max4 = #95;
float(float a, float b, float c, float d, float e) ext_max5 = #95;
float(float a, float b, float c, float d, float e, float f) ext_max6 = #95;
float(float a, float b, float c, float d, float e, float f, float g) ext_max7 = #95;
float(float a, float b, float c, float d, float e, float f, float g, float h) ext_max8 = #95;
float(float minimum, float val, float maximum) ext_bound = #96;
float(float a, float b) ext_pow = #97;
float(float number, float quantity) ext_bitshift = #218;

// This is common, may need to comment out if already defined.
//float(string s) checkextension = #99;


// The engine sin/cos builtins use radians rather than degrees. This is less useful, so convert
float(float val) wrap_sin = { return ext_sin(val*PiOverOneEighty); };
float(float val) wrap_cos = { return ext_cos(val*PiOverOneEighty); };

// this must be called in worldspawn before using any above functions
void () MathlibCheckBuiltins =
{
	local float checkext;

	sqrt = mathlib_sqrt;
	cos = mathlib_cos;
	sin = mathlib_sin;
	pow = mathlib_pow;
	randomvec = mathlib_randomvec;
	min = mathlib_min;
	min3 = mathlib_min3;
	min4 = mathlib_min4;
	min5 = mathlib_min5;
	min6 = mathlib_min6;
	min7 = mathlib_min7;
	min8 = mathlib_min8;
	max = mathlib_max;
	max3 = mathlib_max3;
	max4 = mathlib_max4;
	max5 = mathlib_max5;
	max6 = mathlib_max6;
	max7 = mathlib_max7;
	max8 = mathlib_max8;
	bound = mathlib_bound;
	bitshift = mathlib_bitshift;
	checkext = cvar("pr_checkextension");
	if (checkext)
	{
		if (checkextension("DP_QC_SINCOSSQRTPOW"))
		{
			sqrt = ext_sqrt;
			cos = wrap_cos; 
			sin = wrap_sin;
			pow = ext_pow;
		}

		if (checkextension("DP_QC_RANDOMVEC"))
			randomvec = ext_randomvec;
		if (checkextension("DP_QC_MINMAXBOUND"))
		{
			min = ext_min;
			min3 = ext_min3;
			min4 = ext_min4;
			min5 = ext_min5;
			min6 = ext_min6;
			min7 = ext_min7;
			min8 = ext_min8;
			max = ext_max;
			max3 = ext_max3;
			max4 = ext_max4;
			max5 = ext_max5;
			max6 = ext_max6;
			max7 = ext_max7;
			max8 = ext_max8;
			bound = ext_bound;
		}
		if (checkextension("EXT_BITSHIFT"))
			bitshift = ext_bitshift;
	}
};

vector(vector v) anglemod_view =
{
	while (v_x > 180)
		v_x = v_x - 360;
	while (v_y > 180)
		v_y = v_y - 360;
	while (v_z > 180)
		v_z = v_z - 360;

	while (v_x < -180)
		v_x = v_x + 360;
	while (v_y < -180)
		v_y = v_y + 360;
	while (v_z < -180)
		v_z = v_z + 360;

	return v;
};

float(float v) anglemod_ground =
{
	float n;

	while (v >= 180)
	{
		v = v - 180;	//0..180
		n++;
	}
	while (v < 0)
	{
		v = v + 180;	//-180..0
		n++;
	}

	if (v >= 0)
		v = 180*(n + rint(v/180));
	else
		v = -180*(n - rint(v/180));
		
	return v;
};
vector(vector vec) vreverse = 
{
	return vec * -1;
	
};




vector  (vector m1, vector m2) Rvec =
{
    local vector v;

   
    
    m2 = m2 - m1;
    v_x = m2_x * random() + m1_x;
    v_y = m2_y * random() + m1_y;
    v_z = m2_z * random() + m1_z;
    
    /*
    else
    {	     
    v_x = SUB_RandomRange (m1_x, m2_x);
    v_y = SUB_RandomRange (m1_y, m2_y);
    v_z = SUB_RandomRange (m1_z, m2_z);
    }*/

    return v;
};

float(float f, float MAX) f_bound =
{
    if (MAX > 16777215) MAX = 16777215;

    if (f > MAX)
        f = MAX;
    else if (f < 0)
        f = 0;
    f = floor(f);
    return f;
};

float(float s1, float s2, float s3) encode =
{
    local float f;
    f = f_bound(s1, 255) * 65536 + f_bound(s2, 255) * 256 + f_bound(s3, 255);
    return f;
};

float(float s1, float bits, float pos) g_encode =
{
    local float f;
    f = f_bound(s1, bits) * pos;
    return f;
};

float(float parmval, float which) decode =
{
    local float f;

    if (which == 1)
        f = (parmval / 65536) & 255;
    else if (which == 2)
        f = (parmval / 256) & 255;
    else
        f = parmval & 255;
    return f;
};


float(float parmval, float bits, float pos) g_decode =
{
    local float f;

    f = (parmval / pos) & bits;
    return f;
};


void(entity ent) changeroll =
{
	local vector ang;
	local float current, ideal, move, rspeed;
//bprint ("Rolling\n");
// mod down the current angle

          if (ent.flags& FL_CLIENT) // Real client
	ang = anglemod_view(ent.v_angle);
          else // Bot
	ang = anglemod_view(ent.angles);
	current = ang_z;
	ideal = ent.idealroll;
	rspeed = 2; // >> ent.roll_speed;
   
	if (current == ideal)
		return;
	
	move = ideal - current;

//print("ideal=");
//	print(ftos(ideal));
//	print("\n");

//	print(" current=");
//	print(ftos(current));
//	print("\n");
	
//	print(" move=");
//	print(ftos(move));
//	print("\n");

/*	if (ideal > current)
	{
		if (move > 180)
			move = move - 360;
	}
	else
	{
		if (move < -180)
			move = move + 360;
	}*/

	ang_z = move;
	ang = anglemod_view(ang);
	move = ang_z;
		
	if (move > 0)
	{
		if (move > rspeed)
			move = rspeed;
	}
	else
	{
		if (move < (0 - rspeed))
			move = 0 - rspeed;
	}

//	print(" move2=");
//	print(ftos(move));
//	print("\n");

	current = current + move;

//	print(" current2=");
//	print(ftos(move));
//	print("\n");

//	ent.angles_z = ideal;
	ent.angles_z = current;
};

vector () GetRandomVector =
{
	local vector vec;
	local float r;

	r = random ();
	if ((r < 0.5))
	{
		if ((r < 0.25))
		{
			if ((r < 0.05))
			{
				vec = VEC_ORIGIN;
			}
			else
			{
				if ((r < 0.1))
				{
					vec = '0 0 12';
				}
				else
				{
					if ((r < 0.15))
					{
						vec = '0 12 0';
					}
					else
					{
						if ((r < 0.2))
						{
							vec = '12 0 0';
						}
						else
						{
							vec = '12 12 0';
						}
					}
				}
			}
		}
		else
		{
			if ((r < 0.3))
			{
				vec = '12 0 12';
			}
			else
			{
				if ((r < 0.35))
				{
					vec = '0 12 12';
				}
				else
				{
					if ((r < 0.4))
					{
						vec = '0 12 12';
					}
					else
					{
						if ((r < 0.45))
						{
							vec = '-12 12 0';
						}
						else
						{
							vec = '-12 12 16';
						}
					}
				}
			}
		}
	}
	else
	{
		if ((r < 0.75))
		{
			if ((r < 0.55))
			{
				vec = '0 0 16';
			}
			else
			{
				if ((r < 0.6))
				{
					vec = '12 12 -16';
				}
				else
				{
					if ((r < 0.65))
					{
						vec = '12 12 0';
					}
					else
					{
						if ((r < 0.7))
						{
							vec = '12 0 12';
						}
						else
						{
							vec = '12 0 12';
						}
					}
				}
			}
		}
		else
		{
			if ((r < 0.8))
			{
				vec = '0 0 12';
			}
			else
			{
				if ((r < 0.85))
				{
					vec = '0 0 -12';
				}
				else
				{
					if ((r < 0.9))
					{
						vec = '0 -12 0';
					}
					else
					{
						if ((r < 0.95))
						{
							vec = '-12 0 0';
						}
						else
						{
							vec = '0 0 -16';
						}
					}
				}
			}
		}
	}
	return (vec);
};

//==========================================================================
//  check.qc -- by Patrick Martin               Last updated:  9-8-1997
//--------------------------------------------------------------------------
//  This file contains code that determines whether an entity or a
//  location is inside the various contents found in Quake.
//==========================================================================

//-------------------------------------------------------- New Code --------
//  This checks for obstacles such as solid entities or walls inside
//  the bbox and along its borders.  If an obstacle is met, FALSE is
//  returned.
//--------------------------------------------------------------------------
float(entity head, vector spot) PM_TraceCheck =
{
        local   vector  p1, p2;

// Check for obstacles inside the bbox.
// Order:  1)--- to +++    2)+-- to -++    3)++- to --+    4)-+- to +-+
        p1 = spot + self.mins;
        p2 = spot + self.maxs;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_x = spot_x + self.maxs_x;
        p2_x = spot_x + self.mins_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_y = spot_y + self.maxs_y;
        p2_y = spot_y + self.mins_y;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_x = spot_x + self.mins_x;
        p2_x = spot_x + self.maxs_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

// Check for obstacles along the bbox boundaries.
// Order:  1)+++ to ++-    2)+-+ to +--    3)--+ to ---    4)-++ to -+-
//         5)--- to +--    6)+-- to ++-    7)++- to -+-    8)-+- to ---
//         9)+++ to -++   10)-++ to --+   11)--+ to -+-   12)-+- to +++
        p1 = p2 = spot + self.maxs;
        p2_z = spot_z + self.mins_z;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_x = p2_x = spot_x + self.mins_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_y = p2_y = spot_y + self.mins_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1_x = p2_x = spot_x + self.maxs_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2 = spot + self.mins;
        p2_x = spot_x + self.maxs_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_y = spot_y + self.maxs_y;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_x = spot_x + self.mins_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_y = spot_y + self.mins_y;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2 = spot + self.maxs;
        p2_x = spot_x + self.mins_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_y = spot_y + self.mins_y;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_x = spot_x + self.maxs_x;
        traceline (p1, p2, FALSE, head);
        if (trace_fraction < 1)  return FALSE;

        p1 = p2;
        p2_y = spot_y + self.maxs_y;
        traceline (p1, p2, FALSE, head);
        return (trace_fraction == 1);
};

//-------------------------------------------------------- New Code --------
//  This checks if a bbox is inside a wall or sky.  The bbox's origin
//  and corners are checked.  If any one points is within a solid or sky,
//  TRUE is returned.
//--------------------------------------------------------------------------
float(entity head, vector spot) PM_InWall =
{
        local   vector  p;

// Check origin.
        p = spot;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

// Check bbox faces.
// Order:  1)-00  2)+00  3)0-0  4)0+0  5)00-  6)00+
        p_x = spot_x + head.mins_x; // back
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

        p_x = spot_x + head.maxs_x; // front
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

        p = spot;
        p_y = spot_y + head.mins_y; // left
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

        p_y = spot_y + head.maxs_y; // right
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

        p = spot;
        p_z = spot_z + head.mins_z; // bottom
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

        p_z = spot_z + head.maxs_z; // top
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

// Check bbox corners.


//       1)+++  Upper max corner
        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.maxs_y;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 // 2)-++ 
        p_x = spot_x + head.mins_x;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 // 3)+-+
        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.mins_y;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 
	 // 4)--+ 
        p_x = spot_x + head.mins_x;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 
	 // 5)++- 
        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.maxs_y;
        p_z = spot_z + head.mins_z;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 // 6)-+-
        p_x = spot_x + head.mins_x;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 // 7)+--
        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.mins_y;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        if (pointcontents(p) == CONTENT_SKY)    return TRUE;

	 // 8)---  Lower min corner
        p_x = spot_x + head.mins_x;
        if (pointcontents(p) == CONTENT_SOLID)  return TRUE;
        return (pointcontents(p) == CONTENT_SKY);
};

//-------------------------------------------------------- New Code --------
//  This is a variation of InWall.  The bbox is checked if it is a
//  empty air; that is not inside solid, water, or anything else.
//  If any one point is within a brush, FALSE is returned.
//--------------------------------------------------------------------------
float(entity head, vector spot) PM_InEmpty =
{
        local   vector  p;

// Check origin.
        p = spot;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

// Check bbox faces.
// Order:  1)-00  2)+00  3)0-0  4)0+0  5)00-  6)00+
        p_x = spot_x + head.mins_x;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.maxs_x;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p = spot;
        p_y = spot_y + head.mins_y;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_y = spot_y + head.maxs_y;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p = spot;
        p_z = spot_z + head.mins_z;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_z = spot_z + head.maxs_z;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

// Check bbox corners.
// Order:  1)+++  2)-++  3)+-+  4)--+  5)++-  6)-+-  7)+--  8)---
        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.maxs_y;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.mins_x;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.mins_y;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.mins_x;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.maxs_y;
        p_z = spot_z + head.mins_z;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.mins_x;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.maxs_x;
        p_y = spot_y + head.mins_y;
        if (pointcontents(p) != CONTENT_EMPTY)  return FALSE;

        p_x = spot_x + head.mins_x;
        return (pointcontents(p) == CONTENT_EMPTY);
};

//-------------------------------------------------------- New Code --------
//  This checks if the entity is in a body of liquid.
//--------------------------------------------------------------------------
float(entity head) PM_InLiquid =
{
local float score;
local vector here;
here = head.origin;
   if (head.flags & FL_CLIENT) // Cobalt added for players and bots
{	

	 here_z = here_z - 20; // right at players feet
if (pointcontents (head.absmax - '0 0 56') == CONTENT_WATER) score = score + 1;
if (pointcontents (head.absmax - '0 0 56') == CONTENT_SLIME) score = score + 1;
if (pointcontents (head.absmax - '0 0 56') == CONTENT_LAVA) score = score + 1;

if (pointcontents (head.absmax - '0 32 56') == CONTENT_WATER) score = score + 1;
if (pointcontents (head.absmax - '0 32 56') == CONTENT_SLIME) score = score + 1;
if (pointcontents (head.absmax - '0 32 56') == CONTENT_LAVA) score = score + 1;

if (pointcontents (head.absmin - '0 -32 0') == CONTENT_WATER) score = score + 1;
if (pointcontents (head.absmin - '0 -32 0') == CONTENT_SLIME) score = score + 1;
if (pointcontents (head.absmin - '0 -32 0') == CONTENT_LAVA) score = score + 1;
}

     
        if (pointcontents(here) == CONTENT_WATER)  score = score + 1;
        if (pointcontents(here) == CONTENT_SLIME)  score = score + 1;
        if (pointcontents(here) == CONTENT_LAVA)   score = score + 1;
	 
	  if (pointcontents(head.absmin) == CONTENT_WATER)  score = score + 1;
        if (pointcontents(head.absmin) == CONTENT_SLIME)  score = score + 1;
        if (pointcontents(head.absmin) == CONTENT_LAVA)   score = score + 1;
	 
	  if (pointcontents(head.absmax) == CONTENT_WATER)  score = score + 1;
        if (pointcontents(head.absmax) == CONTENT_SLIME)  score = score + 1;
        if (pointcontents(head.absmax) == CONTENT_LAVA)   score = score + 1;

	 if (score)
	 {
	 local string val;
	 val = strcat ("^5PM_InLiquid  () SCORE: ", (ftos(score)));
	 val = strcat (val, "^7");
	//LogMsg2 (head, val);
	return 1;
	}
        return FALSE;    // Entity is not in liquid.
};


/*
float(entity head) Blocked =
{
if (head.stairstime > time || head.health < 1 || head.waterlevel > 0) return 0;
local float score;
local vector here;
here = head.origin - '0 0 10';

if (!head.button8 && vlen(head.velocity) >= 28) return 0;



   if (head.flags & FL_CLIENT) 
{	



if (pointcontents (here + '18 0 0') == CONTENT_SOLID) 
score = score + 1; // Front at knee level



if (pointcontents (here + '-18 0 0') == CONTENT_SOLID) score = score + 1; // back at knee level

if (pointcontents (here + '18 18 0') == CONTENT_SOLID) 
score = score + 1; // Front side at knee level
if (pointcontents (here + '18 -18 0') == CONTENT_SOLID) 
score = score + 1; // Front side knee level

if (pointcontents (here + '-18 18 0') == CONTENT_SOLID) 
score = score + 1; // back side at knee level
if (pointcontents (here + '-18 -18 0') == CONTENT_SOLID) 
score = score + 1; // back side at knee level

if (pointcontents (here + '0 18 0') == CONTENT_SOLID) 	
score = score + 1; // side at knee level
if (pointcontents (here + '0 -18 0') == CONTENT_SOLID) 
score = score + 1; // side at knee level


}

     
     
	 if (score)
	 {
	 if (head.button8 && vlen(head.velocity) > 44.5)
		  return 0;


		 
		  
	 local string val;
	 val = strcat ("^5Blocked  () SCORE: ", (ftos(score)));
	 val = strcat (val, "^7");
	LogMsg2 (head, val);
		return 1;
	}
        return FALSE;    // Entity is not in blocked.
};

*/
//--------------------------------------------------------------------------
//  END OF LINE.
//--------------------------------------------------------------------------







