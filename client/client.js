// -- / NUI \ -- \\
RegisterNuiCallbackType('sendmail')
on("__cfx_nui:sendmail", (data) => {
   var name = data['secondary'][0]
   var discord = data['secondary'][1]
   var subject = data['secondary'][2]
   var description = data['secondary'][3]
   var email = data['secondary'][4]
   emitNet("cademailSendMailServer", name, discord, subject, description, email)
})

RegisterNuiCallbackType('SendInfo')
on("__cfx_nui:SendInfo", (data) => {
  var discord = data['primary'][0]
  var subject = data['primary'][1]
  var description = data['primary'][2]
  if (discord !== "" && subject !== "" && description !== "") {     
   emitNet("cademailSendMailinfo", data) 
  }
})

RegisterNuiCallbackType('Close')
on("__cfx_nui:Close", () => {  
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
RegisterNetEvent("cademailOpenNUI")
on("cademailOpenNUI", () => {   
   OpenNUI()
})

RegisterNetEvent("cademailMailSent")
on("cademailMailSent", (name, discord, subject, description, email) => {
  SendNUIMessage({type: "mail", name: name, discord: discord, subject: subject, body: description, email: email})
  CloseNUI()
})



// -- / Made By Cadburry#7547 \ -- \\
