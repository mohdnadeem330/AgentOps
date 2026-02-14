/**********************************************************************************************************************
* Name               : DLPZoneTriggerHandler                                                        
* Description        : This class is to write all the trigger automations for the DLPZone__c object
* Usage              : DLPZoneTriggerHandler
* Created By         : PWC Digital Middle East                                                     
******************************************************************************************************************/

public with sharing class DLPZoneTriggerHandler extends TriggerHandler{

    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
    }

    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<DLPZone__c> dlpZoneRecords = new List<DLPZone__c>();
        
        for(DLPZone__c newRecord  : (list<DLPZone__c >) newList){
            DLPZone__c oldRecord = (DLPZone__c)oldMap.get(newRecord.Id);        

            //If Proposed Contractor Dates is changed
            if(newRecord.ProposedContractorDLPStartDate__c  != oldRecord.ProposedContractorDLPStartDate__c  || newRecord.ProposedContractorDLPEndDate__c != oldRecord.ProposedContractorDLPEndDate__c){
                dlpZoneRecords.add(newRecord);
            }
        }

        if(!dlpZoneRecords.isEmpty()){
            createTOCDocument(dlpZoneRecords);
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //To create TOC document
        createTOCDocument((List<DLPZone__c>)newList);
    }
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
    }

    public static void createTOCDocument(list<DLPZone__c> dlpZoneRecords){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<String,ID> documentRecordTypeMap = new map<String,ID>();
        map<String,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_DLP_ZONE});
        map<Id,DLPZone__c> dlpZoneIDToRecMap = new map<Id,DLPZone__c>(dlpZoneRecords);

        if(!documentMap.isEmpty() && !dlpZoneIDToRecMap.isEmpty()){
            //get Existing Documents
            map<String,Document__c> existingDocMap = new map<String,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,DLPZone__c from Document__c where DLPZone__c in :dlpZoneIDToRecMap.keySet()]){
                    existingDocMap.put(tempDoc.DLPZone__c+tempDoc.DocumentType__c,tempDoc);
            }

            for(DLPZone__c dlpZoneRecord : dlpZoneRecords){
                String documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_DLP_ZONE;

                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    String recordTypeID=null;
                    
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                        
                    if(!existingDocMap.containsKey(dlpZoneRecord.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                        documentRecord.DLPZone__c = dlpZoneRecord.Id;

                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(dlpZoneRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }    
            }
        }
        
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }
}