# customizable_hitmarkers
Hitmarkers for Garry's Mod

## Server Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| custom_hitmarkers_ratelimit_enabled | Enables ratelimiting on hitmarkers to prevent net message spam. | 1 |
| custom_hitmarkers_ratelimit_track_duration | The window of time (in seconds) for hit counts to be tracked per player before getting reset to 0. | 0.5 |
| custom_hitmarkers_ratelimit_threshold | How many hit events a player must trigger in short succesion to become ratelimited. | 50 |
| custom_hitmarkers_ratelimit_cooldown | How long (in seconds) hit events for a player will be ignored after breaching the ratelimit threshold. | 2 |

## Client Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| custom_hitmarkers_enabled | Enables hitmarkers. | 1 |
| custom_hitmarkers_npc_enabled | Enables hitmarkers for NPCs. | 0 |
| custom_hitmarkers_ent_enabled | Enables hitmarkers for other entities. | 0 |
| custom_hitmarkers_sound_enabled | Enables hitmarker sounds. | 1 |
| custom_hitmarkers_hit_duration | How long large hit numbers will linger for. 0 to disable. | 3 |
| custom_hitmarkers_mini_duration | How long mini hit numbers will linger for. 0 to disable. | 2.5 |
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
