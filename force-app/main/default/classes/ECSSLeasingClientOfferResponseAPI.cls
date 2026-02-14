@RestResource(urlMapping='/ClientOLResponseAPI')
global with sharing class ECSSLeasingClientOfferResponseAPI {
    
    private static final String OPPORTUNITY_STAGE_BOOKED = 'Booked';
    private static final String NOTIFICATION_NAME = 'ECSS_Offer_Letter_Status';
    
    global class BookingRequest {
        public Id quoteId;
        public String quoteStatus;
        public String reason;
    }
    global class BookingResponse {
        public Id quoteId;
        public Boolean success;
        public String message;
        public BookingResponse(Id qId, Boolean ok, String msg) {
            this.quoteId = qId; this.success = ok; this.message = msg;
        }
    }
    
    @HttpPost
    global static List<BookingResponse> doPost() {
        RestRequest req = RestContext.request;
        List<BookingResponse> responses = new List<BookingResponse>();
        List<BookingRequest> payload;
        try {
            payload = (List<BookingRequest>) JSON.deserialize(req.requestBody.toString(), List<BookingRequest>.class);
            if (payload == null || payload.isEmpty()) {
                throw new AuraHandledException('Empty payload');
            }
        } catch (Exception ex) {
            responses.add(new BookingResponse(null, false, 'Invalid payload: ' + ex.getMessage()));
            RestContext.response.statusCode = 400;
            return responses;
        }
        
        Set<Id> quoteIds = new Set<Id>();
        for (BookingRequest br : payload){
            if (br.quoteId != null) {
                quoteIds.add(br.quoteId);
            }
        } 
        if (quoteIds.isEmpty()) {
            responses.add(new BookingResponse(null, false, 'No quoteId provided in payload'));
            RestContext.response.statusCode = 400;
            return responses;
        }
        
        Map<Id, Quote> quotesById = new Map<Id, Quote>([SELECT Id, Name, ContactId, Contact.Email, OpportunityId, OwnerId,ECSS_OfferStatus__c, Status, AdditionalName,ECSS_TAF_Collection__c, ECSS_Booking_Fee_Collection__c, ECSS_Security_Deposit_Collection__c  FROM Quote WHERE Id IN :quoteIds]);
        
        List<QuoteLineItem> qliSelect = [SELECT Id, QuoteId, Asset__c FROM QuoteLineItem WHERE QuoteId IN : quoteIds]; 
        Set<Id> assetIds = new Set<Id>();
        Map<Id, set<Id>> quoteToAssetIds = new Map<Id, set<Id>>();
        
        if(!qliSelect.isEmpty()){
            for (QuoteLineItem qli : qliSelect) {
                
                assetIds.add(qli.Asset__c);
                if (!quoteToAssetIds.containsKey(qli.QuoteId)) {
            quoteToAssetIds.put(qli.QuoteId, new Set<Id>());
        }
        quoteToAssetIds.get(qli.QuoteId).add(qli.Asset__c);
                
            }
        }
        
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        if (!assetIds.isEmpty()) {
            for (Asset a : [SELECT Id, Status FROM Asset WHERE Id IN :assetIds]) {
                assetsById.put(a.Id, a);
                
            }
        }
        
        Set<Id> opportunityIds = new Set<Id>();
        for (Quote q : quotesById.values()){
            if (q.OpportunityId != null) {
                opportunityIds.add(q.OpportunityId);
            }
        }
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>();
        if (!opportunityIds.isEmpty()) {
            for (Opportunity o : [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIds]) {
                oppById.put(o.Id, o);
            }
        }
        
        List<Asset> assetsToUpdate = new List<Asset>();
        List<Quote> quotesToUpdate = new List<Quote>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id, String> agentNotifications = new Map<Id, String>();
        
        for (BookingRequest br : payload) {
            if (br.quoteId == null) {
                responses.add(new BookingResponse(null, false, 'Missing quoteId'));
                continue;
            }
            Quote q = quotesById.get(br.quoteId);
            if (q == null) {
                responses.add(new BookingResponse(br.quoteId, false, 'Quote not found'));
                continue;
            }
            
            Boolean accepted = false;
            String statusLower = (br.quoteStatus == null) ? '' : br.quoteStatus.trim().toLowerCase();
            if (statusLower == 'accepted' || statusLower == 'accept' || statusLower == 'booked') {
                accepted = true;
            }
            
            if(accepted){
                if(q.ECSS_TAF_Collection__c && q.ECSS_Booking_Fee_Collection__c && q.ECSS_Security_Deposit_Collection__c){
                    try {
                        Quote qUpd = new Quote(Id = q.Id);
                        qUpd.status = 'Booked';
                        qUpd.ECSS_OfferStatus__c = 'Released';
                        qUpd.ECSS_SLA_Date__c = null;
                        quotesToUpdate.add(qUpd);
                          system.debug('test5');
                        
                        set<Id> relatedAssetIds = quoteToAssetIds.containsKey(q.Id) ? quoteToAssetIds.get(q.Id) : new set<Id>();
                        for (Id aId : relatedAssetIds) {
                            Asset a = assetsById.get(aId);
                            if (a == null) continue;
                            Asset assetCopy = new Asset(Id = a.Id);
                            assetCopy.Status = 'Booked with Payments';
                            assetsToUpdate.add(assetCopy);
                              system.debug('test5');
                        }
                        
                        if (accepted && q.OpportunityId != null) {
                            Opportunity o = oppById.get(q.OpportunityId);
                            if (o != null) {
                                Opportunity oUpd = new Opportunity(Id = o.Id);
                                oUpd.StageName = OPPORTUNITY_STAGE_BOOKED;
                                oppsToUpdate.add(oUpd);
                            }
                        } 
                        responses.add(new BookingResponse(q.Id, true, 'Processed'));
                    } catch (Exception e) {
                        responses.add(new BookingResponse(q.Id, false, 'Error: ' + e.getMessage()));
                    }
                } else {
                    try{
                    set<Id> relatedAssetIds = quoteToAssetIds.containsKey(q.Id) ? quoteToAssetIds.get(q.Id) : new set<Id>();
                    system.debug('relatedAssetIds'+ relatedAssetIds);
                    for (Id aId : relatedAssetIds) {
                        Asset a = assetsById.get(aId);
                        if (a == null) continue;
                        Asset assetCopy = new Asset(Id = a.Id);
                        assetCopy.Status = 'Booked';
                        assetsToUpdate.add(assetCopy);
                         system.debug('assetsToUpdate'+ assetsToUpdate);
                    }
                    Quote qUpd = new Quote(Id = q.Id);
                    qUpd.Status = 'Accepted'; 
                    qUpd.ECSS_OfferStatus__c = 'Released';
                    qUpd.ECSS_SLA_Date__c = null;    
                    quotesToUpdate.add(qUpd);
                      system.debug('test4');
                         responses.add(new BookingResponse(q.Id, true, 'Processed'));
                    } catch (Exception e) {
                        responses.add(new BookingResponse(q.Id, false, 'Error: ' + e.getMessage()));
                }
                }
                    

            }else{
                try{
                set<Id> relatedAssetIds = quoteToAssetIds.containsKey(q.Id) ? quoteToAssetIds.get(q.Id) : new set<Id>();
                for (Id aId : relatedAssetIds) {
                    Asset a = assetsById.get(aId);
                    if (a == null) continue;
                    Asset assetCopy = new Asset(Id = a.Id);
                    assetCopy.Status = 'Available for Lease';
                    assetsToUpdate.add(assetCopy);
                }
                Quote qUpd = new Quote(Id = q.Id);
                qUpd.Status = 'Rejected'; 
                qUpd.ECSS_OfferStatus__c = 'Cancelled';
                qUpd.AdditionalName = br.reason;
                qUpd.ECSS_SLA_Date__c = null;
                quotesToUpdate.add(qUpd);
                  system.debug('test3');
                 responses.add(new BookingResponse(q.Id, true, 'Processed'));
                    } catch (Exception e) {
                        responses.add(new BookingResponse(q.Id, false, 'Error: ' + e.getMessage()));
            }
        }
        }
        
        try {
            if (!assetsToUpdate.isEmpty()) update assetsToUpdate;
            if (!quotesToUpdate.isEmpty()) update quotesToUpdate;
            if (!oppsToUpdate.isEmpty()) update oppsToUpdate;
            system.debug('test2');
        } catch (DmlException dmlEx) {
            for (BookingResponse br : responses) if (br.success) br.message += ' (Partial failure: ' + dmlEx.getMessage() + ')';
              system.debug('test1');
        }
        return responses;
    }
    
    private static String joinIds(Set<Id> ids) {
        List<String> quoted = new List<String>();
        for (Id i : ids) quoted.add('\'' + String.escapeSingleQuotes(String.valueOf(i)) + '\'');
        return String.join(quoted, ',');
    }
}