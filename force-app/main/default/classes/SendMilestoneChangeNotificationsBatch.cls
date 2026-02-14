/**********************************************************************************************************************
* Name               : SendMilestoneChangeNotificationsBatch                                                        
* Description        : Class to Send MilestoneChange Notification to customer (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
//* TODO Notification From Payment Milestone

global class SendMilestoneChangeNotificationsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    set<ID> installmentLineIds = new set<ID>();
    public SendMilestoneChangeNotificationsBatch(set<ID> recordIds){
        installmentLineIds=recordIds;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,SalesOrder__r.Account__r.PersonEmail,PaymentInstallments__c,SalesOrder__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Contact__c from InstallmentLines__c where Id in :installmentLineIds' ;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        set<ID> soToProcess = new set<ID>();
        for(InstallmentLines__c tempRec : scope){
            soToProcess.add(tempRec.SalesOrder__c);
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        /*string emailTemplateId = '';
        string emailTemplateLeadId = '';
        string relatedCustomerId = '';
        string orgWideEmailAddress = '';
        list<Opportunity> opportunityRecords = new list<Opportunity>();
    
        for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'MilestoneChangeCustomerNotification' limit 1]){
            emailTemplateId=tempRec.Id;
        }
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL limit 1]){
            //orgWideEmailAddress=tempRec.Id;
        }
        
        list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
        for(InstallmentLines__c tempRec : scope){

            Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
            list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
            if(tempRec.SalesOrder__r.Contact__c !=null){
                //Attachment 1
                PageReference pdf = Page.StatementOfAccountDocument;
                pdf.getParameters().put('id',tempRec.SalesOrder__c);
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('StatementOfAccountDocument.pdf');
                efa.setBody(Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent());
                attachmentList.add(efa);

                tempEmailInstance = Utilities.getEmailInstance(tempRec.SalesOrder__r.Contact__c,emailTemplateId,tempRec.Id,null,null,null,null,null,null,attachmentList,orgWideEmailAddress);
                tempEmailInstance.setSaveAsActivity(true);
                emailsToSend.add(tempEmailInstance);
                //tempEmailInstance.setEntityAttachments(attachmentIds);
            }
        }
        Utilities.sendEmail(emailsToSend);*/
        //get Document RecordType 
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        //Attachment 1 SOA
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();

        for(InstallmentLines__c tempRec : scope){
            
            //Create Placeholder if not present
            intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_MILESTONE_CHANGELETTER,
                                                                        InstallmentLine__c = tempRec.Id,
                                                                        SalesOrder__c = tempRec.SalesOrder__c,
                                                                        RecordtypeId= customerDocumentType,
                                                                        RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
        }
        
        if(!intallmentsForSOAReminder.isEmpty()){
            string deliveryOptionName= Constants.DOC_TYPE_MILESTONE_CHANGELETTER + ' Email';
            list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_MILESTONE_CHANGELETTER]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            map<id,Document__c> docMap = new map<id,Document__c>(intallmentsForSOAReminder.values());
            map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
            for(ID docID :docToCDMap.keySet() ){
                //docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                docMap.get(docID).DocgenPackageId__c =   Test.isRunningTest()? null:deliveryOption[0].Loop__DDP__c;
                docMap.get(docID).DeliveryOptionId__c =   Test.isRunningTest()? null:deliveryOption[0].Id;
                //docMap.get(docID).GenerateDocument__c = true;
                docMap.get(docID).GenerateDocumentEmailTemplate__c = true;
            }
            update docMap.values();
        }
    }
    global void finish(Database.BatchableContext bc){}    
}