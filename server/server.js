// -- / Before running this code, invite your bot to server and add your token below
// -- / https://discordapp.com/oauth2/authorize?client_id=your_client_id&scope=bot&permissions=8

// -- / Dependency and config \ -- \\
const { Client, Intents } = require('discord.js');
const mailbot = new Client({ intents: [Intents.FLAGS.GUILDS] });
global.config = require("./config.json")

// -- / On Bot ready Do \ -- \\
mailbot.on('ready', () => {        
    console.log("\nMailBot (FiveM to Discord DM). Made By Cadburry#7547.\n");         
    console.log(`Discord Bot logged in as ${mailbot.user.tag}`);    
    mailbot.user.setStatus('dnd');     
    updateStatus(mailbot, 10) // updating every 10 secs        
});

// -- / Functions \ -- \\
function updateStatus(client, seconds) { // Adds Bot Activity
   setInterval(function() {        
        let status = `${GetNumPlayerIndices()} Players`            
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
    let ts = Date.now();
    let date_ob = new Date(ts);     
    let DateTime = `${IntTwoChars(date_ob.getHours())}:${IntTwoChars(date_ob.getMinutes())}:${IntTwoChars(date_ob.getSeconds())} ${date_ob.getDate()}/${date_ob.getMonth() + 1}/${date_ob.getFullYear()}`;    
	mailbot.users.fetch(discord).then((user) => user.send('> **From:** '+email+' \n> \n> **Subject:** '+subject+' \n> **Body:** '+body+' \n> \n> **Sign:** '+name+' \n> \n> **Recieved on:** '+DateTime));    
});       

onNet("cademailSendMailinfo", async (data) => {        
    let src = source
    let Player = QBCore.Functions.GetPlayer(src)
    let name = Player.PlayerData.charinfo.firstname+" "+Player.PlayerData.charinfo.lastname
    let email = Player.PlayerData.charinfo.firstname+"_"+Player.PlayerData.charinfo.lastname+"@email.com"
    let discord = data['primary'][0]
    let subject = data['primary'][1]
    let description = data['primary'][2]
    emitNet("cademailMailSent", src, name, discord, subject, description, email)
});       

// -- / COMMANDS \ -- \\
QBCore.Commands.Add('email', 'Send Email to Someone', {}, false, (source, args)  => {
    emitNet('cademailOpenNUI', source)
})

// -- / Made By Cadburry#7547 \ -- \\
