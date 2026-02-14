global class PreDefaultBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
    set<ID> installmentIdsToProcess = new set<ID>();
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,1);
    }
    global PreDefaultBatch(set<ID> recordIDs){
         this.installmentIdsToProcess =recordIDs;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='SELECT Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\'), StopDefaultNotice__c FROM InstallmentLines__c WHERE PreDefaultDate__c = TODAY AND PreDefaultSend__c = false AND Default_Send__c=false AND StopDefaultNotice__c = false';
        
        
        if(installmentIdsToProcess <> null && !installmentIdsToProcess.isEmpty()){
            Date preDefaultDateBuffer = System.today()-1;
            query='SELECT Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\'), StopDefaultNotice__c FROM InstallmentLines__c WHERE PreDefaultSend__c= false AND InstallmentDate__c <= TODAY AND PreDefaultDate__c >=: preDefaultDateBuffer AND Default_Send__c=false AND StopDefaultNotice__c = false AND Id IN: installmentIdsToProcess';
        }
        if(Test.isRunningTest()){
            query='SELECT  Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\') FROM InstallmentLines__c LIMIT 1';
            
        }
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        Set<Id> installmentIdset = new Set<Id>();
        map<id,Handoverdetails__c> hoDetailMap = new map<id,Handoverdetails__c>();
        set<ID> soToProcess = new set<ID>();
        for(InstallmentLines__c ins: scope){
            soToProcess.add(ins.SalesOrder__c);
            installmentIdset.add(ins.Id);
        }
        for(Handoverdetails__c hoRec : [SELECT id,LastInstallment__c,KAR__c,KAR__r.Email FROM Handoverdetails__c WHERE KAR__c!=null and LastInstallment__c in :installmentIdset]){
            hoDetailMap.put(hoRec.LastInstallment__c,hoRec);
        }
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        List<InstallmentLines__c> instUpdateList = new List<InstallmentLines__c>();
        for(InstallmentLines__c tempRec : scope){
            tempRec.PreDefaultSend__c = true;
            instUpdateList.add(tempRec);
            // isRTO = tempRec.SalesOrder__r.RecordTypeId !=null && tempRec.SalesOrder__r.RecordType.Name.equalsIgnoreCase(Constants.SO_RECORD_TYPE_RTO);
            //Create Placeholder if not present
            intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = 'Pre Default Notice',
                                                                      InstallmentLine__c = tempRec.Id,
                                                                      SalesOrder__c = tempRec.SalesOrder__c,
                                                                      RecordtypeId= customerDocumentType,
                                                                      Contact__c = tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__c:null,
                                                                      RecipientEmail__c   = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (hoDetailMap.containskey(tempRec.Id)? ','+ hoDetailMap.get(tempRec.Id).KAR__r.Email : '' ) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
        }
        
        if(!scope.isEmpty()){
            //string deliveryOptionName= '';//Constants.DOC_TYPE_DEFAULT_NOTICE + (isRTO ? ' '+Constants.SO_RECORD_TYPE_RTO : '') +' Email';
            list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = 'Pre Default Notice' limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = 'Pre Default Notice']){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            List<Document__c> documentList = new List<Document__c>();
            for(Document__c docID :intallmentsForSOAReminder.values()){
                docID.DocgenPackageId__c =  Test.isRunningTest()? null:  deliveryOption[0].Loop__DDP__c;
                docID.DeliveryOptionId__c =  Test.isRunningTest()? null:  deliveryOption[0].Id;
                docID.GenerateDocument__c = true;
                documentList.add(docID);
            }
            update documentList;
            update instUpdateList;
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
}