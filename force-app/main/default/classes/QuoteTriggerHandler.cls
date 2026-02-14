public class QuoteTriggerHandler extends TriggerHandler{
    
    
    // ADDED BY CLOUDZLAB START
    
    
    
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        // QuoteTriggerHelper.calculateSecurityDeposit((List<Quote>)newList, new Map<Id, Quote>());
        
        //QuoteTriggerHelper.handleSecurityDeposit((List<Quote>)newList, null);
        
        QuoteTriggerHelper.SLAWithExpirationDate((List<Quote>)newList, null);
    }
    
    // ADDED BY CLOUDZLAB END
    
    
    
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<Id,Quote> oldQuoteMap = new Map<Id,Quote>((List<Quote>)oldList);
        QuoteTriggerHelper.checkAssetAvailabilityForLOI((List<Quote>)newList, oldQuoteMap);
        QuoteTriggerHelper.updateLOISigningDate((List<Quote>)newList, oldQuoteMap);
        
        QuoteTriggerHelper.SLAWithExpirationDate((List<Quote>)newList, oldQuoteMap);
        
        //QuoteTriggerHelper.createPaymentDocumentsForQuote((List<Quote>)newList, oldQuoteMap);
        
        //QuoteTriggerHelper.validatePaymentCollectionFlags((List<Quote>)newList, oldQuoteMap);
        
        // ADDED BY CLOUDZLAB START
        
        // QuoteTriggerHelper.calculateSecurityDeposit((List<Quote>)newList, oldQuoteMap);
        
        //QuoteTriggerHelper.handleSecurityDeposit((List<Quote>)newList, oldQuoteMap);
        
        // ADDED BY CLOUDZLAB END
        
        
    }
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        QuoteTriggerHelper.createQuoteDocuments((List<Quote>)newList);
        
        
    }
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        Map<Id,Quote> oldQuoteMap = new Map<Id,Quote>((List<Quote>)oldList);
        QuoteTriggerHelper.updateAssetStatusForLOI((List<Quote>)newList, oldQuoteMap);
        
        // ADDED BY CLOUDZLAB START
        QuoteTriggerHelper.publishOfferEvents((List<Quote>)newList, oldQuoteMap);
        QuoteTriggerHelper.publishAssetEvents((List<Quote>)newList, oldQuoteMap);
        //QuoteTriggerHelper.handleSecurityDeposit((List<Quote>)newList, oldQuoteMap);
        // ADDED BY CLOUDZLAB END
        
        
    }
}