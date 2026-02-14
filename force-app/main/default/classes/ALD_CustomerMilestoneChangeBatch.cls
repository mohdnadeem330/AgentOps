/**
 * Created By Saravanan Sekar
 * Purpose : One time email to Lagoons project
 * Can be Deleted once emails are triggered
 * Created on 04/12/2023
 */ 
global class ALD_CustomerMilestoneChangeBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {

    
    public List<String> projectIds = new List<String>();
    public String queryStr = '';
    public String templateId = '';
    List<String> installmentIds=new List<String>();

    public ALD_CustomerMilestoneChangeBatch(String queryStr, List<String> projectIds, String templateId){
        this.queryStr=queryStr;
        this.templateId=templateId;
        this.projectIds=projectIds;
    }
    
      public ALD_CustomerMilestoneChangeBatch(String queryStr, List<String> projectIds, String templateId, List<String> installmentIds){
        this.queryStr=queryStr;
        this.templateId=templateId;
        this.projectIds=projectIds;
        this.installmentIds=installmentIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('### queryStr -> '+queryStr);
        if(Test.isRunningTest()){
            queryStr = 'select id, SalesOrder__r.Contact__c	, SalesOrder__r.Unit__r.name, SalesOrder__r.Unit__r.Project__r.name, SalesOrder__r.name, InstallmentAmount__c, OutstandingAmount__c , InstallmentDate__c, InstallmentPayoutDate__c, SalesOrder__r.Account__r.Email__c,SalesOrder__r.Account__r.PersonEmail from InstallmentLines__c Limit 1';
        } else if(!installmentIds.isEmpty() && !Test.isRunningTest()) {
            queryStr = 'select id, SalesOrder__r.Contact__c, SalesOrder__r.Unit__r.name,SalesOrder__r.Unit__r.Project__r.name,SalesOrder__r.name,InstallmentAmount__c, OutstandingAmount__c ,InstallmentDate__c,InstallmentPayoutDate__c,SalesOrder__r.Account__r.Email__c,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Account__r.IsPersonAccount from InstallmentLines__c where ID IN :installmentIds';
        }  else if(queryStr == '' && !Test.isRunningTest()) {
            queryStr = 'select id, SalesOrder__r.Contact__c	, SalesOrder__r.Unit__r.name, SalesOrder__r.Unit__r.Project__r.name, SalesOrder__r.name, InstallmentAmount__c, OutstandingAmount__c , InstallmentDate__c, InstallmentPayoutDate__c, SalesOrder__r.Account__r.Email__c,SalesOrder__r.Account__r.PersonEmail from InstallmentLines__c where InstallmentNumber__c =3 and InstallmentDate__c =2023-12-31 and SalesOrder__r.Unit__r.Project__c IN:projectIds and SalesOrder__r.Status__c =\'Sold\' order by OutstandingAmount__c desc';
        }
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope) {
        string orgWideEmailAddress = '';
        list<Messaging.SingleEmailMessage> bulkEmails = new list<Messaging.SingleEmailMessage>();
        for(OrgWideEmailAddress tempRec: [select Id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1]){
            orgWideEmailAddress=tempRec.Id;
        }
        for(InstallmentLines__c tempRec : scope){
            List<String> toRecipients = new List<String>();
            toRecipients.add(tempRec.SalesOrder__r.Account__r.PersonEmail!=null && tempRec.SalesOrder__r.Account__r.PersonEmail!='' ? tempRec.SalesOrder__r.Account__r.PersonEmail : tempRec.SalesOrder__r.Account__r.Email__c);
            System.debug('##WWE execute email to '+toRecipients);

            bulkEmails.add(ALD_CustomerMilestoneChangeHelper.processAndSendEmail(tempRec.Id,tempRec.SalesOrder__r.Contact__c, templateId, toRecipients, orgWideEmailAddress));
        }
        
        Utilities.sendEmail(bulkEmails);
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
}