global class ECSS_EmailToCaseHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env) {
        // Create an InboundEmailResult object for returning the result of the
        // Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        System.debug('in the email service:'+email.fromAddress);
        String emailplainTextBody = email.plainTextBody;
        String emailFromEmailAddress = email.fromAddress;
        String emailFromName = email.fromName;
        String emailSubject = email.subject;
        
               //list.add(email.headers);
        Id caseId;
        if(email.headers != NULL){
            caseId = Cases.getCaseIdFromEmailHeaders(email.headers);
            System.debug('caseId ' + caseId);
            
            System.debug('email.headers ' + email.headers);
        }
        String contAccountId;
        String contactId;
        
        String personAccountId;
        /*
        Contact[] cont = [SELECT Id, AccountId FROM Contact WHERE Email =: emailFromEmailAddress LIMIT 1];
        List<Account> accList =[SELECT Id FROM Account WHERE isPersonAccount = TRUE AND (Primary_Email__c =: emailFromEmailAddress OR Secondary_Email__c =: emailFromEmailAddress)];
        
        if(!cont.isEmpty()){
            contAccountId = cont[0].AccountId;
            contactId = cont[0].Id;
        }
        else if(!accList.isEmpty()){
            personAccountId = accList[0].Id;
        }*/
        
        try {
            if(caseId == NULL && !Test.IsRunningTest()){
             
                /*
                Case newCase = new Case();
                newCase.Subject = emailSubject;
                newCase.Priority = 'Low';
                newCase.Status = 'Open';
                newCase.Origin = 'Email';
                newCase.Description = emailplainTextBody;
                newCase.SuppliedEmail = emailFromEmailAddress;
                newCase.SuppliedName = emailFromName;
                newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unassigned').getRecordTypeId();
                
                if(contAccountId != NULL){
                    newCase.AccountId = contAccountId;
                    newCase.ContactId = contactId;
                }
                else if(personAccountId != NULL){
                    newCase.AccountId = personAccountId;
                }
                
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;
                newCase.setOptions(dmo);
                
                insert newCase;
                caseId = newCase.Id;
				*/
            }
            else{
                 System.debug('caseId ' + caseId);
                List<EmailMessage>  newEmail = new List<EmailMessage>();
                newEmail.add(new EmailMessage(FromAddress = email.fromaddress,
                                              FromName = email.fromname,
                                              ToAddress = email.toaddresses[0],
                                              Subject = email.subject,
                                              TextBody = email.plainTextBody,
                                              HtmlBody = email.htmlbody,
                                              Incoming = true,
                                              //headers = email.headers,
                                              MessageDate = System.now(),    
                                              ParentId = caseId,
                                             relatedtoId = caseId));
                if(newEmail.size() > 0) insert newEmail;
            }
            System.debug('email.textAttachments  ' + email.textAttachments );
            System.debug('email.BinaryAttachments  ' + email.BinaryAttachments );
            System.debug('email  ' + email );
            List<Attachment> attachments = new List<Attachment>();
            if(email.textAttachments != null)
            {
                for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                    Attachment attachment = new Attachment();
                    attachment.Name = tAttachment.fileName;
                    attachment.Body = Blob.valueOf(tAttachment.body);
                    attachment.ParentId = caseId;
                    attachments.add(attachment);
                }
            }
            if(email.binaryAttachments != null)
            {
                for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                    Attachment attachment = new Attachment();
                    
                    attachment.Name = bAttachment.fileName;
                    attachment.Body = bAttachment.body;
                    attachment.ParentId = caseId;
                    attachments.add(attachment);
                }
            }
            if(attachments.size() > 0)
            {
                insert attachments;
            }
            
        } catch (Exception e) {
            System.debug('EmailToLeadHandler Exception Line: ' + e.getLineNumber());
            System.debug('EmailToLeadHandler Exception Message: ' + e.getMessage());
        }
        
        // Set the result to true. No need to send an email back to the user
        // with an error message
        result.success = true;
        
        // Return the result for the Apex Email Service
        return result;

    }

}