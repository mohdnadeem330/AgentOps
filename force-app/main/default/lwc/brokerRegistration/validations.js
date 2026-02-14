export function validateOwnersEmailAndMobile(context){ 
    const ownerEmailFields = context.template.querySelectorAll('[data-item="OwnerEmailAddress"]');
    const ownerMobileFields = context.template.querySelectorAll('[data-item="OwnerMobileNumber"]');
        
    const ownerEmailSet = [];
    const ownerMobileSet = [];
    const seenEmails = new Set();
    const seenMobiles = new Set();
    ownerEmailSet.push(context.ownerEmail);
    ownerMobileSet.push(context.ownerMobileNumber);
    
    for (let i = 0; i < ownerEmailFields.length; i++) {
        let email = ownerEmailFields[i].value;
        ownerEmailSet.push(email);
    }
    if(ownerEmailSet.length > 0){
        ownerEmailSet.forEach(email => {
            if (seenEmails.has(email)) {
                context.errorDetails.push('Duplicate owner email found. Please ensure that email addresses for owners are unique.');
            }else{
                seenEmails.add(email);
            }
        })
    }

    for (let i = 0; i < ownerMobileFields.length; i++) {
        let mobile = ownerMobileFields[i].value;
        ownerMobileSet.push(mobile);
    }
    if(ownerMobileSet.length > 0){
        ownerMobileSet.forEach(mob => {
            console.log('item ',mob);
            if (seenMobiles.has(mob)) {
                context.errorDetails.push('Duplicate owner mobile found. Please ensure that mobile numbers for owners are unique.');
            }else{
                seenMobiles.add(mob);
            }
        })
    }
}