global with sharing class BatchtoNoSaleNotification implements Schedulable, Database.Batchable<sObject> {
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchtoNoSaleNotification(), 1);
    }

    global String usrId = '';
    
    global BatchtoNoSaleNotification() {
    }

    global BatchtoNoSaleNotification(String usrId) {
        this.usrId = usrId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String salesManagerProfile = Constants.SALES_MANAGER;

        String query = 'SELECT Id, Name, Email, ProfileId, Profile.Name, ManagerId, Manager.Name, Manager.Email FROM User WHERE Profile.Name =: salesManagerProfile';
        if(String.isNotBlank(this.usrId)) {
            query += ' AND Id = \'' + this.usrId + '\'';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<User> userList){
        Date sevenDaysAgoDate = date.today().addDays(-7);
        Date fourteenDaysAgoDate = date.today().addDays(-14);

        List<String> emailTemplateNameList = new List<String>{Constants.SALES_NON_PERFORMANCE_LAST_7_DAYS, Constants.SALES_NON_PERFORMANCE_LAST_14_DAYS};
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        for (EmailTemplate et: [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE Name IN: emailTemplateNameList]) {
            emailTemplateMap.put(et.Name, et);
        }

        String userId = userList[0].Id;
        List<SalesOrder__c> salesOrderList = [SELECT Id, Name, BookingDate__c, SalesManager__c FROM SalesOrder__c WHERE 
                                                SalesManager__c =: userId AND BookingDate__c != null ORDER BY BookingDate__c DESC LIMIT 1];

        if (!salesOrderList.isEmpty()) {
            if (salesOrderList[0].BookingDate__c == sevenDaysAgoDate) {
                senEmail(userList[0], emailTemplateMap.get(Constants.SALES_NON_PERFORMANCE_LAST_7_DAYS), salesOrderList[0]);
            } else if (salesOrderList[0].BookingDate__c == fourteenDaysAgoDate) {
                senEmail(userList[0], emailTemplateMap.get(Constants.SALES_NON_PERFORMANCE_LAST_14_DAYS), salesOrderList[0]);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){

    }

    public static void senEmail(User usr, EmailTemplate et, SalesOrder__c salesOrder) {
        Messaging.SingleEmailMessage sEmail = Messaging.renderStoredEmailTemplate(et.Id, null, salesOrder.Id);
        String subject = sEmail.getSubject();
        String htmlBody = sEmail.getHtmlBody();

        List<String> emailList = new List<String>();
        emailList.add(usr.Manager.Email);
        emailList.add('sdmello@aldar.com');
        emailList.add('mcorrea@aldar.com');
        emailList.add('dnarvekar@aldar.com');
        emailList.add('jdsouza@aldar.com');
        Messaging.SingleEmailMessage emailMessage = Utilities.getEmailInstance(null, null, null, emailList, null, new List<String>{usr.Email}, subject, null, htmlBody, null, Utilities.getOrgWideEmailAddressId());
        
        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailMessage});
        } catch(Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}