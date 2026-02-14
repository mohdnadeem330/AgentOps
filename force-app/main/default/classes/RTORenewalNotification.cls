/**********************************************************************************************************************
* Name               : RTORenewalNotification                                                        
* Description        : Class to Send reminder before the renewal
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
global class RTORenewalNotification implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
    
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,5);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where SalesOrder__r.RecordType.Name=\'RTO\' and InstallmentDate__c = NEXT_N_DAYS:61 and OutstandingAmount__c > '+ System.Label.CommissionAmountBuffer ;
        //String query='select Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where SalesOrder__r.RecordType.Name=\'RTO\' and id= \'a1g2z000000hCT1AAM\'';
       
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        //Check reminder frequency
        set<Integer> customerRenewalNotificationDays =new set<Integer>();
        for(String tempS : System.Label.RTORenewalNotification.split(',')){
            customerRenewalNotificationDays.add(Integer.ValueOf(tempS));
        }
        
        //Joint owners
        set<ID> soToProcess = new set<ID>();
        for(InstallmentLines__c tempRec : scope){
            soToProcess.add(tempRec.SalesOrder__c);
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        
        //Check if the reminder is available
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        //get Document RecordType 
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();

        for(InstallmentLines__c tempRec : scope){
            Integer daysDifference= math.abs( tempRec.InstallmentDate__c.daysBetween(system.today()));
            if(customerRenewalNotificationDays.contains(daysDifference) ||true ){
                //Create Placeholder if not present
                intallmentsForSOAReminder.put(tempRec.Id, new Document__c (DocumentType__c = Constants.DOC_TYPE_RTOREMINDER,
                                                                            InstallmentLine__c = tempRec.Id,
                                                                            SalesOrder__c = tempRec.SalesOrder__c,
                                                                            RecordtypeId= customerDocumentType,
                                                                            RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
            }
        }
        if(!intallmentsForSOAReminder.isEmpty()){
            string deliveryOptionName= Constants.DOC_TYPE_RTOREMINDER + ' Email';
            list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_RTOREMINDER]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            map<id,Document__c> docMap = new map<id,Document__c>([select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_RTOREMINDER]);
            for(ID docID :docMap.keySet() ){
                docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null: deliveryOption[0].Loop__DDP__c;
                docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null: deliveryOption[0].Id;
                docMap.get(docID).GenerateDocument__c = true;
            }
            update docMap.values();
        }      
    }    
    global void finish(Database.BatchableContext bc){
       
    }    
}