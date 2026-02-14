/**********************************************************************************************************************
* Name               : BrokerActivityTriggerHandler                                                        
* Description        : This class contains all the helper methods for the BrokerActivities__c Trigger
* Usage              : BrokerActivityTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class BrokerActivityTriggerHandler  extends TriggerHandler {
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        createActivityDocuments((list<BrokerActivities__c>) newList);
    
    }
    //Create Event/Activity Documents
    public static void createActivityDocuments(list<BrokerActivities__c> activities){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ACTIVITY});
        
        if(!documentMap.isEmpty()){
            for(BrokerActivities__c actRec : activities){
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ACTIVITY)){
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //No existing check as records will be created on insert
                    Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                Activity__c = actRec.Id,
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
}