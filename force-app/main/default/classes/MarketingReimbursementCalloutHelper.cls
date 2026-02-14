public class MarketingReimbursementCalloutHelper {
    public static void PrepareDataForCallout(List<Id> brIds){
        List<BrokerRequest__c> brList = BrokerRequestService.queryAllFieldsWithExtraFields(brIds);
        Map<String,String> mapDocumentIdToBrokerRequestId = new Map<String,String>();
        Map<Id, String> publicURLMap = new Map<Id, String>();

        for(Document__c doc : [SELECT Id, BrokerRequest__c, DocumentType__c, AvailableForExternalUsers__c FROM Document__c 
                               WHERE DocumentType__c = 'Broker Marketing Reimbursement' AND BrokerRequest__c IN: brIds]) {

            mapDocumentIdToBrokerRequestId.put(doc.Id, doc.BrokerRequest__c);  
        }
        System.debug('mapDocumentIdToBrokerRequestId--->'+mapDocumentIdToBrokerRequestId);
      
        List<ContentDistribution> listContentDistr = new List<ContentDistribution>();
        if(!mapDocumentIdToBrokerRequestId.keySet().isEmpty()){
            listContentDistr = [SELECT Id, DistributionPublicUrl, RelatedRecordId FROM ContentDistribution WHERE 
                                RelatedRecordId IN :mapDocumentIdToBrokerRequestId.keySet()];
        }

        System.debug('listContentDistr---'+listContentDistr);
        
        for (ContentDistribution cd : listContentDistr) {
            if (publicURLMap.containsKey(mapDocumentIdToBrokerRequestId.get(cd.RelatedRecordId))) {
                publicURLMap.put(mapDocumentIdToBrokerRequestId.get(cd.RelatedRecordId), (publicURLMap.get(mapDocumentIdToBrokerRequestId.get(cd.RelatedRecordId)) + ',' + cd.DistributionPublicUrl));
            } else {
                publicURLMap.put(mapDocumentIdToBrokerRequestId.get(cd.RelatedRecordId), cd.DistributionPublicUrl);
            }
        }
        System.debug('publicURLMap--->'+publicURLMap);

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> mrdList = new List<Object>();

        List<Id> recordIds = new List<Id>();
        for (BrokerRequest__c br: brList) {
            if (String.isBlank(br.AgencyName__r.ERPID__c)) {
                continue;
            }
            
            recordIds.add(br.Id);
            Map<String, Object> mrdMap = new Map<String, Object>();

            mrdMap.put('agencyId', br.AgencyName__r.ERPID__c);
            mrdMap.put('agentId', br.CreatedBy.Contact != null ? br.CreatedBy.Contact.ERPID__c : '');
            mrdMap.put('invoiceNumber', br.Name);
            mrdMap.put('invoiceDate', br.InvoiceDate__c);
            mrdMap.put('invoiceAmount', String.valueOf(br.InvoiceAmount__c));
            mrdMap.put('taxAmount', String.valueOf(br.TaxAmount__c));
            mrdMap.put('totalAmount', String.valueOf(br.TotalAmount__c));
            mrdMap.put('marketingCategory', br.MarketingCategories__c);
            mrdMap.put('comments', br.Comment__c);
            mrdMap.put('url', (publicURLMap.containsKey(br.Id) && publicURLMap.get(br.Id) != null) ? publicURLMap.get(br.Id) : '');
            mrdMap.put('sfId', br.Id);

            mrdList.add(mrdMap);
        }
        
        finalMap.put('mrktReimburseRq', mrdList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replaceAll(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!mrdList.isEmpty() && System.isFuture() == false) {
            if (System.IsBatch() == true) { 
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.MARKETING_REIMBURSEMENT_INTEGRATION, recordIds);
            } else {
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.MARKETING_REIMBURSEMENT_INTEGRATION, recordIds);
            }
        }
    }
}