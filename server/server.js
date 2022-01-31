// -- / Before running this code, invite your bot to server and add your token below
// -- / https://discordapp.com/oauth2/authorize?client_id=your_client_id&scope=bot&permissions=8

// -- / Dependency and config \ -- \\
const { Client, Intents } = require('discord.js');
const mailbot = new Client({ intents: [Intents.FLAGS.GUILDS] });
const config = require("./config.json")

// -- / On Bot ready Do \ -- \\
mailbot.on("ready", () => { // prints "Ready!" to the console once the bot is online
    console.log("\nMailBot (FiveM to Discord DM). Made By Cadburry#7547.\n");         
    console.log(`Discord Bot logged in as ${mailbot.user.tag}`);    
    mailbot.user.setStatus('dnd');     
    updateStatus(mailbot, 30) // updating every 30 secs   
});

// -- / Functions \ -- \\
function updateStatus(client, seconds) { // Adds Bot Activity
   setInterval(function() {        
        const status = `${GetNumPlayerIndices()} Players`            
        client.user.setActivity(status, {type: 'WATCHING'})
    }, seconds * 1000)    
}

function IntTwoChars(i) {
    return (`0${i}`).slice(-2);
}

// -- / Logging into your bot \ -- \\ 
mailbot.login(config.token);  // Add Your Token Here


// -- / Event which send request to bot \ -- \\
onNet("cademailSendMailServer", async (name, discord, subject, body, email) => {    
    const src = source    
    const date = new Date();    
    mailbot.users.fetch(discord).then((user) => 
        user.send('> **From:** '+email+' \n> \n> **Subject:** '+subject+' \n> **Body:** '+body+' \n> \n> **Sign:** '+name+' \n> \n> '+date).catch(err => {
            const error = emitNet("cademailSendNotify", src, "Cannot send message (DM's Off)")
            return error
        })
    );    
});   

if (config.core == "qbcore") {
    // -- / QBCore Core \ -- \\
    var QBCore = global.exports['qb-core'].GetCoreObject();        

    onNet("cademailSendMailinfo", async (data, bool) => {        
        const src = source            
        const { firstname, lastname } = QBCore.Functions.GetPlayer(src).PlayerData.charinfo;            
        if (bool) {        
            const discord = QBCore.Functions.GetIdentifier(data['primary'][3], 'discord');          
            if (discord) {
                emitNet("cademailMailSent", src, `${firstname} ${lastname}`, discord.replace("discord:", ""), data['primary'][1], data['primary'][2], `${firstname}_${lastname}@email.com`);                                              
            } else {
                emitNet("cademailSendNotify", src, "The person has not linked discord with fivem")
            }
        } else {                
            emitNet("cademailMailSent", src, `${firstname} ${lastname}`, data['primary'][0], data['primary'][1], data['primary'][2], `${firstname}_${lastname}@email.com`);
        }
    });     

    // -- / COMMANDS \ -- \\
    QBCore.Commands.Add('email', 'Send Email to Someone', {}, false, (source, args)  => {
        emitNet('cademailOpenNUI', source)
    })
} else if (config.core == "esx")  {
    let ESX = null
    emit('esx:getSharedObject', (obj) => (ESX = obj));
      
    const GetDiscord = (id) => {
        const values = {};
        for (let i = 0; i < GetNumPlayerIdentifiers(id); i++) {
            const identifier = GetPlayerIdentifier(id, i).split(":");
            values[identifier[0]] = identifier[1];
        }
        return values["discord"] || false;
    };
    
    onNet("cademailSendMailinfo", async (data, bool) => {        
        const src = source                   
        const xPlayer = ESX.GetPlayerFromId(src)
        const name = xPlayer.getName()                      
        if (bool) {        
            const discord = GetDiscord(data['primary'][3]);   
            if (discord) {                
                emitNet("cademailMailSent", src, name, discord, data['primary'][1], data['primary'][2], name+`@email.com`);                                              
            } else {
                emitNet("cademailSendNotify", src, "The person has not linked discord with fivem")
            }            
        } else {                
            emitNet("cademailMailSent", src, name, data['primary'][0], data['primary'][1], data['primary'][2], name+`@email.com`);
        }
    });     

    // -- / COMMANDS \ -- \\
    RegisterCommand('email', (source, args) => {
        emitNet('cademailOpenNUI', source)
    }, false)
    
}

// -- / Made By Cadburry#7547 \ -- \\
