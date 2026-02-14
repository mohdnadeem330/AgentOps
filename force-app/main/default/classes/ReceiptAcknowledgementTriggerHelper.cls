/**********************************************************************************************************************
* Name               : ReceiptAcknowledgementTriggerHandlerWithoutSharing                                                        
* Description        : Class to perform Receipt Acknowledgement Trigger activities in admin context
* Usage              : ReceiptAcknowledgementTriggerHandler
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public without sharing class ReceiptAcknowledgementTriggerHelper{
    /**
    * verifyAndReserveSO
    *
    * This method used to mark the SO as reserved. after payment the guest user should be able to update the status regardless of SO access
    *
    * @param  none
    * @return none
    */
   
    public static Boolean isJobEnqueued = False;
    
    public static void verifyAndReserveSO(set<ID> soIDs ){
        
        List<SalesOrder__c> soRecords =[Select Id,Status__c,Is_Digital_Sales__c,Unit__c,Unit__r.Project__c,Unit__r.Project__r.Name from SalesOrder__c where Id IN : soIDs and Status__c = : constants.STATUS_RESERVATION_IN_PROGRESS];
        Set<Id> soUnitIds = new set<Id>(); //Digital Sales
        List<SalesOrder__c> updateSoStatus = new List<SalesOrder__c>();
        List<SalesOrder__c> updateDigitalSoStatus = new List<SalesOrder__c>();
        Boolean soStatusReserved = false;
        Map<Id,Project__c> getRelatedProject = new Map<Id,Project__c>();
       
        for(SalesOrder__c tempSO: soRecords){
            if(!tempSO.Is_Digital_Sales__c){
                tempSO.Status__c = Constants.STATUS_RESERVED;
            }
            else {
                updateDigitalSoStatus.add(tempSO);
            }
        }
        if(!soRecords.isEmpty()){
            update soRecords;
        }
        
        if(!updateDigitalSoStatus.isEmpty()){
            Map<Id,List<ReceiptAcknowledgement__c>> getAllReceiptAcknowledgements = new Map<Id,List<ReceiptAcknowledgement__c>>();
            
            for(ReceiptAcknowledgement__c receipt : [Select Id,PaymentType__c,Salesorder__r.Status__c,Status__c,ReferenceNumber__c,Amount__c,OnlinePaymentCleared__c,SalesOrder__c,SalesOrder__r.Unit__r.Project__r.ReservationAmount__c,SalesOrder__r.Is_Digital_Sales__c From ReceiptAcknowledgement__c Where Salesorder__c In : updateDigitalSoStatus]){
                if(receipt.SalesOrder__r.Is_Digital_Sales__c && !getAllReceiptAcknowledgements.containsKey(receipt.SalesOrder__c)){
                    getAllReceiptAcknowledgements.put(receipt.SalesOrder__c,new List<ReceiptAcknowledgement__c>());
                } 
                getAllReceiptAcknowledgements.get(receipt.SalesOrder__c).add(receipt);
            }
            
            for(SalesOrder__c So : updateDigitalSoStatus){
                Decimal totalReceiptAmountReceived = 0;
                if(So.Is_Digital_Sales__c && getAllReceiptAcknowledgements.containsKey(So.Id)){
                    List<ReceiptAcknowledgement__c> receiptList = getAllReceiptAcknowledgements.get(So.Id);
                    if(!receiptList.isEmpty() && receiptList.size() > 0){
                        ReceiptAcknowledgement__c receipt = receiptList[0];
                        Decimal projectReservationAmount = receipt.SalesOrder__r?.Unit__r?.Project__r?.ReservationAmount__c != null ? receipt.SalesOrder__r.Unit__r.Project__r.ReservationAmount__c : 0;
                        for(ReceiptAcknowledgement__c rec : receiptList){
                            if((rec.PaymentType__c == Constants.ONLINE && rec.Status__c == Constants.RECEIVED_PAYMENT_STATUS && rec.OnlinePaymentCleared__c) ||
                               (rec.PaymentType__c == Constants.WIRE_TRANSFER && String.isNotBlank(rec.ReferenceNumber__c))){
                                   totalReceiptAmountReceived += (rec.Amount__c ?? 0);
                               }
                        }
                        System.debug('totalReceiptAmountReceived : ' + totalReceiptAmountReceived);
                        System.debug('projectReservationAmount : ' + projectReservationAmount);
                        if(totalReceiptAmountReceived >= projectReservationAmount){
                            So.Status__c = Constants.STATUS_RESERVED;
                            soUnitIds.add(So.Unit__c);
                            updateSoStatus.add(So);
                            getRelatedProject.put(So.Id,So.Unit__r.Project__r);
                        }
                    }
                }   
            }
            if(!updateSoStatus.isEmpty()){
                update updateSoStatus;
                soStatusReserved = true;
            }
            if(!soUnitIds.isEmpty()){
                List<Communication_Preference__c> cpList = new List<Communication_Preference__c>();
                for(Communication_Preference__c cp : [SELECT Id,Unit__c,Active__c,Status__c FROM Communication_Preference__c WHERE Unit__c In : soUnitIds AND Category__c ='Booking']){
                    if(cp.Active__c == true){
                        cp.Active__c = false;
                        cpList.add(cp);
                    }
                }
                if(cpList.size() >0){
                    update cpList;
                }
            }
        }
        if(!isJobEnqueued && soStatusReserved){
            updateSalesOrderStatusToPending(getRelatedProject);
        }
    }
    
    public static void updateSalesOrderStatusToPending(Map<Id,Project__c> getRelatedProject){
        
        Set<Id> getSalesOrderIds = new Set<Id>();
        Set<String> getProjects = new Set<String>();
        String dubaiProjects = System.Label.DubaiDigitalSalesProjects;
        
        if(String.isBlank(dubaiProjects)){
            return;
        }
        
        for(String proj : dubaiProjects.split(',')){
            getProjects.add(proj.trim().toLowerCase());
        }
        
        for(Id soId : getRelatedProject.keySet()){
            Project__c proj = getRelatedProject.get(soId);
            
            if(proj != null && !String.isBlank(proj.Name)){
                String projectName = (proj.Name).trim().toLowerCase();
                if(getProjects.contains(projectName)){
                    getSalesOrderIds.add(soId);
                }
            }
        }
        if(!isJobEnqueued && Limits.getQueueableJobs() == 0 && !getSalesOrderIds.isEmpty()){
            try{
                System.enqueueJob(new UpdateSalesOrderStatusQueueable(getSalesOrderIds));
                isJobEnqueued = true;
            }
            catch(Exception ex){
                LoggerService.save(LoggerService.addApexLog(ex,'UpdateSalesOrderStatusQueueable','ReceiptAcknowledgementTriggerHelper','updateSalesOrderStatusToPending'));
            }
        }
    }
    
    
     //Start ASF-3309 
    public static void populateThirdPartyFlag(List<ReceiptAcknowledgement__c> newList, Map<Id, Sobject> oldMap){
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<String, Id> salesOrderIdAccountIdMap = new Map<String, Id>();
        for(ReceiptAcknowledgement__c ra: newList){
            ReceiptAcknowledgement__c oldRA = oldMap != null ? (ReceiptAcknowledgement__c)oldMap.get(ra.Id) : null;
            if (ra.SalesOrder__c != null && ra.RecievedFromAccount__c != null &&
                (oldRA == null || ra.RecievedFromAccount__c != oldRA.RecievedFromAccount__c)) {
                salesOrderIds.add(ra.SalesOrder__c);
                accountIds.add(ra.RecievedFromAccount__c);
            }           
        }
        if(!salesOrderIds.isEmpty() && !accountIds.isEmpty()){
            for(Sales_Order_Relationship__c sor: [Select Id,SalesOrder__c,Account__c from Sales_Order_Relationship__c where SalesOrder__c in: salesOrderIds AND Account__c in: accountIds 
                                                    AND RecordType.DeveloperName = 'Third_Party' ]){
                salesOrderIdAccountIdMap.put(sor.SalesOrder__c + '-'+ sor.Account__c, sor.Id);
            }
        }
        for(ReceiptAcknowledgement__c ra: newList){
            ReceiptAcknowledgement__c oldRA = oldMap != null ? (ReceiptAcknowledgement__c)oldMap.get(ra.Id) : null;
            if (ra.SalesOrder__c != null && ra.RecievedFromAccount__c != null && 
                (oldRA == null || ra.RecievedFromAccount__c != oldRA.RecievedFromAccount__c)) {
                if(salesOrderIdAccountIdMap.containsKey(ra.SalesOrder__c + '-'+ ra.RecievedFromAccount__c)){
                    ra.Is_Third_party_payment__c = true;
                    ra.Sales_Order_Relationship__c = salesOrderIdAccountIdMap.get(ra.SalesOrder__c + '-'+ ra.RecievedFromAccount__c);
                } else {
                    ra.Is_Third_party_payment__c = false;
                    ra.Sales_Order_Relationship__c = null;
                }
            }
        }      
    }
    //End ASF-3309   

    //Start ASF-3320
    public static void validateInstrumentRecieved(List<ReceiptAcknowledgement__c> newList,Map<Id,Sobject> oldMap){
        Set<Id> salesOrderIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra: newList){
                ReceiptAcknowledgement__c oldRA = oldMap != null ? (ReceiptAcknowledgement__c)oldMap.get(ra.Id) : null;
                if(oldRA != null && oldRA.ChequeReceived__c != ra.ChequeReceived__c && ra.ChequeReceived__c == true && ra.Status__c != 'Cleared'){
                    ra.addError('Cannot mark cheque as received. Sales Order compliance status is not cleared.');
                }
        }
    }
    //End ASF-3320 

    //Start ASF-3309
    public static void updateSalesOrderRelationshipTotals(List<ReceiptAcknowledgement__c> newList, Map<Id, SObject> oldMap) {
        Set<Id> salesOrderIds = new Set<Id>();
        Map<String, Id> salesOrderIdAccountIdMap = new Map<String, Id>();
        List<Sales_Order_Relationship__c> sorUpdates = new List<Sales_Order_Relationship__c>();
        Set<String> statusToExclude = new Set<String>{'Link Sent', 'Reversed'};

        for (ReceiptAcknowledgement__c ra : newList) {
            ReceiptAcknowledgement__c oldRA = oldMap != null ? (ReceiptAcknowledgement__c)oldMap.get(ra.Id) : null;
            if (oldRA == null && ra.SalesOrder__c != null && ra.RecievedFromAccount__c != null && !statusToExclude.contains(ra.Status__c)) {
                salesOrderIds.add(ra.SalesOrder__c);
            }
            if (oldRA != null && (ra.SalesOrder__c != oldRA.SalesOrder__c || ra.RecievedFromAccount__c != oldRA.RecievedFromAccount__c || 
                ra.Amount__c != oldRA.Amount__c || ra.Status__c != oldRA.Status__c)) {
                salesOrderIds.add(ra.SalesOrder__c);
            }
        }

        if (!salesOrderIds.isEmpty()) {
            for (Sales_Order_Relationship__c sor : [SELECT Id, SalesOrder__c, Account__c 
                                                    FROM Sales_Order_Relationship__c 
                                                    WHERE SalesOrder__c IN :salesOrderIds 
                                                    AND RecordType.DeveloperName = 'Third_Party']) {
                salesOrderIdAccountIdMap.put(sor.SalesOrder__c + '-' + sor.Account__c, sor.Id);
            }

            Map<String, Decimal> totalAmountMap = new Map<String, Decimal>();
            
            for (ReceiptAcknowledgement__c ra : [SELECT SalesOrder__c, RecievedFromAccount__c, Amount__c, Status__c 
                                                 FROM ReceiptAcknowledgement__c 
                                                 WHERE SalesOrder__c IN :salesOrderIds 
                                                 AND RecievedFromAccount__c != null]) {
                String key = ra.SalesOrder__c + '-' + ra.RecievedFromAccount__c;
                if (!totalAmountMap.containsKey(key)) {
                    totalAmountMap.put(key, 0);
                }
                Decimal amount = (ra.Status__c == 'Link Sent' || ra.Status__c == 'Reversed') ? 0 : ra.Amount__c;
                totalAmountMap.put(key, totalAmountMap.get(key) + amount);
            }
            
            for (String key : salesOrderIdAccountIdMap.keySet()) {
                Sales_Order_Relationship__c sor = new Sales_Order_Relationship__c(
                    Id = salesOrderIdAccountIdMap.get(key),
                    Total_amount_paid_as_of_today__c = totalAmountMap.containsKey(key) ? totalAmountMap.get(key) : 0
                );
                sorUpdates.add(sor);
            }

            if (!sorUpdates.isEmpty()) {
                update sorUpdates;
            }
        }
    }
    public static void updateJointOwnerTotals(List<ReceiptAcknowledgement__c> newList, Map<Id, SObject> oldMap){
        Set<Id> salesOrderIds = new Set<Id>();
        Map<String, Id> salesOrderIdAccountIdMap = new Map<String, Id>();
        List<JointOwner__c> jointOwnerUpdates = new List<JointOwner__c>();
        Set<String> statusToExclude = new Set<String>{'Link Sent', 'Reversed'};

        for(ReceiptAcknowledgement__c ra : newList){
            ReceiptAcknowledgement__c oldRA = oldMap != null ? (ReceiptAcknowledgement__c)oldMap.get(ra.Id) : null;
            if(oldRA == null && ra.SalesOrder__c != null && ra.RecievedFromAccount__c != null && !statusToExclude.contains(ra.Status__c)) {
                salesOrderIds.add(ra.SalesOrder__c);
            }
            if(oldRA != null && (ra.SalesOrder__c != oldRA.SalesOrder__c || ra.RecievedFromAccount__c != oldRA.RecievedFromAccount__c || 
                ra.Amount__c != oldRA.Amount__c || ra.Status__c != oldRA.Status__c)){
                salesOrderIds.add(ra.SalesOrder__c);
            }
        }

        if (!salesOrderIds.isEmpty()){
            for(JointOwner__c jow : [SELECT Id, SalesOrder__c, Account__c 
                                                    FROM JointOwner__c 
                                                    WHERE SalesOrder__c IN :salesOrderIds]){
                salesOrderIdAccountIdMap.put(jow.SalesOrder__c + '-' + jow.Account__c, jow.Id);
            }

            Map<String, Decimal> totalAmountMap = new Map<String, Decimal>();
            
            for(ReceiptAcknowledgement__c ra : [SELECT SalesOrder__c, RecievedFromAccount__c, Amount__c, Status__c 
                                                 FROM ReceiptAcknowledgement__c 
                                                 WHERE SalesOrder__c IN :salesOrderIds 
                                                 AND RecievedFromAccount__c != null LIMIT 200]){ // LIMIT 200 added by Neelesh 
                String key = ra.SalesOrder__c + '-' + ra.RecievedFromAccount__c;
                if(!totalAmountMap.containsKey(key)){
                    totalAmountMap.put(key, 0);
                }
                Decimal amount = (ra.Status__c == 'Link Sent' || ra.Status__c == 'Reversed') ? 0 : ra.Amount__c;
                totalAmountMap.put(key, totalAmountMap.get(key) + amount);
            }
            
            for(String key : salesOrderIdAccountIdMap.keySet()){
                JointOwner__c jow = new JointOwner__c(
                    Id = salesOrderIdAccountIdMap.get(key),
                    Total_amount_paid_as_of_today__c = totalAmountMap.containsKey(key) ? totalAmountMap.get(key) : 0
                );
                jointOwnerUpdates.add(jow);
            }

            if(!jointOwnerUpdates.isEmpty()){
                update jointOwnerUpdates;
            }
        }
    }
}