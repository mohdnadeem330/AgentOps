public with sharing class ProjectTriggerHandler extends TriggerHandler {
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        createProjectDocuments((list<Project__c>) newList);
    }
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<Id, Project__c> projectsToNotifyDamascusMap = new Map<Id, Project__c>();
        Set<Id> projIdsForDamascusFlag = new Set<Id>();
        for(Project__c projectRecord : (List<Project__c>)newList){
            Id recordId = projectRecord.Id ;
            Project__c oldProjectRecord = (Project__c)oldMap.get(recordId);
            //Dmascus API call for updated changes
            if(Utilities.getChangedFields(projectRecord, oldProjectRecord, System.Label.DamascusNotifyFieldChange_Project) != null){
                projectsToNotifyDamascusMap.put(recordId, projectRecord);
            }
            if(projectRecord.EnableforDamascus__c != oldProjectRecord.EnableforDamascus__c ){
                projIdsForDamascusFlag.add(projectRecord.Id);
            }
        }
       

        if(projectsToNotifyDamascusMap !=null && !projectsToNotifyDamascusMap.isEmpty()){
            CalloutToMuleSoft.calloutFutureService(
                JSON.serialize( new Map<String, Object>{ 'projects' => Damascus_DataMapping.mapProjects( projectsToNotifyDamascusMap.values() ) } ), 
                true, 
                Constants.Damascus_Callback_Project, 
                new List<Id>(projectsToNotifyDamascusMap.keySet())
            );
        }
        
        if(projIdsForDamascusFlag.size () > 0){
            sendUnitsToDamascus(projIdsForDamascusFlag);
        }
    }
    
    public static void createProjectDocuments(list<Project__c> projects){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PROJECT});
        
        if(!documentMap.isEmpty()){
            for(Project__c projectRec : projects){
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PROJECT)){
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //No existing check as records will be created on insert
                    Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                Project__c = projectRec.Id,
                                                RecordtypeId= recordTypeID,
                                                AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c /*,
                                                GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true)*/ );
                    documentListToInsert.add(documentRecord);        
                    
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }
    
    @future(callout=true)
    public static void sendUnitsToDamascus(Set<Id> projIds){
        Map<Id,Unit__c> unitMap = new Map<Id,Unit__c>([SELECT Id FROM Unit__c WHERE Project__c IN: projIds ]);
        Set<String> unitStringSet = new Set<String>( (List<String>)new List<Id>( unitMap.keySet() ) );
        List<String> listOfStrings = new List<String>(unitStringSet);
        CalloutToMuleSoft.calloutService(
            JSON.serialize( new Map<String, Object>{ 'units' => Damascus_RestApiHandler.getModifiedUnits( listOfStrings ) } ), 
            true, 
            Constants.Damascus_Callback_Property, 
            new List<Id>(unitMap.keySet()));
    }
}