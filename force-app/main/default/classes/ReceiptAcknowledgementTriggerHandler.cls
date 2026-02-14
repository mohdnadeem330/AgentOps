public without sharing class ReceiptAcknowledgementTriggerHandler extends TriggerHandler{
    public static boolean throwExceptionForTest = false;
    public static String CREDITNOTE = 'Credit Note';
    //Added by Tharun  
    //public static string REMITTED_PAYMENT_STATUS = 'Remitted';
    
    // FIN-82: Static flag to prevent trigger execution during specific operations
    public static boolean skipReceiptAcknowledgementTrigger = false;
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        // Added by Muzammil to cover exception in ReceiptAcknowledgementTrigger.
        if(ReceiptAcknowledgementTriggerHandler.throwExceptionForTest && test.isRunningTest()){
            throw new CustomException('Exception');
        } 
        User usr = Utilities.getLoggedInUserDetail();
        Set<Id> salesOrderIds = new Set<Id>();
        for(ReceiptAcknowledgement__c receipts : (List<ReceiptAcknowledgement__c>)newList){
            //Credit Note payment type Receipts must not be sent to ERP
            //Adding condition to stop Syncing Credit note Receipt Acknowledgements
            //If integration user is updating, it should not be updated to In progress.
            //Receipts without sales orders should not get synced.
            if(usr.Profile.Name != Constants.INTEGRATION_PROFILE  && receipts.IsStopSyncingWithERP__c == false && receipts.PaymentType__c != CREDITNOTE && receipts.SalesOrder__c != null) {
                receipts.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            receipts.Amount__c = receipts.Amount__c.setScale(2);
            //Start ASF-3309
            if (receipts.SalesOrder__c != null && receipts.RecievedFromAccount__c != null) {
                salesOrderIds.add(receipts.SalesOrder__c);
            }
           //End ASF-3309 
        }
        //Start ASF-3309
        if(!salesOrderIds.isEmpty()){ 
            ReceiptAcknowledgementTriggerHelper.populateThirdPartyFlag(newList,null);  
        }
        //End ASF-3309 
        // Added by Sai Kumar: FIN-82: Populating ReceiptAcknowledgement fields in before insert to avoid after insert update
        populateReceiptAcknowledgementFieldsBeforeInsert((List<ReceiptAcknowledgement__c>)newList);
    }
    
    // Added by Sai Kumar:  FIN-82: Avoiding update of ReceiptAcknowledgement in after insert by populating fields in before insert.
    private void populateReceiptAcknowledgementFieldsBeforeInsert(List<ReceiptAcknowledgement__c> newList) {
        Set<Id> soIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for(ReceiptAcknowledgement__c ra : newList){    
            if(ra.SalesOrder__c != null){
                soIds.add(ra.SalesOrder__c);
            } else if(ra.Opportunity__c != null){
                oppIds.add(ra.Opportunity__c);
            }
        }
        if (!soIds.isEmpty()) {
            for(SalesOrder__c so : [SELECT Id, Account__c, Contact__c 
                                  FROM SalesOrder__c 
                                  WHERE Id IN :soIds]) {
                soMap.put(so.Id, so);
            }
        }

        if (!oppIds.isEmpty()) {
            for(Opportunity opp : [SELECT Id, AccountId, Contact__c 
                                  FROM Opportunity 
                                  WHERE Id IN :oppIds]) {
                oppMap.put(opp.Id, opp);
            }
        } 

        for(ReceiptAcknowledgement__c ra : newList){
            if(ra.SalesOrder__c != null && soMap != null && soMap.containsKey(ra.SalesOrder__c)){
                ra.Contact__c = soMap.get(ra.SalesOrder__c).Contact__c;
                ra.Account__c = soMap.get(ra.SalesOrder__c).Account__c;
            } else if(ra.Opportunity__c != null && oppMap != null && oppMap.containsKey(ra.Opportunity__c)){
                ra.Contact__c = oppMap.get(ra.Opportunity__c).Contact__c;
                ra.Account__c = oppMap.get(ra.Opportunity__c).AccountId;
            }
            // Set RegeneratePaymentLink__c and Status__c for ONLINE and CRYPTO_PAYMENT
            // FIN-75: For bulk installment
            if(Constants.ONLINE.equals(ra.PaymentType__c) && ra.Payment_Gateway__c != 'Stripe' && ra.OnlinePaymentCleared__c == false ){
                ra.RegeneratePaymentLink__c = true;
                ra.Status__c = Constants.LINK_SENT;
            }
            if(Constants.CRYPTO_PAYMENT.equals(ra.PaymentType__c)){
                ra.Status__c = Constants.LINK_SENT;
            }
        }
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        User usr = Utilities.getLoggedInUserDetail();
        set<ID> clearedRARelatedToCaseIds = new set<ID>();
        List<ReceiptAcknowledgement__c> receiptAcknowledgementList = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAcknowledgement__c> receiptAcknowledgementListforRecieved = new List<ReceiptAcknowledgement__c>();
        // ASF-1454 : yenshul@Aldar
        //        Map<Id, Id> raIdToOldSOIdMap = new Map<Id, Id>();
        
        // @story FIN-144 Integration callouts will only be triggered when specific fields from ReceiptAcknowledgement_Integration_Field__c are changed
        // Query integration fields from custom setting
        Map<String, ReceiptAcknowledgement_Integration_Field__c> integrationFields = new Map<String, ReceiptAcknowledgement_Integration_Field__c>();
        
        if (Label.ReceiptAcknowledgement_Integration_Field_Check == 'true') {
            for(ReceiptAcknowledgement_Integration_Field__c field : ReceiptAcknowledgement_Integration_Field__c.getAll().values()) {
                if(field.Is_Active__c) {
                    integrationFields.put(field.API__c, field);
                }
            }
        }
        
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            ReceiptAcknowledgement__c oldRA = (ReceiptAcknowledgement__c)oldmap.get(ra.Id);
            ra.Amount__c = ra.Amount__c.setScale(2);
            // Entered by Sujesh to auto fill ChequeReceived Date and chequeReceivedBy on Cheque receive.
            if(oldRA.ChequeReceived__c != ra.ChequeReceived__c){
                ra.ChequeReceivedDate__c = (ra.ChequeReceived__c ? System.today() : Null);
                if(oldRA.OnlinePaymentCleared__c != ra.OnlinePaymentCleared__c && ra.OnlinePaymentCleared__c){
                    ra.ChequeReceivedBy__c = label.ReceivedByUserIdForOnline;
                }else{
                    ra.ChequeReceivedBy__c = (ra.ChequeReceived__c ? UserInfo.getUserId() : Null);
                }
            }
            ///----- Update Cleared Date 
            if(oldRA.Status__c != ra.Status__c && ra.Status__c == Constants.RECEIPT_STATUS_CLEARED){
                //ra.ClearedDate__c = System.today();
                
                if(ra.Case__c != null){
                    clearedRARelatedToCaseIds.add(ra.Case__c);
                }
            }           
            //Credit Note payment type Receipts must not be sent to ERP
            //Adding condition to stop Syncing Credit note Receipt Acknowledgements
            //Receipts without sales orders should not get synced.
            if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && ra.SyncTime__c == oldRA.SyncTime__c && ra.SyncStatus__c == Constants.STATUS_SYNCED && ra.IsStopSyncingWithERP__c == false && ra.PaymentType__c != CREDITNOTE && ra.SalesOrder__c != null) {
                // @story FIN-144 Integration callouts will only be triggered when specific fields from ReceiptAcknowledgement_Integration_Field__c are changed
                if (Label.ReceiptAcknowledgement_Integration_Field_Check == 'true') {
                    handleIntegrationFieldChanges(ra, oldRA, integrationFields);
                } else {
                    // Original behavior when feature flag is disabled
                ra.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                ra.IsReceiptAcknowledgementChange__c = true;
            }
            }
            // if (!ra.IsReceiptAcknowledgementChange__c && ra.IsReceiptAllocationChange__c == oldRA.IsReceiptAllocationChange__c && ra.IsStopSyncingWithERP__c == false) {
            if (!ra.IsReceiptAcknowledgementChange__c && ra.IsReceiptAllocationChange__c == oldRA.IsReceiptAllocationChange__c) {    
                ra.IsReceiptAcknowledgementChange__c = true;
            }
            if (ra.PaymentType__c == Constants.ONLINE && ra.EncryptedRecordId__c == null) {
                try{
                    ra.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(ra.Id+''), 'UTF-8');
                } catch(Exception e){
                    ra.EncryptedRecordId__c = 'Invalid Encrypted Id';
                }
            }
            //Entered by Sanket to update the reciept status based on payment type change
            if(ra.PaymentType__c != oldRA.PaymentType__c && ra.PaymentType__c != Constants.ONLINE && oldRA.PaymentType__c == Constants.ONLINE && ra.Status__c == Constants.LINK_SENT){
                ra.Status__c = Constants.RECEIVED_PAYMENT_STATUS;
            }else if(ra.PaymentType__c != oldRA.PaymentType__c && ra.PaymentType__c == Constants.ONLINE && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS){
                ra.Status__c = Constants.LINK_SENT;
            }
            if(ra.SalesOrder__c != oldRA.SalesOrder__c && ra.SalesOrder__c != null){
                receiptAcknowledgementList.add(ra);
                // ASF-1454 : yenshul@Aldar
                /*if(oldRA.SalesOrder__c != null){
                    raIdToOldSOIdMap.put(ra.Id, oldRA.SalesOrder__c);
                }*/
            }
            if (oldRA != null && oldRA.ChequeReceived__c != ra.ChequeReceived__c && ra.ChequeReceived__c) { //ASF-3320
                receiptAcknowledgementListforRecieved.add(ra);
            }
        }
        
        if(!receiptAcknowledgementList.isEmpty()){
            // ASF-1454 : yenshul@Aldar
             onSalesOrderChange(receiptAcknowledgementList);
//            onSalesOrderChange(receiptAcknowledgementList, raIdToOldSOIdMap);
        }
        if(!clearedRARelatedToCaseIds.isEmpty()){
            updateCase(clearedRARelatedToCaseIds);
        }

         //Start ASF-3320
         if(!receiptAcknowledgementListforRecieved.isEmpty()){ //ASF-3320
          //  ReceiptAcknowledgementTriggerHelper.validateInstrumentRecieved(receiptAcknowledgementListforRecieved,oldMap);  
         }
        //End ASF-3320
         
        ReceiptAcknowledgementTriggerHelper.populateThirdPartyFlag(newList,oldMap);  //Start ASF-3309
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //Harsh@Aldar RESALE MANAGER CHEQUE When the created record has Manager's Cheque as true, check all the existing payments Allocations
        // and if it is all cleared then update the Opportunity Stage to Payment Cleared
        List<ReceiptAcknowledgement__c> managerChequeReceiptAckList = new List<ReceiptAcknowledgement__c>();
        Set<Id> getSalesOrderIds = new Set<Id>();
        set<Id> srId = new set<Id>();
        
        //Added by Harsh@ALD 20/03/2025 Premium Parking Payments - Generate Order When Stripe Payment is done
        Set<Id> premPark_ReceiptIdSet = new Set<Id>();
        
        // FIN-82: List to store receipts that need encrypted record ID update to avoid trigger recursion
        List<ReceiptAcknowledgement__c> receiptsToUpdateEncryptedId = new List<ReceiptAcknowledgement__c>();
        
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            //Harsh@Aldar RESALE MANAGER CHEQUE
            if(ra.ManagersCheque__c){
                managerChequeReceiptAckList.add(ra);
            }
            //Added by Harsh@Aldar 20/03/2025 Premium Parking Receipts - Used to drive Parking Order Generation
            if(ra.Payment_Gateway__c == 'Stripe'){
                if(Constants.ONLINE.equals(ra.PaymentType__c) && ra.Remarks__c != null && ra.Remarks__c.toLowerCase().contains('parking') && ra.CPQQuote__c != null){
                    premPark_ReceiptIdSet.add(ra.Id);
                }
            }
            
            // FIN-82: Populate encrypted record ID for online payment types and add to update list to avoid trigger recursion
            if (ra.PaymentType__c == Constants.ONLINE && ra.EncryptedRecordId__c == null) {
                // Add to list for update to avoid trigger recursion
                receiptsToUpdateEncryptedId.add(ra);
            }
            
            //Added by Tajinkumar for Lean Payment Receipts
            if(ra.SalesOrder__c != null && ra.PaymentType__c == Constants.WIRE_TRANSFER && ra.Payment_Gateway__c == 'Lean' && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS && String.isNotBlank(ra.ReferenceNumber__c)) {
                getSalesOrderIds.add(ra.SalesOrder__c);
            }
            
            if(ra.Receipt_Type__c =='Charge Fee' && ra.Status__c =='Received' && ra.ServiceRequest__c !=null){
                srId.add(ra.ServiceRequest__c);
            }
            
        }
        
        if(!srId.Isempty()){
            autoCloseServiceChargeFeeStepOnSROnReceiptInsert(srId);
        }
        
        // FIN-82: Update encrypted record IDs for online payment types to avoid trigger recursion
        if(!receiptsToUpdateEncryptedId.isEmpty()) {
            List<ReceiptAcknowledgement__c> recordsToUpdate = new List<ReceiptAcknowledgement__c>();
            for(ReceiptAcknowledgement__c ra : receiptsToUpdateEncryptedId) {
                ReceiptAcknowledgement__c raToUpdate = new ReceiptAcknowledgement__c();
                raToUpdate.Id = ra.Id;
                raToUpdate.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(ra.Id+''), 'UTF-8');
                recordsToUpdate.add(raToUpdate);
            }
            
            if(!recordsToUpdate.isEmpty()) {
                skipReceiptAcknowledgementTrigger = true;
                update recordsToUpdate;
                skipReceiptAcknowledgementTrigger = false;
            }
        }
        
        //Added by Harsh@Aldar 20/03/2025 Premium Parking Receipts - Used to drive Parking Order Generation
        if( !premPark_ReceiptIdSet.isEmpty()){
              PremPark_ReceiptHelper.handleAfterInsert(premPark_ReceiptIdSet);
         }
        
        //ASF-3309
        ReceiptAcknowledgementTriggerHelper.updateSalesOrderRelationshipTotals(newList,null);
         //ASF-3559
        ReceiptAcknowledgementTriggerHelper.updateJointOwnerTotals(newList,null);
        
    /*ChargeFee-STARTED */
        receiptSharing(newList);
        /**** ChargeFee-END*/
        
        //---- to share Receipt record with Sales Order SM and Opportunity EOI.
        //ShareHelper.shareReceiptAcknowledgement(newList, Constants.EDIT_ACCESS);
        //Harsh@Aldar RESALE MANAGER CHEQUE
        if(managerChequeReceiptAckList.size() > 0){
            ResaleUnitService.handleManagerChequeReceipt(managerChequeReceiptAckList);
        }
        //Start SR Step automation
        //
       /* map<string,HexaBPM__Status__c> stepStatusMap = new map <string,HexaBPM__Status__c>();
        for(HexaBPM__Status__c srStepStatus : [SELECT Id,Name FROM HexaBPM__Status__c WHERE Name IN ('Completed')]){
            stepStatusMap.put(srStepStatus.Name,srStepStatus);
        }
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
        Set<Id> serviceRequestIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            if(ra.ServiceRequest__c != null){
                serviceRequestIds.add(ra.ServiceRequest__c);
            }
                
            
        }
        system.debug('serviceRequestIds ::'+serviceRequestIds);
        
        if(!serviceRequestIds.IsEmpty()){
            list<HexaBPM__Service_Request__c> relatedSR = [SELECT ID,Has_OA_NOC__c FROM HexaBPM__Service_Request__c WHERE Id IN:serviceRequestIds AND origin__c='Customer Portal' and srtype__c='Property Transfer NOC'];
            system.debug('relatedSR::'+relatedSR);
            if(!relatedSR.IsEmpty()){
                if(relatedSR[0].Has_OA_NOC__c == true){
                    for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN:serviceRequestIds AND HexaBPM__Summary__c = 'Verify the Customer Documents' AND HexaBPM__Step_Status__c = 'Pending']){
                        srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                        srStepsToUpdateList.add(srStep);
                        system.debug('srStepsToUpdateList ::'+srStepsToUpdateList);
                        
                    }
                }else{
                    for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN:serviceRequestIds AND HexaBPM__Summary__c = 'Signing of the Transfer Documents & Collecting the Transfer Charges' AND HexaBPM__Step_Status__c = 'Pending']){
                        srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                        srStepsToUpdateList.add(srStep);
                        system.debug('srStepsToUpdateList ::'+srStepsToUpdateList);
                        
                    }
                }
            }
        }*/
        /*if(!srStepsToUpdateList.IsEmpty()){
            update srStepsToUpdateList;
            system.debug('Updated succesfully ::'+srStepsToUpdateList[0]);
        }*/
        //
        //END SR Step automation
        
        // Isolated callout logic for after insert - called at the end after all other logic
        // FIN-144 by Sai Kumar: Refactored callout logic into isolated method for better maintainability
        handleCalloutForAfterInsert(newList, null);
        
        //Added by Tajinkumar for Lean Payment Receipts
        if(!getSalesOrderIds.isEmpty()) {
            ReceiptAcknowledgementTriggerHelper.verifyAndReserveSO(getSalesOrderIds);
        }
    }
    

    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
      //  freezeLPCForMortgagePaymentTypes((List<ReceiptAcknowledgement__c>)newList,oldMap); ******** STOP Mortgage Cheque - LPC Dates Update *********
    // if(!DDTransactionResponseHandler.stopExecuteReceiptAckTrigger){
      updateInstallmentOtherCharges(newMap.keySet());
    // }
       
    /*ChargeFee-STARTED*/
        autoCloseServiceChargeFeeStepOnSR((List<ReceiptAcknowledgement__c>)newList,oldMap,'RAObjectTrigger');
        /*ChargeFee-END*/
    
        //Update EOI to Paid
        map<Id,OpportunityEOI__c> EOIRecordsToUpdate = new map<Id,OpportunityEOI__c>();
        set<ID> verifyPaymentforReservation = new set<ID>();
        Set<Id> serviceRequestRAIds = new Set<Id>();
        Set<Id> reversedRAIds = new Set<Id>();
        set<String> defaultSRReason = new set<String>{Constants.REV_REASON_ACCOUNT_CLOSED , Constants.REV_REASON_AMOUNT_MISMATCH, Constants.REV_REASON_INSUFFICIENT_FUND ,Constants.REV_REASON_IRREGULAR_SIGNATIRE ,Constants.REV_REASON_ALTERATION ,Constants.REV_REASON_SWIFT_CONFIRMATION,Constants.REV_REASON_INVALID_DATE,Constants.REV_REASON_RETURN_LESS  };
            set<ID> clearedRAIds = new set<ID>();
        Map<Id,ReceiptAcknowledgement__c> serviceRequestReceiptMap = new Map<Id,ReceiptAcknowledgement__c>();
        Map<Id, ReceiptAcknowledgement__c> receiptAcknowledgementUnallocationMap = new Map<Id, ReceiptAcknowledgement__c>();
        //Harsh@Aldar RESALE MANAGER CHEQUE When the updated record has Manager's Cheque as true, check all the existing payments Allocations
        // and if it is all cleared then update the Opportunity Stage to Payment Cleared
        List<ReceiptAcknowledgement__c> managerChequeReceiptAckList = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAcknowledgement__c> ReceiptackForOtherCharge = new List<ReceiptAcknowledgement__c>();
        //Harsh@Aldar 22Dec'24 Premium Parking Receipts - Automations
        Set<Id> premPark_ReceiptSet = new Set<Id>();
        
        // FIN-75 Enhancement: Bulk Installment Allocation - Handle online payment cleared for bulk allocations
        Set<Id> bulkAllocationReceiptIds = new Set<Id>();
        
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            system.debug('ra::'+ra);
            ReceiptAcknowledgement__c raOld = (ReceiptAcknowledgement__c)oldmap.get(ra.Id);
       
            system.debug('raOld.Bulk_Installment_Allocation__c::'+raOld.Bulk_Installment_Allocation__c);
            system.debug('ra.Bulk_Installment_Allocation__c::'+ra.Bulk_Installment_Allocation__c);
            system.debug('raOld.OnlinePaymentCleared__c::'+raOld.OnlinePaymentCleared__c);
            system.debug('raOld.Status__c::'+raOld.Status__c);
            system.debug('ra.Status__c::'+ra.Status__c);
            system.debug('Label.EnableBulkInstallmentAllocation'+Label.EnableBulkInstallmentAllocation);
            
            // FIN-75 Enhancement: Check for bulk installment allocation with online payment cleared
            if(ra.Bulk_Installment_Allocation__c && ra.OnlinePaymentCleared__c && 
               !raOld.OnlinePaymentCleared__c && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS &&
               Boolean.valueOf(Label.EnableBulkInstallmentAllocation)) {
                bulkAllocationReceiptIds.add(ra.Id);
            }
            
            // && ra.PaymentType__c != CREDITNOTE && ra.SalesOrder__c != null 
            //Harsh@Aldar RESALE MANAGER CHEQUE
            if(ra.ManagersCheque__c && !raOld.ManagersCheque__c){
                managerChequeReceiptAckList.add(ra);
            }
            // Adarsh for bounced cheque
            if (ra.PaymentType__c == Constants.CHEQUE && ra.Status__c == Constants.REVERSED_PAYMENT_STATUS && ra.StatusReason__c != raOld.StatusReason__c 
                && ( ra.StatusReason__c.equalsIgnoreCase('Account closed') || ra.StatusReason__c.equalsIgnoreCase('Insufficient Funds') || ra.StatusReason__c.equalsIgnoreCase('Irregular Signature') )) {
                ReceiptackForOtherCharge.add(ra);
            } 
            
            //Harsh@Aldar 22-12-2024 Premium Parking Receipt Automations
            System.debug('Test'+ra.Order__c);
            if(ra.PaymentType__c == Constants.ONLINE && ra.Remarks__c != null &&ra.Remarks__c.toLowerCase().contains('parking') && ra.Order__c != null){
                premPark_ReceiptSet.add(ra.Id);
                            System.debug('Test'+ra.Id);

            }
            // Commented below line by Tharun to accept for ONLINE paymentType and Status__c == Remitted
            if(ra.SalesOrder__c!=null && 
               (( ra.PaymentType__c == Constants.ONLINE && ra.OnlinePaymentCleared__c != raOld.OnlinePaymentCleared__c && ra.OnlinePaymentCleared__c && ra.Status__c==Constants.RECEIVED_PAYMENT_STATUS) || 
                ( ra.PaymentType__c == Constants.WIRE_TRANSFER && ra.ReferenceNumber__c != raOld.ReferenceNumber__c && ( raOld.ReferenceNumber__c==null || raOld.ReferenceNumber__c=='') ) 
                //|| commented for deployment 
               // ( (ra.PaymentType__c == Constants.CREDIT_CARD || ra.PaymentType__c == Constants.POS ) && ra.ReferenceNumber__c != raOld.ReferenceNumber__c && ( raOld.ReferenceNumber__c==null || raOld.ReferenceNumber__c=='') )
               )){
                   //if(ra.SalesOrder__c!=null && ((ra.Status__c != raOld.Status__c && ra.Status__c==Constants.RECEIPT_STATUS_CLEARED) || (ra.Status__c != raOld.Status__c && ra.Status__c==Constants.RECEIPT_STATUS_CLEARED) || ( ra.ReferenceNumber__c != raOld.ReferenceNumber__c && ( raOld.ReferenceNumber__c==null || raOld.ReferenceNumber__c=='')) )){
                   //if(ra.SalesOrder__c!=null && ( (ra.PaymentType__c == Constants.ONLINE && ra.Status__c != raOld.Status__c && ra.Status__c == REMITTED_PAYMENT_STATUS) || (ra.Status__c != raOld.Status__c && ra.Status__c==Constants.RECEIPT_STATUS_CLEARED) || (ra.Status__c != raOld.Status__c && ra.Status__c==Constants.RECEIPT_STATUS_CLEARED) || ( ra.ReferenceNumber__c != raOld.ReferenceNumber__c && ( raOld.ReferenceNumber__c==null || raOld.ReferenceNumber__c=='')) )){
                   verifyPaymentforReservation.add(ra.SalesOrder__c);
               }
            if(ra.OpportunityEOI__c !=null && ra.ReferenceNumber__c != raOld.ReferenceNumber__c && ( raOld.ReferenceNumber__c==null || raOld.ReferenceNumber__c=='') ){
                EOIRecordsToUpdate.put(ra.OpportunityEOI__c,null);
            }
            /*if(ra.ServiceRequest__c != null && ra.Status__c != raOld.Status__c && ra.Status__c == Constants.RECEIPT_STATUS_CLEARED){
serviceRequestRAIds.add(ra.Id);
}*/
            if(ra.SalesOrder__c!=null && ra.Status__c != raOld.Status__c && ra.Status__c==Constants.REVERSED_PAYMENT_STATUS && defaultSRReason.contains(ra.StatusReason__c)){
                reversedRAIds.add(ra.Id);
            }else if(ra.SalesOrder__c!=null && ra.Status__c != raOld.Status__c && ra.Status__c==Constants.RECEIPT_STATUS_CLEARED ){
                clearedRAIds.add(ra.Id);
            }
           
            //To send charge collected payment confirmation mail
            if(ra.Status__c == 'Cleared' && ra.ServiceRequest__c != null && raOld.status__c != ra.Status__c){
                serviceRequestRAIds.add(ra.ServiceRequest__c);
                //Utilities.sendPaymentConfirmedMail(ra.Id);
            /*commented //Monika: Rebate Request changes **start
                HexaBPM__Service_Request__c srval = [Select id,SRType__c,HexaBPM__External_SR_Status__c  from HexaBPM__Service_Request__c where Id =: ra.ServiceRequest__c];
                if(srval.SRType__c == 'Rebate Request' && ra.PaymentType__c != 'Credit Note')

                {
                    HexaBPM__Step__c srStep = [SELECT Id,HexaBPM__Status__c,HexaBPM__SR__c,HexaBPM__Summary__c,HexaBPM__Step_Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :ra.ServiceRequest__c AND HexaBPM__Summary__c = 'Payment Verification' AND HexaBPM__Step_Status__c = 'Pending' LIMIT 1];

                    HexaBPM__Status__c stpstatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name ='Completed' LIMIT 1];
                    HexaBPM__SR_Status__c srstatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name ='Pending Finance Verification' LIMIT 1];
                    // Update the appropriate records
                    if (stpstatus!= null) {
                        srStep.HexaBPM__Status__c = stpstatus.id;
                    }
                    if (srstatus!=null) {
                        srval.HexaBPM__External_SR_Status__c = srstatus.id;
                    }
                    update srStep; 
                    update srval;                             
                }
                //Monika: Rebate Request changes **end */
                
            }

            //----- Update the SR when receipt is linked to the SR
            if(ra.ServiceRequest__c != null && raOld.ServiceRequest__c == null){
                serviceRequestReceiptMap.put(ra.ServiceRequest__c,ra);
            }
            
            if(ra.Status__c != raOld.Status__c && ra.Status__c == 'Reversed'){
                receiptAcknowledgementUnallocationMap.put(ra.id, ra);
            }
            
        }
        
        // FIN-75 Enhancement: Handle bulk installment allocation - creates separate receipts for other charge types
        // Moved to queueable to avoid trigger recursion
        if(!bulkAllocationReceiptIds.isEmpty()) {
            // Enqueue the bulk allocation processing to avoid trigger recursion
            System.enqueueJob(new BulkInstallmentAllocationQueueable(bulkAllocationReceiptIds));
        }
        
         //Premium Parking Receipt Automations - Added by Harsh@aldar
        if(premPark_ReceiptSet != null && premPark_ReceiptSet.size() > 0){
            PremPark_ReceiptHelper.handleAfterUpdate(premPark_ReceiptSet);
        }
        if(!ReceiptackForOtherCharge.isEmpty()){
           createOtherCharge(ReceiptackForOtherCharge); 
        }        
       
        
    /*ChargeFee-STARTED*/
        /*ChargeFee-END*/
    
        if(receiptAcknowledgementUnallocationMap != null){
            unApplyReceiptsBeforeDelete(receiptAcknowledgementUnallocationMap);
        }
        if(!verifyPaymentforReservation.isEmpty()){
            ReceiptAcknowledgementTriggerHelper.verifyAndReserveSO(verifyPaymentforReservation);
        }
        if(!EOIRecordsToUpdate.isEmpty()){
            UpdateEOISTatus(EOIRecordsToUpdate);
        }
        
        if(!reversedRAIds.isEmpty()){
            system.debug('--->'+reversedRAIds);
            DefaultAndTerminationUtility.verifyReversalandCreateDandTSR(reversedRAIds);
        }
        if(!clearedRAIds.isEmpty()){
            DefaultAndTerminationUtility.verifyandCloseSR(clearedRAIds);
        }
        
        if(!serviceRequestRAIds.isEmpty()){
            UpdateServiceRequest(serviceRequestRAIds);
        }

        if(!serviceRequestReceiptMap.isEmpty()){
            updateServiceForReceipts(serviceRequestReceiptMap);
        }

        //Harsh@Aldar RESALE MANAGER CHEQUE
        if(managerChequeReceiptAckList.size() > 0){
            ResaleUnitService.handleManagerChequeReceipt(managerChequeReceiptAckList);
        }
        //ASF-3309
        ReceiptAcknowledgementTriggerHelper.updateSalesOrderRelationshipTotals(newList,oldMap);
        //ASF-3559
        ReceiptAcknowledgementTriggerHelper.updateJointOwnerTotals(newList,oldMap);
        
        // Isolated callout logic for after update - called at the end after all other logic
        // FIN-144 by Sai Kumar: Refactored callout logic into isolated method for better maintainability
        handleCalloutForAfterUpdate(newList, oldMap);
    }
    
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) {
        unApplyReceiptsBeforeDelete(oldMap);
    }
    
    
    public static void unApplyReceiptsBeforeDelete(Map<Id,SObject> oldMap){
        //ReceiptAcknowledgement__c
        system.debug('oldmap::'+oldMap.keySet());
        try{
        List<ReceiptAllocation__c> allocationRecordList = new List<ReceiptAllocation__c>();
        for(ReceiptAllocation__c allocationRecord : [SELECT Id FROM ReceiptAllocation__c
                                                     WHERE ReceiptAcknowledgement__c IN: oldMap.keySet()
                                                     AND AmountApplied__c > 0]){
                                                         allocationRecord.AmountApplied__c = 0;
                                                         allocationRecordList.add(allocationRecord);
                                                     }
        Update allocationRecordList;
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'ReceiptAcknowledgementTrigger','ReceiptAcknowledgementTriggerHandler',''));
        }
    }
    // Added by Sanath H M - ASF-213
    public static void updateInstallmentOtherChargesOnDelete(Set<Id> receiptIds){
        List<InstallmentLines__c> installmentLineRecList = new List<InstallmentLines__c>();
        List<SalesOrderOtherCharges__c> otherChargeRecList = new List<SalesOrderOtherCharges__c>();
       
        
        for(ReceiptAllocation__c receiptAllocationRec : [SELECT Id,Unapply__c,AmountApplied__c,ReceiptAcknowledgement__r.Status__c,InstallmentLine__c,SalesSupportCost__c,InstallmentLine__r.AmountReceived__c,InstallmentLine__r.InvoicedAmount__c,InstallmentLine__r.SalesSupportCost__c,SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.InvoicedAmount__c, SalesOrderOtherCharges__r.AmountReceived__c,SalesOrderOtherCharges__r.SalesSupportCost__c  FROM ReceiptAllocation__c WHERE Id IN:receiptIds]){
            Decimal amount = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED ) ? receiptAllocationRec.AmountApplied__c  : 0 );
            Decimal amountRecieved = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c!= Constants.LINK_SENT && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c!= Constants.REVERSED_PAYMENT_STATUS ) ? receiptAllocationRec.AmountApplied__c : 0) ;
            Decimal salesSupportCost = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED )?  receiptAllocationRec.SalesSupportCost__c : 0 );
            
            system.debug('receiptIds:::'+receiptAllocationRec);
            if(receiptAllocationRec.InstallmentLine__c != null){
                InstallmentLines__c installmentLineRec = new InstallmentLines__c();
                installmentLineRec.id = receiptAllocationRec.InstallmentLine__c;
                if(receiptAllocationRec.InstallmentLine__r.AmountReceived__c !=null){   
                    installmentLineRec.AmountReceived__c =  receiptAllocationRec.InstallmentLine__r.AmountReceived__c-amount;
                }if(receiptAllocationRec.InstallmentLine__r.InvoicedAmount__c != null){  
                    installmentLineRec.InvoicedAmount__c = receiptAllocationRec.InstallmentLine__r.InvoicedAmount__c -amountRecieved; 
                }if(receiptAllocationRec.InstallmentLine__r.SalesSupportCost__c != null){ 
                    installmentLineRec.SalesSupportCost__c = receiptAllocationRec.InstallmentLine__r.SalesSupportCost__c - salesSupportCost ;
                }installmentLineRecList.add(installmentLineRec);
            }
            
            if(receiptAllocationRec.SalesOrderOtherCharges__c != null){
                SalesOrderOtherCharges__c otherChargeRec = new SalesOrderOtherCharges__c();
                otherChargeRec.Id = receiptAllocationRec.SalesOrderOtherCharges__c ;
                if(receiptAllocationRec.SalesOrderOtherCharges__r.InvoicedAmount__c != null){
                    otherChargeRec.InvoicedAmount__c = receiptAllocationRec.SalesOrderOtherCharges__r.InvoicedAmount__c- amount ;
                }if(receiptAllocationRec.SalesOrderOtherCharges__r.AmountReceived__c != null){
                    otherChargeRec.AmountReceived__c = receiptAllocationRec.SalesOrderOtherCharges__r.AmountReceived__c - amountRecieved ;
                }if(receiptAllocationRec.SalesOrderOtherCharges__r.SalesSupportCost__c != null){
                    otherChargeRec.SalesSupportCost__c = receiptAllocationRec.SalesOrderOtherCharges__r.SalesSupportCost__c-salesSupportCost ;
                }otherChargeRecList.add(otherChargeRec);
            }
        }
        if(!installmentLineRecList.isEmpty()){         update installmentLineRecList;
        }
        if(!otherChargeRecList.isEmpty()){         update otherChargeRecList;
        }
        
    } 

    public static void updateInstallmentOtherCharges(Set<Id> receiptIds){
        
        system.debug('receiptIds:::'+receiptIds);
        Map<Id,InstallmentLines__c> installmentLineMap = new  Map<Id,InstallmentLines__c>();
        Map<Id,SalesOrderOtherCharges__c> otherChargesMap = new  Map<Id,SalesOrderOtherCharges__c>();
        Set<Id> installmentLines = new Set<Id>();
        Set<Id> otherCharges = new Set<Id>();
        Map<Id,Decimal> recordInstallmentOtherChargeMap = new Map<Id,Decimal>();
        Map<Id,Decimal> installmentOtherSupportCost = new Map<Id,Decimal>();

           
     if(!receiptIds.isEmpty()){
             Integer AllocationNumber = Integer.valueOf(system.label.Receipt_Allocation_Count);             
             list<ReceiptAllocation__c> ReceiptAllocationList =  [SELECT Id,InstallmentLine__c,SalesOrderOtherCharges__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN:receiptIds and  LastModifiedDate=TODAY and ReceiptAcknowledgement__r.Allocation_Count__c >: AllocationNumber];
           // System.debug('@@First Condition@@'+ReceiptAllocationList);
             if(ReceiptAllocationList == null || ReceiptAllocationList.isempty() ){
                ReceiptAllocationList = [SELECT Id,InstallmentLine__c,SalesOrderOtherCharges__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN:receiptIds];
          // System.debug('@@Second Condition@@'+ReceiptAllocationList);
             }
             for(ReceiptAllocation__c receiptAllocation :ReceiptAllocationList){
               //  system.debug('receiptIds:::'+receiptAllocation);
                 if(receiptAllocation.InstallmentLine__c != null)
                     installmentLines.add(receiptAllocation.InstallmentLine__c);
                 if(receiptAllocation.SalesOrderOtherCharges__c != null)
                     otherCharges.add(receiptAllocation.SalesOrderOtherCharges__c);
             }
         }
        if(!installmentLines.isEmpty() || !otherCharges.isEmpty()){
            System.debug(installmentLines+'***installmentLines and otherCharges***'+otherCharges);
           
            for(ReceiptAllocation__c receiptAllocationRec : [SELECT AmountApplied__c,SalesOrderOtherCharges__c,InstallmentLine__r.isValidationBypass__c,SalesOrderOtherCharges__r.isValidationBypass__c, InstallmentLine__r.InvoicedAmount__c,InstallmentLine__r.AmountReceived__c,InstallmentLine__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentType__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.ClearedDate__c,ReceiptAcknowledgement__r.ReceiptDate__c, Unapply__c,SalesSupportCost__c,ReceiptAcknowledgement__r.Name FROM ReceiptAllocation__c WHERE (InstallmentLine__c IN:installmentLines OR SalesOrderOtherCharges__c IN:otherCharges) ORDER BY InstallmentLine__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.Status__c]){
                system.debug('receiptAllocationRec:::'+receiptAllocationRec);
                Id installmentLineId = (receiptAllocationRec.InstallmentLine__c!=null ? receiptAllocationRec.InstallmentLine__c : null );
                Id otherChargesId = (receiptAllocationRec.SalesOrderOtherCharges__c!=null ? receiptAllocationRec.SalesOrderOtherCharges__c : null ); 
                Decimal amount = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED ) ? receiptAllocationRec.AmountApplied__c  : 0 );
                Decimal amountRecieved = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c!= Constants.LINK_SENT && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c!= Constants.REVERSED_PAYMENT_STATUS ) ? receiptAllocationRec.AmountApplied__c : 0) ;
                Decimal salesSupportCost = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED )?  receiptAllocationRec.SalesSupportCost__c : 0 );
                System.debug(installmentLineId+'***salesSupportCost***'+salesSupportCost);
                if(installmentLineId !=null && amount !=null){
                    InstallmentLines__c installmentLineRec = new InstallmentLines__c();
                    amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(installmentLineId))? recordInstallmentOtherChargeMap.get(installmentLineId) : 0);
                    amountRecieved = amountRecieved + ((installmentLineMap!=null && installmentLineMap.containsKey(installmentLineId))? installmentLineMap.get(installmentLineId).AmountReceived__c : 0);
                    salesSupportCost = (salesSupportCost!=null ? salesSupportCost : 0) + ((installmentOtherSupportCost!=null && installmentOtherSupportCost.containsKey(installmentLineId))? installmentOtherSupportCost.get(installmentLineId) : 0);
                    installmentLineRec.Id = installmentLineId ;
                    installmentLineRec.InvoicedAmount__c = amount ;
                    installmentLineRec.AmountReceived__c = amountRecieved ;
                                           
                   if(installmentLineMap.get(installmentLineId)!=null){
                            installmentLineRec.PaymentClearanceDate__c= installmentLineMap.get(installmentLineId).PaymentClearanceDate__c;
                            installmentLineRec.PaymentReceiptDate__c= installmentLineMap.get(installmentLineId).PaymentReceiptDate__c; 
                            installmentLineRec.PaymentType__c=   installmentLineMap.get(installmentLineId).PaymentType__c;
                            installmentLineRec.Last_Cleared_Receipt__c=installmentLineMap.get(installmentLineId).Last_Cleared_Receipt__c;
                    }
                  
                    //Updated for HO
                    if(receiptAllocationRec.ReceiptAcknowledgement__c!=null && receiptAllocationRec.ReceiptAcknowledgement__r.ClearedDate__c!=null 
                         && receiptAllocationRec.ReceiptAcknowledgement__r.PaymentType__c!='Credit Note'){  
                        if(installmentLineMap.get(installmentLineId)==null ||  
                           installmentLineMap.get(installmentLineId).PaymentClearanceDate__c ==null || receiptAllocationRec.ReceiptAcknowledgement__r.ClearedDate__c>installmentLineMap.get(installmentLineId).PaymentClearanceDate__c) {
                            installmentLineRec.PaymentClearanceDate__c= receiptAllocationRec.ReceiptAcknowledgement__r.ClearedDate__c;
                            installmentLineRec.PaymentReceiptDate__c= receiptAllocationRec.ReceiptAcknowledgement__r.ReceiptDate__c; 
                            installmentLineRec.PaymentType__c=   receiptAllocationRec.ReceiptAcknowledgement__r.PaymentType__c;
                            installmentLineRec.Last_Cleared_Receipt__c=receiptAllocationRec.ReceiptAcknowledgement__c;
                           }                          
                         }
                   
                   
                    installmentLineRec.SalesSupportCost__c = salesSupportCost ;
                    //InstallmentLine__r.isValidationBypass__c,SalesOrderOtherCharges__r.isValidationBypass__c
                    if(BlkReceiptAckController.isBlkReceiptAckAPI && receiptAllocationRec.InstallmentLine__r.isValidationBypass__c != null ){
                        installmentLineRec.isValidationBypass__c=!(receiptAllocationRec.InstallmentLine__r.isValidationBypass__c);
                    } 
                    installmentLineMap.put(installmentLineId,installmentLineRec);
                    recordInstallmentOtherChargeMap.put(installmentLineId,amount);
                    installmentOtherSupportCost.put(installmentLineId,salesSupportCost);
                }
                if(otherChargesId !=null && amount !=null){
                    amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(otherChargesId))? recordInstallmentOtherChargeMap.get(otherChargesId) : 0);
                    SalesOrderOtherCharges__c otherChargeRec = new SalesOrderOtherCharges__c();
                    amountRecieved = amountRecieved + ((otherChargesMap!=null && otherChargesMap.containsKey(otherChargesId))? otherChargesMap.get(otherChargesId).AmountReceived__c : 0);
                    salesSupportCost = salesSupportCost + ((installmentOtherSupportCost!=null && installmentOtherSupportCost.containsKey(otherChargesId))? installmentOtherSupportCost.get(otherChargesId) : 0);
                    otherChargeRec.Id = otherChargesId ;
                    otherChargeRec.InvoicedAmount__c = amount ;
                    otherChargeRec.AmountReceived__c = amountRecieved ;
                    otherChargeRec.SalesSupportCost__c = salesSupportCost ;
                    if(BlkReceiptAckController.isBlkReceiptAckAPI  && receiptAllocationRec.SalesOrderOtherCharges__r.isValidationBypass__c != null ){
                        otherChargeRec.isValidationBypass__c=!(receiptAllocationRec.SalesOrderOtherCharges__r.isValidationBypass__c); 
                    } 
                    otherChargesMap.put(otherChargesId,otherChargeRec);
                    recordInstallmentOtherChargeMap.put(otherChargesId,amount);
                    installmentOtherSupportCost.put(otherChargesId,salesSupportCost);
                }
            }
            
            System.debug(installmentLineMap+'***installmentLineList and otherChargesList***'+otherChargesMap);
            //----- Update all the installment lines with the amount invoiced
            if(installmentLineMap!=null || installmentLineMap.size()>0){
                update installmentLineMap.values() ; 
            }
            
            //----- Update all the other charges with the amount invoiced
            if(otherChargesMap!=null || otherChargesMap.size()>0){
                update otherChargesMap.values() ; 
            }
        }
    }
    
    public static void UpdateEOISTatus( map<Id,OpportunityEOI__c> eoiRecords ){
        // Added by sujesh on 13March
        // Code has been modified in such a way all the reciepts should be 'Received' with Reference number before the Stauts of EOI to change to Paid. 
        system.debug('+++eoiRecords' + eoiRecords);
        Map<Id, List<ReceiptAcknowledgement__c>> receiptAcknowledgmentMap = new Map<Id, List<ReceiptAcknowledgement__c>>();
        eoiRecords = new map<Id,OpportunityEOI__c>([select id, NumberOfUnits__c from OpportunityEOI__c where id in :eoiRecords.keySet() and Status__c = :Constants.EOISTATUS_UNITCONFIRMED]);
        List<ReceiptAcknowledgement__c> receiptAcknowledgmentList = [SELECT Id, ReferenceNumber__c, OpportunityEOI__c FROM ReceiptAcknowledgement__c WHERE OpportunityEOI__c IN: eoiRecords.keySet()];
        
        system.debug('receiptAcknowledgmentList::'+receiptAcknowledgmentList);
        if(!receiptAcknowledgmentList.isEmpty()){for(ReceiptAcknowledgement__c ra: receiptAcknowledgmentList){if(ra.ReferenceNumber__c != null && ra.ReferenceNumber__c != ''){ List<ReceiptAcknowledgement__c> rackList = receiptAcknowledgmentMap.get(ra.OpportunityEOI__c) != null ? receiptAcknowledgmentMap.get(ra.OpportunityEOI__c) : new List<ReceiptAcknowledgement__c>();  rackList.add(ra); receiptAcknowledgmentMap.put(ra.OpportunityEOI__c, rackList);
                }
            }
        }
        system.debug('receiptAcknowledgmentMap::'+receiptAcknowledgmentMap);
        for(OpportunityEOI__c tempEoi : eoiRecords.values()){ if(receiptAcknowledgmentMap.get(tempEoi.id).size() == tempEoi.NumberOfUnits__c){                tempEoi.Status__c = Constants.EOI_PAID;
            }
        }
        if(!eoiRecords.isEmpty()){            update eoiRecords.values();
        }
        
    }
    
    public static void UpdateServiceRequest(Set<Id> serviceRequestIds){
        List<HexaBPM__Service_Request__c> updateSR = new List<HexaBPM__Service_Request__c>();
        for(HexaBPM__Service_Request__c sr : [SELECT Id, PaymentConfirmed__c from HexaBPM__Service_Request__c where Id in: serviceRequestIds]){
            sr.PaymentConfirmed__c = TRUE;
            updateSR.add(sr);
        }
        
        if(!updateSR.isEmpty())
            update updateSR;
    }
    
    public static void updateCase(Set<Id> casesIds){
        List<Case> updateCases = new List<Case>();
        for(Case caseRecord : [SELECT Id, Status, Recordtype_Name__c from Case where Id in: casesIds]){
            if(caseRecord.Recordtype_Name__c != 'Third_Party_Payment_NOC'){
            caseRecord.Status = Constants.CLOSED_CASE;
            updateCases.add(caseRecord);
            }
        }
        
        if(!updateCases.isEmpty())
            update updateCases;
    }
