public with sharing class OffersPromotionsTriggerHandler extends TriggerHandler {

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        createOfferDocuments((list<OffersPromotions__c>) newList);
        checkAllocationGroupCodes((list<OffersPromotions__c>) newList);
    }

    public static void checkAllocationGroupCodes(list<OffersPromotions__c> offers){
        Set<String> activeAllocationGroupCodes = AllocationGroupService.getAllocationGroupCodes();

        for(OffersPromotions__c offerRec : offers){
            if (String.isNotBlank(offerRec.AllocationGroup__c)) {
                List<String> enteredAllocationGroupCodes = offerRec.AllocationGroup__c.split(',');
                for(String allocationGroupCode : enteredAllocationGroupCodes){
                    if(!activeAllocationGroupCodes.contains(allocationGroupCode)){
                        offerRec.addError('Please fill allocation group code comma separated. Ex :AUH,DXB');
                    }
                }
            }
        }
    }

    public static void createOfferDocuments(list<OffersPromotions__c> offers){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_OFFER});
        
        if(!documentMap.isEmpty()){
            for(OffersPromotions__c offerRec : offers){
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_OFFER)){
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //No existing check as records will be created on insert
                    Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                OfferPromotion__c = offerRec.Id,
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