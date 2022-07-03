# customizable_hitmarkers
Hitmarkers for Garry's Mod

## Server Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| custom_hitmarkers_ratelimit_enabled | Enables ratelimiting on hitmarkers to prevent net message spam. | 1 |
| custom_hitmarkers_ratelimit_track_duration | The window of time (in seconds) for hit counts to be tracked per player before getting reset to 0. | 0.5 |
| custom_hitmarkers_ratelimit_threshold | How many hit events a player must trigger in short succesion to become ratelimited. | 50 |
| custom_hitmarkers_ratelimit_cooldown | How long (in seconds) hit events for a player will be ignored after breaching the ratelimit threshold. | 2 |
| custom_hitmarkers_npc_allowed | Allows players to opt in to NPC hitmarkers. | 1 |
| custom_hitmarkers_ent_allowed | Allows players to opt in to entity hitmarkers. | 1 |
| custom_hitmarkers_hit_duration_default | 3 | How long burst hit numbers will linger for. 0 to disable. Default value used for players. |
| custom_hitmarkers_mini_duration_default | 2.5 | How long mini hit numbers will linger for. 0 to disable. Default value used for players. |

## Client Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| custom_hitmarkers_enabled | Enables hitmarkers. | 1 |
| custom_hitmarkers_npc_enabled | Enables hitmarkers for NPCs. | 0 |
| custom_hitmarkers_ent_enabled | Enables hitmarkers for other entities. | 0 |
| custom_hitmarkers_sound_enabled | Enables hitmarker sounds. | 1 |
| custom_hitmarkers_round_enabled | Rounds damage numbers. | 1 |
| custom_hitmarkers_hit_duration | How long large hit numbers will linger for. 0 to disable. -1 to use server default. | -1 |
| custom_hitmarkers_mini_duration | How long mini hit numbers will linger for. 0 to disable. -1 to use server default. | -1 |
| custom_hitmarkers_hit_sound | Sound used for regular hits. | buttons/lightswitch2.wav |
| custom_hitmarkers_headshot_sound | Sound used for headshots. | buttons/button16.wav |
| custom_hitmarkers_kill_sound | Sound used for kills. | buttons/combine_button1.wav |
| custom_hitmarkers_hit_sound_volume | Volume for hit sounds. | 1.5 |
| custom_hitmarkers_headshot_sound_volume | Volume for headshot sounds. | 1 |
| custom_hitmarkers_kill_sound_volume | Volume for kill sounds. | 1.5 |
| custom_hitmarkers_hit_color | Color for hit numbers. | 255 0 0 |
| custom_hitmarkers_mini_hit_color | Color for mini hit numbers. | 255 100 0 |
| custom_hitmarkers_hit_size | The font size for hit numbers. | 30 |
| custom_hitmarkers_mini_size | The font size for mini hit numbers. | 30 |
| custom_hitmarkers_dps_enabled | Enables a DPS tracker. | 0 |
| custom_hitmarkers_dps_pos_x | The horizontal position for the DPS tracker. | 0.0208 |
| custom_hitmarkers_dps_pos_y | The vertical position for the DPS tracker. | 0.861 |
| custom_hitmarkers_hit_sound_pitch_min | Minimum pitch for hit sounds. 100 is 'normal' pitch. | 90 |
| custom_hitmarkers_hit_sound_pitch_max | Maximum pitch for hit sounds. 100 is 'normal' pitch. | 110 |
| custom_hitmarkers_headshot_sound_pitch_min | Minimum pitch for headshot sounds. 100 is 'normal' pitch. | 90 |
| custom_hitmarkers_headshot_sound_pitch_max | Maximum pitch for headshot sounds. 100 is 'normal' pitch. | 110 |
| custom_hitmarkers_kill_sound_pitch_min | Minimum pitch for kill sounds. 100 is 'normal' pitch. | 100 |
| custom_hitmarkers_kill_sound_pitch_max | Maximum pitch for kill sounds. 100 is 'normal' pitch. | 100 |
| custom_hitmarkers_block_zeros | Don't display hits with a damage value of 0. | 1 |
| custom_hitmarkers_combine_multi_shots | Combine multi-shot hits (e.g. a shotgun blast) into one damage number. | 0 |