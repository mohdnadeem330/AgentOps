/**********************************************************************************************************************
* Name               : CustomerPaymentNotificationHOBatch                                                        
* Description        : Class to Send reminder for handover payment before the due date (Handover Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
global class CustomerPaymentNotificationHOBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
    
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,5);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        set<String> soldSR = HandoverUtility.soldSR; 
        String query='select Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where PaymentInstallments__r.isHandoverPayment__c =true and InstallmentDate__c = LAST_N_DAYS:100 and SalesOrder__r.RecordType.Name!=\'RTO\' and SalesOrder__r.Status__c in :soldSR and OutstandingAmount__c > '+ System.Label.CommissionAmountBuffer ;
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        map<String,object> finalCallMap = new map<String,object>();
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        set<ID> soToProcess = new set<ID>();
        for(InstallmentLines__c tempRec : scope){
            soToProcess.add(tempRec.SalesOrder__c);
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        //Get the Mortgage Cheques

        //Installment ID to Handover SR
        map<id,HexaBPM__Service_Request__c> installmentToHandover = HandoverUtility.getHandoverSR(new map<id,InstallmentLines__c>(scope).keySet());
        map<id,Task> taskToInsert = new map<ID,Task>();

        map<Integer,Integer> customerPaymentNotificationDays =new map<Integer,Integer>();
        Integer lastNotificastionDay = 99999;
        Integer index = 1;
        for(String tempS : System.Label.CustomerPaymentNotificationFrequencyHO.split(',')){
            customerPaymentNotificationDays.put(Integer.ValueOf(tempS), index);
            index++;
            if(lastNotificastionDay > Integer.ValueOf(tempS)){
                lastNotificastionDay = Integer.ValueOf(tempS);
            }
        }
        //get Document RecordType 
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        //Attachment 1 SOA
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();

        //Phone Call out
        //list<object> finalCallList = new list<object>();
        
        for(InstallmentLines__c tempRec : scope){
            //do not send notification if mortgage cheque is present
            
            Integer daysDifference= math.abs( tempRec.InstallmentDate__c.daysBetween(system.today()));
            
            if( tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc!=null && tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc=='971' && tempRec.SalesOrder__r.Account__r.CustomerType__c !=Constants.USER_TEAM_VIP && tempRec.SalesOrder__r.Account__r.MobilePhone__pc!=null && daysDifference == lastNotificastionDay ){
                if(installmentToHandover.containsKey(tempRec.Id)){
                    taskToInsert.put(tempRec.Id, new task(Subject ='Payment Reminder on '+ daysDifference,Status='Completed',WhatId = installmentToHandover.get(tempRec.Id).Id ,ActivityDate =System.today()));
                }
                //Call params
                map<string,string> dataObject = new map<string,string>();
                dataObject.put('Agent_CRM','Salesforce');
                dataObject.put('Title','');
                dataObject.put('Customer Name',tempRec.CustomerName__c);
                dataObject.put('Phone', tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc + tempRec.SalesOrder__r.Account__r.MobilePhone__pc);
                dataObject.put('Sales Order ID',tempRec.SalesOrder__r.Name);
                dataObject.put('Language','English');
                dataObject.put('Project', tempRec.ProjectName__c);
                dataObject.put('Unit No',tempRec.UnitName__c);
                dataObject.put('Unit Type','');
                dataObject.put('Bedrooms','');
                dataObject.put('Order Date',tempRec.SalesOrder__r.SoldDate__c !=null ? tempRec.SalesOrder__r.SoldDate__c.format().replace('/','-'): '');
                dataObject.put('Payment Date',tempRec.InstallmentDate__c.format().replace('/','-'));
                dataObject.put('Attribute1','');
                dataObject.put('Attribute2','');
                dataObject.put('Attribute3','');
                dataObject.put('Attribute4','');
                dataObject.put('Attribute5','');

                map<string,Object> requestObject = new map<string,Object>();
                requestObject.put('id','');
                requestObject.put('contactListId','');
                requestObject.put('callable',true);
                requestObject.put('phoneNumberStatus',null);
                requestObject.put('data',dataObject);

                finalCallMap.put(tempRec.ProjectName__c + tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc + tempRec.SalesOrder__r.Account__r.MobilePhone__pc ,requestObject);

            }else if(customerPaymentNotificationDays.containsKey(daysDifference) ){
                if(installmentToHandover.containsKey(tempRec.Id)){
                    taskToInsert.put(tempRec.Id, new task(Subject ='Payment Reminder on '+ daysDifference,Status='Completed',WhatId = installmentToHandover.get(tempRec.Id).Id ,ActivityDate =System.today()));
                }
                
                //Create Placeholder if not present
                //Add KAR
                intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                                                                            InstallmentLine__c = tempRec.Id,
                                                                            SalesOrder__c = tempRec.SalesOrder__c,
                                                                            RecordtypeId= customerDocumentType,
                                                                            RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ?tempRec.SalesOrder__r.Contact__r.Email :tempRec.SalesOrder__r.Account__r.PersonEmail ) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
                
            }
            
        }

        if(!finalCallMap.isEmpty()){
            Boolean callingSuccess = false;
            string token = OutboundCallUtility.getAccessToken();
            if(token!=null){
                map<string,string> callingOptionMap =  OutboundCallUtility.getContactLists(token);
                if(callingOptionMap!=null && !callingOptionMap.isEmpty()){
                    String contactListID = callingOptionMap.get(Constants.CONTACTLIST_PAYMENT_REMINDER );
                    String JSONBody = JSON.serialize(finalCallMap.values());
                    callingSuccess = OutboundCallUtility.initiateOutboundCall(token,contactListID,JSONBody );
                    
                }
            }
            if(!callingSuccess){
                System.debug('Calling Failed');
                // finalCallMap.keySet();
            }else{
                System.debug('Calling completed successfully');
            }
        }
        
        if(!intallmentsForSOAReminder.isEmpty()){
            string deliveryOptionName= Constants.DOC_TYPE_PAYMENTREMINDER +' RFO%';
            map<string,Loop__DDP_Integration_Option__c> deliveryOptionMap = new  map<string,Loop__DDP_Integration_Option__c>();
            for(Loop__DDP_Integration_Option__c tempDeliveryOption : [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name like :deliveryOptionName]){
                deliveryOptionMap.put(tempDeliveryOption.Name,tempDeliveryOption);
            }
            //Loop__DDP_Integration_Option__c deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name like :deliveryOptionName limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c,InstallmentLine__r.InstallmentDate__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            map<id,Document__c> docMap = new map<id,Document__c>([select id,InstallmentLine__c,InstallmentLine__r.InstallmentDate__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER] );
            map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
            System.debug(docMap.keySet());
            System.debug(docToCDMap.keySet());
            for(ID docID :docToCDMap.keySet() ){
                Integer daysDifference= math.abs( docMap.get(docID).InstallmentLine__r.InstallmentDate__c.daysBetween(system.today()));
                Integer inx = customerPaymentNotificationDays.containsKey(daysDifference) ? customerPaymentNotificationDays.get(daysDifference):1;
                docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null:deliveryOptionMap.get(Constants.DOC_TYPE_PAYMENTREMINDER +' RFO'+inx+' Email').Loop__DDP__c;
                docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null: deliveryOptionMap.get(Constants.DOC_TYPE_PAYMENTREMINDER +' RFO'+inx+' Email').Id;
                docMap.get(docID).GenerateDocument__c = true;
            }
            update docMap.values();
        }

        if(!taskToInsert.isEmpty()){
            insert taskToInsert.values();
        }
    }    
    global void finish(Database.BatchableContext bc){

    }    
}