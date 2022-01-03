var QBCore = global.exports['qb-core'].GetCoreObject();

const RegisterNuiCallback = (name, cb) => {
  RegisterNuiCallbackType(name)
  on(`__cfx_nui:${name}`, cb)
}

// -- / NUI \ -- \\
RegisterNuiCallback('sendmail', (data) => { 
  emitNet("cademailSendMailServer", data['secondary'][0], data['secondary'][1], data['secondary'][2], data['secondary'][3], data['secondary'][4])
})

RegisterNuiCallback('SendInfo', (data) => {
  var discord = data['primary'][0]
  var subject = data['primary'][1]
  var description = data['primary'][2]
  if (discord !== "" && subject !== "" && description !== "") {     
   emitNet("cademailSendMailinfo", data) 
  }
})

RegisterNuiCallback('Close', () => {  
	CloseNUI()  
})


// -- / FUNCTIONS \ -- \\
let display = false
function OpenNUI() {   
  if (display == false) {     
    display = true
    SetNuiFocus(true, true)    
    SendNUIMessage({show: true})
  }
}

function CloseNUI() {
  display = false  
  SetNuiFocus(false)  
  SendNUIMessage({show: false})  
}

// -- / EVENTS \ -- \\
onNet("cademailOpenNUI", () => {   
   OpenNUI()
})

onNet("cademailMailSent", (name, discord, subject, description, email) => {
  SendNUIMessage({type: "mail", name: name, discord: discord, subject: subject, body: description, email: email})
  CloseNUI()
})

onNet("cademailSendNotify", (msg) => {   
  QBCore.Functions.Notify(msg)
})



// -- / Made By Cadburry#7547 \ -- \\
