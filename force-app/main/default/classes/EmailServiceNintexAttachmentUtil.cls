global class EmailServiceNintexAttachmentUtil implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        if(envelope.toAddress.SubStringBefore('@').equalsIgnoreCase('emailservicenintexattachmentutil')) {
            Id SObjectParentId;
            for(Messaging.InboundEmail.Header eachHeaderElement : email.headers){
                if(eachHeaderElement.name == 'X-SFDC-EntityId'){
                   SObjectParentId = eachHeaderElement.value; 
                   break; 
                }
            }
            if(String.IsNotBlank(SObjectParentId)) {
                //creating EmailMessage
                List<Attachment> attachmentList = new List<Attachment>();
                List<EmailMessage> emailMessageActivityList = new List<EmailMessage>();
                if(String.isNotBlank(email.fromname)){
                    EmailMessage emailMsg = new EmailMessage();
                    if(email.ccAddresses <> null) {
                        emailMsg.CcAddress = String.join( email.ccAddresses, ' , ' );
                    }
                    emailMsg.BccAddress = envelope.toAddress;
                    emailMsg.FromAddress = email.fromAddress;
                    if(String.IsNotBlank(email.htmlBody)) {
                        emailMsg.HtmlBody = email.htmlBody.length() < 32000 ? email.htmlBody : email.htmlBody.abbreviate(32000);
                    }
                    emailMsg.Subject = String.IsNotBlank(email.Subject) ? email.Subject : null;
                    if(String.IsNotBlank(email.plaintextbody)) {
                        emailMsg.TextBody = email.plaintextbody.length() < 32000 ? email.plaintextbody : email.plaintextbody.abbreviate(32000);
                    }
                    emailMsg.ToAddress = String.join( email.toAddresses, ' , ' );
                    emailMsg.RelatedToId = SObjectParentId;
                    emailMsg.MessageDate = system.now();
                    emailMsg.status = '3'; // email was sent
                    emailMessageActivityList.add(emailMsg);                    
                }
                if(emailMessageActivityList.size() > 0){
                    insert emailMessageActivityList;
                    //Exception Handling, will be added later
                    //Creating Attachments, if any
                    if(email.binaryAttachments <> null) {
                        for(Messaging.InboundEmail.BinaryAttachment binAttachment : email.binaryAttachments) {   
                           Attachment attachment = new Attachment();
                           attachment.ParentId = emailMessageActivityList[0].Id; 
                           attachment.Name = binAttachment.fileName;
                           attachment.Body = binAttachment.body;
                           attachmentList.add(attachment);             
                        }
                    }
                    if(email.textAttachments <> null) {
                        for(Messaging.InboundEmail.TextAttachment binAttachment : email.textAttachments) {   
                           Attachment attachment = new Attachment();
                           attachment.ParentId = emailMessageActivityList[0].Id; 
                           attachment.Name = binAttachment.fileName;
                           attachment.Body = blob.valueOf(binAttachment.body);
                           attachmentList.add(attachment);             
                        }
                    }
                    if(attachmentList.size() > 0){
                        insert attachmentList;
                        //Exception Handling, will be added later
                    }
                }
            }
        }
        return new Messaging.InboundEmailresult();
    }
}