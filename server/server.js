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

// -- / QBCore Part \ -- \\
var QBCore = global.exports['qb-core'].GetCoreObject();


// -- / Event which send request to bot \ -- \\
onNet("cademailSendMailServer", async (name, discord, subject, body, email) => {        
    const date = new Date();    
	mailbot.users.fetch(discord).then((user) => 
        user.send('> **From:** '+email+' \n> \n> **Subject:** '+subject+' \n> **Body:** '+body+' \n> \n> **Sign:** '+name+' \n> \n> '+date).catch(err => {
            const error = emitNet("cademailSendNotify", src, "Cannot send message (DM's Off)")
            return error
        })
    );    
});       

onNet("cademailSendMailinfo", async (data, bool) => {        
    const src = source            
    const { firstname, lastname } = QBCore.Functions.GetPlayer(src).PlayerData.charinfo;            
    if (bool) {        
        const discord = QBCore.Functions.GetIdentifier(data['primary'][3], 'discord');          
        emitNet("cademailMailSent", src, `${firstname} ${lastname}`, discord.replace("discord:", ""), data['primary'][1], data['primary'][2], `${firstname}_${lastname}@email.com`);                                              
    } else {                
        emitNet("cademailMailSent", src, `${firstname} ${lastname}`, data['primary'][0], data['primary'][1], data['primary'][2], `${firstname}_${lastname}@email.com`);
    }
});     

// -- / COMMANDS \ -- \\
QBCore.Commands.Add('email', 'Send Email to Someone', {}, false, (source, args)  => {
    emitNet('cademailOpenNUI', source)
})

// -- / Made By Cadburry#7547 \ -- \\
