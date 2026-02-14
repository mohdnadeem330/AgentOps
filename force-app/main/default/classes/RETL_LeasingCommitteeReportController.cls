public with sharing class RETL_LeasingCommitteeReportController {
    /**
     * Updates a specific field on the Opportunity record with the provided JSON data.
     * @param oppId The ID of the Opportunity record to update.
     * @param dataJson The JSON string containing the dynamic table data.
     */
    @AuraEnabled
    public static void saveCommitteeData(Id templateId, String dataJson) {
        if (templateId == null) {
            throw new AuraHandledException('Template ID is required.');
        }
        if (String.isBlank(dataJson)) {
            throw new AuraHandledException('Data JSON cannot be empty.');
        }

        try {
            RETL_Leasing_Committee_Data__c rec = new RETL_Leasing_Committee_Data__c(
                Id = templateId,
                Template_Data__c = dataJson
            );
            update rec;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to update template: ' + e.getMessage());
        }
    }


    /**
     * Retrieves the stored committee data from the Opportunity record.
     * @param oppId The ID of the Opportunity record to fetch data from.
     * @return The JSON string of the committee data, or null if none exists.
     */
    @AuraEnabled(cacheable=true)
    public static String fetchCommitteeData(Id oppId) {
        if (oppId == null) {
            return null;
        }

        try {
            // Query the most recently created template linked to this Opportunity
            RETL_Leasing_Committee_Data__c templateRecord = [
                SELECT Template_Data__c
                FROM RETL_Leasing_Committee_Data__c
                WHERE Opportunity__c = :oppId
                ORDER BY Lastmodifieddate DESC
                LIMIT 1
            ];

            return templateRecord.Template_Data__c;

        } catch (QueryException qe) {
            // No rows found → return null (NOT an error)
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch data: ' + e.getMessage());
        }
    }


    /**
     * Retrieves and concatenates the names (Unit Names) of all Opportunity Line Items related to the Opportunity.
     * @param oppId The ID of the Opportunity record.
     * @return A comma-separated string of all related line item names.
     */
    @AuraEnabled(cacheable=true)
    public static OppLineWrapper getOppLineData(Id oppId) {

        // extract names
        List<String> unitNames = new List<String>();
        Integer GLA =0;
        string floor ; 
       // string assetName;


        if (oppId == null) {
            return new OppLineWrapper();
        }

        try {
            Opportunity opp = [
                SELECT Id, Name, StageName, CloseDate, Amount, Account.Name,RETL_Project__c,RETL_Brand__r.Name,Owner.Name
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];

            List<OpportunityLineItem> lineItems = [
                SELECT Id, Name, Quantity, UnitPrice, TotalPrice, 
                    Product2Id, Product2.Name, Product2.Family,RETL_Selected_Unit__r.Unit_Area__c,RETL_Selected_Unit__r.Floor__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :oppId
                ORDER BY CreatedDate ASC
            ];

            
            for (OpportunityLineItem li : lineItems) {
                if (li.Product2 != null && li.Product2.Name != null) {
                    unitNames.add(li.Product2.Name);
                    GLA += Integer.valueof(li.RETL_Selected_Unit__r.Unit_Area__c);
                    if(li.RETL_Selected_Unit__r.Floor__c!=NULL){
                        floor = li.RETL_Selected_Unit__r.Floor__c;
                    }else{
                        floor = 'Missing on UNits';
                    }
                }
            }



            OppLineWrapper result = new OppLineWrapper();
            result.unitNames = String.join(unitNames, ', ');
            result.opp = opp;
            result.lines = lineItems;
            result.GLA = GLA;
            result.floor = floor;

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve opportunity data: ' + e.getMessage());
        }
    }



    @AuraEnabled
    public static void saveTemplateData(String templateName, String dataJson, Id oppId) {
        if (String.isBlank(templateName) || String.isBlank(dataJson)) {
            throw new AuraHandledException('Template name or data is missing.');
        }

        try {
            RETL_Leasing_Committee_Data__c templateRecord = 
                new RETL_Leasing_Committee_Data__c();

            templateRecord.Name = templateName;
            templateRecord.Template_Data__c = dataJson;

            // Map to Opportunity
            if (oppId != null) {
                templateRecord.Opportunity__c = oppId;
            }

            insert templateRecord;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to save template: ' + e.getMessage());
        }
    }



    @AuraEnabled(cacheable=true)
    public static List<TemplateWrapper> getSavedTemplates(Id oppId) {
        if (oppId == null) return new List<TemplateWrapper>();

        List<RETL_Leasing_Committee_Data__c> templates = [
            SELECT Id, Name, Template_data__c, CreatedDate
            FROM RETL_Leasing_Committee_Data__c
            WHERE Opportunity__c = :oppId
            ORDER BY CreatedDate DESC
        ];

        List<TemplateWrapper> result = new List<TemplateWrapper>();
        for(RETL_Leasing_Committee_Data__c t : templates) {
            result.add(new TemplateWrapper(t.Id, t.Name));
        }
        return result;
    }

    public class TemplateWrapper {
        @AuraEnabled public Id templateId;
        @AuraEnabled public String templateName;

        public TemplateWrapper(Id tId, String tName) {
            this.templateId = tId;
            this.templateName = tName;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String fetchTemplateData(Id templateId) {
        if (templateId == null) return null;
        RETL_Leasing_Committee_Data__c record = [
            SELECT Template_data__c
            FROM RETL_Leasing_Committee_Data__c
            WHERE Id = :templateId
            LIMIT 1
        ];
        return record.Template_data__c;
    }
    // LeaseController.cls   
    @AuraEnabled(cacheable=true)
    public static List<Order> getBenchmarkLeases() {
        return [
            SELECT Id, Name, Account.Name//, Unit__c, GLA__c, Floor__c, MN_Sales__c, Sales_PSM__c, BR_PSM__c, TOR_Percent__c, TOR__c, SC_PSM__c, OCR_Percent__c
            FROM Order
            WHERE AccountId != null
            ORDER BY Name
        ];
    }


    public class OppLineWrapper {
        @AuraEnabled public String unitNames;
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public List<OpportunityLineItem> lines;
        @AuraEnabled public Integer GLA;
        @AuraEnabled public String floor;

        public OppLineWrapper() {}
}

}