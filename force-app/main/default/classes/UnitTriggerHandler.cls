public with sharing class UnitTriggerHandler extends TriggerHandler{
    
    private static User currentUser;

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //Create Documents
        map<id,Unit__c> createDocumentMap =  new map<id,Unit__c>();
        for(Unit__c unitRecord : (List<Unit__c>)newList){
            createDocumentMap.put(unitRecord.Id,unitRecord);
        }
        if(!createDocumentMap.isEmpty()){
            createUpdateDocumentPlaceHolder(createDocumentMap);
        }
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        Map<Id, Unit__c> newUnitMap = new Map<Id, Unit__c>();
        Map<Id, Unit__c> oldUnitMap = new Map<Id, Unit__c>();
        Map<Id, Unit__c> unitShareMap = new Map<Id, Unit__c>();
        Map<Id, Unit__c> unitChangedMap = new Map<Id, Unit__c>();
        //Create Documents
        //Create HandoverSR for sold Units
        set<ID> handOverSRUnit = new set<ID>();
        User usr = Utilities.getLoggedInUserDetail();
        Boolean retryDamascusSync = (usr != null && usr.Profile.Name == Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR);
        
        map<id,Unit__c> createDocumentMap =  new map<id,Unit__c>();
        System.debug('newList '+newList);
		 if(newList!=null)
        {
        for(Unit__c unitRecord : (List<Unit__c>)newList){
            Id recordId = unitRecord.Id ;
            Unit__c oldUnitRecord = (Unit__c)oldMap.get(recordId);

            oldUnitMap.put(recordId, oldUnitRecord);
            if(unitRecord.WebFloorPlan__c != oldUnitRecord.WebFloorPlan__c  || unitRecord.AffectionPlan__c != oldUnitRecord.AffectionPlan__c || unitRecord.AffectionPlan2__c != oldUnitRecord.AffectionPlan2__c){
                createDocumentMap.put(unitRecord.Id,unitRecord);
            }
            
            unitShareMap.put(recordId, unitRecord);

            //---- Check if status Or Price is changed or Reprocess is triggered
            if(unitRecord.Status__c != oldUnitRecord.Status__c || unitRecord.SellingPrice__c != oldUnitRecord.SellingPrice__c || unitRecord.ReprocessCallout__c != oldUnitRecord.ReprocessCallout__c || unitRecord.AssignedToUser__c != oldUnitRecord.AssignedToUser__c || unitRecord.AllocationGroup__c != oldUnitRecord.AllocationGroup__c){
                newUnitMap.put(recordId, unitRecord);     
            }
            if(unitRecord.ASiteUnitStatus__c != oldUnitRecord.ASiteUnitStatus__c && unitRecord.ASiteUnitStatus__c==Constants.ASITE_UNIT_CLEARED){
                handOverSRUnit.add(recordId);
            }
            //Dmascus API call for updated changes
            if((unitRecord.DamascusSyncStatus__c  == 'In Progress' && (((unitRecord.EnableForDamascus__c != oldUnitRecord.EnableForDamascus__c) ||
               (unitRecord.Status__c != oldUnitRecord.Status__c) || (unitRecord.UnitPlotArea__c != oldUnitRecord.UnitPlotArea__c) || (unitRecord.UnitModel__c != oldUnitRecord.UnitModel__c) ||
               (unitRecord.ResaleListed__c != oldUnitRecord.ResaleListed__c) || (unitRecord.SellingPrice__c != oldUnitRecord.SellingPrice__c) || 
               (unitRecord.AllocationGroup__c != oldUnitRecord.AllocationGroup__c) || (unitRecord.DigitalSales__c != oldUnitRecord.DigitalSales__c) || 
               (unitRecord.OnlineBrokerFlag__c != oldUnitRecord.OnlineBrokerFlag__c)))) || (unitRecord.DamascusSyncStatus__c != oldUnitRecord.DamascusSyncStatus__c && unitRecord.DamascusSyncStatus__c  == 'In Progress' && retryDamascusSync)){
                   unitChangedMap.put(recordId, unitRecord);
               }
            /* if(unitRecord.ShowOnDamscus__c != oldUnitRecord.ShowOnDamscus__c 
|| unitRecord.Status__c != oldUnitRecord.Status__c 
||unitRecord.UnitPlotArea__c != oldUnitRecord.UnitPlotArea__c 
||unitRecord.UnitModel__c != oldUnitRecord.UnitModel__c 
||unitRecord.ResaleListed__c != oldUnitRecord.ResaleListed__c
||unitRecord.SellingPrice__c != oldUnitRecord.SellingPrice__c){
unitChangedMap.put(recordId, unitRecord);
}*/
        }
		}

        if(unitShareMap!=null && !unitShareMap.isEmpty() && oldUnitMap!=null && !oldUnitMap.isEmpty()){
            UnitShareService.shareOrUnshareUnitAccess(unitShareMap,oldUnitMap);
        }

        if(newUnitMap!=null && !newUnitMap.isEmpty()){
            if(System.IsBatch() == false && System.isFuture() == false){ 
                processUpdatedUnits(newUnitMap,oldUnitMap);
            }
        }
        if(!createDocumentMap.isEmpty()){
            createUpdateDocumentPlaceHolder(createDocumentMap);
        }
        if(!handOverSRUnit.isEmpty()){
            map<id,HandoverDetails__c> unitToHOMap = HandoverUtility.createHandoverSR(handOverSRUnit);
            /*for(Unit__c unitRecord : (List<Unit__c>)newList){
if(unitToHOMap.containsKey(unitRecord.Id) && unitToHOMap.containsKey(unitRecord.Id) !=null ){
unitRecord.HandoverDetail__c = unitToHOMap.get(unitRecord.Id).id;
}
}*/
        }
        
         if(unitChangedMap !=null && !unitChangedMap.isEmpty()){
            processUnitChangesForDamascus(unitChangedMap);
        }
    }

    /*
* Update unit status or price when Status or Price Change or when the admin wants to retrigger process
*/
    public static void processUpdatedUnits(Map<Id, Unit__c> newUnitsMap,Map<Id, Unit__c> oldUnitsMap){

        List<UnitUpdateWrapper.PriceUpdateUnitRecord> unitsWithPriceUpdate = new List<UnitUpdateWrapper.PriceUpdateUnitRecord>();
        List<UnitUpdateWrapper.StatusUpdateUnitRecord> unitsWithStatusUpdate = new List<UnitUpdateWrapper.StatusUpdateUnitRecord>();
        Boolean processRecords = true ;

        List<Id> statusRecordIds = new List<Id>();
        List<Id> pricerecordIds = new List<Id>();
        for(Unit__c unitRecord : newUnitsMap.values()){
            Unit__c oldUnitRecord = oldUnitsMap.get(unitRecord.Id);

            if(unitRecord.Sub_Vertical__c!='Government') // added by Rajat Jain for jira 765
            { 
            if(unitRecord.Status__c !=null && unitRecord.Status__c != oldUnitRecord.Status__c && unitRecord.Status__c != Constants.UNIT_STATUS_BOOKING_INPROGRESS){
                unitsWithStatusUpdate.add(new UnitUpdateWrapper.StatusUpdateUnitRecord(unitRecord));
                statusRecordIds.add(unitRecord.Id);
                } else if ((unitRecord.AssignedToUser__c != oldUnitRecord.AssignedToUser__c || unitRecord.AllocationGroup__c != oldUnitRecord.AllocationGroup__c) && unitRecord!=null ) {
                unitsWithStatusUpdate.add(new UnitUpdateWrapper.StatusUpdateUnitRecord(unitRecord));
                statusRecordIds.add(unitRecord.Id);
            }
            if(unitRecord.SellingPrice__c !=null && unitRecord.SellingPrice__c != oldUnitRecord.SellingPrice__c){
                unitsWithPriceUpdate.add(new UnitUpdateWrapper.PriceUpdateUnitRecord(unitRecord));
                pricerecordIds.add(unitRecord.Id);
            }
            if(unitRecord.ReprocessCallout__c !=null && unitRecord.ReprocessCallout__c != oldUnitRecord.ReprocessCallout__c){
                if(unitRecord.ReprocessCallout__c == Constants.REPROCESS_PRICE){
                    unitsWithPriceUpdate.add(new UnitUpdateWrapper.PriceUpdateUnitRecord(unitRecord));
                    pricerecordIds.add(unitRecord.Id);
                }
                if(unitRecord.ReprocessCallout__c == Constants.REPROCESS_STATUS){
                    unitsWithStatusUpdate.add(new UnitUpdateWrapper.StatusUpdateUnitRecord(unitRecord));
                    statusRecordIds.add(unitRecord.Id);
                }
            }
        }
        }
                              system.debug('unitsWithStatusUpdate '+unitsWithStatusUpdate);
        //----- Check if there was any status update
        if(unitsWithStatusUpdate != null && !unitsWithStatusUpdate.isEmpty()){
            String requestBody = JSON.serialize(new UnitUpdateWrapper.StatusUpdateUnits(unitsWithStatusUpdate));
            if(unitsWithPriceUpdate != null && !unitsWithPriceUpdate.isEmpty())
            processRecords = false ; 
            
            CalloutToMuleSoft.calloutFutureService(requestBody,processRecords,Constants.STATUS_UPDATE, statusRecordIds);
        }
        system.debug('unitsWithPriceUpdate '+unitsWithPriceUpdate);
        //----- Check if there was any price update
        if(unitsWithPriceUpdate != null && !unitsWithPriceUpdate.isEmpty()){
            String requestBody = JSON.serialize(new UnitUpdateWrapper.PriceUpdateUnits(unitsWithPriceUpdate));
            
            CalloutToMuleSoft.calloutFutureService(requestBody,processRecords,Constants.PRICE_UPDATE, pricerecordIds);
        }
        
    }
    
    public static void createUpdateDocumentPlaceHolder(map<id,Unit__c> unitMap){
        map<String,string> documentCodesToCreate = new map<String,string>{Constants.DOCUMENT_TYPE_FLOOR_PLAN=>'WebFloorPlan__c',Constants.DOCUMENT_TYPE_AFFECTION_PLAN=>'AffectionPlan__c','Affection Plan 2'=>'AffectionPlan2__c'};
        map<string,Document__c> documentExistingMap = new map<string,Document__c>();
        String inventoryRecordType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Constants.DOCUMENT_RECORDTYPE_INVENTORY).getRecordTypeId();

        for(Document__c tempDoc : [select id,Unit__c,DocumentType__c,DarcomURL__c from Document__c where Unit__c in :unitMap.keySet() and DocumentType__c in :documentCodesToCreate.keySet()]){
            documentExistingMap.put(tempDoc.Unit__c+tempDoc.DocumentType__c,tempDoc);
        }

        map<string,Document__c> documentsToUpsert = new map<string,Document__c>();
        for(Unit__c tempUnitRecord :unitMap.values() ){
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
                                                                                    Unit__c=tempUnitRecord.id,
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
        if(!documentExistingMap.isEmpty()){
            delete documentExistingMap.values();
        }

    } 
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        List<Unit__c> unitNewList = new List<Unit__c>();
        set<id> releasedUnitIdSet = new set<id>();
        for(Unit__c unitRecord : (List<Unit__c>)newList){
            Unit__c oldUnit = (Unit__c)oldmap.get(unitRecord.Id);

            //Added by SAURABH for unit release bug.
            if(unitRecord.AssignedToUser__c != oldUnit.AssignedToUser__c && string.isNotBlank(oldUnit.AssignedToUser__c) && !UnitSearchController.isManageInventory && system.label.releaseUnitTrigger == 'true'){ 
                releasedUnitIdSet.add(unitRecord.Id);
            }

            if (unitRecord.Status__c == 'Available' && oldUnit.Status__c == 'Booked') {
                unitRecord.addError('This unit is already booked, please try with another unit.');
            }

            if(unitRecord.VirtualAccountNumber__c != oldUnit.VirtualAccountNumber__c || unitRecord.CorporateVirtualAccountNumber__c != oldUnit.CorporateVirtualAccountNumber__c  ){
                unitNewList.add(unitRecord);
            }
            //Dmascus API call for updated changes
            if(unitRecord.EnableForDamascus__c != oldUnit.EnableForDamascus__c ||
               unitRecord.Status__c != oldUnit.Status__c ||unitRecord.UnitPlotArea__c != oldUnit.UnitPlotArea__c ||unitRecord.UnitModel__c != oldUnit.UnitModel__c 
               ||unitRecord.ResaleListed__c != oldUnit.ResaleListed__c ||unitRecord.SellingPrice__c != oldUnit.SellingPrice__c || unitRecord.AllocationGroup__c != oldUnit.AllocationGroup__c
               || unitRecord.DigitalSales__c != oldUnit.DigitalSales__c
               || unitRecord.OnlineBrokerFlag__c != oldUnit.OnlineBrokerFlag__c) {
                   unitRecord.DamascusSyncStatus__c  ='In Progress' ;
                   //unitChangedMap.put(recordId, unitRecord);
               }
        }
        if(!releasedUnitIdSet.isEmpty()){
            overrideSharing cls = new overrideSharing();
            cls.validateUnitRelease(releasedUnitIdSet, newList, oldMap);
        }
        
        system.debug('unitNewList:::'+unitNewList);
        if(!unitNewList.isEmpty()){
            checkforDuplicateVAAssignment(unitNewList);
        }
    }

    //Added by SAURABH for unauthorized unit release in unit assignment.
    public without sharing class overrideSharing{
        public void validateUnitRelease(Set<Id> releasedUnitIdSet, List<Unit__c> newList, Map<Id, SObject> oldMap) {
            
            // Cache current user if not already set
            if (currentUser == null) {
                currentUser = [
                    SELECT Id, Name, Profile.Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId()
                ];
            }

            // Build a map of old Unit__c records by Id
            Map<Id, Unit__c> unitOldMap = new Map<Id, Unit__c>();
            if (oldMap != null && !oldMap.isEmpty()) {
                unitOldMap = new Map<Id, Unit__c>(
                    [SELECT Id, AssignedToUser__c, AssignedToUser__r.ManagerId, Status__c 
                    FROM Unit__c 
                    WHERE Id IN :oldMap.keySet()]
                );
            }

            // Only proceed for Sales Manager profiles or in test context
            if (
                currentUser.Profile.Name == 'Sales Manager' ||
                currentUser.Profile.Name == 'Sales Management' ||
                Test.isRunningTest()
            ) {
                Map<Id, String> errorMap = new Map<Id, String>();

                for (Unit__c oldUnit : unitOldMap.values()) {
                    // Check if the current user is not the assignee or their manager, and the unit is being released
                    if (
                        oldUnit.AssignedToUser__c != currentUser.Id &&
                        oldUnit.AssignedToUser__r.ManagerId != currentUser.Id &&
                        releasedUnitIdSet.contains(oldUnit.Id)
                    ) {
                        errorMap.put(oldUnit.Id, 'You can only release units assigned to you.');
                        break; // Stop after first error
                    }
                }

                if (!errorMap.isEmpty()) {
                    throwValidationError(errorMap, newList);
                }
            }
        }

        public void throwValidationError(Map<Id, String> errorMap, List<Unit__c> newList) {
            for (Unit__c unit : newList) {
                // Add error if present in errorMap and not running test
                if (errorMap.containsKey(unit.Id) && !Test.isRunningTest()) {
                    unit.addError(errorMap.get(unit.Id));
                }
            }
        }
    }

    

    public static void checkforDuplicateVAAssignment(List<Unit__c> newList){
        
        Map<String, String> unitVAMap = new Map<String, String>();
        Map<String, List<Unit__c>> vaUnitListMap = new Map<String, List<Unit__c>>();
        Map<String, List<Unit__c>> vaCorporateUnitListMap = new Map<String, List<Unit__c>>();
        Map<String, List<Unit__c>> newvaUnitListMap = new Map<String, List<Unit__c>>();
        Map<String, List<Unit__c>> newvaCorporateUnitListMap = new Map<String, List<Unit__c>>();
        
        
        for(Unit__c unit: newList){
            if(unit.VirtualAccountNumber__c != null){
                unitVAMap.put(unit.Id, unit.VirtualAccountNumber__c);
                List<Unit__c> allUnits = newvaUnitListMap.get(unit.VirtualAccountNumber__c)  != null ? newvaUnitListMap.get(unit.VirtualAccountNumber__c) : new List<Unit__c>();
                allUnits.add(unit);
                newvaUnitListMap.put(unit.VirtualAccountNumber__c, allUnits);
            }
            if(unit.CorporateVirtualAccountNumber__c != null){
                unitVAMap.put(unit.Id, unit.CorporateVirtualAccountNumber__c);
                List<Unit__c> allCorporateVAUnits = newvaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c) != null ? newvaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c) : new List<Unit__c>();
                allCorporateVAUnits.add(unit);
                newvaCorporateUnitListMap.put(unit.CorporateVirtualAccountNumber__c, allCorporateVAUnits);
            }
        }
        
        for(Unit__c unit: [SELECT Id,VirtualAccountNumber__c, CorporateVirtualAccountNumber__c FROM  Unit__c WHERE Id NOT IN:newList AND (VirtualAccountNumber__c IN:unitVAMap.values() OR CorporateVirtualAccountNumber__c IN:unitVAMap.values())]){
            if(unit.VirtualAccountNumber__c != null){
                List<Unit__c> allUnits = vaUnitListMap.get(unit.VirtualAccountNumber__c)  != null ? vaUnitListMap.get(unit.VirtualAccountNumber__c) : new List<Unit__c>();
                allUnits.add(unit);
                vaUnitListMap.put(unit.VirtualAccountNumber__c, allUnits);
            }
            if(unit.CorporateVirtualAccountNumber__c != null){
                List<Unit__c> allCorporateVAUnits = vaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c) != null ? vaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c) : new List<Unit__c>();
                allCorporateVAUnits.add(unit);
                vaCorporateUnitListMap.put(unit.CorporateVirtualAccountNumber__c, allCorporateVAUnits);
            }
        }
        system.debug('vaUnitListMap:::'+vaUnitListMap);
        for(Unit__c unit: newList){
            Boolean hasError = false;
            if(vaUnitListMap.containsKey(unit.VirtualAccountNumber__c)){
                if(vaUnitListMap.get(unit.VirtualAccountNumber__c).size() >0){
                    hasError = true;
                    //  unit.addError('Same Virtual Account Number cannot be used on multiple Unit');
                }
            }
            if(newvaUnitListMap.containsKey(unit.VirtualAccountNumber__c)){
                if(newvaUnitListMap.get(unit.VirtualAccountNumber__c).size()>1){
                    hasError = true;
                }
            }
            if(vaCorporateUnitListMap.containsKey(unit.CorporateVirtualAccountNumber__c)){
                if(vaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c).size()>0 ){
                     hasError = true;
                   // unit.addError('Same Corporate Virtual Account Number cannot be used on multiple Unit');
                }
            }
            if(newvaCorporateUnitListMap.containsKey(unit.CorporateVirtualAccountNumber__c)){
                if(newvaCorporateUnitListMap.get(unit.CorporateVirtualAccountNumber__c).size()>1){
                    hasError = true;
                }
            }
            if(hasError){
                unit.addError('Same Virtual Account Number cannot be used on multiple Unit');
            }
        }
    }
    //,List<String> newUnitsList
    public static void processUnitChangesForDamascus(Map<Id, Unit__c> newUnitsMap){
        List<String> stringList = new List<String>();
        for (Id id : newUnitsMap.keySet()) {
            if(newUnitsMap.get(id).Sub_Vertical__c!='Government') // Added by Rajat Jain Jira 765
            {
            stringList.add(String.valueOf(id));
        }
            
        }
        //Added by Tajinkumar for Damascus Callback
        if(!stringList.isempty()) {
            System.enqueueJob(new DamascusCallbackQueueable(
                JSON.serialize(new Map<String, Object>{'units' => Damascus_RestApiHandler.getModifiedUnits(stringList)}), 
                true,
                Constants.Damascus_Callback_Property,
                new List<Id>(newUnitsMap.keySet())));
        } 
        
       /* if((System.isBatch()|| System.isFuture()) && !stringList.isempty()){
            CalloutToMuleSoft.calloutService(
                JSON.serialize( new Map<String, Object>{ 'units' =>  Damascus_RestApiHandler.getModifiedUnits(stringList)  } ), 
                true, 
                Constants.Damascus_Callback_Property, 
                new List<Id>(newUnitsMap.keySet())
            );
        }else{
            CalloutToMuleSoft.calloutFutureService(
                JSON.serialize( new Map<String, Object>{ 'units' =>  Damascus_RestApiHandler.getModifiedUnits(stringList)  } ), 
                true, 
                Constants.Damascus_Callback_Property, 
                new List<Id>(newUnitsMap.keySet())
            );
        }*/
    }
}