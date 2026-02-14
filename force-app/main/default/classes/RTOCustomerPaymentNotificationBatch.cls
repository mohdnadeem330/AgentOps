/**********************************************************************************************************************
* Name               : RTOCustomerPaymentNotificationBatch                                                        
* Description        : Class to Send reminder before the due date (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
global class RTOCustomerPaymentNotificationBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts,Schedulable{
    set<ID> installmentIds = new set<ID>();
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,5);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        set<String> soldSR = new set<String>{Constants.SO_STATUS_RTO_SOLD,Constants.SO_STATUS_RTO_Approve_PENDING};
        String query='select Id,ReceiptAcknowledgement__r.MaturityDate__c,SalesOrder__r.Account__r.PersonEmail, InstallmentLine__c, InstallmentLine__r.CustomerName__c,SalesOrder__c,InstallmentLine__r.UnitName__c,SalesOrder__r.SoldDate__c,InstallmentLine__r.ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentLine__r.InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from ReceiptAllocation__c where ReceiptStatus__c = \'Received\' and SalesOrder__r.RecordType.Name=\'RTO\' and SalesOrder__r.Status__c in :soldSR and (ReceiptAcknowledgement__r.MaturityDate__c = NEXT_N_DAYS:65 or ReceiptAcknowledgement__r.MaturityDate__c = N_DAYS_AGO:14)' ;
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<ReceiptAllocation__c> scope){
        
        set<Integer> customerPaymentNotificationDays =new set<Integer>();
        for(String tempS : System.Label.RTOCustomerPaymentNotification.split(',')){
            customerPaymentNotificationDays.add(Integer.ValueOf(tempS));
        }
        
        //get Document RecordType 
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        set<ID> soToProcess = new set<ID>();
        for(ReceiptAllocation__c tempRec : scope){
            soToProcess.add(tempRec.SalesOrder__c);
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        
        for(ReceiptAllocation__c tempRec : scope){
            
            Integer daysDifference= math.abs( tempRec.ReceiptAcknowledgement__r.MaturityDate__c.daysBetween(system.today()));
            system.debug(daysDifference);
            if(customerPaymentNotificationDays.contains(daysDifference)){
                //Create Placeholder if not present
                intallmentsForSOAReminder.put(tempRec.InstallmentLine__c, new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                                                                            InstallmentLine__c = tempRec.InstallmentLine__c,
                                                                            SalesOrder__c = tempRec.SalesOrder__c,
                                                                            RecordtypeId= customerDocumentType,
                                                                            ReceiptAcknowledgement__c = tempRec.ReceiptAcknowledgement__c,
                                                                            RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
            }
            if(tempRec.ReceiptAcknowledgement__r.MaturityDate__c < system.today()){
                installmentIds.add(tempRec.InstallmentLine__c);
            }
        }
        
        if(!intallmentsForSOAReminder.isEmpty()){
            string deliveryOptionName= Constants.DOC_TYPE_PAYMENTREMINDER + ' RTO Email';
            list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            map<id,Document__c> docMap = new map<id,Document__c>([select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]);
            //map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
            for(ID docID :docMap.keySet() ){
                //docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null: deliveryOption[0].Loop__DDP__c;
                docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null: deliveryOption[0].Id;
                docMap.get(docID).GenerateDocument__c = true;
            }
            update docMap.values();
        }
    }    
    global void finish(Database.BatchableContext bc){
        if(!installmentIds.isEmpty()){
            database.executeBatch(new ValidateCrateDandTSRBatch(installmentIds),1);
        }
        
    }    
}