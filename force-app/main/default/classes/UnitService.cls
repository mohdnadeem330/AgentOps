public with sharing class UnitService {
  public UnitService() {}

  public static list<Unit__c> getAllAvailableUnitsUnderBuilding(set<ID> buildingsIds){
    return [select id,Name,NumberOfBedrooms__c,UnitType__c,MultiPurposeAmount__c,MultiPurposeRoomArea__c,MeasuredArea__c,PropertyUsage__c,UnitModel__c,FloorNumber__c,UnitView__c,PropertyStatus__c,SaleableArea__c,TotalRooms__c,UnitCategory__c,MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,UnitPlotArea__c,SellingPrice__c,OnlineReservationFee__c,AffectionPlan__c,MarketingPlan__c,AnticipatedServiceCharges__c,BuildingSectionName__c,BuildingSectionName__r.HomeMaintenanceFee__c,BuildingSectionName__r.PropertyManagementFee__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,BuildingSectionName__r.ReservationAmount__c,ProjectBudget__c,RelatedOpportunity__c,AssignedToUser__c,AssignedToUser__r.Name,Project__r.Reservation_Payment_Method__c from Unit__c where BuildingSectionName__c in :buildingsIds  and IsActive__c =true AND RTOAllowed__c = false AND ( Status__c=:Constants.UNIT_STATUS_AVAILABLE OR (Status__c=:Constants.UNIT_STATUS_BOOKING_INPROGRESS AND (LockedBy__c = :UserInfo.getUserId() OR LockedByCustomer__c = null))) order by Name];
  }
  //swimming pool related changes for yas riva
  public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
    //Added by Chirag DIGITAL SALES
    return [select AssignedToUser__c,Mandatory_Swimming_Pool__c,Swimming_Pool_Price__c,Mandatory_POD__c,DigitalSales__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,BuildingSectionName__r.EligibleforPodium__c,BuildingSectionName__r.TaxPercentage__c,UnitModel__c,TotalRooms__c,Project__r.ProjectBudget__c ,Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,ProjectBudget__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,ReservationAmount__c,EligibleforUnitFurnishing__c, Unit_Feature_for_Payment_Plan__c,LockedByCustomer__c  from Unit__c where id in :unitIds];
  }
  //Added by Chirag DIGITAL SALES
  public static list<Unit__c> getAllOnlineUnitsById(set<ID> unitIds){
    return [select AssignedToUser__c, Mandatory_Swimming_Pool__c,Project__r.City__c,Swimming_Pool_Price__c,Mandatory_POD__c,DigitalSales__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,BuildingSectionName__r.EligibleforPodium__c,BuildingSectionName__r.TaxPercentage__c,UnitModel__c,TotalRooms__c,Project__r.ProjectBudget__c ,Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,ProjectBudget__c,LockedBy__c,LockExpiryTime__c,LockTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,ReservationAmount__c,EligibleforUnitFurnishing__c, Unit_Feature_for_Payment_Plan__c,LockedByCustomer__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c from Unit__c where id in :unitIds AND DigitalSales__c=true];
  }

    @AuraEnabled(cacheable=false)
    public static list<Unit__c> getUnitsById(List<Id> unitIds){
      return [SELECT Id, Name, TotalArea__c, NumberOfCarParks__c, NumberOfBedrooms__c, SellingPrice__c, Project__c FROM Unit__c WHERE Id IN :unitIds];
    }

  @AuraEnabled(cacheable=false) 
  public static list<Unit__c> prepareUnitId(String unitName){
      list<Unit__c> lstUnitsId = new list<Unit__c>();
      lstUnitsId.add([Select Id from Unit__c where Name =: unitName]);
      return lstUnitsId;
  }

  @AuraEnabled(cacheable=false)
  public static void unitBookingMemoApproved(List<MemoLines__c> memoLinesList, String owner){
    for (Integer i = 0; i < memoLinesList.size(); i++) {
      Unit__c unitObj = [Select Id,Status__c from Unit__c where Id =: memoLinesList[i].Unit__c];
      if(unitObj.Status__c == Constants.UNIT_STATUS_BLOCKED) {
          unitObj.Status__c = Constants.UNIT_STATUS_AVAILABLE;
          unitObj.AllocationGroup__c = null;
          unitObj.AssignedToUser__c = owner;
          update unitObj;
      }
    }
  }
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
        tempMapAll.put('label','All');
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

  /**
  * getAllUnitsBrokerPortal 
  *
  * return available all units note: only available units are shared
  * 
  * @usage searchUnit LWC
  *
  * @param none
  * @return   list<Unit__c>  list of availabel units
  * 
  */
  @AuraEnabled(cacheable=true)
  public static list<Unit__c> getAllUnitsBrokerPortal(string projectId){
    if(projectId == ''){
      map<id,Project__c> projectsMap = new map<id,Project__c>(ProjectService.getAllActiveProjects() );
      return [SELECT Id,CommunityName__c,ProjectName__c,Project__r.City__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c,BuildingSectionName__c,BuildingSectionName__r.Name FROM Unit__c WHERE OnlineBrokerFlag__c = True and Project__c in :projectsMap.keyset() ];
    }
    return [SELECT Id,CommunityName__c,ProjectName__c,Project__r.City__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c,BuildingSectionName__c,BuildingSectionName__r.Name FROM Unit__c WHERE OnlineBrokerFlag__c = True and Project__c = :projectId ];
  }



  /*@AuraEnabled(cacheable=false)
  public static List<Unit__c> prepareDropdownDataBrokerPortal(String projectNameParam){
    list<Unit__c> lstDropdownData = new list<Unit__c>();
    if (String.isNotBlank(projectNameParam)) {
      for(Unit__c objUnit : [Select Id,TotalRooms__c,UnitCategory__c,Project__r.Name,HandoverZone__c,FloorNumber__c,UnitView__c,UnitModel__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c from Unit__c where Project__r.Name =: projectNameParam AND OnlineBrokerFlag__c = True AND Project__r.IsActive__c = true]){
        lstDropdownData.add(objUnit);
      }
      }else{
        for(Unit__c objUnit: [Select Id,TotalRooms__c,Project__r.Name,Project__c,UnitCategory__c,HandoverZone__c,UnitView__c,UnitModel__c,FloorNumber__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c  from Unit__c where Project__r.IsActive__c = true AND  OnlineBrokerFlag__c = True]){
        lstDropdownData.add(objUnit);
      }
    }       
      return lstDropdownData;
  }*/

  @AuraEnabled(cacheable=false)
  public static List<Unit__c> prepareDropdownData(String projectNameParam){
    list<Unit__c> lstDropdownData = new list<Unit__c>();
    if (String.isNotBlank(projectNameParam)) {
      for(Unit__c objUnit : [Select Id,TotalRooms__c,UnitCategory__c,Project__r.Name,HandoverZone__c,FloorNumber__c,UnitView__c,UnitModel__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c from Unit__c where Project__r.Name =: projectNameParam AND PropertyStatus__c =:'Sale' AND (Status__c =: 'Available' OR Status__c =: 'Blocked')]){
        lstDropdownData.add(objUnit);
      }
      }else{
        for(Unit__c objUnit: [Select Id,TotalRooms__c,Project__r.Name,Project__c,UnitCategory__c,HandoverZone__c,UnitView__c,UnitModel__c,FloorNumber__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c  from Unit__c where Project__r.IsActive__c = true AND PropertyStatus__c =:'Sale' AND (Status__c =: 'Available' OR Status__c =: 'Blocked')]){
        lstDropdownData.add(objUnit);
      }
    }       
      return lstDropdownData;
  }

  @AuraEnabled(cacheable=false)
  public static List<Unit__c> prepareOptionList(String projectId, String BuildingSectionId){
    list<Unit__c> lstDropdownData = new list<Unit__c>();
    if (String.isNotBlank(BuildingSectionId)) {
      lstDropdownData = [SELECT Id, Name, Project__c, Project__r.Name, BuildingSectionName__c, BuildingSectionName__r.Name, UnitType__c, UnitModel__c, FloorNumber__c, NumberOfBedrooms__c, Status__c FROM Unit__c WHERE Project__c =: projectId AND BuildingSectionName__c =: BuildingSectionId LIMIT 49999];
    }else{
      lstDropdownData = [SELECT Id, Name, Project__c, Project__r.Name, BuildingSectionName__c, BuildingSectionName__r.Name, UnitType__c, UnitModel__c, FloorNumber__c, NumberOfBedrooms__c, Status__c FROM Unit__c WHERE Project__c =: projectId  LIMIT 49999];
    }     
    return lstDropdownData;
  }



  @AuraEnabled(cacheable=false)
  public static List<Unit__c> getUnitQuery(String query) {
    List<Unit__c> records = Database.query(query);
    return records;
  }
  
  /*
  * Release units when the Reservation or Booking is cancelled
  */
  public static void makeUnitsAvailable(Set<Id> unitIds) {

    List<Unit__c> unitList = new List<Unit__c>();
        
    for(Id unitId : unitIds){
        Unit__c unitRecord = new Unit__c();
        unitRecord.Id = unitId ; 
        unitRecord.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        unitRecord.LockedBy__c = null;
        unitRecord.LockTime__c = null;
        unitRecord.LockExpiryTime__c = null;
        unitRecord.RelatedOpportunity__c = null;
        unitRecord.RelatedSalesOrder__c = null;
        unitList.add(unitRecord);
    }

    if(unitList !=null && unitList.size()>0){
      update unitList; 
    }
     
  }

  public static Boolean cancelUnitReservation(Set<String> idList) {
    system.debug('cancelUnitReservation' + idList);
    List<Unit__c> unitList = new List<Unit__c>();
        
    for(Unit__c objUnit : [Select id,Name from Unit__c where id IN:idList]){
      objUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
      unitList.add(objUnit);
    }
    update unitList;
    return true;     
  }
  


  /*
  * Initialise Unit Sharing
  */
  public static Unit__Share getUnitShare(Id unitId, Id userOrGroupId,String accessLevel){
      Unit__Share unitShareRec = new Unit__Share();
      unitShareRec.UserOrGroupId = userOrGroupId;
      unitShareRec.AccessLevel = accessLevel;
      unitShareRec.ParentId = unitId;
      return unitShareRec ;
  } 

  /*
  * Fetch list of units based on the condition.
  */
  public static List<Unit__c> fetchPropertyInventories(string whereCondition){
      
    list<Unit__c> propertyInventoryList = new list<Unit__c>();

    Id userId = UserInfo.getUserId();
    
    try{
      string strQuery = 'Select id,Name,UnitPlotArea__c,PropertyStatus__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,BuildingSectionName__r.ReservationAmount__c,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,TerraceArea__c,MeasuredInternalArea__c,UnitModel__c,UnitView__c,FloorNumber__c,Project__r.ReservationAmount__c,PropertyUsage__c,UnitCategory__c,TotalRooms__c,ReservationAmount__c,AssignedToUser__r.name FROM Unit__c WHERE Id != null ';
        if(whereCondition != null && string.isNotEmpty(whereCondition)){
            strQuery += ' and ('+whereCondition+')';
        } 
        
        strQuery += ' AND ( Status__c =\'Available\' OR (Status__c =\'In-Progress\' AND (LockedBy__c =: userId OR LockedByCustomer__c = null) AND LockExpiryTime__c!=null))';

        strQuery += ' Order By Project__r.Name ASC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
        system.debug('**Unit Query**'+strQuery);
        propertyInventoryList =  Database.query(strQuery);
        return propertyInventoryList;
    }
    catch(Exception e){
        system.debug('*** Exception e***'+e.getMessage());
        throw e;
    }
  }

  public static List<Unit__c> filterAvailableUnits(Map<String, String> mapFieldApiFieldValues){
    System.debug('mapFieldApiFieldValues '+mapFieldApiFieldValues);
    List<String> andConditions = new List<String>();
  /* if (mapFieldApiFieldValues == null)
      mapFieldApiFieldValues = new Map<String, String>();
    mapFieldApiFieldValues.put('Status__c', 'Available');*/

    

    //andConditions.add('( Status__c =\'Available\' OR (Status__c =\'In-Progress\' AND LoggedBy__c=:\'+loggedInUser +'AND LockExpriyTime__c!=null))');

    Utilities.objType = 'inventory';
    String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    if (String.isNotBlank(whereConditionFromMap))
        andConditions.add(whereConditionFromMap);
    System.debug(whereConditionFromMap);
    String whereCondition = String.join(andConditions, ' AND ');
    
    System.debug('**Query**'+whereCondition);
    List<Unit__c> units = fetchPropertyInventories(whereCondition);
    return units;
  }

}