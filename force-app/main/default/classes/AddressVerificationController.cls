public with sharing class AddressVerificationController {
    @InvocableMethod
    public static void VerifyAddress(List<String> rId) {
        List<SalesOrder__c> soList = [SELECT Id, Name, Account__c, Account__r.Name, Account__r.PersonEmail, Account__r.Email__c, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode,Account__r.ShippingCountry FROM SalesOrder__c WHERE Id IN: rId LIMIT 1];

        EmailTemplate et = [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'CustomerAddressVerification'];

        List<Messaging.SingleEmailMessage> emList = new List<Messaging.SingleEmailMessage>();
        for (SalesOrder__c so: soList) {
            Messaging.SingleEmailMessage sEmail = Messaging.renderStoredEmailTemplate(et.Id, null, so.Id);
            String subject = sEmail.getSubject();
            String htmlBody = sEmail.getHtmlBody();

            String custName = String.isNotBlank(so.Account__r.Name) ? so.Account__r.Name : '';
            String custStreet = String.isNotBlank(so.Account__r.ShippingStreet) ? so.Account__r.ShippingStreet : '';
            String custCity = String.isNotBlank(so.Account__r.ShippingCity) ? so.Account__r.ShippingCity : '';
            String custState = String.isNotBlank(so.Account__r.ShippingState) ? so.Account__r.ShippingState : '';
            String custPostalCode = String.isNotBlank(so.Account__r.ShippingPostalCode) ? so.Account__r.ShippingPostalCode : '';
            String custCountry = String.isNotBlank(so.Account__r.ShippingCountry) ? so.Account__r.ShippingCountry : '';

            htmlBody = htmlBody.replace('{CustomerName}', custName);
            htmlBody = htmlBody.replace('{CustomerStreet}', custStreet);
            htmlBody = htmlBody.replace('{CustomerCity}', custCity);
            htmlBody = htmlBody.replace('{CustomerState}', custState);
            htmlBody = htmlBody.replace('{CustomerPostalCode}', custPostalCode);
            htmlBody = htmlBody.replace('{CustomerCountry}', custCountry);

            System.debug('htmlBody>>>' + htmlBody);

            Organization org = Utilities.getOrganizationDetails();
            Constant__mdt constant = new Constant__mdt();
            if (!org.IsSandbox) {
                constant = Utilities.getConstant('EmailServiceProduction');
            } else {
                constant = Utilities.getConstant('EmailServiceSandbox');
            }
            String email = so.Account__r.PersonEmail != null ? so.Account__r.PersonEmail : so.Account__r.Email__c;
            Messaging.SingleEmailMessage em = Utilities.getEmailInstance(null, null, so.Id, new List<String>{email}, null, null, subject, null, htmlBody, null, Utilities.getOrgWideEmailAddressId());
            if (String.isNotBlank(constant.ConstantValue__c)) {
                em.setReplyTo(constant.ConstantValue__c);
            }
            em.setSaveAsActivity(true);
            System.debug('em>>>'+ em);
            emList.add(em);
        }

        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emList);
            System.debug('results>>>' + results);
        } catch(Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}