# Email

Send mail from FiveM straight to a player's Discord DMs. Pure Lua, no Node or yarn needed.

## Features
* **Mail list**: mail can only be sent to people saved in your own mail list
* Add contacts by **Discord ID**, **Citizen ID**, or an **online player's server ID**. For Citizen ID and player ID, their Discord ID is looked up and saved with the contact right away
* Citizen ID contacts still get mail when offline (their last linked Discord is remembered)
* **Sent tab**: every mail is saved with a Delivered or Failed badge and the reason
* **Clear errors**: players are told when DMs are off, the ID is wrong, or the player has no Discord linked, plus a tip on how to fix it
* **Logs**: server console, optional Discord webhook, and a database history
* Works with qbx_core, qb-core, ESX or standalone (auto detected)

## Dependencies
* [ox_lib](https://github.com/overextended/ox_lib)
* [oxmysql](https://github.com/overextended/oxmysql)

## Installation
1. Create a bot at https://discord.com/developers/applications and copy its token.
2. Invite the bot to your Discord server. Players must be in that server to get DMs.
3. Add to `server.cfg` (keep the token secret):
   ```
   set cad_email_token "YOUR_BOT_TOKEN"
   set cad_email_webhook "https://discord.com/api/webhooks/..."   # optional, for staff logs
   ensure cad-email
   ```
4. Start the server. Tables are created on their own (or run `install.sql`).
5. In game, type `/email`.

## Settings
* `config/client.lua`: chat command
* `config/server.lua`: token, webhook, server name, framework, email domain, cooldown, limits, history cleanup

## Why a mail can fail
| Code | Meaning |
|------|---------|
| `dms_off` | The person has DMs off, blocked the bot, or is not in the Discord server |
| `unknown_user` | No Discord account with that ID |
| `invalid_id` | The ID is not a valid Discord ID |
| `no_discord` | The person has no Discord linked to FiveM (or none on record yet) |
| `not_in_list` | The recipient is not in the sender's mail list |
| `invalid_citizenid` | No citizen found with that Citizen ID |
| `bad_token` / `no_token` | The bot token is wrong or missing (check the server console) |
| `discord_down` / `no_connection` | Discord could not be reached |

Type `emailfailures 20` in the server console to see the latest failed mails.

## Opening from other resources
```lua
exports['cad-email']:open()
```

## Support
Discord: https://discord.gg/qxGPARNwNP
