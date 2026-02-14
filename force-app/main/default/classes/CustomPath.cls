public with sharing class CustomPath {
    @AuraEnabled(cacheable=true)
    public static String getCurrentStage(Id recordId,String pathFieldName) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<SObject> lstCase = new List<SObject>();
        String caseQuery = 'SELECT '+pathFieldName+' From '+ sObjName+' where Id=\''+recordId+'\'';
        lstCase = Database.query(caseQuery);
        Object fieldValue = lstCase[0].get(pathFieldName);
        String fieldData = fieldValue.toString();
        return fieldData;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getPathStages(Id recordId, String fieldName) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<String> pathOptions = new List<String>();
        List<SObject> lstCase = new List<SObject>();
        String caseQuery = 'Select Id,'+fieldName+' from '+sObjName+' where Id=\''+recordId+'\'';
        lstCase = Database.query(caseQuery);
        Object fieldValue = lstCase[0].get(fieldName);
        String fieldData = fieldValue.toString();
        List<Custom_path__mdt> lstPathData = [Select Applicable_values__c from Custom_path__mdt where Object__c =:sObjName AND RecordTypeField__c =:fieldName AND RecordType_Value__c =:fieldData];
        if(!lstPathData.isEmpty()){
            pathOptions = lstPathData[0].Applicable_values__c.split(',');
        }
        return pathOptions;
    }

    @AuraEnabled
    public static String updateSelectedStage(Id recordId, String selectedStage, String pathFieldName,String description) {
        String updateStatus = '';
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        
        //if(fieldValue!=null){
            SObject sobjRec = recordId.getSObjectType().newSObject(recordId);
            // Set the Name field dynamically
            sobjRec.put(pathFieldName, selectedStage);
            //if(selectedStage!='Closed'){
                List<Custom_Path_Mandate_Fields__mdt> lstPathData = [Select Current_Value__c,Mandate_Field__c from Custom_Path_Mandate_Fields__mdt where Current_Value__c =:selectedStage ];
                String fieldName = lstPathData[0].Mandate_Field__c;
                sobjRec.put(fieldName, description);
            //}
            try{
                update sobjRec;
                updateStatus = 'Success';
            }
            catch(Exception e){
                updateStatus =  e.getMessage();
            }
        /*}else{
            String fieldLabel = '';
            Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
            if (globalDescribeMap.containsKey(sObjName)) {
                Schema.DescribeSObjectResult sObjectDescribe = globalDescribeMap.get(sObjName).getDescribe();
                Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap();
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    fieldLabel = fieldDescribe.getLabel();
                }
            }
            updateStatus = fieldLabel + ' is Mandatory';
        }*/
        return updateStatus;
    }

}