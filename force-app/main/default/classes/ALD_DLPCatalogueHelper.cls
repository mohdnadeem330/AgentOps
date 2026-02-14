public class ALD_DLPCatalogueHelper {
    public String validFor;

    /**
     * Method to call the metadata API and fetch the picklist values based on the record type.
     *
     * @param objectApiName The API name of the object.
     * @param recordTypeId The ID of the record type.
     * @param fieldApiName The API name of the field.
     * @return A map containing the picklist values with labels as keys and values as values.
     */
    public static Map<String, String> fetchPickListVal(String objectApiName, String recordTypeId, String fieldApiName) {
        // Get the base URL of the Salesforce org
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        
        // Initialize a map to store picklist values
        Map<String, String> picklistValues = new Map<String, String>();
        
        // Construct the endpoint URL for the UI API to fetch picklist values
        String endpoint = baseUrl + '/services/data/v52.0/ui-api/object-info/' + objectApiName + '/picklist-values/' + recordTypeId + '/' + fieldApiName;
        
        // Set up the headers for the API call, including authorization
        Map<String, String> headerConf = new Map<String, String>{'Authorization' => 'Bearer ' + UserInfo.getSessionId()};
         
        try {
            // Make the HTTP GET call to the endpoint
            HttpResponse res = OutboundCallUtility.callOutboundAPI(headerConf, endpoint, 'GET', '');
            
            // Check if the response is successful
            if (res != null && res.getStatusCode() == 200) {
                // Parse the JSON response
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> values = (List<Object>) responseMap.get('values');
                
                // Extract picklist values and populate the map
                for (Object valueObj : values) {
                    Map<String, Object> value = (Map<String, Object>) valueObj;
                    picklistValues.put((String) value.get('label'), (String) value.get('value'));
                }
            }
        } catch (Exception e) {
            // Log any exceptions that occur
            System.debug('Exception: ' + e.getMessage());
        }

        // Return the map of picklist values
        return picklistValues;
    }
    
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
    // Describe the dependent field to get its details
    Schema.DescribeFieldResult depend = dependToken.getDescribe();
    Schema.sObjectField controlToken = depend.getController();
    
    // If there is no controlling field, return an empty map
    if (controlToken == null) {
        return new Map<String, List<String>>();
    }

    // Describe the controlling field to get its details
    Schema.DescribeFieldResult control = controlToken.getDescribe();
    List<Schema.PicklistEntry> controlEntries = control.getType() != Schema.DisplayType.Boolean ? control.getPicklistValues() : null;

    // Base64 character map used to decode the 'validFor' attribute
    String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    // Map to hold the dependent picklist values
    Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();

    // Iterate through the picklist values of the dependent field
    for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
        if (entry.isActive()) {
            // Extract the 'validFor' attribute and convert it to a list of characters
            Map<String, Object> entryMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry));
            String validFor = (String) entryMap.get('validFor');
            if (String.isNotEmpty(validFor)) {
                List<String> base64chars = validFor.split('');

                // Determine the controlling values that the dependent value is valid for
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue = controlEntries == null ? (Object) (index == 1) : (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null);
                    Integer bitIndex = index / 6;

                    // Break if bitIndex exceeds base64chars size
                    if (bitIndex >= base64chars.size()) {
                        break;
                    }

                    Integer bitShift = 5 - Math.mod(index, 6);
                    if (controlValue != null && (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) != 0) {
                        // Add the dependent value to the map if the controlling value is valid
                        if (!dependentPicklistValues.containsKey((String) controlValue)) {
                            dependentPicklistValues.put((String) controlValue, new List<String>());
                        }
                        dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                    }
                }
            }
        }
    }

    // Return the map of dependent picklist values
    return dependentPicklistValues;
}
}