# cad-email
Email to peoples Discord DM directly from FiveM [ESX & QBCore]

# Preview
Demo Video: [Click Here](https://youtu.be/x6OisU5M22A)

![image](https://user-images.githubusercontent.com/72443203/149477441-45e94f16-ce23-4f99-8967-3927a3911bad.png)

# Dependencies
* yarn
* git
* qb-core or es_extended
* node.js

# Installation
* Step 1: Create a Discord Bot, Add it to your server.
* Step 2: Add your bot token in `config.json` & Add your `core` info [Use `qbcore` or `esx`]
* Step 3: Drag and drop `cad-email` to your resources and add it to `server.cfg`
* Step 4: Finish! Now use `/email` command and try it.

# Support
* Discord: https://discord.gg/9tyjPkA6nd


# Updates v1.1
* Fixed Closing with `ESC` not removing cursor
* Removed Lua part and compiled all in javascript [Thanks to Mojito for `qbcore.js`]

# Updates v1.1.1
* Added Notify [if User DM's are off]
* Code Cleanup

# Updates v1.1.2
* Added Option to send mail by entering player id (mail will only go if the target has discord linked with fivem)
* Fixed bugs
* Added Close Button

# Updates v1.1.3
* Added Support for ESX
* Changed Notification to native
* Added `esx.js` package for running esx functions

# Updates v1.1.4
* Removed Status Update
* Post request changes
* Close btn fix
