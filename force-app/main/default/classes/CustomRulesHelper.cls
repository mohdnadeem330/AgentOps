public with sharing class CustomRulesHelper {


    public class OnloadUnitWrapper {
        @AuraEnabled
        public List<SalesOrder__c> saleorderList; 
        
        @AuraEnabled
        public List<SRUnitSelected__c> unitselectedList;

        @AuraEnabled
        public Decimal AdditionalRebatePer=0;

        @AuraEnabled
        public Decimal AdditionalRebateAmt=0;

        @AuraEnabled
        public String Status;

       
    }

    @AuraEnabled
    public static OnloadUnitWrapper getSOandUnitDetails(String srId){

        HexaBPM__Service_Request__c SRVal = [Select id, HexaBPM__Customer__c, HexaBPM__External_Status_Name__c, Rebate_to_be_Offered__c,Additional_Rebate_Offered__c from HexaBPM__Service_Request__c where id = :srId];
        GenericRuleSet__mdt metadataRecords = [SELECT Amount__c, Maximumperc__c,Outstanding_Amount_perc__c,Status__c, DeveloperName FROM GenericRuleSet__mdt WHERE DeveloperName = 'AdditionalRebate1'];     
        // Decimal value = metadataRecords.Outstanding_Amount_perc__c/100;
        List<SalesOrder__c> SOrderList = [Select id,Name, OtherRebateAmount__c,LastInstallmentRebate__c,
        AdditionalRebate__c,AdditionalRebate2__c,UnitSellingPrice__c,SellingPrice__c, Status__c,UnitNumber__c,OutstandingAmount__c,NetAmount__c, Unit__c,TotalOutstanding__c,RebateForfeitureLetterSent__c from SalesOrder__c
        where Account__c = :SRVal.HexaBPM__Customer__c AND Status__c =:metadataRecords.Status__c AND TotalOutstanding__c > 0];
        
        OnloadUnitWrapper Wrapper=new OnloadUnitWrapper();
        Wrapper.saleorderList=SOrderList;
        Wrapper.unitselectedList=getSelectedUnits(srId,SOrderList);
        if(SRVal.Rebate_to_be_Offered__c!=null){
            Wrapper.AdditionalRebatePer=SRVal.Rebate_to_be_Offered__c;
        }
        if(SRVal.Additional_Rebate_Offered__c!=null){
        Wrapper.AdditionalRebateAmt=SRVal.Additional_Rebate_Offered__c;
        }
        if(SRVal.HexaBPM__External_Status_Name__c!= null)
        {
        Wrapper.Status=SRVal.HexaBPM__External_Status_Name__c;
        }
        return Wrapper;
    }


    @AuraEnabled
    public static List<SRUnitSelected__c> getSelectedUnits(String srId,List<SalesOrder__c> SOrderList){
        List<SRUnitSelected__c> selectedUnitList=[select Id,Name,ServiceRequest__c,OutstandingAmount__c,Unit_Selling_Price__c,SellingPrice__c,SalesOrder__c, Unit__c,Rebate_Percentage__c,Previous_Rebate_Offered__c from SRUnitSelected__c  where ServiceRequest__c=:srId];       
        List<SRUnitSelected__c> srUnitList=new  List<SRUnitSelected__c>();
        if(selectedUnitList.isEmpty()){
            for(SalesOrder__c so:SOrderList){
                SRUnitSelected__c srUnit=new SRUnitSelected__c();
                srUnit.Name=so.UnitNumber__c;
                srUnit.OutstandingAmount__c=so.TotalOutstanding__c;
                if(so.RebateForfeitureLetterSent__c == false ){
                    srUnit.Previous_Rebate_Offered__c=rebateAmountSum(so);
                } 
                srUnit.ServiceRequest__c=srId;
                srUnit.Unit__c=so.Unit__c;
                srUnit.SalesOrder__c = so.id;
                srUnit.Unit_Selling_Price__c = so.UnitSellingPrice__c;
                srUnitList.add(srUnit);
            }
        }
        if(!srUnitList.isEmpty()){
            insert srUnitList;
            selectedUnitList=srUnitList;
        }
        return selectedUnitList;
    }

    @AuraEnabled
    public static void createSelectedUnits(List<SRUnitSelected__c> srUnitList, String srId,Decimal percentage, Decimal ammount){       
        update srUnitList;

        HexaBPM__Service_Request__c serviceRequest=new HexaBPM__Service_Request__c();
        serviceRequest.Id=srId;
        serviceRequest.Rebate_to_be_Offered__c=percentage;
        serviceRequest.Additional_Rebate_Offered__c=ammount;
        update serviceRequest;
    }

    @AuraEnabled
    public static void RemoveSelectedUnits(List<String> deleteIds, String srId){
        List<SRUnitSelected__c> srUnitListUpdate = new List<SRUnitSelected__c>();     
        for(String inputSRUnit :deleteIds){              
            SRUnitSelected__c srUnit = new SRUnitSelected__c();
            srUnit.Rebate_Percentage__c = null;
            srUnit.Id=inputSRUnit;
            srUnitListUpdate.add(srUnit);
        }

        HexaBPM__Service_Request__c serviceRequest=new HexaBPM__Service_Request__c();
        serviceRequest.Id=srId;
        serviceRequest.Rebate_to_be_Offered__c=0;
        serviceRequest.Additional_Rebate_Offered__c=0;
        update serviceRequest;

       update srUnitListUpdate;
    }

    @AuraEnabled
    public static void createSOA(String srId){
        Set<Id> soIdList = new Set<Id>();
        Set<Id> unitIdList = new Set<Id>();
        
        HexaBPM__Service_Request__c serviceRequest = [SELECT Id, HexaBPM__External_Status_Code__c, HexaBPM__Customer__c 
                                                      FROM HexaBPM__Service_Request__c 
                                                      WHERE Id = :srId];
        
        GenericRuleSet__mdt metadataRecords = [SELECT Amount__c, Maximumperc__c, Outstanding_Amount_perc__c, Status__c, DeveloperName 
                                               FROM GenericRuleSet__mdt 
                                               WHERE DeveloperName = 'AdditionalRebate1'];
        
        for (SRUnitSelected__c unit : [SELECT Id, ServiceRequest__c, Unit__c, SalesOrder__c, Rebate_Percentage__c
                                        FROM SRUnitSelected__c 
                                        WHERE ServiceRequest__c = :srId AND Rebate_Percentage__c > 0]) {
            unitIdList.add(unit.Unit__c);
        }
        
        List<SalesOrder__c> SOrderList = [SELECT Id, Unit__c, Account__c, Status__c, OutstandingAmount__c,TotalOutstanding__c
                                          FROM SalesOrder__c 
                                          WHERE Unit__c IN :unitIdList 
                                          AND Account__c = :serviceRequest.HexaBPM__Customer__c
                                          AND Status__c = :metadataRecords.Status__c 
                                          AND TotalOutstanding__c > 0];
        
        for (SalesOrder__c so : SOrderList) {
            soIdList.add(so.Id);
        }
        
        System.debug('SOrderList: ' + SOrderList);
        
        if (!SOrderList.isEmpty()) {
            String jobType = (serviceRequest.HexaBPM__External_Status_Code__c == 'Approved by CCO' || 
                              serviceRequest.HexaBPM__External_Status_Code__c == 'Verified by Finance' || 
                              serviceRequest.HexaBPM__External_Status_Code__c =='Pending Finance Verification')
                              ? 'Revised SOA' 
                              : null;
        
            if (jobType != null) {
                System.enqueueJob(new RebateDocGeneration(SOrderList, srId, jobType));
                if (!soIdList.isEmpty()) {
                    Database.executeBatch(new RebateERPSOABatch(soIdList, srId, jobType), 1);
                }
            } else {
                System.enqueueJob(new RebateDocGeneration(SOrderList, srId));
                if (!soIdList.isEmpty()) {
                    Database.executeBatch(new RebateERPSOABatch(soIdList, srId), 1);
                }
            }
        }
        

    }


    // public static void UpdateRebateAmountOnUnits(String srId){
    //     List<SRUnitSelected__c> UnitList = new List<SRUnitSelected__c>();
    //     List<SalesOrder__c> soList = new List<SalesOrder__c>();
    //             for(SRUnitSelected__c so :[Select id,SalesOrder__c, Unit__c,Rebate_Percentage__c,OutstandingAmount__c from SRUnitSelected__c where ServiceRequest__c = :srId])
    //             {
    //                 UnitList.add(new SRUnitSelected__c(id =so.id, Rebate_Amount__c = so.OutstandingAmount__c* (so.Rebate_Percentage__c/100)));
    //                 soList.add(new SalesOrder__c(id =so.SalesOrder__c, Rebate_Amount__c = so.OutstandingAmount__c* (so.Rebate_Percentage__c/100)));
    //             }
    //             system.debug('UnitList' +UnitList);
    //            Update UnitList;
    //            Update soList;
    // }

     //Monika: Create Additional Rebate Request

     public static void handleAdditionalRebateReceipt(String srId){
        // Retrieve the service request record
        HexaBPM__Service_Request__c SRVal = [SELECT Id, HexaBPM__Customer__c, Additional_Rebate_Offered__c
                                              FROM HexaBPM__Service_Request__c 
                                              WHERE Id = :srId];
        List<SRUnitSelected__c> selectedUnitList = [select Id, Name,ServiceRequest__c,Unit__c,Rebate_Percentage__c,SalesOrder__c,SalesOrder__r.Opportunity__c
                                                FROM SRUnitSelected__c where ServiceRequest__c=:srId AND Rebate_Percentage__c > 0];
        if (SRVal.Additional_Rebate_Offered__c> 0) {
           
            List<ReceiptAcknowledgement__c> receiptAcknowledgments = new List<ReceiptAcknowledgement__c>();

            for(SRUnitSelected__c unitSelected: selectedUnitList)
            {
                String PaymentType =Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE;
                String PaymentsubType =Constants.PAYMENT_SUB_TYPE_REBATE;
                Decimal amount = (SRVal.Additional_Rebate_Offered__c * unitSelected.Rebate_Percentage__c/100);
                ReceiptAcknowledgement__c rack = createReceiptAcknowledgment(SRVal, amount,PaymentType,PaymentsubType,unitSelected.SalesOrder__c, unitSelected.SalesOrder__r.Opportunity__c);
                receiptAcknowledgments.add(rack);
            }   
             insert receiptAcknowledgments;
           // insert rallocList;
        }
    }
    
    // Helper method to create a receipt acknowledgment
    public static ReceiptAcknowledgement__c createReceiptAcknowledgment(HexaBPM__Service_Request__c sr, Decimal amount, String PaymentType, String PaymentsubType, String soId, String oppId) {
        ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
            Account__c = sr.HexaBPM__Customer__c,
            ServiceRequest__c = sr.Id,
            PaymentType__c = PaymentType,
            PaymentSubType__c = PaymentsubType,
            Remarks__c = Constants.BUDGET_LINE_REBATE,
            IsStopSyncingWithERP__c = true,
            Amount__c = amount,
            SalesOrder__c = soId,
            Opportunity__c = oppId
        );
        return ra;
    }

    // public static List<ReceiptAllocation__c> prepareRAlloc(HexaBPM__Service_Request__c sRRecord, ReceiptAcknowledgement__c rack, String type) {
    //     set<Id> soId = new set<Id>();
    //     List<ReceiptAllocation__c> rallocList = new List<ReceiptAllocation__c>();
    //     // if(type == 'Credit Note')
    //     // {
    //         for (SRUnitSelected__c unit : [Select id,SalesOrder__c, Unit__c from SRUnitSelected__c where ServiceRequest__c = :sRRecord.id] )
    //         {
    //     //     ReceiptAllocation__c ralloc = new ReceiptAllocation__c();
    //     //     ralloc.TypeOfInvoice__c = type;
    //     //     ralloc.ReceiptAcknowledgement__c = rack.Id;
    //     //     ralloc.Account__c = sRRecord.HexaBPM__Customer__c;
    //     //     ralloc.SalesOrder__c = unit.SalesOrder__c;
    //     //     ralloc.AmountApplied__c = unit.Rebate_Amount__c;
    //     //     ralloc.IsStopSyncingWithERP__c = true;
    //     //     rallocList.add(ralloc);
    //             soId.add(unit.SalesOrder__c);
    //     //     }
    //      }
    //     // else{
    //         List<SalesOrder__c> SalesOrderList = [select id, OutstandingAmount__c, (select id, name from InstallmentLines__r) from SalesOrder__c where id IN :soId];
    //         if(!SalesOrderList.isEmpty())
    //         {
    //         for(SalesOrder__c so :SalesOrderList)
    //         {
    //         ReceiptAllocation__c ralloc = new ReceiptAllocation__c();
    //         Integer len = so.InstallmentLines__r.size();
    //         if(len > -1)
    //         {
    //         ralloc.InstallmentLine__c = so.InstallmentLines__r[len - 1].id;
    //         }
    //         ralloc.TypeOfInvoice__c = type;
    //         ralloc.ReceiptAcknowledgement__c = rack.Id;
    //         ralloc.Account__c = sRRecord.HexaBPM__Customer__c;
    //         ralloc.SalesOrder__c = so.id;
    //        // ralloc.AmountApplied__c = type == 'Credit Note' ? so.Rebate_Amount__c : (so.OutstandingAmount__c - so.Rebate_Amount__c);
    //         ralloc.IsStopSyncingWithERP__c = true;
    //         rallocList.add(ralloc);
    //         }
    
    //     }
    //     return rallocList;
    // }

    /**
     * call for Receipt and ERP Integration on after Payment Verification step.
     */

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }

    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>(); 
        Set<Id> soIds = new Set<Id>();
        Map<String, Object> finalMap = new Map<String, Object>();
        Map<Id, decimal> soIdandAmountList = new Map<Id, decimal>();

        try{
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) { 
            srIds.add(serviceRequest.Id);  
            for (ReceiptAcknowledgement__c recpt: serviceRequest.Receipt_Acknowledgements__r){
                if(recpt.PaymentType__c == CONSTANTS.OTHER_CHARGES_TYPE_CREDIT_NOTE)  
                {            
                    soIdandAmountList.put(recpt.SalesOrder__c, recpt.Amount__c);
                    soIds.add(recpt.SalesOrder__c);
                       
                List<Object> RebateList = new List<Object>();
                Map<String, Object> tempObj = new Map<String, Object>();
                string integrationType = 'ADR';

                    tempObj.put('sfServiceReqId', serviceRequest.Id);
                    tempObj.put('sfSalesOrderId', recpt.SalesOrder__c);
                    tempObj.put('type', integrationType);
                    tempObj.put('raSfId',recpt.id);
                    tempObj.put('rebateAmount', String.Valueof(recpt.Amount__c));
                    RebateList.add(tempObj);                
                
                    finalMap.put('handoverRq', RebateList);

                    String requestBody = JSON.serialize(finalMap);
                    requestBody = requestBody.replace(':null', ':""');
                    System.debug('requestBody>>>' + requestBody);

                    if (!RebateList.isEmpty()) {
                    System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, 'RebateRequest', srIds));
                }
            }
        }
    }
        }
        catch(Exception e)
        {
            system.debug(e.getMessage() + 'Line Number' + e.getLineNumber());
        }

        if(!soIdandAmountList.isEmpty() && !soIds.isEmpty())
        {
            updateSaleOrder(soIdandAmountList, soIds);
        }
    }

    public static void updateSaleOrder(Map<Id, decimal> soIdandAmountList, Set<Id> soIds)
    {
        //SalesOrder__c so : [Select Id, AdditionalRebate__c, AdditionalRebate2__c from SalesOrder__c where Id IN
        List<SalesOrder__c> soList = new List<SalesOrder__c>();
        for(SalesOrder__c so : [Select Id, AdditionalRebate__c, AdditionalRebate2__c from SalesOrder__c where Id IN : soIds])
        {
            if(so.AdditionalRebate__c <= 0 || so.AdditionalRebate__c == null)
            {
                so.AdditionalRebate__c = soIdandAmountList.get(so.Id);
            }
            else if(so.AdditionalRebate2__c <= 0 || so.AdditionalRebate2__c == null) {
            
                so.AdditionalRebate2__c = soIdandAmountList.get(so.Id);
            }
            else if(so.AdditionalRebate2__c > 0) {
            
                so.AdditionalRebate2__c += soIdandAmountList.get(so.Id);
            }
            soList.add(so);
        }
        update soList;
    }

    /**
     * Update ERP Response
     */

    public static void processRebateRequestResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        List<Logger__c> loggerList = new List<Logger__c>();
             
        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        
        List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            HexaBPM__Service_Request__c srRecord = [SELECT Id, ERPID__c, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id = :responseRecord.sfServiceReqId];
            try{

            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
				if(srRecord.ERPID__c == null || srRecord.ERPID__c == '')
				{ srRecord.ERPID__c =  responseRecord.erpId;
				}
				else{
				srRecord.ERPID__c = srRecord.ERPID__c + ',' + responseRecord.erpId;
                }
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = 0;
                srRecord.ErrorReason__c = '';
                srSuccessList.add(srRecord);

                // if(!String.isBlank(responseRecord.raSfId)){
                //     ReceiptAcknowledgement__c receiptRec = new ReceiptAcknowledgement__c();
                //     receiptRec.Id = responseRecord.raSfId;
                //    //receiptRec.ERPID__c = responseRecord.rebateERPId ;
                //     receiptRec.SyncStatus__c = Constants.STATUS_SYNCED;
                //     receiptRec.SyncTime__c = Datetime.now();
                //     receiptList.add(receiptRec);
                // }
            } else if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srRecord.RetryCount__c == null ? 1 : srRecord.RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
                }
            }
        catch(Exception e)
            {
                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
            }
        }
        if (!srSuccessList.isEmpty()) {
            update srSuccessList;
        }

        // if (!receiptList.isEmpty()) {
        //     update receiptList;
        // }
        
        if (!srFailedList.isEmpty()) {
            update srFailedList;
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }    
    }


    public static decimal rebateAmountSum(SalesOrder__c so){

        decimal rebateTotal=0;
        if (so.AdditionalRebate__c != null) {
            rebateTotal += so.AdditionalRebate__c;
        }

        if (so.AdditionalRebate2__c != null) {
            rebateTotal += so.AdditionalRebate2__c;
        }

        if(so.LastInstallmentRebate__c !=null){
            rebateTotal += so.LastInstallmentRebate__c;
        }

        if (so.OtherRebateAmount__c !=null){
            rebateTotal += so.OtherRebateAmount__c; 
        }

        return rebateTotal;

    }

}