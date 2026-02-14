public class SendAlertsForInvoiceBundles implements System.Schedulable {
    public SendAlertsForInvoiceBundles() {}
    public void execute(SchedulableContext sc) {
        Map<Id, Id> InvAgencyMap = new Map<Id, Id>();
        Map<Id, InvoiceBundle__c> InvoiceMap = new Map<Id, InvoiceBundle__c>();
        Map<Id, List<String>> AgencyContactEmailMap = new Map<Id, List<String>>();
        string InvoiceBundleEmail = System.label.InvoiceBundleEmailList;
        
        List<Id> lastAccountId = new List<Id>();
        List<InvoiceBundle__c> lstInvoiceBundles = [SELECT Id, BrokerAgency__c,Status__c, DaysPassedTradyFoSubmission__c, Name, BrokerAgency__r.Owner.Email FROM InvoiceBundle__c WHERE DaysPassedTradyFoSubmission__c = 0 AND Status__c = 'Ready for Submission' AND InitiatedDate__c != null and InvoiceDate__c != null];
        for (InvoiceBundle__c invoice : lstInvoiceBundles) {
            if (invoice.BrokerAgency__c == null) {continue;}
            lastAccountId.add(invoice.BrokerAgency__c);
            InvAgencyMap.put(invoice.Id, invoice.BrokerAgency__c);
            InvoiceMap.put(invoice.Id, invoice);
        }
        List<Contact> lstContact = [SELECT Id, AccountId, Email FROM Contact WHERE AccountId IN: lastAccountId AND BrokerType__c = 'Agency Admin'];
        for(Contact con: lstContact){
            list<String> emailList = AgencyContactEmailMap.get(con.AccountId) != null ? AgencyContactEmailMap.get(con.AccountId) : new List<String>();
            emailList.add(con.email);
            AgencyContactEmailMap.put(con.AccountId,emailList);
        }
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM  OrgWideEmailAddress WHERE DisplayName='Aldar Properties'];
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        
        for(Id invoiceId : InvAgencyMap.keySet()) {
            List<String> ccAddressList = new List<String>();
            if(InvoiceBundleEmail.contains(',')){
                ccAddressList.addAll(InvoiceBundleEmail.split(','));
            }else {
                ccAddressList.add(InvoiceBundleEmail);
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(AgencyContactEmailMap.get(InvAgencyMap.get(invoiceId)));
            system.debug('Email::'+InvoiceMap.get(invoiceId).BrokerAgency__r.Owner.Email);
            ccAddressList.add(InvoiceMap.get(invoiceId).BrokerAgency__r.Owner.Email);
            mail.setCcAddresses(ccAddressList);
            if(owea != null){
                mail.setOrgWideEmailAddressId(owea.Id);
            }
            mail.setSubject('Reminder. Your Invoice Bundle is Ready for Submission');
            //mail.setTargetObjectId(con.Id);
            //mail.setHtmlBody('Dear partner, <br/><br/> Your invoice <b>'+InvoiceMap.get(invoiceId).Name+'</b> is Ready for Submission. <br/>Kindly access weekly commission report and take cation. <br/><br/> Thank You');
            // Added By Moh Sarfaraj for BPE-214
            mail.setHtmlBody('Dear Partner, <br/><br/> We would like to remind you that invoice <b>'+InvoiceMap.get(invoiceId).Name+'</b> is ready for submission. Please access the weekly commission report to proceed with submitting your invoice. <br/>Please log in to your Broker Portal using your admin account and proceed to submit the invoice by following the steps outlined below: <br/><ul><li>Access Weekly Commission Reports through the Reports tab on your Profile Dashboard.</li> <li>Review invoice details by selecting the Eye Icon.</li>  <li>Verify the accuracy of TRN number if applicable, bank details, commission rate, and payout amount.</li>  <li>Should you identify any errors, utilize the reject button, and provide comments in the comment tab.</li> <li>If all details are correct, select the accept button and monitor the progress of your invoice within the same report.</li></ul> <br/>For an optimal experience, we recommend using Google Chrome while completing these steps. <br/>For any additional assistance, please contact your account manager.<br/><br/>Regards,<br/>Aldar Broker Management Team.');
            messages.add(mail);
        }
        Messaging.sendEmail(messages);
    }
}