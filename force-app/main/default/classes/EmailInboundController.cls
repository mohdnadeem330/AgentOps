global class EmailInboundController implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        System.debug('email>>>' + email);
        System.debug('envelope>>>' + envelope);

        EmailMessage em = new EmailMessage();
        em.Status = '3';
        em.FromAddress = email.fromAddress;
        em.FromName = email.fromName;
        em.ToAddress = String.join(email.toAddresses, ',');
        em.Subject = email.subject;
        em.TextBody = email.plainTextBody != null ? email.plainTextBody.escapeXml() : '';
        em.HtmlBody = email.htmlBody != null ? email.htmlBody : '';

        String rId = email.htmlBody != null ? email.htmlBody.substringBetween('rId:', ':rId') : email.plainTextBody.substringBetween('rId:', ':rId');
        if (String.isNotBlank(rId)) {
            em.RelatedToId = rId;
            Integer newConfirmCount = 0;
            Integer oldConfirmCount = email.htmlBody.stripHtmlTags().countMatches('CONFIRMED or YES') * 2;
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('CONFIRMED');
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('Confirmed');
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('confirmed');
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('YES');
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('Yes');
            newConfirmCount = newConfirmCount + email.htmlBody.countMatches('yes');
            System.debug('newConfirmCount>>>' + newConfirmCount + '>>>oldConfirmCount>>>' + oldConfirmCount);

            String htmlbody = email.htmlBody.stripHtmlTags().normalizeSpace();
            Map<String, String> caMap = new Map<String, String>();
            caMap.put('isConfirmed', oldConfirmCount < newConfirmCount ? 'true' : 'false');
            caMap.put('Street', htmlbody.substringBetween('Street:', ':Street').stripHtmlTags().trim());
            caMap.put('City', htmlbody.substringBetween('City:', ':City').stripHtmlTags().trim());
            caMap.put('State', htmlbody.substringBetween('State:', ':State').stripHtmlTags().trim());
            caMap.put('PostalCode', htmlbody.substringBetween('Postal Code:', ':Postal Code').stripHtmlTags().trim());
            caMap.put('Country', htmlbody.substringBetween('Country:', ':Country').stripHtmlTags().trim());

            SalesOrder__c so = new SalesOrder__c();
            so.Id = rId;
            so.CustomerAddress__c = JSON.serialize(caMap);
            update so;
        }
        insert em;
        System.debug('em>>>' + em);

        List<Messaging.SingleEmailMessage> emList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et = Utilities.getEmailTemplate('Address Confirmed From Customer');
        
        Messaging.SingleEmailMessage sEmail = Messaging.renderStoredEmailTemplate(et.Id, null, rId);
        String subject = sEmail.getSubject();
        String htmlBody = sEmail.getHtmlBody();
        
        SalesOrder__c so = [SELECT Id, Name, Account__c, Account__r.PersonEmail, Account__r.Email__c FROM SalesOrder__c WHERE Id =: rId];
        String toEmail = so.Account__r.PersonEmail != null ? so.Account__r.PersonEmail : so.Account__r.Email__c;
        Messaging.SingleEmailMessage emessage = Utilities.getEmailInstance(null, null, rId, new List<String>{toEmail}, null, null, subject, null, htmlBody, null, Utilities.getOrgWideEmailAddressId());
        emessage.setSaveAsActivity(true);
        System.debug('emessage>>>'+ emessage);
        try {
            emList.add(emessage);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emList);
            System.debug('results>>>' + results);
        } catch(Exception ex) {
            System.debug('ex>>>' + ex);
        }

        System.debug('result>>>' + result);
        return result;
    }
}