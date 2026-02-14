/***
Class       : PaymentRequestTriggerHandler
Author      : Smaartt
Description : This trigger handler is to Create the encrypted Id for the payment request.
TestClass   : paymentRequestTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
3.         v1.2             13/10/2025  Pooja@aldar         gateway added for inovice and receipt logic

****************************************************************************************************************/

public without sharing class PaymentRequestTriggerHandler extends TriggerHandler{
     @TestVisible
    public static Boolean skipGuestCheckInTest = true; //Added by Aldar 18/9/2025
    
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){      
        list<Payment_Request__c> updateReq = new list<Payment_Request__c>();
        //Added by Harsh@Aldar 15/09/2025
        List<Id> caseIdList_ERP = new List<Id>(); 
        for(Payment_Request__c reqList : (List<Payment_Request__c>)newList){
            if(reqList.Payment_Type__c == label.DM_Online && reqList.Encrypted_Id__c == null){
                Payment_Request__c pr = new Payment_Request__c(Id = reqList.Id);
                pr.Encrypted_Id__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(reqList.Id+''), 'UTF-8');                    
                updateReq.add(pr);
            }
        }

        try {
            if(updateReq.size()>0){
                Update updateReq;
            }
        } catch(DmlException e) {
            System.debug(e.getMessage());
            LoggerService.save(LoggerService.createApexLog(e,'afterInsertMethod','PaymentRequestTriggerHandler','afterInsertMethod'));
        }
    }
    //@TestVisible
    //public static Boolean forceInternalBranchForTest = false;
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        Set<Id> caseIdSet = new Set<Id>(); 
        //Added by Harsh@Aldar 15/09/2025
        List<Id> caseIdList_ERP = new List<Id>(); 
        List<Id> paymentRequestIdList = new List<Id>();
        List<Payment_Gateway_Event__e> pgEvents = new list<Payment_Gateway_Event__e>();

        //List<Id> invoiceUpdatedPaymentIds = new List<Id>();

        for(Payment_Request__c newReq : (List<Payment_Request__c>)newList){
            Payment_Request__c oldReq = (Payment_Request__c) oldMap.get(newReq.Id);
            //guest user logic
            //since the payment details are updated in payment request from gateway using a community guest user
            //Added by Aldar 18/9/2025
            if((Auth.CommunitiesUtil.isGuestUser() || (skipGuestCheckInTest && Test.isRunningTest()))){
         //  if ((Auth.CommunitiesUtil.isGuestUser() && !forceInternalBranchForTest) || (/*Test.isRunningTest() && */!forceInternalBranchForTest)) {

                // ERP auto sync - check if payment refrence numbers are populate then move to erp 
                if ((newReq.Status__c == 'Pending' || newReq.Status__c == 'Unconfirmed' || newReq.Status__c == 'Received') 
                        && String.isBlank(newReq.ERP_Id__c) 
                        && String.isBlank(newReq.ERP_Invoice_Number__c)) {

                    // Online Payment
                    if (newReq.Payment_Type__c == 'Online' && newReq.Status__c == 'Received'
                        && String.isNotBlank(newReq.Transaction_No__c) 
                        && String.isBlank(oldReq.Transaction_No__c)) {

                        caseIdList_ERP.add(newReq.Id);
                    }
                    // Wire Transfer
                    else if (oldReq.Payment_Type__c == 'Wire Transfer' && newReq.Status__c == 'Unconfirmed'
                            && String.isNotBlank(newReq.Payment_Reference_No__c) 
                            && String.isBlank(oldReq.Payment_Reference_No__c)) {
                            
                        caseIdList_ERP.add(newReq.Id);   
                    }
                    System.debug('#### HARSH -- PAYMENT GATEWAY -- 1');
                            if(caseIdList_ERP.size() > 0 ){
                                Payment_Gateway_Event__e pge = new Payment_Gateway_Event__e(Record_Id__c = caseIdList_ERP[0], Identifier__c ='DM-Payment');
                                pgEvents.add(pge); 
                            }
                    if (newReq.Case__c != null && newReq.Amount__c != null && oldReq.ERP_Id__c == null && newReq.ERP_Id__c != null) {
                    
                        //to do next actions such as updating status flags on parent case
                        caseIdSet.add(newReq.Case__c); 
                        
                        //Added by Harsh@Aldar 15/09/2025
                        //once ERP Id and ERP invoice number are populated, generate the invoice pdf and send the email
                        paymentRequestIdList.add(newReq.Id);
                        //invoiceUpdatedPaymentIds.add(newReq.Id);
                    }

                } 
                
                if (newReq.Case__c != null && newReq.Amount__c != null && oldReq.ERP_Id__c == null && newReq.ERP_Id__c != null) {
                    
                    //to do next actions such as updating status flags on parent case
                    caseIdSet.add(newReq.Case__c); 
                    
                    //Added by Harsh@Aldar 15/09/2025
                    //once ERP Id and ERP invoice number are populated, generate the invoice pdf and send the email
                    paymentRequestIdList.add(newReq.Id);
                    //invoiceUpdatedPaymentIds.add(newReq.Id);
                }
            } else {
                //Added patch by Harsh@ALD 08/10/2025 Start
                //Upaated Logic below
                //Online - Received and Ref(Transaction_No__c) from gateway is populated -> push to ERP -> if erp id is populated -> generate the docs
                //Wire Transfer - Received and Ref (Payment_Reference_No__c) from gateway is populated -> push to ERP -> if erp id is populated -> generate the docs
                //CDC - Unconfirmed and Ref (Cheq Number and Date Payment_Reference_No__c) is populated manually -> push to ERP -> if erp id is populated -> generate the docs
                //PDC - Unconfirmed and Ref (Cheq Number and Date Payment_Reference_No__c) is populated manually -> push to ERP -> if erp id is populated -> generate the docs

                if (newReq.Case__c != null && newReq.Amount__c != null && oldReq.ERP_Id__c == null && newReq.ERP_Id__c != null) {
                    
                    //to do next actions such as updating status flags on parent case
                    caseIdSet.add(newReq.Case__c); 
                    
                    //Added by Harsh@Aldar 15/09/2025
                    //once ERP Id and ERP invoice number are populated, generate the invoice pdf and send the email
                    paymentRequestIdList.add(newReq.Id);
                    //invoiceUpdatedPaymentIds.add(newReq.Id);
                }
                //Added patch by Harsh@ALD 08/10/2025 End
                
                // ERP auto sync - check if payment refrence numbers are populate then move to erp 
                //CDC and PDC details are updated by internal users so this will no go in the system context
                else if ((newReq.Status__c == 'Pending' || newReq.Status__c == 'Unconfirmed' || newReq.Status__c == 'Received')  && String.isBlank(newReq.ERP_Id__c)  && String.isBlank(newReq.ERP_Invoice_Number__c)){

                	    // CDC
                    if (newReq.Payment_Type__c == 'CDC' && newReq.Status__c == 'Pending' && String.isNotBlank(newReq.Payment_Reference_No__c)  && String.isBlank(oldReq.Payment_Reference_No__c)) {
                        caseIdList_ERP.add(newReq.Id);
                    }

                    // PDC
                    else if (newReq.Payment_Type__c == 'PDC' && newReq.Status__c == 'Pending'  && String.isNotBlank(newReq.Payment_Reference_No__c)  && String.isBlank(oldReq.Payment_Reference_No__c)){
                        caseIdList_ERP.add(newReq.Id);
                                system.debug('caseIdList_ERP=='+caseIdList_ERP);
                    }
                    // Online Payment
                    else if (newReq.Payment_Type__c == 'Online' && newReq.Status__c == 'Received'
                        && String.isNotBlank(newReq.Transaction_No__c) 
                        && String.isBlank(oldReq.Transaction_No__c)) {
                        caseIdList_ERP.add(newReq.Id);
                        System.debug('#### HARSH -- NOT PAYMENT GATEWAY -- ONLINE');
                    }
                    else if (oldReq.Payment_Type__c == 'Wire Transfer' && newReq.Status__c == 'Unconfirmed'
                            && String.isNotBlank(newReq.Payment_Reference_No__c) 
                            && String.isBlank(oldReq.Payment_Reference_No__c)) {
                        caseIdList_ERP.add(newReq.Id);
                                system.debug('Request Status==' +newReq);     
                                System.debug('#### HARSH -- NOT PAYMENT GATEWAY -- WIRE 2'); 
                    }
                }
            }
        }

        /*if (!invoiceUpdatedPaymentIds.isEmpty()) {
            processInvoiceGenerationAndEmail(invoiceUpdatedPaymentIds);
        }*/
 		system.debug('Request caseIdList_ERP==' +caseIdList_ERP);   
        if(caseIdList_ERP.size() > 0 && !test.isRunningTest()){ //bypass integration for test class execution, there is a separate test class for integration
            System.debug('*****IM INSIDE');
            //temporary logger to test in dev - remove later - harsh@aldar
            //insert LoggerService.logSuccessResponse('#### DM ERP INTEGRATION TESTING ####','PaymentRequestTriggerHandler', 'afterUpdate', caseIdList_ERP[0],'## DM ERP - COMING TO ERP - Update TRIGGER', caseIdList_ERP[0]);
            Dm_ERPIntegrationCtrl.pushToERPAsync(caseIdList_ERP[0]);
           //System.enqueueJob(new ERPIntegrationQueueable(caseIdList_ERP[0]));

           //Payment_Gateway_Event__e pge = new Payment_Gateway_Event__e(Record_Id__c = caseIdList_ERP[0], Identifier__c ='DM-Payment');
            //pgEvents.add(pge); 

        }
		system.debug('Request caseIdSet==' +caseIdSet);
        if (!caseIdSet.isEmpty()) {
            List<Case> caseRecords = [
                SELECT Id, Service_Price__c, Received_Amount__c, Status, Sub_Status__c  
                FROM Case  
                WHERE Id IN :caseIdSet];
            //updateCaseReceivedAmount(caseRecords);
            String CaseRecordString = String.join(caseIdSet, ',');
            system.debug('== Before Event triggered ==');
            Payment_Gateway_Event__e pge = new Payment_Gateway_Event__e(Record_Id__c = CaseRecordString, Identifier__c ='DM-UpdateCase');
            pgEvents.add(pge); 
            system.debug('== After Event triggered ==');
        }
        
        if (!paymentRequestIdList.isEmpty()) {
            //DmCaseInvoiceDoc.generatePDF(paymentRequestIdList);
            //DM_SendPaymentInvoice.sendInvoicepdfHelper(paymentRequestIdList[0],'xyz');

            Payment_Gateway_Event__e pge = new Payment_Gateway_Event__e(Record_Id__c = paymentRequestIdList[0], Identifier__c ='DM-Payment-DOCGEN');
            pgEvents.add(pge); 
        }
        
        if(pgEvents.size()>0){
            EventBus.publish(pgEvents);
        }

        
    }

    public static void updateCaseReceivedAmount(List<Case> caseRecords) {      
        Map<Id, Decimal> caseReceivedAmounts = new Map<Id, Decimal>();
        for (Case caseRecord : caseRecords) {
            caseReceivedAmounts.put(caseRecord.Id, 0);
        }
        system.debug('== inside update case ==');
        List<AggregateResult> arlist = [
            SELECT Case__c, SUM(Amount__c) sumAmount 
            FROM Payment_Request__c 
           // WHERE Case__c IN :caseReceivedAmounts.keySet() AND Status__c = 'Received' ------------------------> added by sadhana
           Where Case__c IN : caseReceivedAmounts.keySet() ANd Status__c in ('Remitted','Confirmed','Received','Unconfirmed') 
            GROUP BY Case__c
        ];
        system.debug('arlist --> ' +arlist);
        for (AggregateResult ar : arlist) {
            Id caseId = (Id) ar.get('Case__c');
            Decimal totalAmount = (Decimal) ar.get('sumAmount');
            caseReceivedAmounts.put(caseId, totalAmount);
        }
        List<Case> casesToUpdate = new List<Case>();
        for (Case caseRecord : caseRecords) {
            Decimal receivedAmount = caseReceivedAmounts.get(caseRecord.Id);
            caseRecord.Received_Amount__c = receivedAmount;
            if (receivedAmount != null && receivedAmount == caseRecord.Service_Price__c) {
                caseRecord.Status = Label.DM_StatusWorkInProgress;
                caseRecord.Sub_Status__c = Label.DM_SubStatusPaymentSuccessfully;
            }
            casesToUpdate.add(caseRecord); 
        }
        try {
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        } catch (DmlException e) {  LoggerService.save(LoggerService.createApexLog(e,'updateCaseReceivedAmount','PaymentRequestTriggerHandler','updateCaseReceivedAmount')); }
    }

}