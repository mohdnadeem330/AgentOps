public with sharing class UnitDesignTriggerHandler extends TriggerHandler{

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //Create Documents
        map<id,UnitDesign__c> createDocumentMap =  new map<id,UnitDesign__c>();
        for(UnitDesign__c unitRecord : (List<UnitDesign__c>)newList){
            createDocumentMap.put(unitRecord.Id,unitRecord);
        }
        if(!createDocumentMap.isEmpty()){
            createUpdateDocumentPlaceHolder(createDocumentMap);
        }
    }
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(list<SObject> newList,map<ID,SObject> newMap){
        List<UnitDesign__c> unitList = new List<UnitDesign__c>();
        for(UnitDesign__c unitRecord : (List<UnitDesign__c>)newList){
            unitList.add(unitRecord);
        }
        if(!unitList.isEmpty()){
            poupulateUnitName(unitList);
        }
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList,map<Id,SObject> newmap,list<SObject> oldlist,map<Id,SObject> oldmap) {
        List<UnitDesign__c> unitList = new List<UnitDesign__c>();
        for(UnitDesign__c unitRecord : (List<UnitDesign__c>)newList){
            UnitDesign__c oldRec = (UnitDesign__c) oldmap.get(unitRecord.id);
            if(unitRecord.DesignType__c != oldRec.DesignType__c || unitRecord.Unit__c != oldRec.Unit__c){
                
                unitList.add(unitRecord);
            }
            
        }
        if(!unitList.isEmpty()){
            poupulateUnitName(unitList);
        }
    }
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        //Create Documents
        map<id,UnitDesign__c> createDocumentMap =  new map<id,UnitDesign__c>();
        for(UnitDesign__c unitRecord : (List<UnitDesign__c>)newList){
            Id recordId = unitRecord.Id ;
            UnitDesign__c oldUnitRecord = (UnitDesign__c)oldMap.get(recordId);
            if(unitRecord.WebFloorPlan__c != oldUnitRecord.WebFloorPlan__c ){createDocumentMap.put(unitRecord.Id,unitRecord);
            }
        }

        if(!createDocumentMap.isEmpty()){createUpdateDocumentPlaceHolder(createDocumentMap);
        }
    }
    
    public static void poupulateUnitName(List<UnitDesign__c> unitList){
        map<id,Unit__c> unitMap= new map<id,Unit__c>();
        for(UnitDesign__c ud : unitList){
            unitMap.put(ud.Unit__c,null);
        }
        unitMap= new map<id,Unit__c>([select id,Name from Unit__C where id in :unitMap.keySet()]);
        for(UnitDesign__c ud : unitList){
            ud.Name= ud.DesignType__c +'-'+ unitMap.get(ud.Unit__c).Name;
        }
    }
    
    public static void createUpdateDocumentPlaceHolder(map<id,UnitDesign__c> unitMap){
        map<String,string> documentCodesToCreate = new map<String,string>{Constants.DOCUMENT_TYPE_FLOOR_PLAN=>'WebFloorPlan__c'};
        map<string,Document__c> documentExistingMap = new map<string,Document__c>();
        String inventoryRecordType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Constants.DOCUMENT_RECORDTYPE_INVENTORY).getRecordTypeId();

        for(Document__c tempDoc : [select id,UnitDesign__c,DocumentType__c,DarcomURL__c from Document__c where UnitDesign__c in :unitMap.keySet() and DocumentType__c in :documentCodesToCreate.keySet()]){
            documentExistingMap.put(tempDoc.UnitDesign__c+tempDoc.DocumentType__c,tempDoc);
        }
        map<string,Document__c> documentsToUpsert = new map<string,Document__c>();
        for(UnitDesign__c tempUnitRecord :unitMap.values() ){
            for(String docType : documentCodesToCreate.keySet()){
                if(tempUnitRecord.get(documentCodesToCreate.get(docType))!=null && tempUnitRecord.get(documentCodesToCreate.get(docType))!='' ){
                    
                    Document__c tempExistingDocumentRecord = null;
                    if(documentExistingMap.containsKey(tempUnitRecord.id+docType) ){
                        //Remove from getting deleted
                        tempExistingDocumentRecord = documentExistingMap.remove(tempUnitRecord.id+docType);
                        //if no change in the URL then continue
                        if(tempExistingDocumentRecord.DarcomURL__c ==  String.ValueOf(tempUnitRecord.get(documentCodesToCreate.get(docType))) ){
                            continue;
                        }
                    }
                    documentsToUpsert.put(tempUnitRecord.id+docType, new Document__c(id = (tempExistingDocumentRecord!=null?tempExistingDocumentRecord.Id :null),
                                                                                    UnitDesign__c=tempUnitRecord.id,
                                                                                    DarcomURL__c = String.ValueOf(tempUnitRecord.get(documentCodesToCreate.get(docType))) ,
                                                                                    DocumentType__c = docType,
                                                                                    ConvertToImage__c = true,
                                                                                    DocumentAttached__c =false,
                                                                                    RecordTypeId = inventoryRecordType ));

                }
                
            }
        }
        //Update new/updated dpcuments
        if(!documentsToUpsert.isEmpty()){
            upsert documentsToUpsert.values();
        }
        //Delete non required documents
        if(!documentExistingMap.isEmpty()){delete documentExistingMap.values();
        }

    } 
}