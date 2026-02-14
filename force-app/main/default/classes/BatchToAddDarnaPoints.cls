global class BatchToAddDarnaPoints implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
  
    public List<String> rallFieldList = new List<String>{'InstallmentLine__r.SalesOrder__r.BookingDate__c','ReceiptAcknowledgement__r.ClearedDate__c','InstallmentLine__r.SalesOrder__r.TotalInstallmentNo__c','InstallmentLine__r.SalesOrder__r.NetAmount__c','InstallmentLine__r.SalesOrder__r.Unit__r.CommunityName__c','InstallmentLine__r.SalesOrder__r.Unit__r.PropertyUsage__c','InstallmentLine__r.SalesOrder__r.Unit__r.Name','ReceiptAcknowledgement__r.Name','InstallmentLine__r.HandoverPayment__c','InstallmentLine__r.InstallmentNumber__c','InstallmentLine__r.Name','InstallmentLine__r.AmountReceived__c','InstallmentLine__r.InstallmentAmount__c','InstallmentLine__r.IsDarnaAmountProcessed__c','InstallmentLine__r.DarnaAmountProcessed__c','InstallmentLine__r.InstallmentDate__c','InstallmentLine__r.Description__c','ReceiptAcknowledgement__r.Amount__c','ReceiptAcknowledgement__r.Installment_Amount__c','ReceiptAcknowledgement__r.AmountApplied__c','ReceiptAcknowledgement__r.ReceiptDate__c','ReceiptAcknowledgement__r.IsDarnaAmountProcessed__c','ReceiptAcknowledgement__r.DarnaAmountProcessed__c','ReceiptAcknowledgement__r.PaymentType__c','Account__r.PersonEmail','Account__r.PersonMobilePhone','Account__r.DarnaMembershipNumber__pc','SalesOrder__r.UnitNumber__c','SalesOrder__r.UnitType__c','SalesOrder__r.BookingDate__c','SalesOrder__r.NetAmount__c','SalesOrder__r.SellingPrice__c','SalesOrder__r.Unit__r.Project__c','SalesOrder__r.Unit__r.Project__r.Name','SalesOrder__r.Unit__r.Project__r.ConceptName__c','SalesOrder__r.Unit__r.Project__r.ConceptId__c','SalesOrder__r.Unit__r.UnitNumber__c','SalesOrder__r.TotalInstallmentNo__c','SalesOrder__r.Unit__r.PropertyUsage__c','SalesOrder__r.Unit__r.CommunityName__c','SalesOrder__r.Unit__r.Name'};
    public String rallFields = '';
    public String query;
  
    public BatchToAddDarnaPoints(String query){
        this.rallFieldList.addAll(Schema.getGlobalDescribe().get('ReceiptAllocation__c').getDescribe().fields.getMap().keySet());
        this.rallFields = string.join(rallFieldList,',');
        this.query = query;
    }
    
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToAddDarnaPoints(null), 1);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String soldStatus = Constants.SO_STATUS_SOLD;
        Date clearedDateFrom = Date.valueOf(System.label.DarnaClearedDateFrom);
        String rtoSoldStatus = Constants.SO_STATUS_RTO_SOLD;
        Date SalesOrderBookingDate = Date.valueOf(Utilities.getConstant(Constants.SALES_ORDER_BOOKING_DATE).ConstantValue__c);
        Date offerEndDate = Date.valueOf(Utilities.getConstant(Constants.OFFER_END_DATE).ConstantValue__c);
        Date ReceiptClearedDate = Date.valueOf(Utilities.getConstant(Constants.RECEIPT_CLEARED_DATE).ConstantValue__c);
  	    String modifedQuery = 'SELECT Id FROM ReceiptAcknowledgement__c';
        // modifedQuery += ' AND Id IN :specificRAIdSet'; //********** SalesOrder__c!=null AND ReceiptDate__c !=null (Newly added)*********//
        modifedQuery += ' WHERE Status__c = \'Cleared\' AND ClearedDate__c >: clearedDateFrom AND SalesOrder__c!=null AND ReceiptDate__c !=null AND Id IN (SELECT ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE Don_tSkipDarnaWarning__c = false AND AmountApplied__c > 0 AND IsReceiptAllocationForDarna__c = false AND ReceiptAcknowledgement__r.IsDarnaAmountProcessed__c = false AND InstallmentLine__c!=null AND SalesOrder__c !=null AND (SalesOrder__r.Status__c =: soldStatus OR SalesOrder__r.Status__c =: rtoSoldStatus) AND SalesOrder__r.DARNAAmount__c > 0 AND SalesOrder__r.BookingDate__c!=null AND SalesOrder__r.BookingDate__c >=: SalesOrderBookingDate AND SalesOrder__r.BookingDate__c <=: offerEndDate AND ReceiptAcknowledgement__r.ClearedDate__c >=: ReceiptClearedDate AND SalesOrderOtherCharges__c = null AND SalesOrder__r.Unit__r.Project__r.ConceptId__c!=null AND  SalesOrder__r.Unit__r.Project__r.ConceptName__c!=null) Order by SalesOrder__r.Unit__r.Project__r.Name';
        if(Test.isRunningTest()){
            modifedQuery = 'SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1';
        }
        if(query <> null && query <> ''){
            modifedQuery = query;
        }
        return Database.getQueryLocator(modifedQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<ReceiptAcknowledgement__c> receiptAcknowledgementList) {
       // System.debug('size:'+receiptAcknowledgementList.size());
        Date clearedDateFrom = Date.valueOf(System.label.DarnaClearedDateFrom);
        Map<Id,List<ReceiptAllocation__c>> receiptAcknowledgementAndAllocationsMap = new Map<Id,List<ReceiptAllocation__c>>();
        String receiptAllocationToQuery = 'SELECT ' + rallFields + ' FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN :receiptAcknowledgementList AND ReceiptAcknowledgement__r.IsDarnaAmountProcessed__c = false AND IsReceiptAllocationForDarna__c = false AND Don_tSkipDarnaWarning__c = false AND ReceiptAcknowledgement__r.ClearedDate__c >: clearedDateFrom';
        if(Test.isRunningTest()){
            receiptAllocationToQuery = 'SELECT ' + rallFields + ' FROM ReceiptAllocation__c';
        }
        List<ReceiptAllocation__c> ReceiptAllocationList = Database.Query(receiptAllocationToQuery); 
        Map<String,List<ReceiptAllocation__c>> receiptAllocMap = new Map<String,List<ReceiptAllocation__c>>();
        for(ReceiptAllocation__c receipt : ReceiptAllocationList){           
            if(receipt.SalesOrder__r.Unit__r.Project__r.ConceptId__c!=null){
                if(!receiptAllocMap.isEmpty() && receiptAllocMap.containsKey(receipt.SalesOrder__r.Unit__r.Project__r.ConceptId__c)){
                receiptAllocMap.get(receipt.SalesOrder__r.Unit__r.Project__r.ConceptId__c).add(receipt);
                }else{              
                    receiptAllocMap.put(receipt.SalesOrder__r.Unit__r.Project__r.ConceptId__c, new List<ReceiptAllocation__c>{receipt});
                }
            }
            
        }
        
        if(!receiptAllocMap.isEmpty()){
           //  System.debug('keySet()'+receiptAllocMap.keySet());
           //  System.debug('receiptAllocMap'+receiptAllocMap);
             System.enqueueJob(new BatchToAddDarnaPointsQueable(receiptAllocMap));
        }        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}