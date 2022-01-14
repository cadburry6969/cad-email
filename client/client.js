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
  if (data['primary'][3] !== "") {     
    console.log(data['primary'][3])
    emitNet("cademailSendMailinfo", data, true)     
  } else {    
    emitNet("cademailSendMailinfo", data, false) 
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
