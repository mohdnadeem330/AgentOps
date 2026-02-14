public with sharing class ChecklistTriggerHandler extends TriggerHandler{
    static Id Invoice_Bundle_RT = Schema.SObjectType.Checklist__c.getRecordTypeInfosByDeveloperName().get('InvoiceBundle').getRecordTypeId();
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        // Added By Moh Sarfaraj
        List<Checklist__c> filteredlistChecklist = new List<Checklist__c>();
        for(Checklist__c eachChecklist : (List<Checklist__c>) newList){
            Checklist__c oldChecklist = new Checklist__c();
            // oldChecklist = (Checklist__c) oldChecklistMap.get(eachChecklist.Id);
            
            if(String.isNotBlank(Invoice_Bundle_RT) && eachChecklist.Is_Active__c == true &&
               String.isNotBlank(eachChecklist.RecordTypeId) && eachChecklist.RecordTypeId == Invoice_Bundle_RT){

                 filteredlistChecklist.add(eachChecklist);
            }
        }
        if(!filteredlistChecklist.isEmpty()){
            createChecklistPlaceHolder(filteredlistChecklist);
        } 
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        List<Checklist__c> filteredlistChecklist = new List<Checklist__c>();
        for(Checklist__c eachChecklist : (List<Checklist__c>) newList){
            Checklist__c oldChecklist = new Checklist__c();
            // oldChecklist = (Checklist__c) oldChecklistMap.get(eachChecklist.Id);
            
            if(String.isNotBlank(Invoice_Bundle_RT) && eachChecklist.Is_Active__c == true &&
               String.isNotBlank(eachChecklist.RecordTypeId) && eachChecklist.RecordTypeId == Invoice_Bundle_RT){

                 filteredlistChecklist.add(eachChecklist);
            }
        }
        if(!filteredlistChecklist.isEmpty()){
            createChecklistPlaceHolder(filteredlistChecklist);
        }
    }

    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
     
    }

    // Added By Moh Sarfaraj 
    public static void createChecklistPlaceHolder(List<Checklist__c> listChecklist){
       
        if(listChecklist != null && !listChecklist.isEmpty()){
            String DOCUMENT_PLACEHOLDER_CATEGORY_CHECKLIST = 'Invoice Bundle';
            Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(
                                                                      new Set<String>{
                                                                          DOCUMENT_PLACEHOLDER_CATEGORY_CHECKLIST
                                                                       });
            Id docgenpackageId = [SELECT Id FROM Loop__DDP__c WHERE Name = 'Commission Invoices Validation Check List updated' LIMIT 1]?.Id;
            Id deliveryOptionId = [SELECT Id FROM Loop__DDP_Integration_Option__c WHERE Loop__DDP__c = :docgenpackageId]?.Id;    
           
            if(documentMap != null && !documentMap.isEmpty()){
                List<Document__c> documentListToInsert = new List<Document__c>();
                Map<String,Id> documentRecordTypeMap = new Map<String,Id>();
                //get Existing Documents
                Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
                for(Document__c tempDoc : [SELECT Id,DocumentType__c,Checklist__c FROM Document__c WHERE Checklist__c IN :listChecklist]){
                    existingDocMap.put(tempDoc.Checklist__c+tempDoc.DocumentType__c,tempDoc);
                }
                for(Checklist__c eachChecklist : listChecklist){
                    for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(DOCUMENT_PLACEHOLDER_CATEGORY_CHECKLIST)){
                        String recordTypeID = null;
                        if(tempMetaRec.RecordTypeDeveloperName__c != null){
                            if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,
                                                          Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                            }
                            recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                        }
                        if(!existingDocMap.containsKey(eachChecklist.Id + tempMetaRec.DocumentType__c)){
                            system.debug('document insered from Checklist Trigger SF');
                            Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                            documentRecord.Checklist__c   = eachChecklist.Id;
                            //documentRecord.InvoiceBundle__c = eachChecklist.InvoiceBundle__c;
                            documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;
                            documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                            documentRecord.EligibleForeSign__c      = tempMetaRec.EligibleForeSign__c;
                            documentRecord.DocgenPackageId__c = docgenpackageId;
                            documentRecord.DeliveryOptionId__c = deliveryOptionId;
                            documentListToInsert.add(documentRecord);  
                            system.debug('document Added to List for Insert' + docgenpackageId + '-'+deliveryOptionId );
                        }
                    }
                }
                if(!documentListToInsert.isEmpty()){
                    insert documentListToInsert;  
                }
            }
        }
    }
}