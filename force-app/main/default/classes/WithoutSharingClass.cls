public without sharing class WithoutSharingClass {
    public static void updatesalesOrderSyncStatuses(List<SalesOrder__c> salesOrderListToUpdate){
        update salesOrderListToUpdate;
    }   
    public static Map<Id,Document__c> getDocumentforReciepientStatus(Set<Id> sourceIds){
         Map<Id,Document__c> docMap = new Map<Id,Document__c>([SELECT ID,SalesOrder__c,SalesOrder__r.CustomerSPASigned__c,
                                                                  SalesOrder__r.Status__c,SalesOrder__r.SignatureType__c
                                                                  FROM Document__c WHERE Id IN:sourceIds
                                                                  AND SalesOrder__c != null ]);
        return docMap;
    }
    public static List<dfsle__RecipientStatus__c> getReciepientStatusList( Set<Id> envelopeIds){
       List<dfsle__RecipientStatus__c> reciepientList = [SELECT Id,dfsle__EnvelopeStatus__c,dfsle__Completed__c,dfsle__Email__c,
                                                             dfsle__RoutingOrder__c,dfsle__Status__c,dfsle__SourceId__c,CommunicationPreference__c
                                                         FROM dfsle__RecipientStatus__c 
                                                         WHERE dfsle__EnvelopeStatus__c IN : envelopeIds  
                                                         ORDER BY  dfsle__EnvelopeStatus__c,dfsle__RoutingOrder__c ];
        return reciepientList;
    }
    // ASF-3725 changes (Unit Assignment): Bashim
    public static void updateUnitAssignments(List<Unit_Assignment__c> lstUnitAssignment){
        update lstUnitAssignment;
    } 
    public static void insertUnitAssignments(List<Unit_Assignment__c> lstUnitAssignment){
        insert lstUnitAssignment;
    }
    
    public static List<Unit__c> getUnits(List<String> unitsSelected){
        List<Unit__c> lstSelectedUnits = [SELECT Id,Name,Project__r.Name,SellingPrice__c,AllocationGroupUser__c, RelatedOpportunity__c FROM Unit__c WHERE Id IN:unitsSelected]; 
        return lstSelectedUnits;
    }
     // SSC-372 changes (Unit ): Mahidhar
    public static void updateUnits(List<Unit__c> lstUnits){
        update lstUnits;
    }
    // SSC-342 related changes by BASHIM: update account without trigger 
    public static void accountUpdateWithoutTrigger(List<Account> lstAccountToSyncMC){
        if(lstAccountToSyncMC != null && !lstAccountToSyncMC.isEmpty()){
            AccountTriggerHandler.skipAccountTrigger = true;
            update lstAccountToSyncMC;
            AccountTriggerHandler.skipAccountTrigger = false;
        }
    }
    // SSC-342 related changes by BASHIM: update opportunity without trigger 
    public static void opportunityUpdateWithoutTrigger(List<Opportunity> lstOpportunityToSyncMC){
        if(lstOpportunityToSyncMC != null && !lstOpportunityToSyncMC.isEmpty()){
            UtilitiesWithoutSharing.bypassOpportunityTrigger = true;
            update lstOpportunityToSyncMC;
            UtilitiesWithoutSharing.bypassOpportunityTrigger = false;
        }
    }
    // SSC-342 related changes by BASHIM: update contact without trigger
    public static void contactUpdateWithoutTrigger(List<Contact> lstContactToSyncMC){
        if(lstContactToSyncMC != null && !lstContactToSyncMC.isEmpty()){
            update lstContactToSyncMC;
        }
    }
   //Added by Mahidhar to return unit assignments by passing units
    public static List<Unit_Assignment__c> getUnitAssignments(List<String> unitIds){
        return [SELECT Id, Unit__r.Name,Unit__r.AssignedToUser__c,Status__c,RequestedBy__c  FROM Unit_Assignment__c
                                                           WHERE Unit__r.Status__c IN ('Available','In-Progress')
                                                           AND  (Status__c = 'Pending approval' OR Status__c = 'Approved')
                                                           AND Unit__c IN :unitIds];
    }
    
    public static list<Unit__c> getAllOnlineUnitsById(set<ID> unitIds){
        return [select AssignedToUser__c, Mandatory_Swimming_Pool__c,Project__r.City__c,Swimming_Pool_Price__c,Mandatory_POD__c,DigitalSales__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,BuildingSectionName__r.EligibleforPodium__c,BuildingSectionName__r.TaxPercentage__c,UnitModel__c,TotalRooms__c,Project__r.ProjectBudget__c ,Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,ProjectBudget__c,LockedBy__c,LockExpiryTime__c,LockTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,ReservationAmount__c,EligibleforUnitFurnishing__c, Unit_Feature_for_Payment_Plan__c,LockedByCustomer__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c from Unit__c where id in :unitIds AND DigitalSales__c=true FOR UPDATE];
    }
    public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
        return [select AssignedToUser__c,Mandatory_Swimming_Pool__c,Swimming_Pool_Price__c,Mandatory_POD__c,DigitalSales__c,Mandatory_Premium__c,PODMultiPurposeRoomPrice__c,PODkitchenPrice__c,BuildingSectionName__r.EligibleforPodium__c,BuildingSectionName__r.TaxPercentage__c,UnitModel__c,TotalRooms__c,Project__r.ProjectBudget__c ,Project__r.DarnaApplicable__c,BuildingSectionName__r.EligibileforMultiPurposeRoom__c,BuildingSectionName__r.EligibleforUnitFinishes__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,MultiPurposeAmount__c,GFAArea__c,Project__r.Name, Project__r.ReservationAmount__c,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,EscalationServiceCharge__c, BuildingSectionName__r.ReservationAmount__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,FeaturesSpecification__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,BuildingSectionName__r.HomeMaintenanceFee__c,TerraceArea__c,MeasuredInternalArea__c,ProjectBudget__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,Project__r.MapView__c ,UnitCategory__c,Project__r.VideoLink__c,BuildingSectionName__r.ExcludeFromDarna__c,ReservationAmount__c,EligibleforUnitFurnishing__c, Unit_Feature_for_Payment_Plan__c,LockedByCustomer__c  from Unit__c where id in :unitIds];
    }
    
    public static Timer__mdt getTimer(string timerName){
        try{
            Timer__mdt timerDetails = [SELECT Timer__c, Time__c
                                       FROM Timer__mdt
                                       WHERE DEVELOPERNAME =: timerName];
            return timerDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    public static List<Unit__c> lockUnit(List<Unit__c> lstUnits,String customerId,String timerName,String purpose) {
        try {
            Decimal timerDetails = getTimer(timerName).Timer__c;
            String timerUnit = getTimer(timerName).Time__c;
            
            for(Unit__c objUnit : lstUnits) {
                if((objUnit.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS || objUnit.Status__c == Constants.STATUS_RESERVED) && objUnit.LockedByCustomer__c != null && objUnit.LockedByCustomer__c != customerId) {
                    throw new customException(label.UnitLockedByOtherCustomer);
                }
                
                if(UnitAvailabilityWebService.UnitdigitalSales == true) {
                    objUnit.LockedByCustomer__c = customerId;
                    objUnit.LockType__c = (purpose == Constants.BROKER_KYC) ? 'Broker KYC' : (purpose == Constants.BROKER_UNIT_RESERVATION || purpose == Constants.BROKER_RESERVE_UNIT) ? 'Broker Reserve' : objUnit.LockType__c;
                } else {
                    objUnit.LockedBy__c = UserInfo.getUserId();
                }
                objUnit.LockTime__c = system.now();
                objUnit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;       
                if (timerUnit == Constants.HOURS) {
                    timerDetails = timerDetails * 60;
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                } else {
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                }
            }
            system.debug('before update unit details '+lstUnits);
            update lstUnits;
            UnitAvailabilityWebService.callDamascusCallbackMethod(lstUnits[0],true);
        } catch(Exception ex) {
            LoggerService.save(LoggerService.addApexLog(ex,'Locking of Unit','LockingUnits','LockUnits'));
            throw ex;
        }
        return lstUnits;
    }
}