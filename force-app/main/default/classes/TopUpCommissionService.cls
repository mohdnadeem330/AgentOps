public inherited sharing class TopUpCommissionService {

    /**
     * Retrieves a list of TopUpCommission__c records based on classification and internal commission.
     * 
     * @param classificationToInterCommMap Map where keys are Classification__c values and values are Internal_Commission__c.
     * @return List of TopUpCommission__c records matching the provided criteria.
     */
    public static List<TopUpCommission__c> getTopUpCommissionWithClassificationAndInterComm(Map<String, String> classificationToInterCommMap) {
        // Validate the input map
        if (classificationToInterCommMap == null || classificationToInterCommMap.isEmpty()) {
            return new List<TopUpCommission__c>();
        }

        // Build a list of conditions for the SOQL query
        List<String> conditions = new List<String>();
        for (String classification : classificationToInterCommMap.keySet()) {
            String intercomm = classificationToInterCommMap.get(classification);
            if (String.isNotBlank(classification) && String.isNotBlank(intercomm)) {
                conditions.add(
                    '(Classification__c = \'' + String.escapeSingleQuotes(classification) +
                    '\' AND Internal_Commission__c = \'' + String.escapeSingleQuotes(intercomm) + '\')'
                );
            }
        }

        // If no valid conditions were added, return an empty list
        if (conditions.isEmpty()) {
            return new List<TopUpCommission__c>();
        }

        // Join the conditions with 'OR' to build the WHERE clause
        String whereClause = String.join(conditions, ' OR ');

        // Execute the dynamic SOQL query
        return Database.query(
            'SELECT Id, Name, Classification__c, Internal_Commission__c FROM TopUpCommission__c WHERE ' + whereClause
        );
    }
}