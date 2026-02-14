public class ALD_IL_PaymentReminder {
    /**
     * Created By Harsh@Aldar 17/11/2023 Used to send Email Reminder via SendGrid using the Send Payment Reminder button on IL detail
     */
    @AuraEnabled
    public static String sendReminderEmailViaSendGrid(String ilId, String reminderType, String salesOrderId){
        try {
            String iLineQuery = 'SELECT Id, SalesOrder__r.Account__r.PersonEmail, CustomerName__c, SalesOrder__c, UnitName__c, SalesOrder__r.SoldDate__c, ProjectName__c, SalesOrder__r.Name, SalesOrder__r.Account__r.MobileCountryCode__pc, SalesOrder__r.Account__r.MobilePhone__pc, SalesOrder__r.Contact__c, SalesOrder__r.Contact__r.ResidentStatus__c, SalesOrder__r.Contact__r.Email, SalesOrder__r.Opportunity__r.Contact__c, InstallmentDate__c, SalesOrder__r.Account__r.CustomerType__c FROM InstallmentLines__c WHERE PaymentInstallments__r.isHandoverPayment__c = false AND (SalesOrder__r.RecordType.Name != \'RTO\' AND SalesOrder__r.OpportunitySaleType__c != \'RTO\') AND SalesOrder__r.Status__c IN (\'Approve Pending\', \'Sold\') AND (InstallmentDate__c = NEXT_N_DAYS:46 OR InstallmentDate__c = TODAY) AND OutstandingAmount__c > ' + System.Label.CommissionAmountBuffer + ' AND Id = \'' + ilId + '\'';

            List<InstallmentLines__c> instList = Database.query(iLineQuery);

            if (instList.size() <= 0) {
                return 'Invalid Installment Line to Send Payment Reminder';
            }

            // Map to store InstallmentLines for SOA reminder
            Map<Id, Document__c> installmentsForSOAReminder = new Map<Id, Document__c>();
            Set<ID> salesOrdersToProcess = new Set<ID>();

            for (InstallmentLines__c tempRec : instList) {
                salesOrdersToProcess.add(tempRec.SalesOrder__c);
            }

            // Get a map of Sales Orders to their joint owner emails
            Map<Id, Set<String>> salesOrderToJointOwnerMap = DefaultAndTerminationUtility.getOwnerEmailList(salesOrdersToProcess);

            // Get Document RecordType 
            ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();

            Integer reminderNumber;

            if (reminderType != null && reminderType != '') {
                switch on reminderType {
                    when 'first' {
                        reminderNumber = 1;
                    }
                    when 'second' {
                        reminderNumber = 2;
                    }
                    when 'third' {
                        reminderNumber = 3;
                    }
                    when else {
                        reminderNumber = null;
                    }
                }
            } else {
                reminderNumber = null;
            }

            for (InstallmentLines__c tempRec : instList) {
                installmentsForSOAReminder.put(tempRec.Id, new Document__c(
                    DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                    InstallmentLine__c = tempRec.Id,
                    SalesOrder__c = tempRec.SalesOrder__c,
                    RecordtypeId = customerDocumentType,
                    Payment_Reminder_No__c = reminderNumber,
                    RecipientEmail__c = (tempRec.SalesOrder__r.Contact__c != null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (salesOrderToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ? ',' + String.join(new List<String>(salesOrderToJointOwnerMap.get(tempRec.SalesOrder__c)), ',') : '')
                ));
            }

            if(!installmentsForSOAReminder.isEmpty()){
                //If Placeholder present then get the ID
                for(Document__c tempRec: [select id,InstallmentLine__c,RecipientEmail__c from Document__c where InstallmentLine__c in : installmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
                    installmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
                }
                upsert installmentsForSOAReminder.values();

                if(installmentsForSOAReminder.size() > 0 && reminderNumber != null){
                    Map<Id, Integer> sendGridPayloadMap = new Map<Id, Integer>{installmentsForSOAReminder.values()[0].Id => reminderNumber};

                    SendGridIntegrationController.sendPaymentReminder(sendGridPayloadMap);

                    return 'Email Queued Successfully! Please check Activity for confirmation.';
                }
                
                return 'Something went wrong. Please contact System Admin';
            }    
        } catch (Exception e) {
            System.debug('#### EXCEPTION WHEN SENDING EMAIL VIA SENDGRID: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        return null;
    }

    @AuraEnabled
    public static String sendReminder(String ilId, String process, String salesOrderId) {
        System.debug('#### ilId>>> '+ilId);
        if(ilId!=null && ilId!='') {
            try{
                if(process == 'Payment Reminder') {
                    String iLineQuery = 'select Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where PaymentInstallments__r.isHandoverPayment__c =false and (SalesOrder__r.RecordType.Name!=\'RTO\' and SalesOrder__r.OpportunitySaleType__c!=\'RTO\') and SalesOrder__r.Status__c in (\'Approve Pending\', \'Sold\')  and  InstallmentDate__c = NEXT_N_DAYS:46 and OutstandingAmount__c > '+ System.Label.CommissionAmountBuffer+' and Id=\''+ilId+'\'' ;
                    System.debug('### iLineQuery -> '+iLineQuery);
                    
                    List<InstallmentLines__c> instList = Database.query(iLineQuery);
                    System.debug('instList.size() > '+instList.size());
                    
                    if(instList.size() == 0) {
                        return 'Invalid Installment Line to Send Payment Reminder';
                    }
                    
                    map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
                    set<ID> soToProcess = new set<ID>();
                    for(InstallmentLines__c tempRec : instList){
                        soToProcess.add(tempRec.SalesOrder__c);
                    }
                    map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
                    system.debug('soToJointOwnerMap -> '+soToJointOwnerMap);
                    //get Document RecordType 
                    ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
                    //Attachment 1 SOA
                    map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
                    
                    for(InstallmentLines__c tempRec : instList){
                        intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                                                                                  InstallmentLine__c = tempRec.Id,
                                                                                  SalesOrder__c = tempRec.SalesOrder__c,
                                                                                  RecordtypeId= customerDocumentType,
                                                                                  RecipientEmail__c  = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
                    }
                    if(!intallmentsForSOAReminder.isEmpty()){
                        string deliveryOptionName= Constants.DOC_TYPE_PAYMENTREMINDER + ' Email';
                        list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
                        //If Placeholder present then get the ID
                        for(Document__c tempRec: [select id,InstallmentLine__c,RecipientEmail__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]){
                            intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
                            System.debug('RecipientEmail__c -> '+tempRec.RecipientEmail__c);
                        }
                        upsert intallmentsForSOAReminder.values();

                        // [01/11/23 Harsh@Aldar] Commented this logic to send notification using SendGrid
                        map<id,Document__c> docMap = new map<id,Document__c>([select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_PAYMENTREMINDER]);
                        map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
                        for(ID docID :docToCDMap.keySet() ){
                            //docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                            docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null: deliveryOption[0].Loop__DDP__c;
                            docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null: deliveryOption[0].Id;
                            //docMap.get(docID).GenerateDocument__c = true;
                            docMap.get(docID).GenerateDocumentEmailTemplate__c = true;
                        }
                        update docMap.values();
                    }
                } else if(process == 'Mile stone change letter') {
                    set<ID> soToProcess = new set<ID>();
                    String iLineQueryForMileStoneChange = 'select id,SalesOrder__r.Account__r.PersonEmail,PaymentInstallments__c,SalesOrder__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Contact__c from InstallmentLines__c where Id=\''+ilId+'\'';
                    map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
                    ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
                    //Attachment 1 SOA
                    map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();

                    map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(new Set<Id>{salesOrderId});                           
                    for(InstallmentLines__c tempRec : Database.query(iLineQueryForMileStoneChange)) {
                        soToProcess.add(tempRec.SalesOrder__c);
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
                        for(ID docID : docToCDMap.keySet() ){
                            //docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                            docMap.get(docID).DocgenPackageId__c =   Test.isRunningTest()? null:deliveryOption[0].Loop__DDP__c;
                            docMap.get(docID).DeliveryOptionId__c =   Test.isRunningTest()? null:deliveryOption[0].Id;
                            //docMap.get(docID).GenerateDocument__c = true;
                            docMap.get(docID).GenerateDocumentEmailTemplate__c = true;
                        }
                        update docMap.values();
                    }
                        
                }
            } catch(Exception ex) {
                system.debug('### Exception Occured > '+ex.getStackTraceString()+' >> '+ex.getMessage()+' >> '+ex.getLineNumber()+' >> '+ex.getCause());
                return 'Oops Exception Occured > '+ex.getStackTraceString()+' >> '+ex.getMessage()+' >> '+ex.getLineNumber()+' >> '+ex.getCause();
            }
            return 'Success';
        }
        return 'Invalid Installment Id';
    }
}