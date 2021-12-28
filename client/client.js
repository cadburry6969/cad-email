// -- / Events \ -- \\
RegisterNuiCallbackType('sendmail');
on("__cfx_nui:sendmail", (data,cb) => {
   var name = data['secondary'][0]
   var discord = data['secondary'][1]
   var subject = data['secondary'][2]
   var description = data['secondary'][3]
   var email = data['secondary'][4]
   emitNet("sendmailserver", name, discord, subject, description, email);
})

// -- / Made By Cadburry#7547 \ -- \\