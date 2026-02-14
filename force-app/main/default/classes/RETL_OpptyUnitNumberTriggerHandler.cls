public class RETL_OpptyUnitNumberTriggerHandler {

    public static void populateUnitNumbers(Set<Id> oppIds) {

        if (oppIds == null || oppIds.isEmpty()) return;

        // Get Record Type safely
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

        if (!rtMap.containsKey('RETL_Opportunity')) return;

        Id rtId = rtMap.get('RETL_Opportunity').getRecordTypeId();

        // Query Opportunities
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id
             FROM Opportunity
             WHERE Id IN :oppIds
             AND RecordTypeId = :rtId]
        );

        if (oppMap.isEmpty()) return;

        // Query OLIs
        List<OpportunityLineItem> oliList = [
            SELECT OpportunityId,
                   PricebookEntry.Product2.ProductCode
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppMap.keySet()
        ];

        // Build Opp → Product Codes
        Map<Id, List<String>> oppToProductCodes = new Map<Id, List<String>>();

        for (OpportunityLineItem oli : oliList) {
            if (oli.PricebookEntry != null &&
                oli.PricebookEntry.Product2 != null &&
                oli.PricebookEntry.Product2.ProductCode != null) {

                if (!oppToProductCodes.containsKey(oli.OpportunityId)) {
                    oppToProductCodes.put(oli.OpportunityId, new List<String>());
                }
                oppToProductCodes.get(oli.OpportunityId)
                    .add(oli.PricebookEntry.Product2.ProductCode);
            }
        }

        // Prepare Opportunity updates
        List<Opportunity> oppToUpdate = new List<Opportunity>();

        for (Id oppId : oppMap.keySet()) {
            Opportunity opp = new Opportunity(Id = oppId);

            if (oppToProductCodes.containsKey(oppId)) {
                opp.UnitNumber__c =
                    String.join(oppToProductCodes.get(oppId), ', ');
            } else {
                // Last OLI deleted
                opp.UnitNumber__c = null;
            }

            oppToUpdate.add(opp);
        }

        if (!oppToUpdate.isEmpty()) {
            update oppToUpdate;
        }
    }
}