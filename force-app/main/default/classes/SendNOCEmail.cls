public class SendNOCEmail {
    public class FlowInput {
        @InvocableVariable public String rId;
        @Invocablevariable public String templateId;
        @Invocablevariable public String toAddress;
    } //SendNOCEmail.
    
    @InvocableMethod
    public static void sendEmail(List<FlowInput> flowInput) {
        System.debug('flowInput>>>' + flowInput);
        List<String> attachmentIds = new List<String>();
        FlowInput input = FlowInput[0];
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(input.templateId, null, input.rId);
        
        List<String> toAddresses = new List<String>();
        toAddresses = input.toAddress.split(','); 
		List<HexaBPM__Service_Request__c> srRequest = [SELECT Id,BuyerEmail__c,(SELECT Id,Account__c,EmailAddress__c FROM Partners__r) FROM HexaBPM__Service_Request__c WHERE Id=: input.rId ];
        for (HexaBPM__Service_Request__c sr : srRequest) {
            for (AgencyTeam__c secBuyer : sr.Partners__r) {
                toAddresses.add(secBuyer.EmailAddress__c);
            }              
        }
        for(OrgWideEmailAddress orgWideEmail: [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName =: Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE LIMIT 1]){
            email.setOrgWideEmailAddressId(orgWideEmail.Id);
        }
        system.debug('fiAdresses::'+toAddresses);
        email.setToAddresses(toAddresses);
        list<HexaBPM__SR_Doc__c> srDoc = [SELECT Id, Name, (SELECT Id, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks 
                                                            ORDER BY SystemModstamp DESC LIMIT 1) FROM HexaBPM__SR_Doc__c WHERE 
                                          HexaBPM__Service_Request__c =: input.rId AND (Name =: Constants.DOCUMENT_TYPE_SIGNED_NOC_COPY OR Name =:'Provis NOC') ];
        for (HexaBPM__SR_Doc__c srDocRecord: srDoc ){
            for (ContentDocumentLink docLink : srDocRecord.ContentDocumentLinks) {
                attachmentIds.add(docLink.ContentDocument.LatestPublishedVersionId);
            }
        }
        email.setEntityAttachments(attachmentIds);
         try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            System.debug('results>>>' + results);
        } catch(Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}