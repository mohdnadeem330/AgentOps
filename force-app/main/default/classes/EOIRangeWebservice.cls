@RestResource (urlMapping = '/get/eoiranges')
global class EOIRangeWebservice {
    @HTTPPost
    global static void doPost(String opportunityId)
    {
        RestContextHandler handler = new RestContextHandler(true);
        try {       
            
            List<EOIRange__c> eoiRangeData = EOIRangeService.getEOIRangeQuery('SELECT BuildingName__c,UnitType__c,UnitModel__c,UnitFeatures__c,ProjectName__c,MinPriceRange__c, MaxPriceRange__c, BuildingSectionEOIFee__c FROM EOIRange__c LIMIT 200');
            
            Boolean processRecords = false;
            
            EOIRangesResponse response = new EOIRangesResponse(eoiRangeData, 'EOIRange__c', processRecords);
            
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();                       
        }
        catch(Exception e)
        {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
            
        }
    }
    
    global with sharing class EOIRangesResponse extends QueryResponse
    {                
        Set<String> projects = new Set<String>();
        Set<String> buildings = new Set<String>();
        Set<String> unitModels = new Set<String>();
        Set<String> unitTypes = new Set<String>();
        Set<String> unitFeatures = new Set<String>();

        List<EOIRangeBuildingFee> eoiRangeBuildingFee = new List<EOIRangeBuildingFee>();
        
        
        Map<String, Set<String>> projectBuildingMap = new Map<String, Set<String>>();
        Map<String, Set<String>> buildingUnitModelMap = new Map<String, Set<String>>();
        Map<String, Set<String>> unitModelUnitTypeMap = new Map<String, Set<String>>();
        Map<String, Set<String>> unitTypeUnitFeaturesMap = new Map<String, Set<String>>();
        List<String> paymentMode = new List<String>();
        
        global EOIRangesResponse (List<SObject> records, String objectName, Boolean processRecords) {
            super(records, objectName, processRecords);
            
            for (SObject record : records) {
                EOIRange__c eoiRange = (EOIRange__c) record;

                EoiRangeBuildingFee eoiRangeBuildingFeeRecord = new eoiRangeBuildingFee();
                eoiRangeBuildingFeeRecord.key = eoiRange.ProjectName__c+'-'+eoiRange.BuildingName__c+'-'+eoiRange.UnitModel__c+'-'+eoiRange.UnitType__c+'-'+eoiRange.UnitFeatures__c;
                String unitTypekey = eoiRange.ProjectName__c+'-'+eoiRange.BuildingName__c+'-'+eoiRange.UnitModel__c ;
                String unitFeaturekey = eoiRange.ProjectName__c+'-'+eoiRange.BuildingName__c+'-'+eoiRange.UnitModel__c+'-'+eoiRange.UnitType__c ;


                eoiRangeBuildingFeeRecord.minimumPriceRange = eoiRange.MinPriceRange__c;
                eoiRangeBuildingFeeRecord.maximumPriceRange = eoiRange.MaxPriceRange__c;
                eoiRangeBuildingFeeRecord.eoiFee = eoiRange.BuildingSectionEOIFee__c;

                eoiRangeBuildingFee.add(eoiRangeBuildingFeeRecord);
                
                if (eoiRange.ProjectName__c != null) {
                    String projectName = eoiRange.ProjectName__c;
                    
                    projects.add(projectName);
                    
                    if (eoiRange.BuildingName__c != null){
                        String buildingName = eoiRange.BuildingName__c;
                        buildings.add(buildingName);
                        
                        Set<String> buildingNames = new Set<String>(); 
                        if(projectBuildingMap.containsKey(projectName)){
                            buildingNames = projectBuildingMap.get(projectName);
                        }
                        buildingNames.add(buildingName);
                        projectBuildingMap.put(projectName,buildingNames);
                        
                        if(eoiRange.UnitModel__c != null){
                            String unitModelName = eoiRange.UnitModel__c;
                            unitModels.add(buildingName);
                            
                            Set<String> unitModel = new Set<String>(); 
                            if(buildingUnitModelMap.containsKey(buildingName)){
                                unitModel = buildingUnitModelMap.get(buildingName);
                            }
                            unitModel.add(eoiRange.UnitModel__c);
                            buildingUnitModelMap.put(buildingName,sortedStrings(unitModel));



                            if(eoiRange.UnitType__c != null){
                                String unitType = eoiRange.UnitType__c;
                                unitTypes.add(unitType);
                                
                                Set<String> unitTypeSet = new Set<String>(); 
                                if(unitModelUnitTypeMap.containsKey(unitTypekey)){
                                    unitTypeSet = unitModelUnitTypeMap.get(unitTypekey);
                                }
                                unitTypeSet.add(eoiRange.UnitType__c);
                                unitModelUnitTypeMap.put(unitTypekey,sortedStrings(unitTypeSet));



                                if(eoiRange.UnitFeatures__c != null){
                                    String unitFeature = eoiRange.UnitFeatures__c;
                                    unitFeatures.add(unitFeature);
                                    
                                    Set<String> unitFeatureSet = new Set<String>(); 
                                    if(unitTypeUnitFeaturesMap.containsKey(unitFeaturekey)){
                                        unitFeatureSet = unitTypeUnitFeaturesMap.get(unitFeaturekey);
                                    }
                                    unitFeatureSet.add(eoiRange.UnitFeatures__c);
                                    unitTypeUnitFeaturesMap.put(unitFeaturekey,sortedStrings(unitFeatureSet));
                                }
                            }
                        }
                    }
                    
                }
            }   
            
        Schema.DescribeFieldResult fieldResult = OpportunityEOI__c.PaymentMode__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
        for( Schema.PicklistEntry pickListVal : ple){
			paymentMode.add(pickListVal.getLabel());
		}   
        
        } 
    }

    public static Set<String> sortedStrings(Set<String> unorderedSet){
        Set<String> orderedSet = new Set<String>();
        List<String> stringList = new List<String>(unorderedSet);
        stringList.sort();
        orderedSet.addAll(stringList);
        return orderedSet ;
    }

    global class EOIRangeBuildingFee{
        public String key                   {get;set;}
        public Decimal minimumPriceRange    {get;set;}
        public Decimal maximumPriceRange    {get;set;}
        public Decimal eoiFee               {get;set;}
    }
}