//     ASF-1454 : yenshul@Aldar
    public static void onSalesOrderChange(List<ReceiptAcknowledgement__c> receiptAcknowledgementList){
        Set<Id> salesOrderIds  = new Set<Id>();
        for(ReceiptAcknowledgement__c rAck: receiptAcknowledgementList){
            salesOrderIds.add(rAck.SalesOrder__c);
        }
        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>([Select Id, Account__c, Contact__c,Opportunity__c, SalesManager__c FROM SalesOrder__c WHERE Id in: salesOrderIds]);
        
        
        for(ReceiptAcknowledgement__c rAck: receiptAcknowledgementList){
            rAck.Opportunity__c = salesOrderMap.get(rAck.SalesOrder__c).Opportunity__c;
            rAck.Account__c = salesOrderMap.get(rAck.SalesOrder__c).Account__c;
            rAck.Contact__c = salesOrderMap.get(rAck.SalesOrder__c).Contact__c;
            rAck.Sales_Manager__c = salesOrderMap.get(rAck.SalesOrder__c).SalesManager__c;
        }
    }
    // ASF-1454 : yenshul@Aldar
/*    public static void onSalesOrderChange(List<ReceiptAcknowledgement__c> receiptAcknowledgementList, Map<Id, Id> raIdToOldSOIdMap){
        Set<Id> salesOrderIds  = new Set<Id>();
        Set<Id> oldSalesOrderIds = new Set<Id>();
        Map<Id, Set<Id>> accIdToRelatedAccs = new Map<Id, Set<Id>>();
        raIdToOldSOIdMap = raIdToOldSOIdMap != null ? raIdToOldSOIdMap : new Map<Id, Id>();
        
        system.debug('receiptAcknowledgementList::'+receiptAcknowledgementList);
        system.debug('raIdToOldSOIdMap::'+raIdToOldSOIdMap);
        
        for(ReceiptAcknowledgement__c rAck: receiptAcknowledgementList){
            salesOrderIds.add(rAck.SalesOrder__c);
            if(raIdToOldSOIdMap.containsKey(rAck.Id)){
                if(raIdToOldSOIdMap.get(rAck.Id) != null){
                    oldSalesOrderIds.add(raIdToOldSOIdMap.get(rAck.Id));
                }else{
                    raIdToOldSOIdMap.remove(rAck.Id);
                }
            }
        }

        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>(
                                                    [SELECT Id, Account__c, Contact__c, Opportunity__c, SalesManager__c 
                                                     FROM SalesOrder__c 
                                                     WHERE Id IN: salesOrderIds 
                                                            OR Id IN: oldSalesOrderIds ]);
        Map<Id, Id> oldSOIdToAccIdMap = new Map<Id, Id>();
        if(!oldSalesOrderIds.isEmpty()){
            for(Id oldSOId: oldSalesOrderIds){
                Id accId = salesOrderMap.containsKey(oldSOId) ? salesOrderMap.get(oldSOId).Account__c : null;
                if(accId != null){
                    oldSOIdToAccIdMap.put(oldSOId, accId);
                }
            }
            
            system.debug('oldSOIdToAccIdMap:::'+oldSOIdToAccIdMap);
            
            if(!oldSOIdToAccIdMap.isEmpty()){
                for(AccountRelationship__c ar : [SELECT Id, Account__c, RelatedAccount__c, RelationshipType__c 
                                                 FROM AccountRelationship__c 
                                                 WHERE Account__c IN: oldSOIdToAccIdMap.values()]){
                                                     system.debug('ar::'+ar);
                    if(accIdToRelatedAccs.containsKey(ar.Account__c)){
                        accIdToRelatedAccs.get(ar.Account__c).add(ar.RelatedAccount__c);
                    }else{
                        accIdToRelatedAccs.put(ar.Account__c, new Set<Id>{ar.RelatedAccount__c} );
                    }
                }
            }
        }
        
        for(ReceiptAcknowledgement__c rAck: receiptAcknowledgementList){
            if(salesOrderMap.containsKey(rAck.SalesOrder__c)){
                Boolean newSOIsValid = true;

                Id newAccId = salesOrderMap.get(rAck.SalesOrder__c).Account__c;
                Id oldSOId = raIdToOldSOIdMap.containsKey(rAck.Id) ? raIdToOldSOIdMap.get(rAck.Id) : null;
                if( newAccId != null && oldSOId != null && oldSOIdToAccIdMap.containsKey(oldSOId) ){
                    Id oldAccId = oldSOIdToAccIdMap.get(oldSOId);
                    if( oldAccId != null && newAccId != oldAccId ){
                        Set<Id> oldRelatedAccIds = accIdToRelatedAccs.containsKey(oldAccId) ? accIdToRelatedAccs.get(oldAccId) : new Set<Id>();
                        if(!oldRelatedAccIds.contains(newAccId)){
                            newSOIsValid = false;
                        }
                    }
                }

                if(newSOIsValid){
                    rAck.Opportunity__c = salesOrderMap.get(rAck.SalesOrder__c).Opportunity__c;
                    rAck.Account__c = salesOrderMap.get(rAck.SalesOrder__c).Account__c;
                    rAck.Contact__c = salesOrderMap.get(rAck.SalesOrder__c).Contact__c;
                    rAck.Sales_Manager__c = salesOrderMap.get(rAck.SalesOrder__c).SalesManager__c;
                }else{
                    rAck.addError( System.Label.ReceiptAckSalesOrderChangeError1 ); // 'Invalid Sales Order. Selected sales order is not owned by the same Customer or any of it\'s relatives.'
                }
            }
        }
    }*/

    public static void updateServiceForReceipts(Map<Id,ReceiptAcknowledgement__c> serviceRequestReceiptMap){
        List<HexaBPM__Service_Request__c> updateSRList = new List<HexaBPM__Service_Request__c>();

        for(Id recordId : serviceRequestReceiptMap.keySet()){
            HexaBPM__Service_Request__c serviceRequestRec = new HexaBPM__Service_Request__c();
            serviceRequestRec.Id = recordId ;
            serviceRequestRec.IsChargeReceiptCreated__c = TRUE;
            updateSRList.add(serviceRequestRec);
        }
        
        if(!updateSRList.isEmpty())
            update updateSRList;
        
    }
    
    /*public static void verifyAndReserveSO(set<ID> soIDs ){
list<SalesOrder__c> soRecords =[select id,status__c from SalesOrder__c where Id IN:soIDs AND status__c = :constants.STATUS_RESERVATION_IN_PROGRESS];
for(SalesOrder__c tempSO: soRecords){
tempSO.Status__c = Constants.STATUS_RESERVED;
}
if(!soRecords.isEmpty()){
update soRecords;
}
}*/
    //Description : This method helps in updating the LPC Freeze Date and LPC Freeze Until Date on Installment Lines for the Mortgage Cheque payment types
  /**** REMOVED FREEZE UPDATE LOGIC ***  public static void freezeLPCForMortgagePaymentTypes(List<ReceiptAcknowledgement__c> newReceiptAcknowledgementList,Map<Id, SObject> oldReceiptAcknowledgementMap){
        Set<Id> eligibleReceiptAcknowledgementLPCFreezeSet = new Set<Id>();
        Map<Id,Id> impactedSaleOrderAndReceiptAcknowledgementIdMap = new Map<Id,Id>();
        Map<Id,Date> impactedReceiptAcknowledgementIdReceiptDateMap = new Map<Id,Date>();
        List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
        for(ReceiptAcknowledgement__c receiptAck : newReceiptAcknowledgementList){
            ReceiptAcknowledgement__c raOld = (ReceiptAcknowledgement__c)oldReceiptAcknowledgementMap.get(receiptAck.Id);
           //*** if(receiptAck.PaymentType__c == Constants.MORTGAGE_CHEQUE && raOld.ReceiptDate__c == null && receiptAck.ReceiptDate__c <> null){
          /**  if(receiptAck.PaymentType__c == Constants.MORTGAGE_CHEQUE && raOld.ChequeReceivedDate__c == null && receiptAck.ChequeReceivedDate__c <> null){ //*** Added based on Syed Recent Request*** JIRA-ASF-2662 ***
                /**** REMOVED FREEZE UPDATE LOGIC ***  if(receiptAck.SalesOrder__c <> null) {
                    impactedSaleOrderAndReceiptAcknowledgementIdMap.put(receiptAck.SalesOrder__c,receiptAck.Id);                               
                } ***/
                //impactedReceiptAcknowledgementIdReceiptDateMap.put(receiptAck.Id,receiptAck.ReceiptDate__c);
               //   impactedReceiptAcknowledgementIdReceiptDateMap.put(receiptAck.Id,receiptAck.ChequeReceivedDate__c); //*** Added based on Syed Recent Request **** JIRA-ASF-2662 *******//
        /**** REMOVED FREEZE UPDATE LOGIC ***      } **/
     //   } **/
        //Traverse through all the service requests of the related sales orders with Type as 'Handover' but handover not completed
     /**** REMOVED FREEZE UPDATE LOGIC ***     if(!impactedSaleOrderAndReceiptAcknowledgementIdMap.isEmpty()) {
            for(HexaBPM__Service_Request__c serviceRqst : [SELECT SalesOrder__c from HexaBPM__Service_Request__c WHERE SalesOrder__c IN :impactedSaleOrderAndReceiptAcknowledgementIdMap.keySet() AND SRType__c =:Constants.HANDOVER_RT AND HandoverDetail__r.HandoverCompleted__c = false]){
                eligibleReceiptAcknowledgementLPCFreezeSet.add(impactedSaleOrderAndReceiptAcknowledgementIdMap.get(serviceRqst.SalesOrder__c));
            }
        } 
        //Update Installation Lines, traversing through Receipt Allocations of impacted receipt acknowledgements
        if(!eligibleReceiptAcknowledgementLPCFreezeSet.isEmpty()){
            for(ReceiptAllocation__c eachreceiptAllocation : [SELECT InstallmentLine__c,ReceiptAcknowledgement__c from ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN :eligibleReceiptAcknowledgementLPCFreezeSet]){
                if(!impactedReceiptAcknowledgementIdReceiptDateMap.isEmpty() && impactedReceiptAcknowledgementIdReceiptDateMap.containsKey(eachreceiptAllocation.ReceiptAcknowledgement__c)){
                    installmentLinesToUpdate.add(new InstallmentLines__c(Id = eachreceiptAllocation.InstallmentLine__c,LPCFreezeDate__c = impactedReceiptAcknowledgementIdReceiptDateMap.get(eachreceiptAllocation.ReceiptAcknowledgement__c),LPCFreezeUntilDate__c = impactedReceiptAcknowledgementIdReceiptDateMap.get(eachreceiptAllocation.ReceiptAcknowledgement__c).addMonths(6)));
                }
            }
        }
        if(!installmentLinesToUpdate.isEmpty()){
            update installmentLinesToUpdate;
//            LPCCalloutHelper.prepareDataForERPSync(installmentLinesToUpdate);
        }
    } ***/
  
  /*ChargeFee-STARTED*/
    public static void syncRelatedOtherServiceChargeDetails(Set<Id> receiptAcknowledgementIdSet){
         Set<Id> otherChargeIdsToSync = new Set<Id>();
        List<SalesOrderOtherCharges__c> failureSOUpdate = new List<SalesOrderOtherCharges__c>();
        for(ReceiptAllocation__c eachAllocation : [SELECT SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.SyncStatus__c from ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN :receiptAcknowledgementIdSet AND SalesOrderOtherCharges__r.SyncStatus__c IN (:Constants.STATUS_IN_PROGRESS,:Constants.STATUS_FAILED) AND ReceiptAcknowledgement__r.Receipt_Type__c = 'Charge Fee']){
            otherChargeIdsToSync.add(eachAllocation.SalesOrderOtherCharges__c);
            if(eachAllocation.SalesOrderOtherCharges__r.SyncStatus__c == Constants.STATUS_FAILED){
                SalesOrderOtherCharges__c soUpd = new SalesOrderOtherCharges__c();
                soUpd.Id = eachAllocation.SalesOrderOtherCharges__c;
                soUpd.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                failureSOUpdate.add(soUpd);
            }
        }
        if(!failureSOUpdate.isEmpty()){
            update failureSOUpdate;
        }
        if(!otherChargeIdsToSync.IsEmpty()){
            ALDOC_OtherChargesHelper.doOtherChargeCallout(new List<Id>(otherChargeIdsToSync),null);
        }
    }
    
    
    public static void autoCloseServiceChargeFeeStepOnSR(List<ReceiptAcknowledgement__c> newReceiptAcknowledgementList,Map<Id, SObject> oldReceiptAcknowledgementMap,String SourceOfInvocation){
        Map<String,HexaBPM__Status__c> stepStatusMap = new Map<String,HexaBPM__Status__c>();
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
        Set<Id> srIdSet = new Set<Id>();
        List<PaymentGatewayEventManager__e> pgEventList = new List<PaymentGatewayEventManager__e>();
        for(ReceiptAcknowledgement__c receiptAck : newReceiptAcknowledgementList){
            ReceiptAcknowledgement__c raOld = oldReceiptAcknowledgementMap <> null ? (ReceiptAcknowledgement__c)oldReceiptAcknowledgementMap.get(receiptAck.Id) : null;
            if(Auth.CommunitiesUtil.isGuestUser()){
                //Publish Platform Event
                PaymentGatewayEventManager__e pgEvent = new PaymentGatewayEventManager__e(Receipt_Acknowledgement_Id__c = receiptAck.Id,Receipt_Type__c = receiptAck.Receipt_Type__c);
                pgEventList.add(pgEvent);
            } 
            //Proceed in w/o sharing mode
            else{
                if(receiptAck.Receipt_Type__c == 'Charge Fee' && receiptAck.Status__c == Constants.RECEIVED_PAYMENT_STATUS && (SourceOfInvocation == 'PlatformEventTrigger' || (SourceOfInvocation == 'RAObjectTrigger' && raOld <> null &&  receiptAck.Status__c <> raOld.Status__c))){
                    srIdSet.add(receiptAck.ServiceRequest__c);
                }
            }
        }
        if(!pgEventList.IsEmpty()){
            EventBus.publish(pgEventList);
        }        
        for(HexaBPM__Status__c srStepStatus : [SELECT Id,Name FROM HexaBPM__Status__c WHERE Name IN ('Completed')]){
            stepStatusMap.put(srStepStatus.Name,srStepStatus);
        }
        if(!stepStatusMap.IsEmpty()){
            for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdSet AND HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__Step_Status__c = 'Pending']){
                if(stepStatusMap.containsKey('Completed')){
                    srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                    srStepsToUpdateList.add(srStep);
                }               
            }
            if(!srStepsToUpdateList.IsEmpty()){
                update srStepsToUpdateList;
            }
        } 
    }
    public static void autoCloseServiceChargeFeeStepOnSROnReceiptInsert(set<Id> srIds){
        Id completedSts = ServiceRequestTriggerHelper.getStepStatus().get(Constants.COMPLETED_STATUS)?.Id;
        List<HexaBPM__Step__c> srStepsToInsertList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIds AND HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__Step_Status__c = 'Pending' AND HexaBPM__SR__r.SRType__c='Property Transfer (Off Plan)' ]){
            srStep.HexaBPM__Status__c = completedSts;
            srStepsToInsertList.add(srStep);
        }
        if(!srStepsToInsertList.IsEmpty()){
            update srStepsToInsertList;
        }
    }
    
