public without sharing class ECSS_FieldsMetadataHelper {
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        //This method retrieves the fields from a specified field set of a given object.
        //It returns a list of field API names that are part of the field set.
        
        //Create the list that will hold the field API names.
        List<String> fieldNames = new List<String>();
        
        //Get the SObject type for the given object name.
        //If the object does not exist, return an empty list.
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        if (sobjectType == null) return fieldNames;
        
        //Get the describe result for the SObject type. Get the field Set details by its name.
        Schema.DescribeSObjectResult describe = sobjectType.getDescribe();
        Schema.FieldSet fieldSet = describe.fieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) return fieldNames;
        
        //Loop through the field set members and add their field paths to the list.
        //This will give us the API names of the fields in the field set.
        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            fieldNames.add(f.getFieldPath());
        }
        
        //Return the list of field API names.
        return fieldNames;
    }
    
    
    @AuraEnabled
    public static Map<String,Object> getRecordData(String ObjectName, String recordId, List<String>fieldsList){
        //Get the record data from the provided record Id.
        //The fields to retrieve are defined in the Field Set, fieldsList.
        System.debug('ObjectName: '+ObjectName);
        System.debug('RecordId: '+recordId);
        try {
            String query = 'SELECT ' + String.join(fieldsList, ',')+ ' FROM ' + ObjectName + ' WHERE Id = :recordId';
            System.debug( 'Query: '+query);
            SObject result = Database.query(query);
            //return the poulated fields as a map of string which is the field API name and the object value.
            return result.getPopulatedFieldsAsMap();
        } catch (Exception exceptionMessage) {
            throw new AuraHandledException(exceptionMessage.getMessage());
        }
    }
    
}