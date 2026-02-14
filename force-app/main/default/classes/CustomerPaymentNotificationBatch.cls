/**********************************************************************************************************************
* Name               : CustomerPaymentNotificationBatch                                                        
* Description        : Class to Send reminder before the due date (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft  
* 1.1           hrohilla@aldar.com      08/11/2023      Updated to add SendGrid Integration     
******************************************************************************************************************/
global class CustomerPaymentNotificationBatch implements Database.Batchable<sObject>,Database.AllowsCallouts, Schedulable{
    
    public String query;    
    
   public CustomerPaymentNotificationBatch(){
        //[Harsh@Aldar 08/11] Updated the Query to work on TODAY's Due Installments too, it was a legacy issue
        this.query='select Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where PaymentInstallments__r.isHandoverPayment__c =false and (SalesOrder__r.RecordType.Name!=\'RTO\' and SalesOrder__r.OpportunitySaleType__c!=\'RTO\') and SalesOrder__r.Status__c in (\'Approve Pending\', \'Sold\')  and  (InstallmentDate__c = NEXT_N_DAYS:46 OR InstallmentDate__c = TODAY) and  OutstandingAmount__c > '+ System.Label.CommissionAmountBuffer;
        if(Test.isRunningTest()){
            this.query = this.query + ' LIMIT 1';
        }
    }
    
    public CustomerPaymentNotificationBatch(String queryStr){
        this.query=queryStr;
    }
    
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,1);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
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
        
        set<Integer> customerPaymentNotificationDays =new set<Integer>();
        
        //[Harsh 13/10] Only the last value would be coming from label that would represent the call frequency
        // Integer lastNotificastionDay = 99999;
        // for(String tempS : System.Label.CustomerPaymentNotificationFrequency.split(',')){ //30 10 7
        //     customerPaymentNotificationDays.add(Integer.ValueOf(tempS));
        //     if(lastNotificastionDay > Integer.ValueOf(tempS)){
        //         lastNotificastionDay = Integer.ValueOf(tempS);
        //     }
        // }
        // Integer lastNotificastionDayNR = 99999;
        // set<Integer> customerPaymentNotificationDaysNR =new set<Integer>();
        // for(String tempS : System.Label.CustomerPaymentNotificationFrequencyNR.split(',')){ //45 10 15
        //     customerPaymentNotificationDaysNR.add(Integer.ValueOf(tempS));
        //     if(lastNotificastionDayNR > Integer.ValueOf(tempS)){
        //         lastNotificastionDayNR = Integer.ValueOf(tempS);
        //     }
        // }

        //[Harsh 13/10]
        Integer lastNotificastionDay = Integer.valueOf(System.Label.CustomerPaymentNotificationFrequency); //7
        Integer lastNotificastionDayNR = Integer.valueOf(System.Label.CustomerPaymentNotificationFrequencyNR); //15

        //added by harsh@aldar 05/10/2023
        List<Integer> sendGridNotificationFrequencyList = new List<Integer>();
        Integer lastNotificastionDaySendGrid = 99999;
        for(String tempS : System.Label.SendGridPaymentReminderFrequency.split(',')){ //30 15 0
            sendGridNotificationFrequencyList.add(Integer.ValueOf(tempS));
            if(lastNotificastionDaySendGrid > Integer.ValueOf(tempS)){
                lastNotificastionDaySendGrid = Integer.ValueOf(tempS);
            }
        }
        
        //get Document RecordType 
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        //Attachment 1 SOA
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();

        //Phone Call out
        //list<object> finalCallList = new list<object>();
        
        for(InstallmentLines__c tempRec : scope){
            boolean isResident = (tempRec.SalesOrder__r.Contact__r.ResidentStatus__c == Constants.RESIDENTSTATUS_RESIDENT);
            Integer daysDifference= math.abs( tempRec.InstallmentDate__c.daysBetween(system.today()));
            if( tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc!=null && tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc=='971' && tempRec.SalesOrder__r.Account__r.CustomerType__c !=Constants.USER_TEAM_VIP && tempRec.SalesOrder__r.Account__r.MobilePhone__pc!=null && ( (isResident &&  daysDifference == lastNotificastionDay) || (!isResident &&  daysDifference == lastNotificastionDayNR) ) ){
                //Call params
                system.debug(tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc + tempRec.SalesOrder__r.Account__r.MobilePhone__pc);
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
                //new added
                dataObject.put('Timezone','');
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

                finalCallMap.put(tempRec.ProjectName__c + tempRec.SalesOrder__r.Account__r.MobileCountryCode__pc + tempRec.SalesOrder__r.Account__r.MobilePhone__pc,requestObject);

            // } else if((isResident && customerPaymentNotificationDays.contains(daysDifference) ) || (!isResident && customerPaymentNotificationDaysNR.contains(daysDifference) ) ){
            //     //Create Placeholder if not present
            //     intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
            //                                                                 InstallmentLine__c = tempRec.Id,
            //                                                                 SalesOrder__c = tempRec.SalesOrder__c,
            //                                                                 RecordtypeId= customerDocumentType,
            //                                                                 RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
             }

            else if(sendGridNotificationFrequencyList.contains(daysDifference) ){
                //customerPaymentNotificationDays is an ordered list (30,15,0) -- using this order to predict the reminder number using index
                Integer index = sendGridNotificationFrequencyList.indexOf(daysDifference);
                // System.debug('####index: '+index);
                // //Create Placeholder if not present
                intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                                                                            InstallmentLine__c = tempRec.Id,
                                                                            SalesOrder__c = tempRec.SalesOrder__c,
                                                                            RecordtypeId= customerDocumentType,
                                                                            Payment_Reminder_No__c = index + 1,
                                                                            RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
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

        //Harsh@Aldar 14/09/2023 Replacing Nintex with VFPage PDFs and calling sendgrid
        if(!intallmentsForSOAReminder.isEmpty()){ 
            for(Document__c tempRec: [select id,InstallmentLine__c, Payment_Reminder_No__c  from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();

            Map<Id, Integer> docIdList = new Map<Id, Integer>();
            for(Document__c thisDoc: intallmentsForSOAReminder.values()){
                docIdList.put(thisDoc.Id, Integer.valueOf(thisDoc.Payment_Reminder_No__c));
            }

            //attach documents and call sendgrid
            SendGridIntegrationController.sendPaymentReminder(docIdList);
        }

        
        // if(!intallmentsForSOAReminder.isEmpty()){
        //     string deliveryOptionName= Constants.DOC_TYPE_PAYMENTREMINDER + ' Email';
        //     list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
        //     //If Placeholder present then get the ID
        //     for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
        //         intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
        //     }
        //     upsert intallmentsForSOAReminder.values();

        //     map<id,Document__c> docMap = new map<id,Document__c>([select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]);
        //     map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
        //     for(ID docID :docToCDMap.keySet() ){
        //         //docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
        //         docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null: deliveryOption[0].Loop__DDP__c;
        //         docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null: deliveryOption[0].Id;
        //         //docMap.get(docID).GenerateDocument__c = true;
        //         docMap.get(docID).GenerateDocumentEmailTemplate__c = true;
        //     }
        //     update docMap.values();
        // }

    }    
    global void finish(Database.BatchableContext bc){
    }    
}