@RestResource (urlMapping = '/query/propertyinventory')
global with sharing class PropertyInventoryQueryWebService {
    
    @HttpPost
    global static void doPost(){   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            
           // List<Unit__c> propertyInventories = UnitService.filterAvailableUnits(mapFieldApiFieldValues);
             List<Unit__c> unitList = UnitService.filterAvailableUnits(mapFieldApiFieldValues);

             List<Unit__c> propertyInventories = new List<Unit__c>();
            
            
         //Code added by Noor
        Set<Id> unitIds = new Set<Id>();  
        for(Unit__c u : unitList){
            unitIds.add(u.id);
        }
        //do not show units which are requested added by Noor
        List<Unit_Assignment__c> unitAssList = [Select ID,Unit__c,ownerId FROM Unit_Assignment__c
        WHERE Status__c = 'Pending approval' AND Unit__c IN: unitIds];
        Set<Id> toRemoveUnits = new Set<Id>();  
        for(Unit_Assignment__c unt : unitAssList){
           if( unt.ownerId != UserInfo.getUserId()){
            toRemoveUnits.add(unt.Unit__c);
           }
        }
        List<Unit__c> finalListOfUnit = new List<Unit__c>();
        for(Unit__c unt : unitList){
            if(!toRemoveUnits.contains(unt.id) ){
            propertyInventories.add(unt);
            }
        }
            
            Boolean processRecords = false;

            PropertyInventoryQueryResponse response = new PropertyInventoryQueryResponse(propertyInventories, 'Unit__c', processRecords);
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }
    
    global with sharing class PropertyInventoryQueryResponse extends QueryResponse {
        
        Set<String> buildings = new Set<String>();
        Set<String> projects = new Set<String>();
        Map<String,Set<String>> projectBuildingMap = new Map<String,Set<String>>();
        Map<String,Set<String>> buildingUnitTypeMap = new Map<String,Set<String>>();
        Map<String,Set<String>> buildingUnitViewMap = new Map<String,Set<String>>();
        Map<String,Set<String>> buildingUnitModelMap = new Map<String,Set<String>>();
        Map<String,Set<String>> buildingUnitCategoryMap = new Map<String,Set<String>>();
        Set<String> bedrooms = new Set<String>();
        Set<String> multiPurposeRoom = new Set<String>{'Yes', 'No'};
        Set<String> unitFinishes = new Set<String>{'Yes', 'No'};
        boolean isBlocked = OpportunityUnitSearchController.getUserStatus();
        String blockedMessage = 'Temporary access restriction has been imposed. Please contact your Line Manager to resolve and reinstate access.';
        global PropertyInventoryQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {
            super(records, objectName, processRecords);

            for (SObject record : records) {
                Unit__c unit = (Unit__c) record;
                
                if (unit.Project__c != null) {
                    String projectName = unit.Project__r.Name ;
                    projects.add(projectName);

                    if (unit.BuildingSectionName__c != null){
                        //----- Map the building names with project
                        String buildingName = unit.BuildingSectionName__r.Name ;
                        buildings.add(buildingName);
                        Set<String> buildingNames = new Set<String>(); 
                        if(projectBuildingMap.containsKey(projectName)){
                            buildingNames = projectBuildingMap.get(projectName);
                        }
                        buildingNames.add(buildingName);
                        projectBuildingMap.put(projectName,buildingNames);
                        //----- Map the unit type with Building
                        if(unit.UnitType__c != null){
                            Set<String> unitTypes = new Set<String>(); 
                            if(buildingUnitTypeMap.containsKey(buildingName)){
                                unitTypes = buildingUnitTypeMap.get(buildingName);
                            }
                            unitTypes.add(unit.UnitType__c);
                            //buildingUnitTypeMap.put(buildingName,unitTypes);
                            buildingUnitTypeMap.put(buildingName,sortedStrings(unitTypes));
                        }
                        //----- Map the unit view with Building
                        if(unit.UnitView__c != null){
                            Set<String> unitViews = new Set<String>(); 
                            if(buildingUnitViewMap.containsKey(buildingName)){
                                unitViews = buildingUnitViewMap.get(buildingName);
                            }
                            unitViews.add(unit.UnitView__c);
                            //buildingUnitViewMap.put(buildingName,unitViews);
                            buildingUnitViewMap.put(buildingName,sortedStrings(unitViews));
                        }
                        //---- Map the unit model with building
                        if(unit.UnitModel__c != null){
                            Set<String> unitModel = new Set<String>(); 
                            if(buildingUnitModelMap.containsKey(buildingName)){
                                unitModel = buildingUnitModelMap.get(buildingName);
                            }
                            unitModel.add(unit.UnitModel__c);
                            buildingUnitModelMap.put(buildingName,sortedStrings(unitModel));
                        }
                        //---- Map the unit category with building
                        if(unit.UnitCategory__c != null){
                            Set<String> unitCategory = new Set<String>(); 
                            if(buildingUnitCategoryMap.containsKey(buildingName)){
                                unitCategory = buildingUnitCategoryMap.get(buildingName);
                            }
                            unitCategory.add(unit.UnitCategory__c);
                            buildingUnitCategoryMap.put(buildingName,sortedStrings(unitCategory));
                        }
                    }    
                    //---- Number of Bedrooms
                    if(unit.NumberOfBedrooms__c != null){
                        bedrooms.add(unit.NumberOfBedrooms__c);
                    }   
                }   
            }
            if(bedrooms!=null)
                bedrooms =  sortedStrings(bedrooms);
        }
    }
    
    public static Set<String> sortedStrings(Set<String> unorderedSet){
        Set<String> orderedSet = new Set<String>();
        List<String> stringList = new List<String>(unorderedSet);
        stringList.sort();
        orderedSet.addAll(stringList);
        return orderedSet ;
    }

}