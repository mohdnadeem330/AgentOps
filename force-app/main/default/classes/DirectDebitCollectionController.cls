public without sharing class DirectDebitCollectionController {
    
    public class collectionWrapper {
        @AuraEnabled public String rowId;
        @AuraEnabled public InstallmentLines__c installment;
        @AuraEnabled public String salesOrderId;
        @AuraEnabled public String hasServiceRequest;
        @AuraEnabled public String serviceRequest;
        @AuraEnabled public String serviceRequestId;
        @AuraEnabled public String CustomerBankAccountName;
        @AuraEnabled public Decimal UnallocatedReceiptAmount;
        @AuraEnabled public DirectDebitRequest__c directDebitRequest;
    }
    @AuraEnabled(cacheable=false)
    public static List<collectionWrapper> getInstallmentLinesQuery(String query, Integer rowLimit, Integer rowOffSet){
        
        List<collectionWrapper> collectionWrapperList = new List<collectionWrapper>();
        try{
            query = query+' ORDER BY InstallmentNumber__c ASC ' ;
            
            Map<Id, List<InstallmentLines__c>> soInstallmentMap = new Map<Id, List<InstallmentLines__c>>();
            Map<Id, List<InstallmentLines__c>> soInstallmentFinalMap = new Map<Id, List<InstallmentLines__c>>();
            List<DirectDebitRequest__c> approvedDirectDebit = new List<DirectDebitRequest__c>();
            system.debug('query::'+query);
            List<InstallmentLines__c> installmentLines = Database.query(query);
            system.debug('installmentLines::'+installmentLines);
            if(!installmentLines.isEmpty()){
                for(InstallmentLines__c installmentLine: installmentLines){
                    installmentLine.AmountReceived__c = installmentLine.AmountReceived__c != null ? installmentLine.AmountReceived__c : 0;
                   Decimal eligibleAmount = (installmentLine.OutstandingAmount__c - installmentLine.AmountReceived__c) == 0 ? (installmentLine.InstallmentAmount__c - installmentLine.OutstandingAmount__c) : (installmentLine.OutstandingAmount__c - installmentLine.AmountReceived__c);
                    if(installmentLine.OutstandingAmount__c != null ){
                        
                        if( eligibleAmount != 0 ){
                            //if(installmentLine.Receipt_Allocations__r.size()==0){
                            List<InstallmentLines__c> soInstallmentLines =  soInstallmentMap.get(installmentLine.SalesOrder__c) != null ? soInstallmentMap.get(installmentLine.SalesOrder__c) : new List<InstallmentLines__c>();
                            soInstallmentLines.add(installmentLine);
                            soInstallmentMap.put(installmentLine.SalesOrder__c, soInstallmentLines);
                            //}
                        }
                    }
                }
            }
            
            List<SalesOrder__c> allsalesOrders = [SELECT Id,
                                                  (SELECT
                                                   Id
                                                   FROM  Direct_Debit_Request__r
                                                   WHERE Status__c = 'Approved by Bank'
                                                   AND DDAreferencenumber__c != null)
                                                  FROM SalesOrder__c 
                                                  WHERE Id IN: soInstallmentMap.keySet()];
            system.debug('allsalesOrders::'+allsalesOrders);
            if(!allsalesOrders.isEmpty()){
                for(SalesOrder__c so: allsalesOrders){
                    if(so.Direct_Debit_Request__r.size()>0){
                        //soInstallmentFinalMap.put(so.Id, soInstallmentMap.get(so.id));
                        approvedDirectDebit.addAll(so.Direct_Debit_Request__r);
                    }
                }
            }
            system.debug('allsalesOrders::'+allsalesOrders);
            system.debug('approvedDirectDebit::'+approvedDirectDebit);
            List<DirectDebitRequest__c> ddRDDtInProgressList = [SELECT ID, SalesOrder__c,
                                                                (SELECT
                                                                 Id,
                                                                 DirectDebitRequest__c,
                                                                 DirectDebitRequest__r.SalesOrder__c,
                                                                 Requesttype__c
                                                                 FROM DD_Transactions__r
                                                                 WHERE Requesttype__c = 'Collection'
                                                                 AND TransactionStatus__c =  'Unprocessed'
                                                                 AND Receipt_Acknowledgement__c != null) 
                                                                FROM DirectDebitRequest__c
                                                                WHERE Id IN: approvedDirectDebit];
            
            
            for(DirectDebitRequest__c directDebitRequest: ddRDDtInProgressList){
                if(directDebitRequest.DD_Transactions__r.size()==0){
                    List<InstallmentLines__c> installmentList = soInstallmentMap.get(directDebitRequest.SalesOrder__c) != null ?  soInstallmentMap.get(directDebitRequest.SalesOrder__c) : new List<InstallmentLines__c>();
                    soInstallmentFinalMap.put(directDebitRequest.SalesOrder__c, installmentList);
                } 
            }
            
            Map<Id, DirectDebitRequest__c> soDirectDebitmap = getDirectDebitForSalesoder(soInstallmentFinalMap.keySet());
            Map<String,Decimal> receiptAcknowledgementSOMap = getReceiptAcknowledgementForSalesoder(soInstallmentFinalMap.keySet());
            List<InstallmentLines__c> finalinstallmentLines = new List<InstallmentLines__c>();
            Map<Id, HexaBPM__Service_Request__c> soSrMap    = getSOSRMap(soInstallmentFinalMap.keySet());
            
            for(Id saleorderId: soInstallmentFinalMap.keySet()){
                List<InstallmentLines__c> soInstallmentlines = soInstallmentFinalMap.get(saleorderId);
                finalinstallmentLines.addAll(soInstallmentlines);
            }
            
            if(!finalinstallmentLines.isEmpty()) {
                for(InstallmentLines__c installment: finalinstallmentLines) {
                    collectionWrapper wrap = new collectionWrapper();
                    wrap.rowId = installment.Id;
                    wrap.installment = installment;
                    wrap.CustomerBankAccountName = soDirectDebitmap.get(installment.SalesOrder__c) != null ? soDirectDebitmap.get(installment.SalesOrder__c).CustomerAccountName__c:null;
                    wrap.UnallocatedReceiptAmount = receiptAcknowledgementSOMap.get(installment.SalesOrder__c) != null? receiptAcknowledgementSOMap.get(installment.SalesOrder__c): null;    
                    wrap.hasServiceRequest = soSrMap.get(installment.SalesOrder__c) != null ? 'Yes': null;
                    wrap.serviceRequest = soSrMap.get(installment.SalesOrder__c) != null ? soSrMap.get(installment.SalesOrder__c).Name : null;
                    wrap.serviceRequestId = soSrMap.get(installment.SalesOrder__c) != null ? soSrMap.get(installment.SalesOrder__c).Id : null;
                    wrap.directDebitRequest = soDirectDebitmap.get(installment.SalesOrder__c) != null ? soDirectDebitmap.get(installment.SalesOrder__c) : null;
                    collectionWrapperList.add(wrap);
                }
            }
        }catch(Exception ex){
            system.debug('Exception '+ex);
        } 
        return collectionWrapperList;
    }
    private static Id getRecordTypeId(String RecordTypeName){
        return  Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get(RecordTypeName).getRecordTypeId();
    }
    private static Map<Id, HexaBPM__Service_Request__c> getSOSRMap(Set<Id> SalesOrderIdSet){
        Id propertyTransferId = getRecordTypeId('Property Transfer');
        Id cancellationId = getRecordTypeId('Cancellation');
        Id paymentPlanId = getRecordTypeId('Payment Plan Change');
        Id consolidationId = getRecordTypeId('Consolidation');
        Id MutualCancellationId = getRecordTypeId('Mutual Cancellation');
        Id paymentExtensionId = getRecordTypeId('Payment Extension and Cheque Replacement');
        Id PlotPropertyTransferId = getRecordTypeId('Plot Property Transfer');
        Id UnitSwapId = getRecordTypeId('Unit Swap');
        Map<Id, HexaBPM__Service_Request__c> soSrMap = new Map<Id, HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> serviceRequests = [SELECT
                                                             Id,
                                                             Name,
                                                             SalesOrder__c
                                                             FROM HexaBPM__Service_Request__c 
                                                             WHERE SalesOrder__c IN: SalesOrderIdSet
                                                             AND (RecordTypeId =:propertyTransferId
                                                                  OR RecordTypeId =:cancellationId
                                                                  OR RecordTypeId =:paymentPlanId
                                                                  OR RecordTypeId =:consolidationId
                                                                  OR RecordTypeId =:MutualCancellationId
                                                                  OR RecordTypeId =: paymentExtensionId
                                                                  OR RecordTypeId =:PlotPropertyTransferId
                                                                  OR RecordTypeId =:UnitSwapId) 
                                                             AND HexaBPM__IsClosedStatus__c= false
                                                             AND HexaBPM__Closed_Date_Time__c = null
                                                            ]; 
        
        if(!serviceRequests.isEmpty()){
            for(HexaBPM__Service_Request__c serviceRequest: serviceRequests){
                soSrMap.put(serviceRequest.SalesOrder__c, serviceRequest);
            }
        }
        return soSrMap;
    }
    private static Map<Id, DirectDebitRequest__c> getDirectDebitForSalesoder(Set<Id> salesOrderIds) {
        
        Map<Id, DirectDebitRequest__c> soDirectDebitmap = new Map<Id, DirectDebitRequest__c>();
        List<DirectDebitRequest__c> directDebitrequests = [SELECT
                                                           Id,
                                                           SalesOrder__c,
                                                           CustomerAccountName__c
                                                           FROM
                                                           DirectDebitRequest__c
                                                           WHERE SalesOrder__c IN:salesOrderIds 
                                                           AND Status__c = 'Approved by Bank'
                                                           AND DDAreferencenumber__c != null];
        
        if(!directDebitrequests.isEmpty()){
            for(DirectDebitRequest__c directDebitRequest: directDebitrequests){
                soDirectDebitmap.put(directDebitRequest.SalesOrder__c, directDebitRequest); 
            }
        }
        return soDirectDebitmap;    
    }
    
    private static Map<String,Decimal> getReceiptAcknowledgementForSalesoder(Set<Id> salesOrderIds){
        Map<String,Decimal> receiptAcknowledgementSOMap  = new Map<String,Decimal>();
        AggregateResult[] receiptAcknowledgements = [SELECT
                                                     SalesOrder__c soId, 
                                                     SUM(OutstandingAmount__c)outstandingAmount
                                                     FROM ReceiptAcknowledgement__c
                                                     WHERE Status__c IN ('Remitted', 'Cleared')
                                                     AND SalesOrder__c IN: salesOrderIds
                                                     GROUP BY SalesOrder__c];
        if(!receiptAcknowledgements.isEmpty()){
            for(AggregateResult ar: receiptAcknowledgements){
                receiptAcknowledgementSOMap.put(String.valueOf(ar.get('soId')), Decimal.valueOf(String.valueOf(ar.get('outstandingAmount'))));
            }
        }
        return receiptAcknowledgementSOMap;
        
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Unit__c> prepareDropdownData(String projectNameParam){
        list<Unit__c> lstDropdownData = new list<Unit__c>();
        if (String.isNotBlank(projectNameParam)) {
            for(Unit__c objUnit : [Select
                                   Id,
                                   TotalRooms__c,
                                   UnitCategory__c,
                                   Project__r.Name,
                                   HandoverZone__c,
                                   FloorNumber__c,
                                   UnitView__c,
                                   UnitModel__c,
                                   CommunityName__c,
                                   UnitType__c,
                                   BuildingSectionName__r.Name,
                                   Project__r.City__c 
                                   from Unit__c
                                   where Project__r.Name =: projectNameParam
                                   AND Project__r.IsActive__c = true 
                                   AND Project__r.DirectDebitOIC__c != null]){
                                       lstDropdownData.add(objUnit);
                                   }
        }else{
            for(Unit__c objUnit: [Select
                                  Id,
                                  TotalRooms__c,
                                  Project__r.Name,
                                  Project__c,
                                  UnitCategory__c,
                                  HandoverZone__c,
                                  UnitView__c,
                                  UnitModel__c,
                                  FloorNumber__c,
                                  CommunityName__c,
                                  UnitType__c,
                                  BuildingSectionName__r.Name,
                                  Project__r.City__c
                                  from Unit__c
                                  where Project__r.IsActive__c = true 
                                  AND Project__r.DirectDebitOIC__c != null]){
                                      lstDropdownData.add(objUnit);
                                  }
        }   
        return lstDropdownData;
    }
    
    @AuraEnabled
    public static String createDirectDebitTransaction(Object finalInstallmentCollectionAmtMap) {
        String message='';
        SavePoint sp = database.SetSavePoint();
        try{
            String installmentJson = string.valueOf(finalInstallmentCollectionAmtMap);
            Map<String, Object> installmentCollectionMap = Test.isRunningTest() ? (Map<String, Object>)JSON.deserializeUntyped(installmentJson):  (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(finalInstallmentCollectionAmtMap));
            Map<String, DirectDebitRequest__c> installmentDirectdibitRequestMap = getDDAreferenceNumber(installmentCollectionMap.keyset());
            Map<String, String> installmentSaleorderMap = getSalesOrderMap(installmentCollectionMap.keyset());
            Map<Id, InstallmentLines__c> installmentLineMap = new Map<Id, InstallmentLines__c>([SELECT
                                                                                                Id,
                                                                                                Name,
                                                                                                SalesOrder__c,
                                                                                                SalesOrder__r.Account__c,
                                                                                                SalesOrder__r.Account__r.Name,
                                                                                                SalesOrder__r.Opportunity__c,
                                                                                                SalesOrder__r.Unit__r.Name,
                                                                                                InstallmentNumber__c
                                                                                                FROM InstallmentLines__c
                                                                                                WHERE ID IN: installmentCollectionMap.keyset()]);
            List<DDTransaction__c> ddTransactionList = new List<DDTransaction__c>();
            List<ReceiptAcknowledgement__c> receiptAcknowledgementList = new List<ReceiptAcknowledgement__c>();
            
            for(Id installmentLineId: installmentCollectionMap.keyset()){
                ReceiptAcknowledgement__c receiptAcknowledgement = new ReceiptAcknowledgement__c();
                receiptAcknowledgement.PaymentType__c = 'Direct Debit';
                receiptAcknowledgement.MaturityDate__c = System.today();
                receiptAcknowledgement.Remarks__c = 'Installment Line #: '+installmentLineMap.get(installmentLineId).InstallmentNumber__c;
                receiptAcknowledgement.PaidBy__c = installmentDirectdibitRequestMap.get(installmentLineId) != null ? installmentDirectdibitRequestMap.get(installmentLineId).PayerAccount__r.Name : null;
                receiptAcknowledgement.Amount__c = (decimal)installmentCollectionMap.get(installmentLineId);
                receiptAcknowledgement.SalesOrder__c = installmentLineMap.get(installmentLineId).SalesOrder__c;
                receiptAcknowledgement.Opportunity__c = installmentLineMap.get(installmentLineId).SalesOrder__r.Opportunity__c;
                receiptAcknowledgement.RecievedFromAccount__c = installmentDirectdibitRequestMap.get(installmentLineId) != null ? installmentDirectdibitRequestMap.get(installmentLineId).PayerAccount__c : null;
                //installmentLineMap.get(installmentLineId).SalesOrder__r.Account__c;
                receiptAcknowledgement.Installment_Line__c = installmentLineId;
                receiptAcknowledgement.ReferenceNumber__c = installmentDirectdibitRequestMap.get(installmentLineId).DirectDebitBank__c == 'First Abu Dhabi Bank'? installmentDirectdibitRequestMap.get(installmentLineId).DDAreferencenumber__c:installmentDirectdibitRequestMap.get(installmentLineId).Name;
                receiptAcknowledgement.ChequeReceived__c = true;
                receiptAcknowledgement.BankName__c = installmentDirectdibitRequestMap.get(installmentLineId) != null ? installmentDirectdibitRequestMap.get(installmentLineId).CustomerBankName_Aldar__c:null;
                receiptAcknowledgement.CustomerBankAccount__c = installmentDirectdibitRequestMap.get(installmentLineId) != null ? installmentDirectdibitRequestMap.get(installmentLineId).CustomerIBANNumber__c:null;
                receiptAcknowledgement.DDCollectionStatus__c = 'Collection Initiated';
                receiptAcknowledgementList.add(receiptAcknowledgement);            
            }
            
            if(!receiptAcknowledgementList.isEmpty()) {
                insert receiptAcknowledgementList; 
                List<ReceiptAcknowledgement__c> allReceiptAcknowledgementList = [SELECT
                                                                                 Id,
                                                                                 Amount__c,
                                                                                 Installment_Line__c,
                                                                                 RecievedFromAccount__c,
                                                                                 SalesOrder__c
                                                                                 FROM
                                                                                 ReceiptAcknowledgement__c
                                                                                 WHERE ID IN:receiptAcknowledgementList];
                createDDTransaction(allReceiptAcknowledgementList, installmentCollectionMap.keyset());
                createReceiptAllocation(allReceiptAcknowledgementList);
            }
            message = 'Success';  
        }catch(Exception ex){
            system.debug('Exception::'+ex);
            message = ex.getMessage();
            database.Rollback(sp);
            //'Something went wrong, kindly check with your System Administrator.';
            LoggerService.save(LoggerService.createApexLog(ex,'Direct debit Collection','DirectDebitCollectionController','createDirectDebitTransaction'));
            
        } 
        return message;
    }
    
    private static void createDDTransaction(List<ReceiptAcknowledgement__c> receiptAcknowledgementList, Set<String> installmentCollectionMapSet){
        List<DDTransaction__c> ddTransactionList = new List<DDTransaction__c>();  
        Map<String, DirectDebitRequest__c> installmentDirectdibitRequestMap = getDDAreferenceNumber(installmentCollectionMapSet);
        for(ReceiptAcknowledgement__c receiptAcknowledgement : receiptAcknowledgementList){
            DDTransaction__c ddTransaction = new DDTransaction__c();
            ddTransaction.RequestType__c = 'Collection';
            ddTransaction.TransactionStatus__c =  'Unprocessed';
            ddTransaction.Receipt_Acknowledgement__c = receiptAcknowledgement.Id;
            ddTransaction.CollectionAmount__c = receiptAcknowledgement.Amount__c;
            ddTransaction.DirectDebitRequest__c = installmentDirectdibitRequestMap.get(receiptAcknowledgement.Installment_Line__c).Id != null? installmentDirectdibitRequestMap.get(receiptAcknowledgement.Installment_Line__c).Id : null;
            ddTransaction.DDBank__c = installmentDirectdibitRequestMap.get(receiptAcknowledgement.Installment_Line__c).Id != null ? installmentDirectdibitRequestMap.get(receiptAcknowledgement.Installment_Line__c).DirectDebitBank__c: null;
            ddTransaction.Installment_Line__c = receiptAcknowledgement.Installment_Line__c;
            ddTransactionList.add(ddTransaction);
        }
        if(!ddTransactionList.isEmpty()){
            insert ddTransactionList;
        }
    }
    
    private static void createReceiptAllocation(List<ReceiptAcknowledgement__c> receiptAcknowledgementList){
        List<ReceiptAllocation__c> ReceiptAllocationList = new  List<ReceiptAllocation__c>();
        
        for(ReceiptAcknowledgement__c receiptAcknowledgement: receiptAcknowledgementList){
            ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
            receiptAllocation.ReceiptAcknowledgement__c = receiptAcknowledgement.id;
            receiptAllocation.InstallmentLine__c = receiptAcknowledgement.Installment_Line__c;
            receiptAllocation.Account__c = receiptAcknowledgement.RecievedFromAccount__c;
            receiptAllocation.SalesOrder__c = receiptAcknowledgement.SalesOrder__c;
            receiptAllocation.AmountApplied__c = receiptAcknowledgement.Amount__c;
            ReceiptAllocationList.add(receiptAllocation);
        }
        if(!ReceiptAllocationList.isEmpty()){
            insert ReceiptAllocationList;
        }
        
    }
    public static Map<String, DirectDebitRequest__c> getDDAreferenceNumber(Set<String> installmentIds){
        Set<Id> salesOrderIdSet = new Set<Id>();
        Map<String, String> installmentSaleorderMap = getSalesOrderMap(installmentIds);
        Map<String, DirectDebitRequest__c> saleorderDirectDebitMap = new Map<String, DirectDebitRequest__c>();
        Map<String, DirectDebitRequest__c> installmentDirectdibitRequestMap = new Map<String, DirectDebitRequest__c>();
        
        List<DirectDebitRequest__c> directDebitRequests = [SELECT
                                                           Id,
                                                           DDAreferencenumber__c,
                                                           SalesOrder__c,
                                                           SalesOrder__r.Directdebitauthorityreferencenumber__c,
                                                           DirectDebitBank__c,
                                                           PayerAccount__c,
                                                           PayerAccount__r.Name,
                                                           CustomerBankName__c,
                                                           CustomerBankAccountType__c,
                                                           CustomerBankName_Aldar__c,
                                                           CustomerIBANNumber__c,
                                                           Name
                                                           FROM DirectDebitRequest__c
                                                           WHERE SalesOrder__c IN: installmentSaleorderMap.values()
                                                           AND Status__c NOT IN ('Cancelled', 'Cancellation in progress')
                                                           AND DDAreferencenumber__c != Null];
        
        if(!directDebitRequests.isEmpty()){
            for(DirectDebitRequest__c directdebitRequest: directDebitRequests) {
                if(directdebitRequest.DDAreferencenumber__c == directdebitRequest.SalesOrder__r.Directdebitauthorityreferencenumber__c){
                    saleorderDirectDebitMap.put(directdebitRequest.SalesOrder__c, directdebitRequest);
                }
            }
        }
        for(String installmentId : installmentIds){
            installmentDirectdibitRequestMap.put(installmentId, saleorderDirectDebitMap.get(installmentSaleorderMap.get(installmentId)));
        }
        return installmentDirectdibitRequestMap;
    }
    
    private static Map<String, String> getSalesOrderMap(Set<String> installmentIds){
        Map<String, String> installmentSaleorderMap = new Map<String, String>();
        List<InstallmentLines__c> installmentLines = [SELECT
                                                      SalesOrder__c
                                                      FROM
                                                      InstallmentLines__c
                                                      WHERE ID IN:installmentIds];
        if(!installmentLines.isEmpty()){
            for(InstallmentLines__c installmentLine: installmentLines){
                installmentSaleorderMap.put(installmentLine.id, installmentLine.SalesOrder__c);
            }
        }
        return installmentSaleorderMap;
    }
}