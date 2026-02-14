public class SendCommunityManagerEmail {
    public class FlowInput {
        @InvocableVariable public String srId;
        @Invocablevariable public String emailtemplateId;
        @Invocablevariable public list<String> toAddress;
    }
     @InvocableMethod
    public static void sendEmail(List<FlowInput> flowInput) {
        System.debug('flowInput>>>' + flowInput);
        List<String> attachmentIds = new List<String>();
        FlowInput input = FlowInput[0];
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(input.emailtemplateId, null, input.srId);

		email.setToAddresses(input.toAddress);
        
        for(OrgWideEmailAddress orgWideEmail: [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName =: Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE LIMIT 1]){
            email.setOrgWideEmailAddressId(orgWideEmail.Id);
        }
        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            System.debug('results>>>' + results);
        } catch(Exception ex) {
            System.debug('ex>>>' + ex);
        }

    }

}