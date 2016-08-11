# Creepcam2
Creepcam Version II for Darkplaces

Basicly a modified version of Creepcam Version 1, except includes Darkplaces QC extensions file to make full use of Darkplaces optimizations
if the modder chooses to.

This mod is coop designed only and includes "Ogres fire grenades into cover" mod along with improved Demon jumping attacks when skill is set > 1.
Ogres chainsaws can now gib zombies, and the player can be gibbed by a monster attack which does alot of damage.

Death messages are more detailed describing the kind of attack the monster did that killed the player.

The players axe does more damage on attacks from behind, and certain kinds of attacks that occur such as the double handed overhead
swing do alot of damage, than other types od swings.

The Creepcam chasecam now has a respawn timer where it will find 
another player so they can be chased while another player respawns. If no players are available, monsters are cammed, or if killed by a monster,
that monster is camerad till respawn

Also added ident code for looking at a player to see their netname, Oxygen/ Biosuit level meter for player and cameras chasing them,
QIP's Armor drowning fix, QIP's Ax walkframe bugfix, better waterjump and Megahealth rot fix and better explobox explosions.

An o2 meter has been included to show the players current remaining oxygen...also indicates Biosuit remaining o2. 
Players who are being camerad by Creepcam also see the 02 meter.


The base src of this mod is Gnouc's clean QC src which has "killstring" fixes for the obit messages that display wrong ones if the player
changes weapons quickly.

Future plans include scoring frags based on types of monsters killed, and partial frags for when players team up to kill a monster.
