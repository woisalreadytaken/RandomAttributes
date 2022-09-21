# Random Attributes

Scuffed pseudo-gamemode that gives random attributes to weapons, made in a way that's compatible with vanilla and custom gamemodes.

Currently deemed incomplete. It works fine, but is a bit rough internally.

## Dependencies
- SourceMod 1.10+
- [nosoop's TF2Attributes fork](https://github.com/nosoop/tf2attributes)
- [TF2 Econ Data](https://forums.alliedmods.net/showthread.php?t=315011)

## Commands
|Command|Description|
|-|-|
|`sm_ra_refreshattributes`|Refreshes the attributes config|
|`sm_ra_refreshsettings`|Refreshes the settings config|
|`sm_ra_refresh`|Refreshes both configs|

## ConVars
|ConVar|Default Value<br>(is locked by settings config by default?)|Description|
|-|:-:|-|
|`sm_ra_enabled`|1|Is 'Random Attributes' enabled?|
|`sm_ra_amount`|20<br>(locked)|Amount of random attributes to roll per weapon|
|`sm_ra_amountupdate`|0|Should attributes be rerolled the moment sm_ra_amount is changed?|
|`sm_ra_onlyallowteam`|""|Only allows the specified team to make use of this plugin's functionality. Accepts 'red' and 'blu(e)', anything else means we'll assume you're fine with both teams|
|`sm_ra_rerolldeath`|1<br>(locked)|Should attributes be rerolled when a player dies?<br>- 0: No, only roll once per round<br>- 1: Yes, excluding suicides<br>- 2: Always|
|`sm_ra_rerollslot`|0<br>(locked)|Should attributes be rerolled when a weapon in a slot is changed?<br>Optional setting meant for gamemodes that give you weapons mid-round and you don't want players to be stuck with the same attributes<br>Note: if `sm_ra_rerolldeath` is set to 0, this setting will still work if players choose to switch weapons (or are forced to, such as in the Randomizer gamemode)!|
|`sm_ra_activeonly`|0|Forces the 'provide on active' attribute onto weapons, making (or at least trying its best to make) passive effects only work when a weapon with them is active|

## Thanks To
* [42](https://github.com/FortyTwoFortyTwo): providing code related to displaying localized strings and letting me borrow him and the Red Sun dev server for occasional private testing.
* [Mikusch](https://github.com/Mikusch) & [Red Sun Over Paradise](https://redsun.tf): helping me out with public playtesting.