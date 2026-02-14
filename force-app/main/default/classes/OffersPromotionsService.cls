public with sharing class OffersPromotionsService {
    
    /*
    * Get Active Offers and Promotions by Project or Id
    */
    public static List<OffersPromotions__c>  getActiveOffersAndPromotions(Set<Id> buildingIds, Set<Id> projectIds){

        List<OffersPromotions__c> allOfferPromotions = new List<OffersPromotions__c>();
        List<OffersPromotions__c> allOfferPromotionsToLoop = new List<OffersPromotions__c>();
        List<OffersPromotions__c> applicableOfferPromotionsFinal = new List<OffersPromotions__c>();
        set<String> allocationGroupNames = AllocationGroupUserService.getUserAllocationGroupNames();


        User loggedIdUser = Utilities.getLoggedInUserDetail();
        String userProfileName = loggedIdUser.ProfileName__c;
        String userProfileId = loggedIdUser.Id;
        //DIGITAL SALES DigitalSales__c
        allOfferPromotions =  [select id,Name,BuildingSectionName__c,DigitalSales__c,Project__c,
                               BookingMemo__r.OwnerId,Unit__c,AllocationGroup__c,BrokerPortalFlag__c,
                               BookingMemo__r.RelatedOpportunity__c, 
                               (select id,Name,OfferName__c,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,
                                ResidentStatus__c,Unit__c,UnitType__c,UnitFeatures__c,UnitModel__c,NumberOfBedrooms__c,
                                LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,
                                BudgetTaskName__c,OfferValueType__c,PromoType__c,PromoValue__c,AgentType__c,
                                Enquiry_Category__c from Offers_Lines__r) from OffersPromotions__c where IsActive__c = true
                                and(Project__c in :projectIds or BuildingSectionName__c in :buildingIds)];
		  
		Map<Id,OffersPromotions__c> offersPromotionsMap = new Map<Id,OffersPromotions__c>(allOfferPromotions);
		
        List<BuildingOfferBOJ__c> BuildingJunctionList = [SELECT Id,Name,BuildingSection__c,BuildingSection__r.Project__c,OfferPromotion__c,
                                     OfferPromotion__r.Name FROM BuildingOfferBOJ__c WHERE 
                                     BuildingSection__c IN: buildingIds];
								
		if(!BuildingJunctionList.isEmpty()){
			for(BuildingOfferBOJ__c boj : BuildingJunctionList){
                if(offersPromotionsMap.containsKey(boj.OfferPromotion__c) && offersPromotionsMap.get(boj.OfferPromotion__c) != null){
                    allOfferPromotionsToLoop.add(offersPromotionsMap.get(boj.OfferPromotion__c));
                }				
			}			
		}else{
			allOfferPromotionsToLoop.addAll(allOfferPromotions);
		}
        
        //if (userProfileName.contains('PT1') || userProfileName.contains(Constants.SALES_MANAGER)) { //PT1 for development only 
          allOfferPromotions =  [select id,Name,BuildingSectionName__c,Project__c,BookingMemo__r.OwnerId,Unit__c,AllocationGroup__c,BrokerPortalFlag__c, (select id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitFeatures__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c,PromoType__c,PromoValue__c,AgentType__c from Offers_Lines__r) from OffersPromotions__c where  IsActive__c = true  //and BookingMemoOwner__c =: userProfileId 
          and(Project__c in :projectIds or BuildingSectionName__c in :buildingIds)];
        //}//booking memo owner

        //--- Check Logged In user profile, contains SM then get the allocation group
        
        //--- Get the offer by buiding, project, allocation group

        for(OffersPromotions__c offerProm : allOfferPromotionsToLoop){
            if(String.isNotBlank(offerProm.AllocationGroup__c)){
                List<String> offerAllocationGroupCode = offerProm.AllocationGroup__c.split(',', 15);
                for(String codeValue : offerAllocationGroupCode){
                    if(allocationGroupNames.contains(codeValue)){
                      applicableOfferPromotionsFinal.add(offerProm);
                    }
                }
            } 
            else{
                applicableOfferPromotionsFinal.add(offerProm);
            }
        }
        System.debug('**Applicable Offers Final **'+applicableOfferPromotionsFinal);
        return applicableOfferPromotionsFinal ;
    }

    public static OffersPromotions__c  getSelectedOffersAndPromotions(Id offersPromotionsId){

        OffersPromotions__c allOfferPromotions = new OffersPromotions__c();

        allOfferPromotions =  [SELECT id,Name,BuildingSectionName__c,Project__c,BookingMemo__r.OwnerId,Unit__c,AllocationGroup__c,BrokerPortalFlag__c, (SELECT id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitFeatures__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c,AgentType__c FROM Offers_Lines__r) FROM OffersPromotions__c where  Id  =: offersPromotionsId];

        return allOfferPromotions ;
    }

    @AuraEnabled(cacheable=false)
    public static void insertOffersPromotions(List<OffersPromotions__c> offersPromotionsList){
      insert offersPromotionsList;
    }

    @AuraEnabled(cacheable=false)
    public static String lastCreatedIdOffersPromotions(String bookingMemoId, String unitId)  {   
    String lastCreatedId;
    List<OffersPromotions__c> records = [select Id from OffersPromotions__c where BookingMemo__c =: bookingMemoId and Unit__c =: unitId limit 1];
        if(records.size() > 0)
        {
           lastCreatedId = records[0].Id;
        }
        return lastCreatedId;     
    }

    public static Map<String,OffersPromotions__c> getOffersPromotionsByName(Set<String> offersPromotionsNames) {   
        
        Map<String,OffersPromotions__c> offersPromotionsMap = new Map<String,OffersPromotions__c>();    

        for(OffersPromotions__c offerPromotionRecord : [SELECT Id, Name, OfferName__c FROM OffersPromotions__c WHERE OfferName__c In : offersPromotionsNames]){
            offersPromotionsMap.put(offerPromotionRecord.OfferName__c,offerPromotionRecord);
        }       
        return offersPromotionsMap;
    }

    public static Map<Id,List<OffersPromotions__c>> getActiveOffersPromotions(Opportunity opportunityRec,List<Unit__c> unitList,User loggedInUser){

        Map<Id,List<OffersPromotions__c>> unitOfferMap = new Map<Id,List<OffersPromotions__c>>();
        Map<Id,List<OffersPromotions__c>> buildingProjectOfferMap = new Map<Id,List<OffersPromotions__c>>();


        for(Unit__c unitRec : unitList){
            buildingProjectOfferMap.put(unitRec.BuildingSectionName__c,new List<OffersPromotions__c>());
            buildingProjectOfferMap.put(unitRec.Project__c,new List<OffersPromotions__c>());
            unitOfferMap.put(unitRec.Id,new List<OffersPromotions__c>());
        }

        if(buildingProjectOfferMap != null){
            Map<Id,OffersPromotions__c> offersMap = new Map<Id,OffersPromotions__c>(OffersPromotionsService.getActiveOffersAndPromotions(buildingProjectOfferMap.keySet(),buildingProjectOfferMap.keySet()));

            for(OffersPromotions__c offerRec : offersMap.values()){
                if(buildingProjectOfferMap.containsKey(offerRec.BuildingSectionName__c)){
                    buildingProjectOfferMap.get(offerRec.BuildingSectionName__c).add(offerRec);
                }
                if(buildingProjectOfferMap.containsKey(offerRec.Project__c)){
                    buildingProjectOfferMap.get(offerRec.Project__c).add(offerRec);
                }
            }

            for(Unit__c unitRec : unitList){
                if(buildingProjectOfferMap.containsKey(unitRec.BuildingSectionName__c)){
                    for(OffersPromotions__c offerRec : buildingProjectOfferMap.get(unitRec.BuildingSectionName__c)){
                        System.debug(offerRec+'**Offer Record**');
                        //------ Standard Offers
                        if(offerRec.BookingMemo__c == null){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                            //------ Check if Memo offer is applicable
                        else if(opportunityRec!=null && offerRec.BookingMemo__c != null && offerRec.Unit__c  == unitRec.Id && offerRec.BookingMemo__r.OwnerId == loggedInUser.Id && offerRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                    }
                } 
                if(buildingProjectOfferMap.containsKey(unitRec.Project__c)){
                    for(OffersPromotions__c offerRec : buildingProjectOfferMap.get(unitRec.Project__c)){
                        System.debug(offerRec+'**Offer Record**');
                        //------ Standard Offers
                        if(offerRec.BookingMemo__c == null && offerRec.BuildingSectionName__c==null){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                            //------ Check if Memo offer is applicable
                        else if(opportunityRec!=null  && offerRec.BuildingSectionName__c==null && offerRec.BookingMemo__c != null && offerRec.Unit__c  == unitRec.Id && offerRec.BookingMemo__r.OwnerId == loggedInUser.Id && offerRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                    }
                }
            }
            System.debug('**Unit Offers**'+unitOfferMap);
        }
        return unitOfferMap ;

    }
   
}