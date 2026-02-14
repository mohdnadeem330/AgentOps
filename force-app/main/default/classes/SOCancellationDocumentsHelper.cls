/**********************************************************************************************************************
* Name               : SOCancellationDocumentsHelper                                                        
* Description        : Handler to create Document Placeholders for Sales Order Cancellation on insert. Called from Sales Order Cancellation - After Insert flow.
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     18/03/2024      Initial Draft       
******************************************************************************************************************/
public with sharing class SOCancellationDocumentsHelper {
    public SOCancellationDocumentsHelper() {

    }
    /* ANONYMOUS SCRIPT
        Id recordId = 'a282500000QDqcvAAD';
        List<SalesOrderCancellation__c> thisRecordList = [SELECT Id FROM SalesOrderCancellation__c WHERE Id =: recordId];
        SOCancellationDocumentsHelper.createDocuments(thisRecordList);
    */

    @InvocableMethod(label='Create SO Cancellation Document Placeholders' iconName='slds:standard:email')
    public static void createDocuments (List<FlowInputParamsWrapper> inputParamList) {
        List<Id> recordIdList = new List<Id>();
        for(FlowInputParamsWrapper thisInputParam : inputParamList){
            recordIdList.add(thisInputParam.recordId);
        }
        List<SalesOrderCancellation__c> thisRecordList = [SELECT Id FROM SalesOrderCancellation__c WHERE Id IN: recordIdList];
        SOCancellationDocumentsHelper.createDocuments(thisRecordList);
    }

    public static void createDocuments(List<SalesOrderCancellation__c> soCancellationRecords){
        List<Document__c> documentListToInsert = new List<Document__c>();
        Map<String, Id> documentRecordTypeMap = new Map<String, Id>();
        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_SO_CANCELLATION});
        
        Map<Id, SalesOrderCancellation__c> soCancelIDToRecMap = new Map<Id, SalesOrderCancellation__c>(soCancellationRecords);

        if(!documentMap.isEmpty() && !soCancelIDToRecMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Sales_Order_Cancellation__c FROM Document__c WHERE Sales_Order_Cancellation__c in :soCancelIDToRecMap.keySet()]){

                existingDocMap.put(tempDoc.Sales_Order_Cancellation__c + tempDoc.DocumentType__c, tempDoc);
            }

            for(SalesOrderCancellation__c soCancelRecord : soCancellationRecords){

                String documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_SO_CANCELLATION;

                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    string recordTypeID = null;
                
                    if(tempMetaRec.RecordTypeDeveloperName__c != null){ //SOCancellationDocument
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    if(!existingDocMap.containsKey(soCancelRecord.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = new Document__c();
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c = tempMetaRec.EligibleForeSign__c;
                        documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                        documentRecord.Sales_Order_Cancellation__c = soCancelRecord.Id;
                        documentRecord.Status__c = Constants.PENDING_STATUS;
                        documentRecord.RecordTypeID = recordTypeID;
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(soCancelRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }

    public class FlowInputParamsWrapper{
        @InvocableVariable(label='Record Id' required=true description='Sales Order Cancellation Record Id')
        public String recordId;
    }
}