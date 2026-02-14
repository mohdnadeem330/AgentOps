public with sharing class SalesOrderCancellationTriggerHandler extends TriggerHandler{
    public SalesOrderCancellationTriggerHandler(){}
    
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){ 
        SOCancellationDocumentsValidation.validateDocumentUpload(oldMap, newList);
    }

    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        System.debug('in side beforeInsertMethod');
        List<SalesOrderCancellation__c> cancellations = (List<SalesOrderCancellation__c>) newList;

        // Step 1: Filter only relevant cancellations (Reason check on top)
        List<SalesOrderCancellation__c> relevantCancellations = new List<SalesOrderCancellation__c>();
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> oppIdsToQuery = new Set<Id>();

        for (SalesOrderCancellation__c soCancel : cancellations) {
            if (soCancel.ReasonforCancellation__c == 'Changing customer name or switching between the joint owners.') {

                relevantCancellations.add(soCancel);

                if (soCancel.SalesOrder__c != null) {
                    salesOrderIds.add(soCancel.SalesOrder__c);
                }
                if (soCancel.New_Buyer_Opportunity__c != null) {
                    oppIdsToQuery.add(soCancel.New_Buyer_Opportunity__c);
                }
            }
        }

        if (relevantCancellations.isEmpty()) {
            return; // nothing to validate
        }

        // Step 2: Query SalesOrders with Opportunities
        Map<Id, Id> salesOrderToOppId = new Map<Id, Id>();
        if (!salesOrderIds.isEmpty()) {
            for (SalesOrder__c so : [
                SELECT Id, Opportunity__c
                FROM SalesOrder__c
                WHERE Id IN :salesOrderIds
            ]) {
                if (so.Opportunity__c != null) {
                    salesOrderToOppId.put(so.Id, so.Opportunity__c);
                    oppIdsToQuery.add(so.Opportunity__c);
                }
            }
        }

        // Step 3: Query all Opportunities in ONE go
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>();
        if (!oppIdsToQuery.isEmpty()) {
            for (Opportunity opp : [
                SELECT Id, LeadSource, EnquiryCategory__c, EnquiryTrigger__c
                FROM Opportunity
                WHERE Id IN :oppIdsToQuery
            ]) {
                oppById.put(opp.Id, opp);
            }
        }

        // Step 4: Validate
        for (SalesOrderCancellation__c soCancel : relevantCancellations) {
            Opportunity oldOpp = soCancel.SalesOrder__c != null ? oppById.get(salesOrderToOppId.get(soCancel.SalesOrder__c)) : null;
            Opportunity newOpp = soCancel.New_Buyer_Opportunity__c != null ? oppById.get(soCancel.New_Buyer_Opportunity__c) : null;

            if (oldOpp != null && newOpp != null) {
                if (oldOpp.LeadSource != newOpp.LeadSource ||
                    oldOpp.EnquiryCategory__c != newOpp.EnquiryCategory__c ||
                    oldOpp.EnquiryTrigger__c != newOpp.EnquiryTrigger__c) {
                    
                    soCancel.addError(
                        'Method of Contact, Enquiry Category, and Enquiry Trigger must match between the old Opportunity and the New Buyer Opportunity for this reason of cancellation.'
                    );
                }
            }
        }
    }
}