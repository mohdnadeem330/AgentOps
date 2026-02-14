public without sharing class UnitServiceWithoutSharing {
    
    public static String ALLOCATION_GROUP_ALL = Label.AllInternalUsersAllocationGroupID;

    /**
    * getAllProjects 
    *
    * return available projects
    * 
    * @usage searchUnit LWC
    *
    * @param none
    * @return   list<map<String,string>>  list of select options 
    * 
    */
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getAllProjectsBrokerPortal(){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        map<string,string> tempMapAll=new map<string,string>();
        tempMapAll.put('label','All Projects');
        tempMapAll.put('value','');
            filtersToReturn.add(tempMapAll);
        for(Project__c tempProject: ProjectService.getAllActiveProjects() ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }

    @AuraEnabled()
    public static List<Map<String, String>> getAllProjectsBrokerPortalBySaleType(Boolean isResale){
        List<Map<String, String>> filtersToReturn = new List<Map<String, String>>{
            new Map<String, String>{
                'label' => 'All Projects',
                'value' => ''
            }
        };
        
        List<Project__c> projList = isResale == true ? getAllResaleProjects() : ProjectService.getAllActiveProjects();

        for(Project__c p: projList ){
            filtersToReturn.add(
                new Map<String, String>{
                    'label' => p.Name,
                    'value' => p.id
                }
            );
        }
        return filtersToReturn;
    }
    
    public static List<Project__c> getAllResaleProjects(){
        List<String> acceptedStatusList = System.Label.ResaleUnitAcceptStatusList.split(',');
        return [SELECT id, Name, AccountNumberEscrow__c, AccountNumberCorporate__c
                FROM Project__c 
                WHERE Id IN (SELECT Project__c FROM Unit__c 
                                WHERE ResaleListed__c = TRUE
                                    AND ResaleStatus__c NOT IN :acceptedStatusList)
                ORDER BY Name ];
    }

    /**
    * getAllUnitsBrokerPortal 
    *
    * return available all units note: only available units are shared
    * 
    * @usage searchUnit LWC
    *
    * @param none
    * @return   list<Unit__c>  list of availabel units
    * @chagnes Harsh@Aldar to handle the resale logic -- NEW METHOD
    */
    //COMMENTED BY HARSH@ALDAR to add SOQL for Resale Units -- OLD METHOD
    // @AuraEnabled(cacheable=true)
    // public static list<Unit__c> getAllUnitsBrokerPortal(string projectId){
    //     if(projectId == ''){
    //         map<id,Project__c> projectsMap = new map<id,Project__c>(ProjectService.getAllActiveProjects());
    //         System.debug('projectsMap>>>' + projectsMap);
    //         return [SELECT Id,CommunityName__c,ProjectName__c,Project__r.City__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c,BuildingSectionName__c,BuildingSectionName__r.Name FROM Unit__c WHERE OnlineBrokerFlag__c = true and Status__c = 'Available' and Project__c in :projectsMap.keyset() AND AllocationGroup__c=:ALLOCATION_GROUP_ALL];
    //     }
    //     return [SELECT Id,CommunityName__c,ProjectName__c,Project__r.City__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c,BuildingSectionName__c,BuildingSectionName__r.Name FROM Unit__c WHERE OnlineBrokerFlag__c = true and Status__c = 'Available' and Project__c = :projectId AND AllocationGroup__c=:ALLOCATION_GROUP_ALL];
    // }
    @AuraEnabled(cacheable=true)
    public static List<Unit__c> getAllUnitsBrokerPortal(string projectId, Boolean isResale){
        // Create a common list to store the final results
        List<Unit__c> unitsList = new List<Unit__c>();
        //Harsh@Aldar -- 30-08-23 -- Added the Unit's ResaleStatus__c filter criteria
        List<String> acceptedStatusList = System.Label.ResaleUnitAcceptStatusList.split(',');
        // Construct the common part of the query, which is the same for both cases
        // Updated By Moh Sarfaraj for BPE-324
        String commonQueryPart = 'SELECT Id, CurrencyIsoCode, PropertyId__c, Listing_Price__c, CommunityName__c, ProjectName__c, Project__r.Country__c, Project__r.City__c, Project__r.Name, Name, Status__c, UnitType__c, UnitModel__c, UnitView__c, PlotArea__c, UnitPlotArea__c, MeasuredInternalArea__c, TerraceArea__c, TotalArea__c, MarketPrice__c, SellingPrice__c, BuildingSectionName__c, BuildingSectionName__r.Name FROM Unit__c WHERE';

        // Check if projectId is empty, and if yes, retrieve all active projects
        if (String.isBlank(projectId)){
            map<id,Project__c> projectsMap = new map<id,Project__c>(ProjectService.getAllActiveProjects());
            System.debug('projectsMap>>>' + projectsMap);
            Set<Id> projectMapKeySet = projectsMap.keySet();
            // Check if it's a resale and append the appropriate condition
            if (isResale) {
                commonQueryPart += ' ResaleListed__c = true AND ResaleStatus__c NOT IN :acceptedStatusList';
            } else {
                commonQueryPart += ' OnlineBrokerFlag__c = true AND Status__c = \'Available\' AND Project__c IN :projectMapKeySet AND ( AllocationGroup__c = :ALLOCATION_GROUP_ALL OR AIPListed__c = true )';
            }
        } else {
            // Check if it's a resale and append the appropriate condition
            if (isResale) {
                commonQueryPart += ' ResaleListed__c = true AND Project__c = :projectId AND ResaleStatus__c NOT IN :acceptedStatusList';
            } else {
                commonQueryPart += ' OnlineBrokerFlag__c = true AND Status__c = \'Available\' AND Project__c = :projectId AND ( AllocationGroup__c = :ALLOCATION_GROUP_ALL OR AIPListed__c = true )';
            }
        }
        unitsList = Database.query(commonQueryPart);
        return unitsList;
    }

    public static list<Unit__c> getUnitsFromProjectIds(Set<Id> projectIds){
        return [Select Id,SellingPrice__c,UnitType__c,Project__c,Status__c from Unit__c where Project__c in :projectIds and (( OnlineBrokerFlag__c = true AND ( AllocationGroup__c=:ALLOCATION_GROUP_ALL OR AIPListed__c = TRUE )) OR ResaleListed__c = TRUE  ) ];
    }

    @AuraEnabled(cacheable=false)
    public static list<Unit__c> getUnitsById(List<Id> unitIds, Boolean isResale){
        if(isResale){ // Updated By Moh Sarfaraj for BPE-324
            return [SELECT Id, Name, CurrencyIsoCode, RelatedSalesOrder__c, ListedCase__c, ListedCase__r.SalesOrder__c, TotalArea__c, NumberOfCarParks__c, NumberOfBedrooms__c, SellingPrice__c, Project__c, PropertyId__c, Listing_Price__c, Project__r.Amenities__c FROM Unit__c WHERE Id IN :unitIds];
        }// Updated By Moh Sarfaraj for BPE-324
        return [SELECT Id, CurrencyIsoCode, Name, TotalArea__c, NumberOfCarParks__c, NumberOfBedrooms__c, SellingPrice__c, Project__c,Project__r.Amenities__c FROM Unit__c WHERE Id IN :unitIds and OnlineBrokerFlag__c = true AND AllocationGroup__c=:ALLOCATION_GROUP_ALL];
    }
    /* This query is used for the Offer generation */
    public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
        /*
      return [select Eligible_for_Etihad_Miles__c, Etihad_Miles__c,Unit_Feature_for_Payment_Plan__c,OriginalSellingPrice__c, 
              Mandatory_POD__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,
              BuildingSectionName__r.EligibleforPodium__c, EligibleforUnitFurnishing__c,BuildingSectionName__r.TaxPercentage__c,
              MarketLeaseRent__c,UnitModel__c,TotalRooms__c,Project__r.ExcludeFromADM__c ,Project__r.ProjectBudget__c,
              Project__r.DigitalSignatureApplied__c, Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,
              BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,
              MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,
              SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,
              BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,
              Project__c,BuildingSectionName__c,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,
              TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,
              ProjectBudget__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,
              Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,BuildingSectionName__r.IBANNoEscrow__c,
              BuildingSectionName__r.IBANNoCorporate__c, ReservationAmount__c,Project__r.DirectDebitApplied__c, 
              OffPlanProperty__c, Project__r.City__c, Project__r.IBANNoCorporate__c  from Unit__c where id in :unitIds];
			*/
        // Added the swimming pool field for yas riva
        return [select AssignedToUser__c, Mandatory_Swimming_Pool__c,Swimming_Pool_Price__c,Internal_Area__c,DigitalSales__c, Eligible_for_Etihad_Miles__c, Etihad_Miles__c,Unit_Feature_for_Payment_Plan__c, Mandatory_POD__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,BuildingSectionName__r.EligibleforPodium__c, EligibleforUnitFurnishing__c,BuildingSectionName__r.TaxPercentage__c,MarketLeaseRent__c,UnitModel__c,TotalRooms__c,Project__r.ExcludeFromADM__c ,Project__r.ProjectBudget__c,Project__r.DigitalSignatureApplied__c, Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,ProjectBudget__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,ReservationAmount__c,Project__r.DirectDebitApplied__c, OffPlanProperty__c,Project__r.City__c, Project__r.IBANNoCorporate__c,Project__r.CurrencyISOCode,CommunityName__c,ExpectedCustomerHandoverDate__c  from Unit__c where id in :unitIds];
    }
    /* This query is used for the Offer generation */
    public static list<UnitDesign__c> getAllUnitDesign(set<ID> unitIds){
        return [select Unit__r.ProjectName__c,DesignType__c,GFAArea__c,PremiumAmount__c,SaleableArea__c,SellingPrice__c,TerraceArea__c,Unit__c,WebFloorPlan__c from UnitDesign__c where Unit__c in :unitIds];
    }
}