public static void receiptSharing(List<SObject> newList){
        List<ReceiptAcknowledgement__Share> updateReceiptList = new List<ReceiptAcknowledgement__Share>();
        Map<Id,HexaBPM__Service_Request__c> serviceRequestmap = new Map<Id,HexaBPM__Service_Request__c>();
        Set<Id> serviceRequestIdSet = new Set<Id>();
        for(ReceiptAcknowledgement__c receipt:(List<ReceiptAcknowledgement__c>)newList){
            if(receipt.ServiceRequest__c <> null && receipt.Receipt_Type__c == 'Charge Fee'){
                serviceRequestIdSet.add(receipt.ServiceRequest__c);
            }
        }
        if(!serviceRequestIdSet.isEmpty()){
            Map<Id,Id> reciptOwnerSharingMap = new Map<Id,Id>();
            for(HexaBPM__Service_Request__c sr:[SELECT Id,OwnerId,ChargeType__c FROM HexaBPM__Service_Request__c WHERE Id IN: serviceRequestIdSet]){ 
                serviceRequestmap.put(sr.Id,sr);
            }
            if(!serviceRequestmap.isEmpty()){
                for(ReceiptAcknowledgement__c receipt:(List<ReceiptAcknowledgement__c>)newList){
                    if(receipt.Receipt_Type__c == 'Charge Fee' && receipt.ServiceRequest__c <> null && serviceRequestmap.containsKey(receipt.ServiceRequest__c)){
                        reciptOwnerSharingMap.put(receipt.Id,serviceRequestmap.get(receipt.ServiceRequest__c).OwnerId);
                    }
                }
               if(!reciptOwnerSharingMap.isEmpty())
                ShareHelper.shareReceipt(reciptOwnerSharingMap,Constants.EDIT_ACCESS);
            }
        } 
    }
    /*ChargeFee-END*/
    
    /**
     * Handles callout logic for after insert event
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newList List of new ReceiptAcknowledgement records (Trigger.new)
     * @param oldMap Map of old ReceiptAcknowledgement records (Trigger.oldMap - null for insert)
     */
    private void handleCalloutForAfterInsert(List<SObject> newList, Map<Id, SObject> oldMap) {
        // FIN-144 by Sai Kumar: Check if both ReceiptAcknowledgement and ReceiptAllocation are being created in the same transaction
        // If so, skip the web service call from ReceiptAcknowledgement trigger to avoid duplicate calls
        // The web service call will be made from ReceiptAllocation trigger instead
        if (ReceiptAcknowledgementController.isCreatingBothReceiptAndAllocation) {
            System.debug('FIN-144: Skipping ReceiptAcknowledgement web service call - both ReceiptAcknowledgement and ReceiptAllocation are being created in same transaction');
            return;
        }
        
        // Step 1: Initial raIds collection using same logic as before
        List<Id> initialRaIds = new List<Id>();
        //Added by Tajinkumar for Syncing Lean & Stripe Receipts with ERP
        List<Id> stripeOrLeanPaymentReceiptIds = new List<Id>();
        
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            if (ra.SyncStatus__c == Constants.STATUS_IN_PROGRESS && ra.ReferenceNumber__c != null && ra.PaymentType__c != CREDITNOTE && ra.SalesOrder__c != null && ra.PaymentType__c !='Direct Debit') {
                if (ra.PaymentType__c == Constants.ONLINE && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS) {
                    initialRaIds.add(ra.Id);
                } else if (ra.PaymentType__c != Constants.ONLINE) {
                    initialRaIds.add(ra.Id);
                }
                if(((ra.PaymentType__c == Constants.ONLINE && ra.Payment_Gateway__c == 'Stripe') || (ra.PaymentType__c == Constants.WIRE_TRANSFER && ra.Payment_Gateway__c == 'Lean'))  && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS){
                    stripeOrLeanPaymentReceiptIds.add(ra.Id);
                } 
            }
        }
        
        system.debug('Initial raIds::'+initialRaIds);
        system.debug('Initial raIds size::'+initialRaIds.size());
        system.debug('stripeOrLeanPaymentReceiptIds::'+ stripeOrLeanPaymentReceiptIds);
        
        // Step 2: For insert, all initial raIds are final raIds (no field change detection needed)
        List<Id> finalRaIds = initialRaIds;
        
        system.debug('Final raIds::'+finalRaIds);
        system.debug('Final raIds size::'+finalRaIds.size());
        
        User usr = Utilities.getLoggedInUserDetail();
        if (!finalRaIds.isEmpty() && !System.IsBatch() && usr.Profile.Name != Constants.INTEGRATION_PROFILE) {
            ReceiptCalloutHelper.PrepareDataForCallout(finalRaIds);
        } else if(!stripeOrLeanPaymentReceiptIds.isEmpty() && !System.IsBatch()){
            ReceiptCalloutHelper.PrepareDataForCallout(stripeOrLeanPaymentReceiptIds);
        }
    }
    
    
    /**
     * Handles callout logic for after update event
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newList List of new ReceiptAcknowledgement records (Trigger.new)
     * @param oldMap Map of old ReceiptAcknowledgement records (Trigger.oldMap)
     */
    private void handleCalloutForAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        // Step 1: Collect raIds that need callout based on sync status
        List<Id> raIdsForCallout = new List<Id>();
        
        for(ReceiptAcknowledgement__c ra : (List<ReceiptAcknowledgement__c>)newList){
            if (ra.SyncStatus__c == Constants.STATUS_IN_PROGRESS && ra.ReferenceNumber__c != null) {
                if (ra.PaymentType__c == Constants.ONLINE && (ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS || ra.Status__c == Constants.RECEIPT_STATUS_CLEARED)) {
                    raIdsForCallout.add(ra.Id);
                } else if (ra.PaymentType__c != Constants.ONLINE) {
                    raIdsForCallout.add(ra.Id);
                }
            }
        }
        
        system.debug('raIdsForCallout::'+raIdsForCallout);
        system.debug('raIdsForCallout size::'+raIdsForCallout.size());
        
        User usr = Utilities.getLoggedInUserDetail();
        if (!raIdsForCallout.isEmpty() && !System.IsBatch()) {
            if(usr.Profile.Name != Constants.INTEGRATION_PROFILE) {
                system.debug('###raIdsForCallout###'+raIdsForCallout);
                ReceiptCalloutHelper.PrepareDataForCallout(raIdsForCallout);
            }            
            syncRelatedOtherServiceChargeDetails(new Set<Id>(raIdsForCallout));
        }
    }
    
    /**
     * Checks if any integration fields have changed between old and new ReceiptAcknowledgement records
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newRecord The new ReceiptAcknowledgement record
     * @param oldRecord The old ReceiptAcknowledgement record
     * @param integrationFields Map of integration fields to check
     * @return Boolean indicating if any integration fields have changed
     */
    private Boolean checkIntegrationFieldChanges(ReceiptAcknowledgement__c newRecord, ReceiptAcknowledgement__c oldRecord, 
        Map<String, ReceiptAcknowledgement_Integration_Field__c> integrationFields) {
        
        for (String field : integrationFields.keySet()) {
            if (newRecord.get(field) != oldRecord.get(field)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Handles checking and updating sync status based on integration field changes
     * FIN-144 by Sai Kumar: Follows the same pattern as AccountTriggerHandler
     * @param newRecord The new ReceiptAcknowledgement record
     * @param oldRecord The old ReceiptAcknowledgement record
     * @param integrationFields Map of integration fields to check
     */
    private void handleIntegrationFieldChanges(ReceiptAcknowledgement__c newRecord, ReceiptAcknowledgement__c oldRecord, 
        Map<String, ReceiptAcknowledgement_Integration_Field__c> integrationFields) {
            
        Boolean hasChanges = false;
        for (String field : integrationFields.keySet()) {
            if (newRecord.get(field) != oldRecord.get(field)) {
                hasChanges = true;
                break;
            }
        }

        if (hasChanges) {
            newRecord.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            newRecord.IsReceiptAcknowledgementChange__c = true;
        }
    }
    
    public static void createOtherCharge(List<ReceiptAcknowledgement__c> newList){  
        Decimal chargeAmount = 0;
        Decimal vatAmount = 0;
        Decimal amountWithoutVAT = 0;
        list<SalesOrderOtherCharges__c> otcharge = new list<SalesOrderOtherCharges__c>();
        for(ChargeRule__c chargeRule : [SELECT ChargeAmount__c,ChargePercentage__c,VATChanges__c from ChargeRule__c WHERE SRType__c ='Cheque Replacement' AND ChargeType__c ='Bounced Cheques' AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]){
            amountWithoutVAT = chargeRule.ChargeAmount__c;
            vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
            chargeAmount = amountWithoutVAT + vatAmount;
        }
        SalesOrderOtherCharges__c rack = new SalesOrderOtherCharges__c();
        if(chargeAmount >0){
            for(ReceiptAcknowledgement__c sRRecord : newList){
                rack.Account__c = sRRecord.Account__c;
                rack.SalesOrder__c = sRRecord.SalesOrder__c;
                rack.Amount__c = chargeAmount;
                rack.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE;
                rack.SubType__c='Bounced Cheque Amount';
                rack.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                rack.VATAmount__c = vatAmount;
                rack.AmountWithoutVAT__c = amountWithoutVAT;
                otcharge.add(rack);
            }
            if(!otcharge.isEmpty()){
                insert rack;   
            }
        } 
    }
}