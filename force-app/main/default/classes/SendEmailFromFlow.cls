public with sharing class SendEmailFromFlow {
    public class FlowInput {
        @InvocableVariable
        public String whatId = null;
        
        @InvocableVariable
        public String whoId = null;
        
        @Invocablevariable(required=true)
        public String templateName;
        
        @Invocablevariable(required=true)
        public String toAddress;
        
        @Invocablevariable
        public String ccAddress = null;
        
        @Invocablevariable
        public String bccAddress = null;
        
        @Invocablevariable
        public String replyTo = null;

        @Invocablevariable
        public Boolean addSRAmendment = false;
    }

    @InvocableMethod
    public static void sendEmail(List<FlowInput> flowInput) {
        System.debug('flowInput>>>' + flowInput);
        FlowInput input = FlowInput[0];
        EmailTemplate template = [SELECT Id, Name FROM EmailTemplate WHERE Name =: input.templateName];

        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, input.whoId, input.whatId);
        
        List<String> toAddresses = input.toAddress.split(',');
        if (input.addSRAmendment) {
            for (AgencyTeam__c srAmendment: [SELECT Id, Account__c, Account__r.IsPersonAccount, Account__r.PersonEmail, Account__r.Email__c FROM AgencyTeam__c WHERE ServiceRequest__c =: input.whatId AND Account__c != null]) {
                if (srAmendment.Account__r.IsPersonAccount && String.isNotBlank(srAmendment.Account__r.PersonEmail)) {
                    toAddresses.add(srAmendment.Account__r.PersonEmail);
                } else if (String.isNotBlank(srAmendment.Account__r.Email__c)) {
                    toAddresses.add(srAmendment.Account__r.Email__c);
                }
            }
        }
        email.setToAddresses(toAddresses);

        if (input.ccAddress != null) {
            List<String> ccAddresses = input.ccAddress.split(',');
            email.setToAddresses(ccAddresses);
        }

        if (input.bccAddress != null) {
            List<String> bccAddresses = input.bccAddress.split(',');
            email.setToAddresses(bccAddresses);
        }

        if (input.replyTo != null) {
            email.setInReplyTo(input.replyTo);
        }
        
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