/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Service class for ResaleComponentService.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Harsh Rohilla   <hrohilla@aldar.com>
* @modifiedBy     
* @maintainedBy   
* @version        1.0
* @created        2023-06-22
* @modified       2023-06-22
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
 */
public without sharing class ResaleComponentService {
    /**
     * @description getUnitDetailsById get Unit Details by Id
     * @param  unitId unitId description
     * @return        return description
     */
    public static Unit__c getUnitDetailsById(String unitId){
        Unit__c thisUnit = [SELECT Id, Name, Project__r.Name, BuildingSectionName__r.Name , Project__c, BuildingSectionName__c
                            FROM Unit__c 
                            WHERE Id =: unitId 
                            LIMIT 1];

        return thisUnit;
    } 

    /**
     * @description Get Opportunity Details by Opportunity Id
     * @param  oppId oppId description
     * @return       return description
     */
    public static Opportunity getOppDetailsById(String oppId){
        Opportunity thisOpp = [SELECT Id, Name, CurrencyISOCode, 
                                    Project__c, DeliveryMethod__c, EmployeeName__c,SubsidyYears__c, 
                                    SaleType__c, DealType__c, BookingType__c, AgentType__c, ReferralType__c, 
                                    BankName__c, CustomerResidentStatus__c, 
                                    BrokerAgentName__c,BrokerAgencyAccount__c, BrokerAgencyAccount__r.Name, 
                                    ServiceRequest__c, ServiceRequest__r.SwappedUnit__c, ServiceRequest__r.SwappedUnit__r.BuildingSectionName__c, 
                                    AccountId, Account.CorporateWealthName__c, Account.Name, Account.PersonEmail, Account.MobilePhone__pc, Account.PersonMobilePhone, 
                                    Unit__c, SalesOrder__c, SalesOrder__r.Name, SalesOrder__r.Account__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Account__r.MobilePhone__pc, SalesOrder__r.Account__r.PersonMobilePhone 
                                FROM Opportunity 
                                WHERE Id =: oppId 
                                LIMIT 1];
        return thisOpp;
    }

    /**
     * @description getAllProjects description ASF 936 Harsh@Aldar
     * @return   return description
     */ 
    @AuraEnabled(cacheable=true)
    public static list<Project__c> getAllProjects(){
        return [SELECT Id, Name, AccountNumberEscrow__c, AccountNumberCorporate__c 
                FROM Project__c 
                ORDER BY Name ASC];
    }

    /**
     * @description get Approved resale offers by unit id
     * @param  unitId unitId description
     * @return        return description
     */
    public static List<Resale_Offers__c> getApprovedResaleOffersByUnitId(String unitId){
        List<Resale_Offers__c> thisOfferList = [SELECT Id, Status__c, Sales_Order__c, Opportunity__c, Opportunity__r.Name, Unit__r.Name,
                                                Comments__c,Unit__r.Listing_Price__c 
                                                FROM Resale_Offers__c 
                                                WHERE Unit__c =: unitId 
                                                AND Status__c =: ResaleConstants.STATUS_APPROVED];

        return thisOfferList;
    }

    /**
     * @description getAllSalesOrdersRelatedtoUnit ASF 936
     * @param  unitId unitId description
     * @return        return description
     */ 
    public static Unit__c getAllSalesOrdersRelatedtoUnit(String unitId ){
    
        Unit__c thisUnit =  [SELECT Id, UnitNumber__c, Name, CurrencyISOCode,
                                Listing_Price__c, Sellingprice__c, 
                                ProjectName__c, UnitType__c, TotalRooms__c, SaleableArea__c, NumberOfBathrooms__c, TotalArea__c, 
                                RelatedOpportunity__c, RelatedSalesOrder__c, 
                                RelatedSalesOrder__r.Name, RelatedSalesOrder__r.Account__c, RelatedSalesOrder__r.Account__r.Name, 
                                ListedCase__c, ListedCase__r.SalesOrder__c, ListedCase__r.SalesOrder__r.Name,
                                ListedCase__r.AccountId, ListedCase__r.Account.Name, ListedCase__r.Account.PersonEmail, ListedCase__r.Account.MobilePhone__pc, ListedCase__r.Account.PersonMobilePhone
                            FROM Unit__c 
                            WHERE Id =: unitId 
                            LIMIT 1];
System.debug(JSON.serializePretty(thisUnit));
        return thisUnit;
 
    }

    /**
   * @description getAvailableResaleUnits Get List of Resale Units under Buildings 
   * ASF-936 Developed by Harsh@Aldar 12/06/23
   * @param  buildingsIds buildingsIds description
   * @return              return description
   */
  public static List<Unit__c> getAvailableResaleUnits(Set<Id> buildingsIds){
    String acceptedStatusListString = System.Label.ResaleUnitAcceptStatusList;
    // Split the values using the comma as a delimiter
    List<String> acceptedStatusList = acceptedStatusListString.split(',');
    return [SELECT Id, Name, NumberOfBedrooms__c, UnitType__c, MultiPurposeAmount__c, MultiPurposeRoomArea__c,
            MeasuredArea__c, PropertyUsage__c, UnitModel__c, FloorNumber__c, UnitView__c, PropertyStatus__c, 
            SaleableArea__c, TotalRooms__c, UnitCategory__c, MeasuredInternalArea__c, TerraceArea__c, TotalArea__c,
            UnitPlotArea__c, SellingPrice__c, OnlineReservationFee__c, AffectionPlan__c, MarketingPlan__c, 
            AnticipatedServiceCharges__c, BuildingSectionName__c, Listing_Price__c,ProjectName__c, PropertyId__c,
            BuildingSectionName__r.HomeMaintenanceFee__c, BuildingSectionName__r.PropertyManagementFee__c,
            BuildingSectionName__r.EligibileforMultiPurposeRoom__c, BuildingSectionName__r.EligibleforUnitFinishes__c,
            BuildingSectionName__r.ReservationAmount__c, ProjectBudget__c, ListedBy__c, ListedBy__r.Name, Listing_Expiry_Date__c
            FROM Unit__c 
            WHERE BuildingSectionName__c IN :buildingsIds  
            AND ResaleListed__c = true
            AND ResaleStatus__c NOT IN :acceptedStatusList
            ORDER BY Name];
    } 

    
    public static void updateUnitWithoutSharing (List<Unit__c> unitList){
        update unitList;
    }
}