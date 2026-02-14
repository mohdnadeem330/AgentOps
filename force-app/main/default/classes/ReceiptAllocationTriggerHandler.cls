public without sharing class ReceiptAllocationTriggerHandler extends TriggerHandler{
    
    // FIN-140: Static flag to prevent trigger execution during specific operations
    // Added by Sai Kumar
    public static boolean skipReceiptAllocationTrigger = false;
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        Set<Id> raIds = new Set<Id>();
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            if(receiptAllocation.AmountApplied__c !=null){
                receiptAllocation.DateOfApplication__c = Date.Today();
                receiptAllocation.AmountApplied__c = receiptAllocation.AmountApplied__c.setScale(2);
            }
            // FIN-144 by Sai Kumar: Inactiving the flow 'Update Receipt Allocation field' and adding logic in trigger itself
            if(receiptAllocation.InstallmentLine__c !=null){
                receiptAllocation.TypeOfInvoice__c = 'Installment';
        }
        }
        
        
        validateAmountApplied(newList,null);
        validateInstallmentsNumbers(newList,null);
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Set<Id> raIds = new Set<Id>();
        Set<Id> rAllocIdset = new Set<Id>();
        Set<Id> clearedRAIds = new Set<Id>();
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            if (receiptAllocation.IsStopSyncingWithERP__c == false) {
                raIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            }
            if(receiptAllocation.InstallmentLine__c !=null){
                rAllocIdset.add(receiptAllocation.Id);
            }
        }
        
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !raIds.isEmpty()) {
            List<ReceiptAcknowledgement__c> darnaReceiptAcknowledgementToCleared = new List<ReceiptAcknowledgement__c>();
            
            List<ReceiptAcknowledgement__c> rackList = ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(new List<Id>(raIds));
            for (ReceiptAcknowledgement__c ra: rackList) {
                if(ra.Case__c != null && ra.RedemptionReferenceCode__c != null){
                    ra.Status__c = Constants.RECEIPT_STATUS_CLEARED;
                    darnaReceiptAcknowledgementToCleared.add(ra);
                }
            }
            if(!darnaReceiptAcknowledgementToCleared.isEmpty()){
                Update darnaReceiptAcknowledgementToCleared;
            }
        }
        //**** Mortgage LPC Date Update *****************//
        List<ReceiptAllocation__c> rAllocList = [SELECT Id,ReceiptAcknowledgement__r.ChequeReceivedDate__c,InstallmentLine__r.LPCFreezeUntilDate__c,InstallmentLine__r.LPCFreezeDate__c,InstallmentLine__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentType__c FROM ReceiptAllocation__c WHERE ID IN: rAllocIdset AND ReceiptAcknowledgement__r.PaymentType__c ='Mortgage Cheque' AND ReceiptAcknowledgement__r.ChequeReceivedDate__c!=null];
        if(!rAllocList.isEmpty()){
            mortgageLPCUpdate(rAllocList);
        }
        ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherCharges(raIds);
        for(ReceiptAllocation__c rc:[SELECT Id,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE ID IN: rAllocIdset AND ReceiptAcknowledgement__r.Status__c ='Cleared']){
            clearedRAIds.add(rc.ReceiptAcknowledgement__c);
        }
        if(!clearedRAIds.isEmpty()){
        DefaultAndTerminationUtility.verifyandCloseSR(clearedRAIds);
        }
        
        // Isolated callout logic for after insert - called at the end after all other logic
        // FIN-144 by Sai Kumar: Refactored callout logic into isolated method for better maintainability
        handleCalloutForAfterInsert(newList, null);
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            ReceiptAllocation__c oldRecord =  (ReceiptAllocation__c)oldMap.get(receiptAllocation.Id);
            if(receiptAllocation.Unapply__c && !oldRecord.Unapply__c){
                receiptAllocation.DateOfUnapplication__c = Date.Today();
            }
            if(receiptAllocation.AmountApplied__c !=null){
                receiptAllocation.AmountApplied__c = receiptAllocation.AmountApplied__c.setScale(2);
            }
            // FIN-144 by Sai Kumar: Inactiving the flow 'Update Receipt Allocation field' and adding logic in trigger itself
            if(receiptAllocation.InstallmentLine__c !=null){
                receiptAllocation.TypeOfInvoice__c = 'Installment';
            }

        }
        validateAmountApplied(newList,oldMap);
        validateInstallmentsNumbers(newList, oldMap);
        
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        Set<Id> clearedRAIds = new Set<Id>();
        Set<Id> clearedRAllocIds = new Set<Id>();
        
        Set<Id> receiptAcknowledgementIds = new Set<Id>();
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            receiptAcknowledgementIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            if(oldMap != null && receiptAllocation.InstallmentLine__c !=null && oldMap.get(receiptAllocation.Id).get('AmountApplied__c') != receiptAllocation.AmountApplied__c){
               clearedRAllocIds.add(receiptAllocation.Id); 
            }
        }
        
        for(ReceiptAllocation__c rc:[SELECT Id,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE ID IN: clearedRAllocIds AND ReceiptAcknowledgement__r.Status__c ='Cleared']){
            clearedRAIds.add(rc.ReceiptAcknowledgement__c);
        }
        if(!clearedRAIds.isEmpty()){
        DefaultAndTerminationUtility.verifyandCloseSR(clearedRAIds);
        }
        
        // Isolated callout logic for after update - called at the end after all other logic
        // FIN-144 by Sai Kumar: Refactored callout logic into isolated method for better maintainability
        handleCalloutForAfterUpdate(newList, oldMap);
    }
    
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
      // Added by Sanath H M - ASF-213
        Set<Id> raIds = new Set<Id>();
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)oldList){
            raIds.add(receiptAllocation.Id );
        }
        ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherChargesOnDelete(raIds); 
    }
    
    public void validateAmountApplied(List<ReceiptAllocation__c> newList,Map<Id, SObject> oldMap){
        
        Set<Id> receiptIds = new Set<Id>();
        Map<Id,Decimal> receiptAcknowledgementAmountMap = new Map<Id,Decimal>();
        Map<Id,Decimal> newAmountMap = new Map<Id,Decimal>();
        Set<Id> allocationIds = new Set<Id>();
        
        if(oldMap !=null)
            allocationIds = oldMap.keySet();
        
        SystemMessages__mdt receiptAllocationMessage = Utilities.getSystemMessages(Constants.RECEIPT_ALLOCATION_RESTRICTION);
        
        for(ReceiptAllocation__c receiptAllocation : newList){
            receiptIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            receiptAcknowledgementAmountMap.put(receiptAllocation.ReceiptAcknowledgement__c,receiptAllocation.ReceiptAcknowledgementAmount__c);
            if(!receiptAllocation.Unapply__c && receiptAllocation.Id !=null){
                Decimal recieptAmount = ( newAmountMap.containsKey(receiptAllocation.ReceiptAcknowledgement__c) ? newAmountMap.get(receiptAllocation.ReceiptAcknowledgement__c) : 0);
                recieptAmount = recieptAmount +receiptAllocation.AmountApplied__c ;
                newAmountMap.put(receiptAllocation.ReceiptAcknowledgement__c,recieptAmount);
                if(receiptAllocation.AmountApplied__c > receiptAllocation.ReceiptAcknowledgementAmount__c && receiptAllocation.AmountApplied__c != receiptAllocation.ReceiptAcknowledgementAmount__c){
                    receiptAllocation.addError(receiptAllocationMessage.Message__c);
                }
            }
            
        }
        
        if(receiptIds!=null){
            SystemMessages__mdt allocationAccountMessage = Utilities.getSystemMessages(Constants.ALLOCATION_AMOUNT_RESTRICTION);
            
            for(AggregateResult aggRes : [SELECT SUM(AmountApplied__c) amount,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE (ReceiptAcknowledgement__c IN:receiptIds AND Unapply__c=false AND Id NOT IN:allocationIds)  GROUP BY ReceiptAcknowledgement__c]){
                Decimal amount = (Decimal)aggRes.get('amount') ;
                Id receiptAcknowledgement = (aggRes.get('ReceiptAcknowledgement__c')!=null ? (Id) aggRes.get('ReceiptAcknowledgement__c') : null );
                Decimal receiptAmount = (receiptAcknowledgementAmountMap.containsKey(receiptAcknowledgement)? receiptAcknowledgementAmountMap.get(receiptAcknowledgement) : 0);
                System.debug(receiptAmount+'**Receipt Amount Before**'+amount);
                amount =  amount + (newAmountMap.containsKey(receiptAcknowledgement) ? newAmountMap.get(receiptAcknowledgement) : 0);
                System.debug(receiptAmount+'**receiptAmount After**'+amount);
                if(amount > receiptAmount && amount != receiptAmount){
                   newList[0].addError(allocationAccountMessage.Message__c);
                }
            }
        }
        
    }
    public void validateInstallmentsNumbers(List<ReceiptAllocation__c> newList, Map<Id, SObject> oldMap){
        Set<Id> receiptIds = new Set<Id>();
        Map<String, List<ReceiptAllocation__c>> receiptAllocationMap =  new Map<String, List<ReceiptAllocation__c>>();
        Map<String, String> ExistingreceiptAllocationMap   = new  Map<String, String> ();    
        List<ReceiptAllocation__c> ExistingreceiptAllocationList = new List<ReceiptAllocation__c>();
        List<ReceiptAllocation__c> receiptAllocationList = new List<ReceiptAllocation__c>();
        
        for(ReceiptAllocation__c receiptAllocation : newList){
            receiptIds.add(receiptAllocation.ReceiptAcknowledgement__c);
        }
        if(!receiptIds.isEmpty()){ 
        ExistingreceiptAllocationList = [SELECT 
                                         ReceiptAcknowledgement__c,
                                         Id, 
                                         ReceiptAcknowledgement__r.UnitNumber__c,
                                         Account__c,
                                         SalesOrder__c,
                                         SalesOrder__r.Unit__r.Name,
                                         SalesOrder__r.Unit__c,
                                         InstallmentLine__c
                                         FROM ReceiptAllocation__c
                                         WHERE  ReceiptAcknowledgement__c IN:receiptIds ];
        }
        if(!ExistingreceiptAllocationList.isEmpty()){
            for(ReceiptAllocation__c receiptAllocation: ExistingreceiptAllocationList){
                ExistingreceiptAllocationMap.put(receiptAllocation.ReceiptAcknowledgement__c, receiptAllocation.ReceiptAcknowledgement__r.UnitNumber__c);
            }
        }
        system.debug('ExistingreceiptAllocationMap::'+ExistingreceiptAllocationMap);
        if(!receiptIds.isEmpty()){
            receiptAllocationList = [SELECT 
                                     ReceiptAcknowledgement__c,
                                     Id, 
                                     ReceiptAcknowledgement__r.UnitNumber__c,
                                     Account__c,
                                     SalesOrder__c,
                                     SalesOrder__r.Unit__r.Name,
                                     SalesOrder__r.Status__c,
                                     InstallmentLine__c,
                                     InstallmentLine__r.InstallmentNumber__c,
                                     InstallmentLine__r.PendingAmount__c,
                                     SalesOrderOtherCharges__c,
                                     SalesOrderOtherCharges__r.TypeOfCharge__c,
                                     SalesOrderOtherCharges__r.SubType__c,
                                     SalesOrderOtherCharges__r.PendingAmount__c,
                                     SalesOrder__r.Unit__c
                                     FROM ReceiptAllocation__c
                                     WHERE Id NOT IN: newList
                                     AND ReceiptAcknowledgement__c IN:receiptIds ];
        }
        if(!receiptAllocationList.isEmpty()){
            for(ReceiptAllocation__c receiptAllocation: receiptAllocationList){
                String uniqueKey ;
                if(receiptAllocation.InstallmentLine__c != null && receiptAllocation.SalesOrder__c != null && receiptAllocation.Account__c != null && receiptAllocation.ReceiptAcknowledgement__c != null){
                        uniqueKey = receiptAllocation.Account__c + String.valueof(receiptAllocation.SalesOrder__c) + receiptAllocation.InstallmentLine__c + receiptAllocation.ReceiptAcknowledgement__c;
                        List<ReceiptAllocation__c> allocationList = receiptAllocationMap.get(uniqueKey) != null ? receiptAllocationMap.get(uniqueKey) : new List<ReceiptAllocation__c>();
                        allocationList.add(receiptAllocation);
                        receiptAllocationMap.put(uniqueKey, allocationList);
                    
                }
                if(receiptAllocation.SalesOrderOtherCharges__c != null && receiptAllocation.SalesOrder__c != null && receiptAllocation.Account__c != null  && receiptAllocation.ReceiptAcknowledgement__c != null){
                        uniqueKey = receiptAllocation.Account__c + String.valueof(receiptAllocation.SalesOrder__c) + receiptAllocation.SalesOrderOtherCharges__c + receiptAllocation.ReceiptAcknowledgement__c;
                        List<ReceiptAllocation__c> allocationList = receiptAllocationMap.get(uniqueKey) != null ? receiptAllocationMap.get(uniqueKey) : new List<ReceiptAllocation__c>();
                        allocationList.add(receiptAllocation);
                        receiptAllocationMap.put(uniqueKey, allocationList);
                }
            }
        } 
        
        if(!newList.isEmpty()){
            for(ReceiptAllocation__c receiptAllocation : newList) {
                boolean isDuplicate = false;
                String uniqueKeyInstallment;
                String uniqueKeySalesOrderOtherCharges;
                if(receiptAllocation.InstallmentLine__c != null && receiptAllocation.SalesOrder__c != null){
                    uniqueKeyInstallment = receiptAllocation.Account__c + String.valueof(receiptAllocation.SalesOrder__c) + receiptAllocation.InstallmentLine__c + receiptAllocation.ReceiptAcknowledgement__c ;
                } 
                if(receiptAllocation.SalesOrderOtherCharges__c != null && receiptAllocation.SalesOrder__c != null){
                    uniqueKeySalesOrderOtherCharges = receiptAllocation.Account__c +String.valueof(receiptAllocation.SalesOrder__c) + receiptAllocation.SalesOrderOtherCharges__c + receiptAllocation.ReceiptAcknowledgement__c;
                }
                if(receiptAllocationMap.containsKey(uniqueKeyInstallment)){
                    if(receiptAllocationMap.get(uniqueKeyInstallment).size()>0){
                        isDuplicate = true; 
                    }
                }
                if(receiptAllocationMap.containsKey(uniqueKeySalesOrderOtherCharges)){
                    if(receiptAllocationMap.get(uniqueKeySalesOrderOtherCharges).size()>0){
                        isDuplicate = true; 
                    }  
                }
                if(isDuplicate && !receiptAllocation.ReceiptWriteOff__c){
                    receiptAllocation.addError('Please do not select the same Installment number or other changes. Kindly use the existing one.');
                }
            }
        }
    }
    public static void mortgageLPCUpdate(List<ReceiptAllocation__c> rAllocList){
        List<InstallmentLines__c> instListUpdate = new List<InstallmentLines__c>();
        for(ReceiptAllocation__c rAlloc: rAllocList){//[SELECT Id,ReceiptAcknowledgement__r.ChequeReceivedDate__c,InstallmentLine__r.LPCFreezeUntilDate__c,InstallmentLine__r.LPCFreezeDate__c,InstallmentLine__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentType__c FROM ReceiptAllocation__c WHERE ID IN: rAllocIdset AND ReceiptAcknowledgement__r.PaymentType__c ='Mortgage Cheque' AND ReceiptAcknowledgement__r.ChequeReceivedDate__c!=null]){
            InstallmentLines__c installment = new InstallmentLines__c();
            installment.Id = rAlloc.InstallmentLine__c;
            installment.LPCFreezeDate__c = rAlloc.InstallmentLine__r.LPCFreezeDate__c <> null && rAlloc.InstallmentLine__r.LPCFreezeDate__c < rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c ? rAlloc.InstallmentLine__r.LPCFreezeDate__c:rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c;
            installment.LPCFreezeUntilDate__c = rAlloc.InstallmentLine__r.LPCFreezeUntilDate__c <> null && rAlloc.InstallmentLine__r.LPCFreezeUntilDate__c > rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c.addMonths(6) ? rAlloc.InstallmentLine__r.LPCFreezeUntilDate__c:rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c.addMonths(6);
            instListUpdate.add(installment);
        }
        if(!instListUpdate.isEmpty()){
            update instListUpdate;
            //***LPCCalloutHelper.prepareDataForERPSync(instListUpdate); //**** MOVED TO INSTALLMENT HANDLER ****//
        }
    }
    
    /**
     * Handles callout logic for after insert event
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newList List of new ReceiptAllocation records (Trigger.new)
     * @param oldMap Map of old ReceiptAllocation records (Trigger.oldMap - null for insert)
     */
    private void handleCalloutForAfterInsert(List<SObject> newList, Map<Id, SObject> oldMap) {
        Set<Id> raIds = new Set<Id>();
        //Added by Tajinkumar for Syncing Lean Receipts with ERP
        List<Id> getLeanPaymentReceiptIds = new List<Id>();
        
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            if (receiptAllocation.IsStopSyncingWithERP__c == false) {
                raIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            }
        }
        
        User usr = Utilities.getLoggedInUserDetail();
        if (!raIds.isEmpty()) {
            List<Id> raIdList = new List<Id>();
            raIdList.addAll(raIds);
            
            List<Id> raNewIdList = new List<Id>();
            List<ReceiptAcknowledgement__c> rackList = ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(raIdList);
            for (ReceiptAcknowledgement__c ra: rackList) {
                if (ra.ReferenceNumber__c != null && ra.IsStopSyncingWithERP__c == false) {
                    if (ra.PaymentType__c == Constants.ONLINE && (ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS  || ra.Status__c == Constants.RECEIPT_STATUS_CLEARED)) {
                        raNewIdList.add(ra.Id);
                    } else if (ra.PaymentType__c != Constants.ONLINE) {
                        raNewIdList.add(ra.Id);
                    }
                } else if (ra.PaymentType__c == Constants.PAYMENT_TYPE_CREDIT_NOTE && ra.IsStopSyncingWithERP__c == false) {
                    raNewIdList.add(ra.Id);
                }
                if(ra.PaymentType__c == Constants.WIRE_TRANSFER && ra.Payment_Gateway__c == 'Lean' && ra.ReferenceNumber__c != null && ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS) {
                    getLeanPaymentReceiptIds.add(ra.Id);
                }
            }
           if (!raNewIdList.isEmpty() && usr.Profile.Name != Constants.INTEGRATION_PROFILE) {
                ReceiptCalloutHelper.PrepareDataForCallout(raNewIdList);
            } else if(!getLeanPaymentReceiptIds.isEmpty() && !System.IsBatch()) {
                ReceiptCalloutHelper.PrepareDataForCallout(getLeanPaymentReceiptIds);
            }
        }
    }

    /**
     * Handles callout logic for after update event
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newList List of new ReceiptAllocation records (Trigger.new)
     * @param oldMap Map of old ReceiptAllocation records (Trigger.oldMap)
     */
    private void handleCalloutForAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        Set<Id> receiptAcknowledgementIds = new Set<Id>();
        
        // Query integration fields from custom setting
        Map<String, ReceiptAllocation_Integration_Fields__c> integrationFields = new Map<String, ReceiptAllocation_Integration_Fields__c>();
        
        if (Label.ReceiptAllocation_Integration_Field_Check == 'true') {
            for(ReceiptAllocation_Integration_Fields__c field : ReceiptAllocation_Integration_Fields__c.getAll().values()) {
                if(field.Is_Active__c) {
                    integrationFields.put(field.API__c, field);
                }
            }
        }
        
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            ReceiptAllocation__c oldReceiptAllocation = (ReceiptAllocation__c)oldMap.get(receiptAllocation.Id);
            
            // Check if any integration fields have changed
            Boolean hasIntegrationFieldChanges = false;
            
            if (Label.ReceiptAllocation_Integration_Field_Check == 'true' && !integrationFields.isEmpty()) {
                hasIntegrationFieldChanges = checkIntegrationFieldChanges(receiptAllocation, oldReceiptAllocation, integrationFields);
            } else {
                // Original behavior when feature flag is disabled - always trigger callout
                hasIntegrationFieldChanges = true;
            }
            
            if (hasIntegrationFieldChanges) {
                receiptAcknowledgementIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            }
        }
        
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !receiptAcknowledgementIds.isEmpty()) {
            List<ReceiptAcknowledgement__c> updateReceiptAcknowledgement = new List<ReceiptAcknowledgement__c>();
            
            for (Id recordId: receiptAcknowledgementIds) {
                ReceiptAcknowledgement__c receiptAcknowledgement = new ReceiptAcknowledgement__c();
                receiptAcknowledgement.Id = recordId;
                receiptAcknowledgement.RetriggerCalculation__c = true;
                receiptAcknowledgement.IsReceiptAllocationChange__c = true;
                receiptAcknowledgement.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                system.debug('+++++RECEIPT ALLOCATION CALLOUT');
                updateReceiptAcknowledgement.add(receiptAcknowledgement);
            }
            
            if (!updateReceiptAcknowledgement.isEmpty()) {
                update updateReceiptAcknowledgement;
            }
        }
    }
    
    /**
     * Checks if any integration fields have changed between old and new ReceiptAllocation records
     * FIN-144 by Sai Kumar: Isolated callout logic for better maintainability and testability
     * @param newRecord The new ReceiptAllocation record
     * @param oldRecord The old ReceiptAllocation record
     * @param integrationFields Map of integration fields to check
     * @return Boolean indicating if any integration fields have changed
     */
    private Boolean checkIntegrationFieldChanges(ReceiptAllocation__c newRecord, ReceiptAllocation__c oldRecord, 
        Map<String, ReceiptAllocation_Integration_Fields__c> integrationFields) {
        
        for (String field : integrationFields.keySet()) {
            if (newRecord.get(field) != oldRecord.get(field)) {
                return true;
            }
        }
        return false;
    }
}