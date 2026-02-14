/**********************************************************************************************************************
* Name               : OpportunityUnitSearchController                                                        
* Description        : This class is used as controller for LWC (opportunityUnitSearch)
* Usage              : opportunityUnitSearch LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class OpportunityUnitSearchController{
   
    // iPad changes:static variable to resuse the same wrapper in the booking process: Bashim
    public static map<id,SalesOfferUtility.SalesOfferDetails> reservationWrapper;
    /**
* getsObjectType 
*
* return sobjectType and relevent fields
* 
* @usage opportunityUnitSearch LWC
*
* @param Id Record ID
* @return    map<String,object>  list of select options 
* 
*/
    @AuraEnabled(cacheable=true)
    public static map<String,object> getsObjectType(Id recordID){
        map<String,sObject> mapToReturn = new map<String,sObject>();
        Schema.SObjectType sobjectType = recordID.getSObjectType();
        string sobjectName = sobjectType.getDescribe().getName();
        if(sobjectName.equalsIgnoreCase('Opportunity')){
            // Commented below field for Deployment - Muzammil
            //, ServiceRequest__c, ServiceRequest__r.SwappedUnit__c, ServiceRequest__r.SwappedUnit__r.BuildingSectionName__c
            mapToReturn.put(sobjectName,[select id,CurrencyISOCode,Project__c,CustomerResidentStatus__c,DeliveryMethod__c,Account.CorporateWealthName__c,Name,SaleType__c,DealType__c,BookingType__c,AgentType__c,ReferralType__c,BankName__c,BrokerAgentName__c,BrokerAgencyAccount__c,EmployeeName__c,SubsidyYears__c,BrokerAgencyAccount__r.Name from Opportunity where id = :recordID limit 1]);
        }else if(sobjectName.equalsIgnoreCase('Unit__c')){
            mapToReturn.put(sobjectName,[select id,Project__r.Name,Name from Unit__c where id = :recordID limit 1]);
        }else if(sobjectName.equalsIgnoreCase('SalesOrder__c')){
            mapToReturn.put(sobjectName,[select id,Opportunity__c,Opportunity__r.CustomerResidentStatus__c from SalesOrder__c where id = :recordID limit 1]);
        }
    
        return mapToReturn;
    }
    
    /**
* calculateNetValue 
*
* return the total net value
* 
* @usage opportunityUnitSearch LWC
*
* @param List<Decimal>  amountValues
* @return  Decimal of the total net value
* NOTE: SHOULD BE REMOVED
    
@AuraEnabled(cacheable=true)
public static Decimal calculateNetValue(List<Decimal> amountValues){
Decimal totalValue = 0;
for (Decimal value : amountValues) {
if (value != null) {
totalValue += value;
}
}
return totalValue;
}
*/
    /**
* calculateNetImpact 
*
* return the Net Impact
* 
* @usage opportunityUnitSearch LWC
*
* @param Decimal netOfferValue, Decimal unitSellingPrice
* @return  Decimal of the Net Impact
* NOTE: SHOULD BE REMOVED
    
@AuraEnabled(cacheable=true)
public static Decimal calculateNetImpact(Decimal netOfferValue, Decimal unitSellingPrice){
Decimal totalNetImpact = 0;
totalNetImpact = netOfferValue / unitSellingPrice * 100;
totalNetImpact = totalNetImpact.setScale(2);
return totalNetImpact;
}
*/

    /**
* unitFurnishingValues 
*
* return SalesOrder__c level UnitFurnishing__c picklist values
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.UnitFurnishing__c picklist Values
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> unitFurnishingValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = SalesOrder__c.UnitFurnishing__c.getDescribe();
        map<string,string> blankVal=new map<string,string>();
        blankVal.put('label','--None--');
        blankVal.put('value','');
        picklistToReturn.add(blankVal);
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }

    /*
@AuraEnabled(cacheable=true)
public static list<String> getUnitFurnishingOptions(String projectName, String buildingName){
Map<String,ProjectUnitFurnishing__mdt> metaDataMap = ProjectUnitFurnishing__mdt.getAll();
List<String> picklistToReturn = new List<String>();
List<Project__c> project = [SELECT Name FROM Project__C WHERE Id =:projectName Limit 1];
List<BuildingSection__c> building = [SELECT Name FROM BuildingSection__c WHERE Id =:buildingName Limit 1 ];
String projectActualName = project[0].Name;
String buildingActualName = building[0].Name;
for(String key : metaDataMap.keySet()){
if(projectActualName == metaDataMap.get(key).Project__c && (buildingActualName == metaDataMap.get(key).BuildingName__c || metaDataMap.get(key).BuildingName__c=='All' )){
if(metaDataMap.get(key).Active__c == true){
picklistToReturn.add(metaDataMap.get(key).Type_Of_Furnishing__c);
}
}
}
return picklistToReturn;
}
*/
    /**
* unitFinishingValues 
*
* return SalesOrder__c level UnitFinishing__c picklist values
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.UnitFinishing__c picklist Values
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> unitFinishingValues() {
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = SalesOrder__c.UnitFinishing__c.getDescribe();
        map<string,string> blankVal=new map<string,string>();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* mortgageApplicableValues 
*
* return SalesOrder__c level MortgageApplicable__c picklist values
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.MortgageApplicable__c picklist Values
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> mortgageApplicableValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = SalesOrder__c.MortgageApplicable__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* mortgageBankValues 
*
* return SalesOrder__c level mortgageBank__c picklist values
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.mortgageBank__c picklist Values
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> mortgageBankValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = SalesOrder__c.mortgageBank__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getWinReasonPickList 
*
* return Opportunity level WinReason__c picklist values
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return  list<map<String,string>> Opportunity.WinReason__c picklist Values
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getWinReasonPickList(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Opportunity.WinReason__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* calculateMultiply 
*
* return multiplication of 2 decimals
* 
* @usage opportunityUnitSearch LWC
*
* @param firstValue Decimal
*        secondValue Decimal
* 
* @return  Decimal multiplication
* NOTE: SHOULD BE REMOVED
*
@AuraEnabled(cacheable=true)
public static Decimal calculateMultiply(Decimal firstValue, Decimal secondValue){
Decimal total = 0;
if (firstValue != null && secondValue != null ) {
total = firstValue * secondValue;
}
return total;
}
*/
    
    /**
* getAllProjects 
*
* return available projects
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return   list<map<String,string>>  list of select options 
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getAllProjects(){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        
        for(Project__c tempProject: ProjectService.getAllActiveProjects() ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
     /**
* getProjectCurrency
*
* return projecty currency
* 
* @usage opportunityUnitSearch LWC
*
* @param projectId
* @return  String
* 
*/
    @AuraEnabled(cacheable=true)
    public static String getProjectCurrency(String projectId){
        if(projectId != '' && projectId != null){
            return [SELECT Id, CurrencyISOCode FROM Project__c WHERE Id =:projectId][0].CurrencyISOCode;
        }else{
            return '';
        }
    }
    @AuraEnabled(cacheable=true)
    public static String getProjectCurrencyfromUnit(String recordId){
        Id recroddataId = recordId;
        String sObjName = recroddataId.getSObjectType().getDescribe().getName();
        if(sObjName == 'Unit__c'){
            
            return [SELECT Id, Project__r.CurrencyISOCode FROM Unit__c WHERE Id =:recordId][0].Project__r.CurrencyISOCode;
        }else{
            return '';
        }
    }
    
    /**
* getProjectToProjectBudget 
*
* return ProjectBudget__c information/Id for selected projects
* 
* @usage opportunityUnitSearch LWC
*
* @param projectId
* @return   Project__c  project record with ProjectBudget__c field
* 
*/
    @AuraEnabled(cacheable=true)
    public static Project__c getProjectToProjectBudget(string projectId){
        return [select id,ProjectBudget__c from Project__c where id = :projectId];
    }
    
    
    /**
* getAllBuildings 
*
* return available Buildings for given Project
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return   list<map<String,string>>  list of select options 
* 
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getAllBuildings(string projectId){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();//{new map<string,string>{'label' =>'All' , 'value' => ''}};
        
        for(BuildingSection__c  tempBuilding: BuildingSectionService.prepareBuildingsNames(projectId) ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempBuilding.Name);
            tempMap.put('value',tempBuilding.id);
            filtersToReturn.add(tempMap);
        }
        
        return filtersToReturn;
    }
    /*Added by Sanath H M
* As part of ASF-116
*/ 
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> signatureTypes(string recordId){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        List<SalesOrder__c> SalesOrderList = [SELECT
                                              Id,
                                              Unit__r.Project__r.DigitalSignatureApplied__c
                                              FROM SalesOrder__c
                                              WHERE Id=: recordId];
       /* List<Project__c> projectList = [SELECT
Id,
DirectDebitApplied__c
FROM
Project__c
WHERE Id =: projectId]; */
        
        if(!SalesOrderList.isEmpty()){
            if(SalesOrderList[0].Unit__r.Project__r.DigitalSignatureApplied__c){
                Schema.DescribeFieldResult fieldResult = SalesOrder__c.SignatureType__c.getDescribe();
                for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
                    map<string,string> tempMap=new map<string,string>();
                    tempMap.put('label',tempVal.getLabel());
                    tempMap.put('value',tempVal.getValue());
                    filtersToReturn.add(tempMap);
                } 
            }
        }
        
        return filtersToReturn;
    }    
    
    /**
* getUnitDetails
*
* return available Buildings for given Project
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return   list<map<String,string>>  list of select options 
* 
*/
    @AuraEnabled(cacheable=true)
    public static UnitWrapper getUnitDetails(ID buildingsId){ 
        UnitWrapper unitsToReturn;
        list<Unit__c> unitList = UnitService.getAllAvailableUnitsUnderBuilding(new set<ID>{buildingsId});
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
            finalListOfUnit.add(unt);
            }
        }
        unitsToReturn = new UnitWrapper(finalListOfUnit);            
       
        return unitsToReturn;
    }
    
    /**
* expiredReservation
*
* 
* This method is called to cancel the reservation process, The method is supoosed release unit, Cancel Sales Order and Opportunity
*
* @param lstSalesOrder - SalesOrders for which reservation is rejected
* @return   none
* 
*/    
    @InvocableMethod
    public static void expiredReservation(list<SalesOrder__c> lstSalesOrder){
    
        Set<Id> unitIds = new Set<Id>(); 
        Set<String> opportunityIds = new Set<String>(); 
        Set<String> salesOrderIds = new Set<String>(); 
    
    
        for(SalesOrder__c salesOrder : lstSalesOrder){
            unitIds.add(salesOrder.unit__c);
            opportunityIds.add(salesOrder.Opportunity__c);
            salesOrderIds.add(salesOrder.Id);
        }
       
        OpportunityService.cancelOpportunityReservation(opportunityIds);
        SalesOrderService.cancelSalesOrderReservation(salesOrderIds);
        UnitService.makeUnitsAvailable(unitIds);
        //UtilitiesWithoutSharing.makeUnitsAvailable(unitIds);
    }
        
    /**
* uploadFile
* 
* This method is used to upload file to give record ID
*
* @param base64 - Base 64 file content
*     filename - File name to be uploaded
*     recordId - record ID to attach file to
* @return   string returns content document link ID
* 
*/  
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cv == null || cdl == null) { return null; }
        return cdl.Id;
    }
        
    /**
* createContentVersion
* 
* Helper method for uploadFile, crete content version record
*
* @param base64 - Base 64 file content
*     filename - File name to be uploaded
* @return ContentVersion inserted contentVersion record
* 
*/  
    private static ContentVersion createContentVersion(String base64, String filename) {
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
          insert cv;
          
          return cv;
        } catch(DMLException e) {
          
          return null;
        }
    }
        
    /**
* createContentLink
* 
* Helper method for uploadFile, crete ContentDocumentLink  record
*
* @param contentVersionId - inserted contentVersion record Id
*     recordId - record ID to attach file to
* @return ContentDocumentLink inserted ContentDocumentLink record
* 
*/ 
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        

        if (contentVersionId == null || recordId == null) { return null; }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
            cdl.LinkedEntityId = recordId;
            // ShareType is either 'V', 'C', or 'I'
            // V = Viewer, C = Collaborator, I = Inferred
            cdl.ShareType = 'V';
            try {
                insert cdl;
               
                return cdl;
            } catch(DMLException e) {
                
                return null;
        }
    }
    
    /**
* lockUnits
* 
* Utility method to lock selected units
*
* @param unitIds - selected unit Ids
*     
* @return string Lock response, defualt should be Success
* 
*/ 
    @AuraEnabled(cacheable=false)
    public static string lockUnits(list<String> unitIds){
        string msg =Constants.SUCCESS_MESSAGE;
        list<Unit__c> unitsToLock = new list<Unit__c>();
        list<Unit__c> verifyUnits=[select id,AssignedToUser__c,Name,LockedBy__c,Status__c from unit__c where id in :unitIds];
        for(Unit__c unit : verifyUnits){
            if(unit.AssignedToUser__c != UserInfo.getUserId()){
                msg='Selected Unit is no longer available';
                break;
            }
        }
        list<Unit_Assignment__c> lstUnitAssignment = [SELECT Id, Unit__c,Status__c FROM Unit_Assignment__c WHERE Unit__c IN: unitIds AND Status__c = 'Pending approval'];
        //SSC-376 related changes: Get unit assignment for unit which in pending approval
        Map<Id,Unit_Assignment__c> mapUnitIdVsUnitAssignment = new Map<Id,Unit_Assignment__c>();
        for(Unit_Assignment__c unitass: [SELECT Id, Unit__c,Status__c FROM Unit_Assignment__c WHERE Unit__c IN: unitIds AND Status__c = 'Pending approval']){
            mapUnitIdVsUnitAssignment.put(unitass.Unit__c,unitass);
        }
        if(verifyUnits.isEmpty()){
            msg='Selected Unit is no longer available';
        }
        for(unit__c tempUnitRec : verifyUnits){
            // SSC-376 related changes: check if any pending approval unit assignment on selected units
            if((tempUnitRec.Status__c == Constants.UNIT_STATUS_AVAILABLE && !mapUnitIdVsUnitAssignment.containsKey(tempUnitRec.Id)) || (tempUnitRec.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && tempUnitRec.LockedBy__c == UserInfo.getUserId() ) ){
                unitsToLock.add(new Unit__c(id= tempUnitRec.Id));
            }else{
                msg='Selected Unit '+tempUnitRec.Name+' is no longer available';
                break;
            }
        }
        if(msg == Constants.SUCCESS_MESSAGE ){
            BookingUtility.lockUnit(unitsToLock,constants.RESERVATION_TIMMERNAME);
        }
        return msg;
    }
        
    /**
* performBudgetCheck
* 
* Utility method to perform budgect check for selected units/projects
*
* @param saleOfferInputParam - selected Units Wrapper
*     opportunityId - Opportunity Id
*     
* @return boolen represents budget availibiltiy
* 
*/     
    @AuraEnabled(cacheable=false)
    public static boolean performBudgetCheck(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId){
        list<ProjectBudget__c> budgetNotifications =  new list<ProjectBudget__c>();
        //iPad Changes: commented the below code by bashim : use the static variable  
        //map<id,SalesOfferUtility.SalesOfferDetails> reservationWrapper = generateSalesOffer(saleOfferInputParam,opportunityId);
        reservationWrapper = generateSalesOffer(saleOfferInputParam,opportunityId);
        Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper = new Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();
        Set<Id> projectBudgetIds = new Set<Id>();
        for(Id tempUnitKey : reservationWrapper.keySet()){
            for(SalesOfferUtility.PaymentPlanWrapper paymentPlans : reservationWrapper.get(tempUnitKey).applicablePaymentPlansCalculated){
                if(paymentPlans.isSelected){
                    if(reservationWrapper.get(tempUnitKey).unitRecord.ProjectBudget__c != null){
                        projectBudgetIds.add(reservationWrapper.get(tempUnitKey).unitRecord.ProjectBudget__c);
                        budgetNotifications.add(new ProjectBudget__c(id = reservationWrapper.get(tempUnitKey).unitRecord.ProjectBudget__c, NotifyDevelopment__c=true));
                    }
                    unitPaymentPlanWrapper.put(reservationWrapper.get(tempUnitKey).unitRecord ,paymentPlans);
                }
            }
        }
        Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = BudgetLinesService.checkAvailableProjectBudget(projectBudgetIds,unitPaymentPlanWrapper);
        if(projectSalesOrderMap==null){
            update budgetNotifications;
            return false;
        }
        for(ProjectBudgetWrapper wrapper : projectSalesOrderMap.values()){
            if(wrapper.isBudgetAvailable == false){
                //update budgetNotifications;
                ProjectBudgetService.updatProjectBudgetList(budgetNotifications);
                return false;
            }
        }
        return true;
    }
        
    /**
* convertReservation
* 
* This method is used by COnvertToBooking LWC quick action, This is used to convert the existing reservation SO to Booking SO
*
* @param recordID - SalesOrder Record
*     winReason - Win Loss reason for opportunity
*     
* @return map<string,string> success/Failur message
* 
*/  
    @AuraEnabled(cacheable=false)
    public static map<string,string> convertReservation(String recordID , string winReason){
    
        //Stop the Process when the Opporunty is not approved --> Buttons hould be hidden at page payout level
    
        map<string,string> valueToReturn = new map<string,string>();
        valueToReturn.put('message','success');
        list<SalesOrder__c> salesOrderList = [select id,Opportunity__c,Unit__c,RAcknowledgementReservationAmount__c,Account__c,(select id,InstallmentAmount__c,InstallmentDate__c from InstallmentLines__r where InstallmentNumber__c =1),(select id,Amount__c from Payments__r order by createdDate desc) from SalesOrder__c where id = :recordID];
        if(!salesOrderList.isEmpty()){
            //Update Sales Order
            salesOrderList[0].Status__c = constants.OPPO_UNIT_STATUS_PENDING; 
            salesOrderList[0].SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM; 
            salesOrderList[0].BookingDate__c = system.Today();
           // salesOrderList[0].SignatureType__c = signatureType != '' ? signatureType : System.label.PhysicalSignatureType;
            update salesOrderList[0];
            
            //Update Opportunity
             map<id,Opportunity> opportunityMap = OpportunityService.getOpportunityDetailsMapbyId(salesOrderList[0].Opportunity__c);
            if(opportunityMap.get(salesOrderList[0].Opportunity__c).StageName != Constants.STAGE_CLOSEDWON  ){
                update new Opportunity(id = salesOrderList[0].Opportunity__c, StageName =  Constants.STAGE_CLOSEDWON, CloseDate = system.today(), WinReason__c=winReason);
            }
            //Update Unit
            update new Unit__c(id= salesOrderList[0].Unit__c,Status__c= Constants.UNIT_STATUS_BOOKED,AllocationGroup__c =null,AssignedToUser__c = UserInfo.getUserId());

           
            // Check if we have the Recipet Ack record is present,
            // Then Create Recipet Allocation and link it with SO and Recipet Ack
            /*if( !salesOrderList[0].Payments__r.isEmpty() && !salesOrderList[0].InstallmentLines__r.isEmpty() ){
insert new ReceiptAllocation__c(Account__c=salesOrderList[0].Account__c,
AmountApplied__c=salesOrderList[0].Payments__r[0].Amount__c,
InstallmentLine__c=salesOrderList[0].InstallmentLines__r[0].Id,
ReceiptAcknowledgement__c = salesOrderList[0].Payments__r[0].id,
SalesOrder__c=salesOrderList[0].Id,
TypeOfInvoice__c=Constants.INVOICE_TYPE_INSTALLMENT);
}*/
        }
    
        return valueToReturn;
    }
    
    /**
* reserveUnit
* 
* This method is used to perform reservation or booking action based on action parameter
*
* @param saleOfferInputParam - Selected Units
*     opportunityId - Selected Opportunity record ID for Sales Order
*     winReason - win/loss reason for opportunity
*     action - Reserve/booking action
*     selectedEOI - Selected EOI record ID (used for booking)
*     
* @return map<string,string> success/Failur message
* 
*/ 
    @AuraEnabled(cacheable=false)
    public static map<string,string> reserveUnit(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, string action, string winReason,string selectedEOI){
      
        map<string,string> valueToReturn = new map<string,string>();
        PaymentPlan__c selectedPaymentPlan;
        String defaultCurrency = '';
        Map<String, Municipality_Fee_Details__mdt> mfdByCountryMap = new Map<String, Municipality_Fee_Details__mdt>();
        Id OpportunityResaleRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
        for(Municipality_Fee_Details__mdt mfd : Municipality_Fee_Details__mdt.getAll().values()){
            if(mfd.isActive__c){
                mfdByCountryMap.put(mfd.City__c, mfd);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try{   
            
            if(!performBudgetCheck(saleOfferInputParam,opportunityId)){
                valueToReturn.put('result','Budget check failed');
                    return valueToReturn;
            }
            set<String> applicableVoucher = new set<String>();
            // iPad Changes: commented the below line by bashim: already calculated reservationWrapper in budget call function
            //map<id,SalesOfferUtility.SalesOfferDetails> reservationWrapper = generateSalesOffer(saleOfferInputParam,opportunityId);
            map<ID,SalesOfferUtility.SaleOfferInputParam> unitToInputParam = new map<ID,SalesOfferUtility.SaleOfferInputParam>();
            
            
            
            
            
            map<Id,ProjectBudgetWrapper> projectSalesOrderMap = new map<Id,ProjectBudgetWrapper>();
            map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper = new map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();
            Set<Id> unitsProject = new Set<Id>(); 
            List<String> countryList = CountryList__mdt.getInstance('IncludedCountryList').Countries__c.split(';');
            for(SalesOfferUtility.SaleOfferInputParam tempIncomingParam : saleOfferInputParam ){
                unitToInputParam.put(tempIncomingParam.unitId,tempIncomingParam);
            }
            
            //Records to create
            map<id,Unit__c> unitsToReserve = new map<id,Unit__c>(); 
            map<id,SalesOrder__c> opportunityUnitsToCreate = new map<id,SalesOrder__c>();
            map<id,list<InstallmentLines__c>> installmentLines = new map<id,list<InstallmentLines__c>>();
            map<id,list<OpportunityOfferLine__c>> offerLines = new map<id,list<OpportunityOfferLine__c>>();
            map<id,ReceiptAcknowledgement__c> createPaymentLines = new map<id,ReceiptAcknowledgement__c>();
            map<id,List<CommissionLineItem__c>> createCommissionMap = new map<id,List<CommissionLineItem__c>>();
            map<ID,list<SalesOrderOtherCharges__c>> unitToOtherSalesOrderCharges = new  map<ID,list<SalesOrderOtherCharges__c>> ();
            Opportunity opportunityRecord = new Opportunity(id= opportunityId);
            map<string,CommissionLineItem__c> externalCommisionMap = new map<string,CommissionLineItem__c>();
            List<OpportunityOfferLine__c> offlineList= new List<OpportunityOfferLine__c>();
            //get Opportunity details
            Opportunity opportunityDetails = OpportunityService.getOpportunityDetailsbyId(opportunityId);
            //EOI Assignment 
            list<OpportunityEOI__c> EOIList = [select id,BuildingSectionName__c,ProjectName__c,(select id from Payments__r) from OpportunityEOI__c where id = :selectedEOI];
            list<ReceiptAcknowledgement__c> eoiRAtoReparent = new list<ReceiptAcknowledgement__c>();
            
            Map<Id, Id> unitProjectMap = new Map<Id, Id>();
            Set<String> CorporateIBANSet = new Set<String>();            
            if(!EOIList.isEmpty()){
                eoiRAtoReparent = EOIList[0].Payments__r;
            }
            //get unit details 
            for(Id tempUnitKey : reservationWrapper.keySet()){
               
                SalesOfferUtility.SalesOfferDetails tempOfferRecord = reservationWrapper.get(tempUnitKey);
                defaultCurrency = tempOfferRecord.unitRecord.Project__r.CurrencyISOCode;
                unitProjectMap.put(tempUnitKey, tempOfferRecord.unitRecord.Project__c);
                CorporateIBANSet.add( tempOfferRecord.unitRecord.Project__r.IBANNoCorporate__c);
                
                
                
                if(tempOfferRecord.unitRecord !=null && (tempOfferRecord.unitRecord.status__c == Constants.UNIT_STATUS_AVAILABLE || tempOfferRecord.unitRecord.status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS)){
                    SalesOrder__c tempOpportunityUnit = new SalesOrder__c();
                    tempOpportunityUnit.CurrencyISOCode = defaultCurrency;
                    //opportunity Record amount
                    opportunityRecord.Amount= tempOfferRecord.totalOfAllUnitNetSellingPrice!=null? tempOfferRecord.totalOfAllUnitNetSellingPrice : 0;
    
                    tempOpportunityUnit.Account__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.AccountId : null;
                    tempOpportunityUnit.Contact__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Contact__c : null;
                    tempOpportunityUnit.CustomerType__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Account.CustomerType__c : null;
                    tempOpportunityUnit.CustomerSubType__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Account.CustomerSubType__c : null;
                    tempOpportunityUnit.Email__c = (tempOfferRecord.opportunityRecord !=null && tempOfferRecord.opportunityRecord.Contact__c!=null) ? tempOfferRecord.opportunityRecord.Contact__r.Email : null;
                    tempOpportunityUnit.CorporateWealthName__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Account.CorporateWealthName__c : null;
                    
                   /* // Added By Moh Sarfaraj for Sub Account Manager
                    if(tempOfferRecord?.opportunityRecord != null && 
                       String.isNotBlank(tempOfferRecord?.opportunityRecord?.BrokerAgencyAccount__c) && 
                       String.isNotBlank(tempOfferRecord?.opportunityRecord?.BrokerAgencyAccount__r?.SubAccountManager__c)){ 

                        tempOpportunityUnit.BrokerSubAccountManager__c = tempOfferRecord?.opportunityRecord?.BrokerAgencyAccount__r?.SubAccountManager__c;
                    }*/

                    //tempOpportunityUnit.EmployeeName__c = ; NA ** comes from oppotunity at later stage
                    //tempOpportunityUnit.HoldFlag__c = true;
                    tempOpportunityUnit.MobileNumber__c = (tempOfferRecord.opportunityRecord !=null && tempOfferRecord.opportunityRecord.Contact__c!=null) ? tempOfferRecord.opportunityRecord.Contact__r.MobilePhone : null;
                    if(unitToInputParam.get(tempUnitKey).multiPurposeAmountApplicable!=null && unitToInputParam.get(tempUnitKey).multiPurposeAmountApplicable){
                        if(tempOfferRecord.unitDesignRecordId!=null  ){
                            tempOpportunityUnit.DesignPremiumAmount__c =tempOfferRecord.unitDesignRecord.PremiumAmount__c  ; 
                        }else if(tempOfferRecord.hasUnitDesign ==true || (Label.LagoonsProjectName).contains(tempOfferRecord.unitRecord.Project__r.Name)){
                            tempOpportunityUnit.DesignPremiumAmount__c =tempOfferRecord.unitRecord.MultiPurposeAmount__c  ;
                        }else{
                            tempOpportunityUnit.MultiPurposeAmount__c =tempOfferRecord.unitRecord.MultiPurposeAmount__c  ;
                            tempOpportunityUnit.MultiPurposeRoom__c = true;  
                        }
                    }else{
                        tempOpportunityUnit.MultiPurposeRoom__c = false; 
                    }
                    tempOpportunityUnit.UnitDesign__c = tempOfferRecord.unitDesignRecordId;
                    tempOpportunityUnit.DesignType__c = tempOfferRecord.hasUnitDesign ? (tempOfferRecord.unitDesignRecordId!=null ?tempOfferRecord.unitDesignRecord.DesignType__c : tempOfferRecord.unitDesignRecordName):'';
                     //Commented by Arvind to allow the Digital Type for all the Country
                    //tempOpportunityUnit.SignatureType__c = tempOfferRecord.unitRecord.Project__r.DigitalSignatureApplied__c == false ? 'Physical Signature' : (tempOfferRecord.opportunityRecord.Account.ResidentStatus__pc == 'Resident' ?  'Digital Signature' : (countryList.contains(tempOfferRecord.opportunityRecord.Account.Nationality__pc) ? 'Digital Signature': 'Physical Signature' ) );
                    tempOpportunityUnit.SignatureType__c = (tempOfferRecord.unitRecord.Project__r.DigitalSignatureApplied__c == false || tempOfferRecord.opportunityRecord.Account.RecordType.Name == 'Organization Account') ? 'Physical Signature' : 'Digital Signature';// added by Noor ASF-3700
                    tempOpportunityUnit.FirstMethodofContact__c = tempOfferRecord.opportunityRecord.FirstMethodofContact__c != null?tempOfferRecord.opportunityRecord.FirstMethodofContact__c:null;
                    tempOpportunityUnit.FirstEnquiryCategory__c = tempOfferRecord.opportunityRecord.FirstEnquiryCategory__c != null?tempOfferRecord.opportunityRecord.FirstEnquiryCategory__c:null;
                    tempOpportunityUnit.FirstEnquiryTrigger__c = tempOfferRecord.opportunityRecord.FirstEnquiryTrigger__c != null?tempOfferRecord.opportunityRecord.FirstEnquiryTrigger__c:null;
                    //tempOpportunityUnit.HoldFlag__c = true;
                    
                    /*if(tempOfferRecord.unitDesignRecordId!=null){   
tempOpportunityUnit.DesignPremiumAmount__c =tempOfferRecord.unitDesignRecord.PremiumAmount__c  ; 
}else{
tempOpportunityUnit.MultiPurposeAmount__c =tempOfferRecord.unitRecord.MultiPurposeAmount__c  ; 
tempOpportunityUnit.MultiPurposeRoom__c = unitToInputParam.get(tempUnitKey).multiPurposeAmountApplicable!=null?unitToInputParam.get(tempUnitKey).multiPurposeAmountApplicable:false;
}*/
                    if(tempOfferRecord.opportunityRecord.Account.ResidentStatus__pc != null && tempOfferRecord.unitRecord.Project__r.DirectDebitApplied__c ){
                        tempOpportunityUnit.Payment_Type__c = tempOfferRecord.opportunityRecord.Account.ResidentStatus__pc == 'Resident' ? 'Direct Debit' : 'Wire Transfer';
                    }else{
                        tempOpportunityUnit.Payment_Type__c = tempOfferRecord.opportunityRecord.Account.ResidentStatus__pc == 'Resident' ? 'Cheque' : 'Wire Transfer';
                    }
                    tempOpportunityUnit.Offer__c = tempOfferRecord.offerId; 
                    tempOpportunityUnit.Opportunity__c = tempOfferRecord.opportunityId;
                    tempOpportunityUnit.OwnerManger__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.Owner.ManagerId : null;
                    tempOpportunityUnit.ReferralType__c = opportunityDetails.ReferralType__c;
                    tempOpportunityUnit.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                    tempOpportunityUnit.LockExpiryDateTime__c = tempOfferRecord.unitRecord.LockExpiryTime__c; // Added by Tajinkumar - LAC-1869
                    tempOpportunityUnit.ProjectBudget__c =tempOfferRecord.unitRecord.ProjectBudget__c;
                    if(unitToInputParam.get(tempUnitKey).unitFinishes != null && unitToInputParam.get(tempUnitKey).unitFinishes != ''){
                        tempOpportunityUnit.UnitFinishing__c = unitToInputParam.get(tempUnitKey).unitFinishes;
                    }
                    tempOpportunityUnit.PODChoosen__c = tempOfferRecord.PodiumSelection;
                    tempOpportunityUnit.PODAmount__c =  tempOfferRecord.PodiumAmount;
                     // swimming pool related changes for yas riva
                    tempOpportunityUnit.Swimming_Pool_Price__c = tempOfferRecord.swimmingPoolSelection=='Yes'?tempOfferRecord.swimmingPoolAmount:0;
                    tempOpportunityUnit.Etihad_Guest_Miles__c = 0 ;
                    
                    //tempOpportunityUnit.Etihad_Guest_Miles__c = 
                    
                    if(tempOfferRecord.unitRecord.Eligible_for_Etihad_Miles__c) { 
                        tempOpportunityUnit.Etihad_Guest_Miles__c = tempOfferRecord.unitRecord.Etihad_Miles__c;
                    }

                    tempOpportunityUnit.UnitFurnishing__c = unitToInputParam.get(tempUnitKey).unitFurnishing;
                    tempOpportunityUnit.Unit__c = tempUnitKey;
                    tempOpportunityUnit.OffPlanSalesOrder__c = tempOfferRecord.unitRecord.OffPlanProperty__c;
                    tempOpportunityUnit.mortgageApplicable__c = unitToInputParam.get(tempUnitKey).mortgageApplicable!=null && unitToInputParam.get(tempUnitKey).mortgageApplicable ? Constants.YES : Constants.NO ;
                    tempOpportunityUnit.mortgageBank__c = unitToInputParam.get(tempUnitKey).mortgageBank;
                    //EOI Assignment
                    if(!EOIList.isEMpty() && EOIList[0].BuildingSectionName__c==tempOfferRecord.unitRecord.BuildingSectionName__c && EOIList[0].ProjectName__c ==tempOfferRecord.unitRecord.Project__c ){
                        tempOpportunityUnit.OpportunityEOI__c = EOIList[0].Id;
                        EOIList.remove(0);
                    }
                    List<CommissionLineItem__c> commissionLineList = new List<CommissionLineItem__c>();
                    //tempOpportunityUnit.UnitFinishing__c = ;
                    //Iterate overPyment and populate content from selected payment
                    installmentLines.put(tempUnitKey, new list<InstallmentLines__c>() ); 
                    for(SalesOfferUtility.PaymentPlanWrapper tempPaymentPlan : tempOfferRecord.applicablePaymentPlansCalculated){
                        //get data for selected payment
                         
                        if(tempPaymentPlan.isSelected){
                            tempOpportunityUnit.PaymentPlan__c = tempPaymentPlan.paymentPlanDetails.Id;
                            tempOpportunityUnit.SellingPrice__c = tempOfferRecord.unitRecord.SellingPrice__c;
                            tempOpportunityUnit.Discount__c = tempPaymentPlan.discountAmount;
                            tempOpportunityUnit.AmountPayable__c= tempPaymentPlan.netSalesPrice.setScale(2);
                            tempOpportunityUnit.TaxableAmount__c = (tempOfferRecord.unitRecord.BuildingSectionName__r.TaxPercentage__c !=null ) ? tempPaymentPlan.netSalesPrice * tempOfferRecord.unitRecord.BuildingSectionName__r.TaxPercentage__c : 0;
                            tempOpportunityUnit.NetAmount__c = (tempOpportunityUnit.TaxableAmount__c+tempOpportunityUnit.AmountPayable__c).setScale(2);
                            tempOpportunityUnit.NetAmountInWords__c = Utilities.amountInWords(tempOpportunityUnit.NetAmount__c,'Dirham','Fils');
                            tempOpportunityUnit.BulkDiscount__c = tempPaymentPlan.bulkDiscountAmount;
                            tempOpportunityUnit.CorporateDiscount__c = tempPaymentPlan.corporateDiscountAmount;
                            tempOpportunityUnit.PaymentPlanDiscount__c = tempPaymentPlan.paymentPlanDiscountAmount;//tempPaymentPlan.paymentPlanDetails.PaymentPlanDiscount__c;
                            tempOpportunityUnit.PremiumAmount__c = tempPaymentPlan.premiumAmmount;
                            tempOpportunityUnit.WealthDiscount__c = tempPaymentPlan.wealthDiscountAmount;
    
                            tempOpportunityUnit.OtherRebateAmount__c = tempPaymentPlan.rebateAmount!=null?tempPaymentPlan.rebateAmount.setScale(2):tempPaymentPlan.rebateAmount;
                            tempOpportunityUnit.ADMFeeWaivedAmount__c = tempPaymentPlan.admFeeWaiverAmount!=null?tempPaymentPlan.admFeeWaiverAmount.setScale(2):tempPaymentPlan.admFeeWaiverAmount;
                            tempOpportunityUnit.OtherSalesSupportAmount__c = tempPaymentPlan.otherSalesSupportAmount!=null?tempPaymentPlan.otherSalesSupportAmount.setScale(2):tempPaymentPlan.otherSalesSupportAmount;
                            tempOpportunityUnit.ServiceChargeWaivedAmount__c = tempPaymentPlan.serviceChargeAmount!=null?tempPaymentPlan.serviceChargeAmount.setScale(2):tempPaymentPlan.serviceChargeAmount;
                            tempOpportunityUnit.ServiceChargeWaivedYears__c = tempPaymentPlan.serviceChargeWaivedYears;
                            tempOpportunityUnit.PMFeesWaivedAmount__c = tempPaymentPlan.pmWavedFee;
                            tempOpportunityUnit.HomeMaintenanceWaivedAmount__c = tempPaymentPlan.homeMaintenanceWaiverFee!=null?tempPaymentPlan.homeMaintenanceWaiverFee.setScale(2):tempPaymentPlan.homeMaintenanceWaiverFee;
                            tempOpportunityUnit.ExternalCommissionAmount__c = tempPaymentPlan.externalComissionAmount!=null?tempPaymentPlan.externalComissionAmount.setScale(2):tempPaymentPlan.externalComissionAmount;
                            
                            tempOpportunityUnit.SubsidyAmount__c = tempPaymentPlan.mortgageSubsidy!=null?tempPaymentPlan.mortgageSubsidy.setScale(2):tempPaymentPlan.mortgageSubsidy;
                            tempOpportunityUnit.DARNAAmount__c = tempPaymentPlan.darnaAmount!=null?tempPaymentPlan.darnaAmount.setScale(2):tempPaymentPlan.darnaAmount;
                            tempOpportunityUnit.InternalCommissionAmount__c = tempPaymentPlan.internalComissionAmount!=null?tempPaymentPlan.internalComissionAmount.setScale(2):tempPaymentPlan.internalComissionAmount;
                            unitsProject.add(tempOfferRecord.unitRecord.Project__c);
                            unitPaymentPlanWrapper.put(tempOfferRecord.unitRecord , tempPaymentPlan);
                            
                            String projectCity = tempOfferRecord.unitRecord.Project__r.City__c;
                            Decimal fee_percentage = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Fee_perc__c : 0.00;
                            String typeOfCharge = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).MasterLabel : '';
                            
                            Decimal adminFeeToBeCharged = 0.0;
                            adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
                            

                            //Mahidhar - Start
                            //Discription : Here we are calculating Service Fee and VAT charges based on Project City as part of ASF-3618
                            Decimal serviceFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Aldar_Service_Fee__c : 0.00;
                            Decimal adminFeeVATToBeCharged = adminFeeToBeCharged > 0 ? (adminFeeToBeCharged * (mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_ChargeAldar_Service_Fee_VAT__c : 0.00) / 100) : 0.00;
                            Decimal serviceFeeVATToBeCharged = serviceFeeToBeCharged > 0 ? (serviceFeeToBeCharged * (mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_ChargeAldar_Service_Fee_VAT__c : 0.00) / 100) : 0.00;
                            //Mahidhar- End
                            /*
// New ADM fee changes
// ASF-3400 Start
if (projectCity == 'Abu Dhabi') {
if(tempOfferRecord.unitRecord.OffPlanProperty__c)
adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
else
adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Ready_Projects_Fee__c : 0.00;
}else{
adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
}
*/
                            // ASF-3400 End
                           
    
                            //Populate Other Sales Order Charges
                            //Currently Only populating ADM Charges
                            //Decimal ADMToBeCharged =  (tempPaymentPlan.netSalesPrice * 0.02).setScale(2);
                            Decimal ADMToBeCharged =  (tempPaymentPlan.netSalesPrice * fee_percentage/100).setScale(2);
                            //Decimal ADMAdminFeetoBeCharged =  decimal.valueOf(Label.ADMAdminFee);
                            Decimal ADMAdminFeetoBeCharged =  adminFeeToBeCharged;
                            tempOpportunityUnit.ADMFeeAmount__c = ADMToBeCharged;
                            
                            ADMToBeCharged = (ADMToBeCharged - tempOpportunityUnit.ADMFeeWaivedAmount__c).setScale(2);
                           
                            list<SalesOrderOtherCharges__c> lstSOOtherCharges =  new list<SalesOrderOtherCharges__c>();

                            
                            if(ADMToBeCharged > 0 && tempOfferRecord.unitRecord.Project__r.ExcludeFromADM__c ==false ){
                                //unitToOtherSalesOrderCharges.put(tempUnitKey, new list<SalesOrderOtherCharges__c> {new SalesOrderOtherCharges__c(Amount__c = ADMToBeCharged.setScale(2),TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c)} );
                                lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c =  (ADMToBeCharged.setScale(2)+ADMAdminFeetoBeCharged.setScale(2)+serviceFeeToBeCharged.setScale(2)+adminFeeVATToBeCharged.setScale(2)+serviceFeeVATToBeCharged.setScale(2)) ,TypeOfCharge__c = typeOfCharge, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c, ADMAdminFeeAmount__c=ADMAdminFeetoBeCharged.setScale(2),ADMAdminFeeVAT__c= adminFeeVATToBeCharged.setScale(2),AldarServiceFee__c=serviceFeeToBeCharged.setScale(2),AldarServiceFeeVAT__c= serviceFeeVATToBeCharged.setScale(2),CurrencyISOCode = defaultCurrency ));
                            }else if(ADMToBeCharged == 0 && tempOfferRecord.unitRecord.Project__r.ExcludeFromADM__c ==false && ADMAdminFeetoBeCharged>0){
                                 lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c =  (ADMAdminFeetoBeCharged.setScale(2)+serviceFeeToBeCharged.setScale(2)+adminFeeVATToBeCharged.setScale(2)+serviceFeeVATToBeCharged.setScale(2)) ,TypeOfCharge__c = typeOfCharge, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c, ADMAdminFeeAmount__c=ADMAdminFeetoBeCharged.setScale(2), ADMAdminFeeVAT__c= adminFeeVATToBeCharged.setScale(2) ,AldarServiceFee__c=serviceFeeToBeCharged.setScale(2),AldarServiceFeeVAT__c= serviceFeeVATToBeCharged.setScale(2) ,CurrencyISOCode = defaultCurrency));
  
                            }
                            
                            if(tempOfferRecord.unitRecord.Project__r.ExcludeFromADM__c ==true){
                                tempOpportunityUnit.ADMFeeAmount__c = null;
                                tempOpportunityUnit.ADMFeeWaivedAmount__c =null;
                            }

                            //ADM Admin Fee of 450 AED as a new salesOrder other Charges
                            
                            if(ADMAdminFeetoBeCharged>0){
                             //   lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c = ADMAdminFeetoBeCharged.setScale(2),TypeOfCharge__c = Constants.BUDGET_LINE_ADMADMINFEE, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c));
                            }
                            if(!lstSOOtherCharges.isEmpty()){
                                unitToOtherSalesOrderCharges.put(tempUnitKey,lstSOOtherCharges);
                            }

                            
                            // ASF-3354 No commission lines for customer type/subtype Aldar Staff
                            if(tempOfferRecord.opportunityRecord.Account.VIPClass__c != 'Aldar Staff' && (tempOfferRecord.opportunityRecord.Account.CustomerSubType__c !='Aldar Staff' && tempOfferRecord.opportunityRecord.Account.CustomerType__c !='Aldar Staff')){
                            //Split based on Staff and Sales Manager create 2 records
                            if (tempPaymentPlan.internalStaffComissionAmount != null && tempPaymentPlan.internalStaffComissionAmount != 0) {
                                CommissionLineItem__c commissionLineRecord = new CommissionLineItem__c();
                                commissionLineRecord.CommissionAmount__c = tempOfferRecord.opportunityRecord.ReferredBy__c != null ? (tempPaymentPlan.internalStaffComissionAmount.setScale(2)*0.5) : tempPaymentPlan.internalStaffComissionAmount.setScale(2);
                                commissionLineRecord.CommissionPercentage__c = 100;// tempPaymentPlan.internalStaffComissionAmount / tempOpportunityUnit.NetAmount__c;
                                commissionLineRecord.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
                                commissionLineRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                commissionLineRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                commissionLineRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                                commissionLineRecord.CurrencyISOCode = defaultCurrency;
                                commissionLineList.add(commissionLineRecord);
                                
                                
                                
                                 if(tempOfferRecord.opportunityRecord.ReferredBy__c != null && tempOfferRecord.opportunityRecord.RecordTypeId != OpportunityResaleRecordTypeId){
                                    CommissionLineItem__c interDepartmentcommissionLineRecord = new CommissionLineItem__c();
                                    interDepartmentcommissionLineRecord.CommissionAmount__c = tempPaymentPlan.internalStaffComissionAmount.setScale(2)*0.5;
                                    interDepartmentcommissionLineRecord.CommissionPercentage__c = 100;
                                    interDepartmentcommissionLineRecord.CommissionType__c = 'Inter Dept Referral';
                                    interDepartmentcommissionLineRecord.SalesManager__c = tempOfferRecord.opportunityRecord.ReferredBy__c;
                                    interDepartmentcommissionLineRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                    interDepartmentcommissionLineRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                    interDepartmentcommissionLineRecord.CurrencyISOCode = defaultCurrency;
                                    commissionLineList.add(interDepartmentcommissionLineRecord);
                                }
                                
                                if(tempOfferRecord.opportunityRecord.EmployeeId__c != null && tempOfferRecord.opportunityRecord.EmployeeEmail__c != null){
                                    Decimal incentiveAmount = 0;
                                    if(tempOpportunityUnit.NetAmount__c <= 1000000 ){
                                        incentiveAmount = 2500;
                                    }else{
                                        incentiveAmount = 5000;  
                                    }
                                    CommissionLineItem__c staffcommissionLineRecord = new CommissionLineItem__c();
                                    staffcommissionLineRecord.CommissionType__c = 'Staff Incentive';
                                    //staffcommissionLineRecord.SalesOrder__c = so.Id;
                                    staffcommissionLineRecord.EmployeeEmail__c = tempOfferRecord.opportunityRecord.EmployeeEmail__c;
                                    staffcommissionLineRecord.EmployeeId__c = tempOfferRecord.opportunityRecord.EmployeeId__c;
                                    staffcommissionLineRecord.CommissionPercentage__c = 0;
                                    staffcommissionLineRecord.CommissionAmount__c = incentiveAmount;
                                    staffcommissionLineRecord.TotalPayableCommission__c = incentiveAmount;
                                    staffcommissionLineRecord.CurrencyISOCode = defaultCurrency;
                                    commissionLineList.add(staffcommissionLineRecord);
                                }
                            }
                            }
                            // ASF-3354 No commission lines for customer type/subtype Aldar Staff
                            if (tempPaymentPlan.internalReferralComissionAmount != null && tempPaymentPlan.internalReferralComissionAmount != 0 && (tempOfferRecord.opportunityRecord.Account.CustomerSubType__c !='Aldar Staff' && tempOfferRecord.opportunityRecord.Account.CustomerType__c !='Aldar Staff')) {
                                CommissionLineItem__c commissionLineRecord = new CommissionLineItem__c();
                                commissionLineRecord.CommissionAmount__c = tempPaymentPlan.internalReferralComissionAmount!=null?tempPaymentPlan.internalReferralComissionAmount.setScale(2):tempPaymentPlan.internalReferralComissionAmount;
                                commissionLineRecord.CommissionPercentage__c = 100;//tempPaymentPlan.internalReferralComissionAmount / tempOpportunityUnit.NetAmount__c;
                                commissionLineRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                commissionLineRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                commissionLineRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;    
                                commissionLineRecord.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
                                commissionLineRecord.CurrencyISOCode = defaultCurrency;
                                commissionLineList.add(commissionLineRecord);
                            }
    
                            //Populate Opportunity Instalment Lines
                            for(SalesOfferUtility.PaymentInstallmentWrapper tempInstallmentLine : tempPaymentPlan.installmentDetails){
                                installmentLines.get(tempUnitKey).add(new InstallmentLines__c( 
                                    BrokerPayoutPercentage__c= tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c,
                                    Description__c= tempInstallmentLine.installmentRecord.Description__c,
                                    InstallmentNumber__c = tempInstallmentLine.installmentRecord.InstallmentNumber__c,
                                    InstallmentPercentage__c= tempInstallmentLine.installmentRecord.InstallmentPercentage__c,
                                    InstallmentDate__c= tempInstallmentLine.installmentRecord.InstallmentDate__c, 
                                    InstallmentAmount__c= tempInstallmentLine.totalValue!=null?tempInstallmentLine.totalValue.setScale(2):tempInstallmentLine.totalValue,
                                    //Arvind Chnaged Dhirams  to Dirhams
                                    InstallmentAmountintheWords__c = Utilities.amountInWords( (tempInstallmentLine.totalValue!=null?tempInstallmentLine.totalValue.setScale(2):tempInstallmentLine.totalValue),'Dirhams','Fils'),
                                    PaymentInstallments__c= tempInstallmentLine.installmentRecord.Id,
                                    PaymentPlan__c= tempInstallmentLine.installmentRecord.PaymentPlan__c,
                                    CurrencyISOCode = defaultCurrency
                                )); 
    
                                //Create Commission
                                //split based on the payout 
                                // ASF-3354 No commission lines for customer type/subtype Aldar Staff
                                if (tempOpportunityUnit.ExternalCommissionAmount__c != null && tempOpportunityUnit.ExternalCommissionAmount__c != 0 && tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c!=null && tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c!=0 && (tempOfferRecord.opportunityRecord.Account.CustomerSubType__c !='Aldar Staff' && tempOfferRecord.opportunityRecord.Account.CustomerType__c !='Aldar Staff')) {
                                    CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                                    commissionLineExtenalRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                    commissionLineExtenalRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                    commissionLineExtenalRecord.CommissionAmount__c = (tempOpportunityUnit.ExternalCommissionAmount__c * (tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c/100)).setScale(2);
                                    commissionLineExtenalRecord.CommissionPercentage__c =  tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c;
                                    commissionLineExtenalRecord.PercentageWRTNetPrice__c =((commissionLineExtenalRecord.CommissionAmount__c/tempOpportunityUnit.NetAmount__c)*100).setScale(2);  //tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c;
                                    commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                                    commissionLineExtenalRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                                    commissionLineExtenalRecord.ExternalCommissionAmountBasis__c = tempPaymentPlan.externalComissionAmountBasis;
                                    commissionLineExtenalRecord.CurrencyISOCode = defaultCurrency;
                                    //commissionLineExtenalRecord.PaymentDueDate__c = tempInstallmentLine.installmentRecord.InstallmentDate__c;
                                    externalCommisionMap.put(''+tempUnitKey + tempInstallmentLine.installmentRecord.InstallmentNumber__c , commissionLineExtenalRecord);
                                }
                                //Selected Payment Plan to create Opportunity OfferLine
                                selectedPaymentPlan = tempPaymentPlan.paymentPlanDetails;
    
                            }
                        }
                    }                    
                    offerLines.put(tempUnitKey , new list<OpportunityOfferLine__c>());
                    //Payment Plan OfferLines -ASF-682
                    if(selectedPaymentPlan!=null){
                        if(selectedPaymentPlan.RebatePercentage__c != null && selectedPaymentPlan.RebatePercentage__c > 0 && offerLines.containsKey(tempUnitKey) && offerLines.get(tempUnitKey) != null){
                            offerLines.get(tempUnitKey)
                                .add(new OpportunityOfferLine__c
                                     (Name = selectedPaymentPlan.Name+'-Rebate',                                             
                                      PaymentPlan__c = selectedPaymentPlan.Id,
                                      OfferValue__c = selectedPaymentPlan.RebatePercentage__c,
                                      PaymentPlanPromoType__c = System.Label.PaymentPlanRebate));
                        }
                        if(selectedPaymentPlan.PaymentPlanDiscount__c != null && selectedPaymentPlan.PaymentPlanDiscount__c > 0 && offerLines.containsKey(tempUnitKey) && offerLines.get(tempUnitKey) != null){
                            offerLines.get(tempUnitKey)
                                .add(new OpportunityOfferLine__c
                                     (Name = selectedPaymentPlan.Name+'-Discount',
                                      PaymentPlan__c = selectedPaymentPlan.Id,
                                      OfferValue__c = selectedPaymentPlan.PaymentPlanDiscount__c,
                                      PaymentPlanPromoType__c = System.Label.PaymentPlanDiscount));
                        }
                    }
                    //Addedd BY Chirag
                    
                    List<SalesOfferUtility.UnitAddonWrapperdata> unitAddonMap = new List<SalesOfferUtility.UnitAddonWrapperdata>();
                    if(unitToInputParam.get(tempUnitKey).UnitAddonList != null){
                        unitAddonMap = unitToInputParam.get(tempUnitKey).UnitAddonList;
                    }
                    
                    for(SalesOfferUtility.UnitAddonWrapperdata str :unitAddonMap){
                        OpportunityOfferLine__c off = new OpportunityOfferLine__c();
                        off.Name =str.key;
                        off.Unit_AddOn__c =str.value;
                        offerLines.get(tempUnitKey).add(off);
                    }
                    //Offer lines
                    for(OfferLines__c tempOfferLine : tempOfferRecord.applicableOfferLinesCalculated){
                        if(tempOfferLine.OfferType__c.equalsIgnoreCase(Constants.OFFER_TYPE_VOUCHER) && tempOfferLine.Bulk__c){
                            if(applicableVoucher.contains(tempOfferLine.Id)){continue;}
                            applicableVoucher.add(tempOfferLine.Id);
                        }
                        offerLines.get(tempUnitKey).add(new OpportunityOfferLine__c(name= tempOfferLine.Name,
                                                                                    OfferLine__c = tempOfferLine.Id,
                                                                                    OfferValue__c = tempOfferLine.OfferValue__c));
                    }
                    
                    
    
                    createCommissionMap.put(tempUnitKey, commissionLineList);
                    //Populate SO Details based on Action
                    if(action=='RESERVE'){
                        if(opportunityDetails.isDigitalSales__c == true){
                            tempOpportunityUnit.Is_Digital_Sales__c = true;
                        }
                        tempOpportunityUnit.Status__c = constants.STATUS_RESERVATION_IN_PROGRESS; //constants.STATUS_RESERVED;
                        tempOpportunityUnit.SubStatus__c= constants.STATUS_APPROVAL_PENDING;
                        tempOpportunityUnit.ReceiptAcknowledgementPaymentMethod__c = unitToInputParam.get(tempUnitKey).paymentMethod;
                        tempOpportunityUnit.RAcknowledgementReservationAmount__c  =  unitToInputParam.get(tempUnitKey).amount;
                        //Arvind Chnaged Dhirams  to Dirhams
                        if(unitToInputParam.get(tempUnitKey).amount != null){
                            tempOpportunityUnit.ReservationAmountinwords__c = Utilities.amountInWords(unitToInputParam.get(tempUnitKey).amount ,'Dirhams','Fils');
                        }
                        tempOpportunityUnit.ReservationAmountType__c = unitToInputParam.get(tempUnitKey).amountType;
                        tempOpportunityUnit.ReservationEnddate__c = system.Today().addDays(5); 
                        tempOpportunityUnit.ReservationStartDate__c = system.Today();
                    
                    }else if(action=='BOOKING'){
                        tempOpportunityUnit.Status__c = constants.OPPO_UNIT_STATUS_PENDING; 

                        tempOpportunityUnit.SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM; 
                        tempOpportunityUnit.BookingDate__c = system.Today();
                    }
                    
                    
                    //populate unit details based on Action
                    Unit__c unitToUpdate = new Unit__c(id=tempUnitKey );
                    if(action=='RESERVE'){
                        unitToUpdate.Status__c=  Constants.STATUS_RESERVED;
                    }else if(action=='BOOKING'){
                        unitToUpdate.Status__c=  Constants.UNIT_STATUS_BOOKED;
                        unitToUpdate.AllocationGroup__c =null;
                        unitToUpdate.AssignedToUser__c = UserInfo.getUserId();
                        //
                        opportunityRecord.StageName =  Constants.STAGE_CLOSEDWON;
                        opportunityRecord.CloseDate = system.today();
                        opportunityRecord.WinReason__c=winReason;
                    }
    
                    // Add Unit
                    unitsToReserve.put(tempUnitKey,unitToUpdate);
                    //Add SO
                    opportunityUnitsToCreate.put(tempUnitKey, tempOpportunityUnit);
                    
                }else{
                    valueToReturn.put('result','Unit not available for '+action);
                    return valueToReturn;
                }
    
            }
            
            
    
            //projectSalesOrderMap = BudgetLinesService.checkAvailableProjectBudget(unitsProject,unitPaymentPlanWrapper);
    
    
            
            //Create Opportunity Unit
            if(!opportunityUnitsToCreate.isEmpty()){
                
                insert opportunityUnitsToCreate.values();
                /*if (opportunityDetails.ServiceRequest__c != null) {
HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
serviceRequest.Id = opportunityDetails.ServiceRequest__c;
serviceRequest.SwappedOrder__c = opportunityUnitsToCreate.values()[0].id;
update serviceRequest;
}*///Commented by Akash
            }
            //Reparent EOI records
            /*if(!eoiRAtoReparent.isEmpty()  ){
for(ReceiptAcknowledgement__c ra : eoiRAtoReparent){
ra.SalesOrder__c = opportunityUnitsToCreate.values()[0].id;
}
update eoiRAtoReparent;
}*///Commented by Akash
            //Update Unit
            if(!unitsToReserve.isEmpty()){
                for(id tempUnitKey : unitsToReserve.keySet()){
                    unitsToReserve.get(tempUnitKey).RelatedSalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                }
                update unitsToReserve.values();
            }
            //Create Opportunity Unit Installments
            if(!installmentLines.isEmpty()){
                list<InstallmentLines__c> finalListToInsert = new list<InstallmentLines__c>();
                map<ID,ID> salesOrderToUnitMap = new map<Id,Id>();
                for(id tempUnitKey : installmentLines.keySet()){
                    for(InstallmentLines__c tempInstallmentRecord : installmentLines.get(tempUnitKey)){
                        tempInstallmentRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        salesOrderToUnitMap.put(opportunityUnitsToCreate.get(tempUnitKey).Id , tempUnitKey);
                        finalListToInsert.add(tempInstallmentRecord);
                    }
                }
                insert finalListToInsert;
                //Populate external commission
                for(InstallmentLines__c tempLineItem : finalListToInsert){
                    if(externalCommisionMap.containsKey(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c)){
                        externalCommisionMap.get(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c).InstallmentLine__c = tempLineItem.Id;
                    
                        if(!createCommissionMap.containsKey(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c))){
                            createCommissionMap.put(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c), new list<CommissionLineItem__c>());
                        }
                        
                        createCommissionMap.get(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c) ).add(externalCommisionMap.get(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c));
                    }
                    
                }
            }
    
            //Create Other Sales Charges
            if(!unitToOtherSalesOrderCharges.isEmpty()){
                list<SalesOrderOtherCharges__c> finalListToInsert = new list<SalesOrderOtherCharges__c>();                
                for(id tempUnitKey : unitToOtherSalesOrderCharges.keySet()){
                    for(SalesOrderOtherCharges__c tempOtherChargeRecord : unitToOtherSalesOrderCharges.get(tempUnitKey)){
                        tempOtherChargeRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        finalListToInsert.add(tempOtherChargeRecord);
                    }
                }                
                insert finalListToInsert;
            }
    
            //Create Commission Lines
            if(!createCommissionMap.isEmpty()){
                list<CommissionLineItem__c> finalListToInsert = new list<CommissionLineItem__c>();
                list<CommissionLineItem__c> clListToInsert = new list<CommissionLineItem__c>();
                for(id tempUnitKey : createCommissionMap.keySet()){
                    for(CommissionLineItem__c tempCommissionLineRecord : createCommissionMap.get(tempUnitKey)){
                        tempCommissionLineRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        finalListToInsert.add(tempCommissionLineRecord);
                    }
                }
                clListToInsert.addAll(finalListToInsert);
                insert clListToInsert;
            }
    
            //Create Opportunity Unit Offers
            if(!offerLines.isEmpty()){
                list<OpportunityOfferLine__c> finalListToInsert = new list<OpportunityOfferLine__c>();
                for(id tempUnitKey : installmentLines.keySet()){
                    for(OpportunityOfferLine__c tempOfferRecord : offerLines.get(tempUnitKey)){
                    tempOfferRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        finalListToInsert.add(tempOfferRecord);
                    }
                }
                insert finalListToInsert;
            }
    
            //Create Opportunity Unit Payment Lines
            if(!createPaymentLines.isEmpty()){
                for(id tempUnitKey : createPaymentLines.keySet()){
                createPaymentLines.get(tempUnitKey).SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                }
                insert createPaymentLines.values();
            }
    
            // Update Sales Order to call Sales Order API
            /*if(!opportunityUnitsToCreate.isEmpty()){
for (SalesOrder__c salesOrder: opportunityUnitsToCreate.values()) {
salesOrder.IsBookingCompleted__c = true;
}
TriggerHandler.processedIds = new Set<Id>();
update opportunityUnitsToCreate.values();
}*///Commented by Akash
    
             //Update the Opportunity Win Reason
             update opportunityRecord;
             //DIGITAL SALES CHIRAG START
             Opportunity oprec = [SELECT Id,isDigitalSales__c FROM Opportunity WHERE Id=:opportunityRecord.Id];
            
            //For reservation send for approval
            if(action=='RESERVE' && oprec.isDigitalSales__c == false){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Reservation Approval Request for units ');
                req1.setObjectId(opportunityId);
                //---- Submit as logged in user
                req1.setSubmitterId(UserInfo.getUserId());
                //---- Submit the record to specific process
                req1.setProcessDefinitionNameOrId(Label.ReservationApprovalAPIName);
                req1.setSkipEntryCriteria(true);
                //---- Submit the approval request for the opportunity    
                Approval.ProcessResult result = Approval.process(req1);
                //vals to return
            }
    
            valueToReturn.put('result','success');
            valueToReturn.put('id',opportunityUnitsToCreate.values()[0].id);
            
           updateVirtualAccountToUnit(unitProjectMap,CorporateIBANSet);
            System.enqueueJob(new BookingQueable(opportunityDetails, opportunityUnitsToCreate.values(),eoiRAtoReparent));// Added by Akash

            
        }
        catch(exception e){
            Database.rollback(sp);
            valueToReturn.put('result','Exception : '+e.getMessage());
            
        }
        return valueToReturn;
    }
    
    
    /**
* generateOfferPDF 
*
* This method is used to generate PDF and attach it under the opportunity record
* 
* @usage opportunityUnitSearch LWC
*
* @param saleOfferInputParam    List of unit,offer and payment details (LwC doesn't support complex types)
* @param opportunityId          optinal opportunity ID
* @param singleUnitId           selected Unit IDs
* @return   String content version ID
*/
    @AuraEnabled(cacheable=false)
    public static string generateOfferPDF(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, String customerName, Id singleUnitId){
        //get Content as PDF
        boolean hasLead=false;
        map<id,Messaging.EmailFileAttachment> unitToAttachmentDetails = new map<id,Messaging.EmailFileAttachment>();
        map<id,Unit__c> allUnitIds = new map<id,Unit__c>();
        for(SalesOfferUtility.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            allUnitIds.put(tempPramObj.unitId,null);
        }
        allUnitIds = new map<id,Unit__c>( UnitServiceWithoutSharing.getAllUnitsById(allUnitIds.keySet()));
        //IF need to attach as activity uncomment **Attach
        //Content versions
        list<ContentVersion> contentVersionsToAttach = new list<ContentVersion>();
       
        for(SalesOfferUtility.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            Id currentUnit=tempPramObj.unitId;
            Id currentOffer=(tempPramObj.offerId!=null)?tempPramObj.offerId:null;
            String otherUnits='';
            String selectedPayments='';
            String designIdVal='';
            String PODSelection = tempPramObj.podiumSelection;
            // swimming pool related changes for yas riva
            String swimmingPoolSelection = tempPramObj.swimmingPoolSelection;
            boolean multiPurposeAmount =tempPramObj.multiPurposeAmountApplicable!=null ? tempPramObj.multiPurposeAmountApplicable : false;
            if( tempPramObj.selectedPayments !=null && !tempPramObj.selectedPayments.isEmpty() ){
                for(string tempPaymentID : tempPramObj.selectedPayments) {
                        selectedPayments = selectedPayments + (selectedPayments!=''?'|':'') +tempPaymentID;
                }
            }
            for(String tempID :  allUnitIds.keySet()){
                if(tempID!=currentUnit){
                    otherUnits = otherUnits + (otherUnits!=''?'|':'') + tempID;
                }
            }
            if(singleUnitId !=null && singleUnitId != currentUnit){
                continue;
            }
            if(tempPramObj.designId!=null ){
                designIdVal=tempPramObj.designId;
            }
            PageReference pdf = Page.OfferDetailsPDF;
            pdf.getParameters().put('id',(opportunityId!=null?opportunityId:''));
            pdf.getParameters().put('currentUnit',currentUnit);
            pdf.getParameters().put('otherUnits',otherUnits);
            pdf.getParameters().put('currentOffer',currentOffer);
            pdf.getParameters().put('selectedPayments',selectedPayments);
            
            pdf.getParameters().put('PODSelection',PODSelection);
            // swimming pool related changes for yas riva
            pdf.getParameters().put('swimmingPoolSelection',swimmingPoolSelection);
            pdf.getParameters().put('multiPurposeAmount',string.ValueOf(multiPurposeAmount));
            pdf.getParameters().put('customerName',(customerName!=null?customerName:''));
            pdf.getParameters().put('selectedDesign',designIdVal);

    
            pdf.setRedirect(true);
        
            //Attach
            ContentVersion cv = new ContentVersion();
            cv.VersionData = Test.isRunningTest() ? blob.valueOf('Methods defined as TestMethod do not support getContent call') : pdf.getContent();
            cv.Title = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
            cv.PathOnClient = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
            cv.Description = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
            cv.isMajorVersion = true;
            contentVersionsToAttach.add(cv);
        }
        //insert CV
      
        list<Id> attachmentIds = new list<ID>();
        insert contentVersionsToAttach;
        
        return contentVersionsToAttach[0].Id;
    }
    

    /**
* sendSalesOfferPDF 
*
* This method is used to send the email with attached PDF
* 
* @usage opportunityUnitSearch LWC
*
* @param saleOfferInputParam    List of unit,offer and payment details (LwC doesn't support complex types)
* @param opportunityId          optinal opportunity ID
* @param singleUnitId           selected Unit IDs
* @return   none
*/
    @AuraEnabled(cacheable=false)
    public static void sendSalesOfferPDF(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, String customerName, Id singleUnitId){
        //get Content as PDF
        boolean hasLead=false;
        map<id,Messaging.EmailFileAttachment> unitToAttachmentDetails = new map<id,Messaging.EmailFileAttachment>();
        map<id,Unit__c> allUnitIds = new map<id,Unit__c>();
        for(SalesOfferUtility.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            allUnitIds.put(tempPramObj.unitId,null);
        }
        allUnitIds = new map<id,Unit__c>( UnitServiceWithoutSharing.getAllUnitsById(allUnitIds.keySet()));
        //IF need to attach as activity uncomment **Attach
        //Content versions
        //**Attach list<ContentVersion> contentVersionsToAttach = new list<ContentVersion>();
        for(SalesOfferUtility.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            Id currentUnit=tempPramObj.unitId;
            Id currentOffer=(tempPramObj.offerId!=null)?tempPramObj.offerId:null;
            String otherUnits='';
            String selectedPayments='';
            String designIdVal='';
            String PODSelection = tempPramObj.podiumSelection;
            // swimming pool related changes for yas riva
            String swimmingPoolSelection = tempPramObj.swimmingPoolSelection;
            boolean multiPurposeAmount =tempPramObj.multiPurposeAmountApplicable!=null ? tempPramObj.multiPurposeAmountApplicable : false;
            if( tempPramObj.selectedPayments !=null && !tempPramObj.selectedPayments.isEmpty() ){
                for(string tempPaymentID : tempPramObj.selectedPayments) {
                        selectedPayments = selectedPayments + (selectedPayments!=''?'|':'') +tempPaymentID;
                }
            }
            for(String tempID :  allUnitIds.keySet()){
                if(tempID!=currentUnit){
                    otherUnits = otherUnits + (otherUnits!=''?'|':'') + tempID;
                }
            }
            if(singleUnitId !=null && singleUnitId != currentUnit){
                continue;
            }
            if(tempPramObj.designId!=null ){
                designIdVal=tempPramObj.designId;
            }
            PageReference pdf = Page.OfferDetailsPDF;
            pdf.getParameters().put('id',(opportunityId!=null?opportunityId:''));
            pdf.getParameters().put('currentUnit',currentUnit);
            pdf.getParameters().put('otherUnits',otherUnits);
            pdf.getParameters().put('currentOffer',currentOffer);
            pdf.getParameters().put('selectedPayments',selectedPayments);
            pdf.getParameters().put('PODSelection',PODSelection);
            // swimming pool related changes for yas riva
            pdf.getParameters().put('swimmingPoolSelection',swimmingPoolSelection);
            pdf.getParameters().put('multiPurposeAmount',string.ValueOf(multiPurposeAmount));
            pdf.getParameters().put('customerName',(customerName!=null?customerName:''));
            pdf.getParameters().put('selectedDesign',designIdVal);
    
            pdf.setRedirect(true);
        
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf');
            //efa.setFileName(allUnitIds.get(currentUnit).Project__r.Name+'_'+allUnitIds.get(currentUnit).Name+'.pdf');
            efa.setBody(Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent());
            unitToAttachmentDetails.put(currentUnit,efa);
            /* //**Attach remove above Messaging.EmailFileAttachment
ContentVersion cv = new ContentVersion();
cv.VersionData = pdf.getContent();
cv.Title = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
cv.PathOnClient = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
cv.Description = 'Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf';
cv.isMajorVersion = true;
contentVersionsToAttach.add(cv);*/
        }
        //insert CV
        /* //**Attach
list<Id> attachmentIds = new list<ID>();
insert contentVersionsToAttach;
for(ContentVersion cv : contentVersionsToAttach){
attachmentIds.add(cv.id);
}*/
        // Get Template
        string emailTemplateId = '';
        string emailTemplateLeadId = '';
        string relatedCustomerId = '';
        string orgWideEmailAddress = '';
        list<Opportunity> opportunityRecords = new list<Opportunity>();
    
        for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = :Constants.ALDAR_OFFER_LETTER limit 1]){
            emailTemplateId=tempRec.Id;
        }
    
        for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = :Constants.ALDAR_OFFER_LETTER_LEAD limit 1]){
            emailTemplateLeadId=tempRec.Id;
        }
        // Get Contact
        if(opportunityId!=null ){
            if(opportunityId.getsobjecttype() == Lead.sobjecttype){
                hasLead=true;
            }else{
                hasLead=false;
            }
    
            opportunityRecords=[select id,Contact__c,StageName from opportunity where id =:opportunityId limit 1];
            if(!opportunityRecords.isEmpty()){
                relatedCustomerId = opportunityRecords[0].Contact__c;
                //update opportunity stage to proposal after email is sent
                if(opportunityRecords[0].StageName == Constants.STAGE_NEW ||  opportunityRecords[0].StageName == Constants.STAGE_IN_PROGRESS){
                    opportunityRecords[0].StageName=Constants.STAGE_PROPOSAL;
                    update opportunityRecords;
                }
            }
        }
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL limit 1]){
            orgWideEmailAddress=tempRec.Id;
        }
        
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
        if (hasLead) {
            tempEmailInstance = Utilities.getEmailInstance(opportunityId,emailTemplateLeadId,null,null,null,null,null,null,null,unitToAttachmentDetails.values(),orgWideEmailAddress);
        } else {
            tempEmailInstance = Utilities.getEmailInstance(relatedCustomerId,emailTemplateId,opportunityId,null,null,null,null,null,null,unitToAttachmentDetails.values(),orgWideEmailAddress);
        }
        /* //**Attach
if(!attachmentIds.isEmpty()){
tempEmailInstance.setEntityAttachments(attachmentIds);
}
*/
        tempEmailInstance.setSaveAsActivity(true);
    
        Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{tempEmailInstance});
    }
    
    /**
* sendAssignRequestEamil 
*
* This method is used to trigger unit assignment request email
*
* @param unitsSelected    Selected unit list
* @return   none
*/
    @AuraEnabled(cacheable=false)
    public static String sendAssignRequestEmail(list<String> unitsSelected, String opportunityId){
        String assingmentRequestMessage = 'Unit has been auto approved';
        try {
            List<Unit_Assignment__c> lstUnitAssingments = new List<Unit_Assignment__c>();
            
            USER userData = [SELECT Id,name,ManagerId,Email FROM USER WHERE Id=:UserInfo.getUserId()];
            Map<Id, Set<Id>> mapUnassingedUnits = new Map<Id, Set<Id>>();

            for (Unit_Assignment__c unitAssignment : [
                SELECT Id, Unit__c, RequestedBy__c
                FROM Unit_Assignment__c
                WHERE Unit__c IN :unitsSelected
            ]) {
                if (!mapUnassingedUnits.containsKey(unitAssignment.Unit__c)) {
                    mapUnassingedUnits.put(unitAssignment.Unit__c, new Set<Id>());
                }
                mapUnassingedUnits.get(unitAssignment.Unit__c).add(unitAssignment.RequestedBy__c);
            }
            //List<Unit__c> lstSelectedUnits = [SELECT Id,Name,Project__r.Name,SellingPrice__c,AllocationGroupUser__c, RelatedOpportunity__c FROM Unit__c WHERE Id IN:unitsSelected];
            List<Unit__c> lstSelectedUnits = WithoutSharingClass.getUnits(unitsSelected);
            // ------------------ Unit Assingment logic--------------------------//
            
            for (Unit__c tempRec : lstSelectedUnits) {
                Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
                unitAssingment.RequestedBy__c = userData.Id;
                unitAssingment.Status__c = 'Pending approval';
                unitAssingment.Unit__c = tempRec.Id;
                unitAssingment.Approver__c = userData.ManagerId;
                unitAssingment.RequestedDate__c = System.now();
                unitAssingment.Opportunity__c = Label.UnitAssignmentAutoApporval == 'true' ? opportunityId : null;

                Boolean userHasRequestedBefore = mapUnassingedUnits.containsKey(tempRec.Id) &&
                                 mapUnassingedUnits.get(tempRec.Id).contains(userData.Id);

                if (!userHasRequestedBefore && Label.UnitAssignmentAutoApporval == 'true') {
                    unitAssingment.AutoApprove__c = true;
                } else {
                    assingmentRequestMessage = 'Request has been sent to line manager for approval.';
                }

                // ASF-3725 changes (Unit Assignment) : Bashim End
                lstUnitAssingments.add(unitAssingment);
            }
            // ------------------ Unit Assingment logic--------------------------//
            if (lstUnitAssingments.size() > 0) {
                //insert lstUnitAssingments;
                WithoutSharingClass.insertUnitAssignments(lstUnitAssingments);
                
            }
            List<Unit_Assignment__c> approvedList = new List<Unit_Assignment__c>();
            if(Label.UnitAssignmentAutoApporval=='true'){ 
                for(Unit_Assignment__c ua : lstUnitAssingments){
                    if(ua.AutoApprove__c){
                        ua.Status__c = 'Approved';
                        approvedList.add(ua);
                    }
                }
            }
            if(approvedList.size() > 0){
                //Update approvedList;
                WithoutSharingClass.updateUnitAssignments(approvedList);
            }
            
        } catch (Exception ex) {
            LoggerService.save(LoggerService.createApexLog(ex,'Unit Assignment','OpportunityUnitSearchController','sendAssignRequestEamil'));
            throw new AuraHandledException(ex.getMessage());
        }
        return assingmentRequestMessage;
    }
    
    /**
* generateSalesOffer 
*
* return available offers
* 
* @usage opportunityUnitSearch LWC
*
* @param saleOfferInputParam    List of unit,offer and payment details (LwC doesn't support complex types)
* @param OpportunityId          optinal opportunity ID
* @return   map<id,SalesOfferDetails>   map of unit to its offer details
*/
    @AuraEnabled(cacheable=false)
    public static map<id,SalesOfferUtility.SalesOfferDetails> generateSalesOffer(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId){
        map<Id,Id> unitIdToOffer = new map<Id,Id>();
        map<Id,boolean> unitToMultiPurposeAmountApplicableMap = new map<Id,boolean>();
        map<Id,string> unitToPodiumSelectedMap = new map<Id,string>();
        // swimming pool related changes for yas riva
        map<Id,string> unitToSwimmingPoolSelectedMap = new map<Id,string>();
        map<Id,ID> unitWithDesignMap = new  map<Id,ID>();
        map<id,set<Id>> unitToSelectedPaymentPlanMap=  new map<id,set<Id>>();
        map<Id, String> unitSignaturetypemap = new map<Id, String>();
    
        for(SalesOfferUtility.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            unitIdToOffer.put(tempPramObj.unitId,tempPramObj.offerId);
            unitSignaturetypemap.put(tempPramObj.unitId, tempPramObj.signatureType);
            if(tempPramObj.multiPurposeAmountApplicable!=null){
                unitToMultiPurposeAmountApplicableMap.put(tempPramObj.unitId,tempPramObj.multiPurposeAmountApplicable);
            }

            if(tempPramObj.podiumSelection!=null){
                unitToPodiumSelectedMap.put(tempPramObj.unitId,tempPramObj.podiumSelection);
            }
            
             // swimming pool related changes for yas riva
            if(tempPramObj.swimmingPoolSelection!=null){
                unitToSwimmingPoolSelectedMap.put(tempPramObj.unitId,tempPramObj.swimmingPoolSelection);
            }


            if(tempPramObj.designId!=null ){
                unitWithDesignMap.put(tempPramObj.unitId,tempPramObj.designId);
            }
            
            unitToSelectedPaymentPlanMap.put(tempPramObj.unitId,new set<ID>(tempPramObj.selectedPayments) );
        }
        
        return SalesOfferUtility.generateSalesOfferMap(unitIdToOffer,unitToMultiPurposeAmountApplicableMap,unitToPodiumSelectedMap,unitToSwimmingPoolSelectedMap,unitToSelectedPaymentPlanMap,unitWithDesignMap,opportunityId, unitSignaturetypemap);
    }
    
    /**
* validateRegistrationAllowed.
*
* Method to validat eall the required fields on Opportunity and Account before proceeding with Booking/Reservation
* 
* @usage opportunityUnitSearch LWC
*
* @param OpportunityId          selected opportunity ID
* @return   string   representing validation error
*/
    @AuraEnabled(cacheable=false)
    public static string validateRegistrationAllowed( Id opportunityId){
        opportunity optyRecord = [select id,AccountId from opportunity where id= :opportunityId limit 1];
        String opportunityValidation = OpportunityService.opportunityFieldsValidation(opportunityId);
        String accountValidation = AccountService.accountsFieldsValidation(optyRecord.AccountId);
        //TODO check if opportunity already have reserved unit
        if(opportunityValidation!=null && opportunityValidation!='' ){
            return 'Please populate values for '+opportunityValidation +' field(s) on related Opportunity record';
        }else if(accountValidation!=null && accountValidation !=''){
            return 'Please populate values for '+accountValidation +' field(s) on related Account record';
        }
        return null;
    }
    
    
    /**
* UnitWrapper 
*
* Wrapper class used to render the Unit list on the OpportunityUnitSearch Screen
*/
    public with sharing class UnitWrapper{
        @AuraEnabled
        public list<map<String,string>> propertyUsageList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitTypesSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitModelSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> floorNumberSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitBedRoomsSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitViewSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<UnitDetilsWrapper> unitDetailList=new list<UnitDetilsWrapper>();
        public UnitWrapper(list<Unit__c> unitData){
            set<String> propertyUsageSet=new Set<String>();
            set<String> unitTypesSet=new Set<String>();
            set<String> unitModelSet=new Set<String>();
            set<String> floorNumberSet=new Set<String>();
            set<String> unitBedRoomsSet=new Set<String>();
            set<String> unitViewSet=new Set<String>();
           
            for(Unit__c tempUnit : unitData){
                if(tempUnit.PropertyUsage__c !=null ){
                    propertyUsageSet.add(tempUnit.PropertyUsage__c );
                }
                if(tempUnit.UnitType__c !=null ){
                    unitTypesSet.add(tempUnit.UnitType__c );
                }
                if(tempUnit.UnitModel__c !=null ){
                    unitModelSet.add(tempUnit.UnitModel__c );
                }
                if(tempUnit.FloorNumber__c !=null ){
                    floorNumberSet.add(tempUnit.FloorNumber__c );
                }
                if(tempUnit.NumberOfBedrooms__c !=null ){
                    unitBedRoomsSet.add(String.ValueOf(tempUnit.NumberOfBedrooms__c ));
                }
                if(tempUnit.UnitView__c !=null ){
                    unitViewSet.add(tempUnit.UnitView__c );
                } 
                unitDetailList.add( new UnitDetilsWrapper(tempUnit) );
    
            }
            List<String> sortedPropertyUsageSet = new List<String>(propertyUsageSet);
            sortedPropertyUsageSet.sort();
            for(String tempS : sortedPropertyUsageSet){
                propertyUsageList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitTypesSet = new List<String>(unitTypesSet);
            sortedunitTypesSet.sort();
            for(String tempS : sortedunitTypesSet){
                unitTypesSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitModelSet = new List<String>(unitModelSet);
            sortedunitModelSet.sort();
            for(String tempS : sortedunitModelSet){
                unitModelSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedfloorNumberSet = new List<String>(floorNumberSet);
            sortedfloorNumberSet.sort();
            for(String tempS : sortedfloorNumberSet){
                floorNumberSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitBedRoomsSet = new List<String>(unitBedRoomsSet);
            sortedunitBedRoomsSet.sort();
            for(String tempS :sortedunitBedRoomsSet){
                unitBedRoomsSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitViewSet = new List<String>(unitViewSet);
            sortedunitViewSet.sort();
            for(String tempS : sortedunitViewSet){
                unitViewSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
        }
    
    }
    
    /**
* UnitDetilsWrapper 
*
* Wrapper class used to render the Unit details on the OpportunityUnitSearch Screen
*/
    public with sharing class UnitDetilsWrapper{
        @AuraEnabled
        public boolean isSelected; 
        @AuraEnabled
        public Unit__c unitDetails;
        public UnitDetilsWrapper(Unit__c tempUnit){
            isSelected=false;
            unitDetails=tempUnit;
        }
    }
    public class blockWrapper{
        @AuraEnabled public boolean isBlocked = false;
        @AuraEnabled public string blockedMessage;
    }
    @AuraEnabled
    public static boolean getUserStatus(){
        boolean isBlocked = false;
        List<RoundRobinAssignmentMatrix__c> roundRobinAssignmentList = [SELECT
                                                                        Id,
                                                                        User__c,
                                                                        BlockUser__c,
                                                                        Status__c
                                                                        FROM RoundRobinAssignmentMatrix__c
                                                                        WHERE User__c =: UserInfo.getUserId() LIMIT 1];
        if(roundRobinAssignmentList.size()>0){
            if(roundRobinAssignmentList[0].BlockUser__c){
                isBlocked = true;
            }
        }
        return isBlocked;
    }
    @AuraEnabled
    public static blockWrapper checkSMAuthorizationForBooking(Id recordId){
       
        boolean isBlocked = false;
        isBlocked = getUserStatus();
        blockWrapper wrap = new blockWrapper();
        if(isBlocked){
            wrap.isBlocked = true;
            wrap.blockedMessage = 'Temporary access restriction has been imposed. Please contact your Line Manager to resolve and reinstate access.';
        }
        
        
        if (!isBlocked){
            
            List<Opportunity> opplist = [SELECT LeadNumber__c,Account.CustomerType__c,VIPApproval__c  FROM Opportunity WHERE Id =:recordId];
            
            if(!opplist.isEmpty()){
                //  List<Lead> leadList = [SELECT Id, CustomerType__c FROM Lead WHERE LeadNumber__c =: LeadNumber];
                
                //  if(!leadList.isEmpty()){
                User us = [Select Id, Team__c FROM User WHERE Id =: UserInfo.getUserId()]; 
                
                if(opplist[0].VIPApproval__c != 'Approved'){
                    if(us.Team__c != null && us.Team__c != 'VIP' && us.Team__c !='Land' && (opplist[0].Account.CustomerType__c == 'VIP' || opplist[0].Account.CustomerType__c == 'Aldar Staff')){
                        wrap.isBlocked = true;
                        wrap.blockedMessage = 'Booking for VIP/Aldar Staff is restricted and not within your authorization.';
                    }
                }
                //}
            }
        }
        
        return wrap;
    }
  
   @future
    public static void updateVirtualAccountToUnit(Map<Id, Id> unitProjectMap, Set<String> CorporateIBANSet){
        try{
            List<BankVirtualAccounts__c> bvaListToUpdate = new List<BankVirtualAccounts__c>();
            List<Unit__c> unitsToUpdate = new List<Unit__c>();
            Map<Id, List<BankVirtualAccounts__c>> projectBVAMap = new Map<Id, List<BankVirtualAccounts__c>>();
            Map<String, List<BankVirtualAccounts__c>> corporateBVAMap = new Map<String, List<BankVirtualAccounts__c>>();
            Map<String, Map<String, List<BankVirtualAccounts__c>>> corporateIBANBVAMap = new Map<String, Map<String, List<BankVirtualAccounts__c>>>();
            
            
            List<Unit__c> unitList = [SELECT
                                      Id,
                                      Project__c,
                                      CorporateVirtualAccountNumber__c,
                                      VirtualAccountNumber__c,
                                      BuildingSectionName__c,
                                      Project__r.IBANNoCorporate__c,
                                      BuildingSectionName__r.IBANNoCorporate__c,
                                      (SELECT Id FROM Bank_Virtual_Accounts__r)
                                      FROM Unit__c
                                      WHERE Id IN: unitProjectMap.keySet()
                                      AND (Project__c IN: unitProjectMap.Values())]; 
            
            List<BankVirtualAccounts__c> escrowbankVirtualAccounts = [SELECT
                                                                      Id,
                                                                      Unit__c,
                                                                      BufferFlag__c,
                                                                      Project__c,
                                                                      BuildingSection__c,
                                                                      Virtual_Account_Type__c
                                                                      FROM BankVirtualAccounts__c
                                                                      WHERE (((Project__c IN: unitProjectMap.Values())
                                                                              AND Virtual_Account_Type__c = 'Escrow'))
                                                                      AND Unit__c = null
                                                                      AND BufferFlag__c = true
                                                                      AND Statusflag__c = 'Available' LIMIT: unitProjectMap.keySet().size()];
            
            
            List<BankVirtualAccounts__c> corporatebankVirtualAccounts =  [SELECT
                                                                          Id,
                                                                          Unit__c,
                                                                          BufferFlag__c,
                                                                          Project__c,
                                                                          BuildingSection__c,
                                                                          Virtual_Account_Type__c,
                                                                          EscrowIBANAccountNumber__c
                                                                          FROM BankVirtualAccounts__c
                                                                          WHERE (Virtual_Account_Type__c = 'Aldar Corporate')
                                                                          AND Unit__c = null
                                                                          AND BufferFlag__c = true
                                                                          AND EscrowIBANAccountNumber__c IN: CorporateIBANSet
                                                                          AND Statusflag__c = 'Available' ];
            
            for(BankVirtualAccounts__c bva : escrowbankVirtualAccounts){
                if(bva.Virtual_Account_Type__c == 'Escrow'){
                    
                    List<BankVirtualAccounts__c> bvaList = projectBVAMap.get(bva.BuildingSection__c) != null ? projectBVAMap.get(bva.BuildingSection__c) : (projectBVAMap.get(bva.Project__c) != null ? projectBVAMap.get(bva.Project__c) : new List<BankVirtualAccounts__c>());
                        // projectBVAMap.get(bva.Project__c) != null ? projectBVAMap.get(bva.Project__c) : new List<BankVirtualAccounts__c>();
                        bvaList.add(bva);
                    if(bva.BuildingSection__c != null){
                        projectBVAMap.put(bva.BuildingSection__c, bvaList);
                    }else if(bva.Project__c != null){
                        projectBVAMap.put(bva.Project__c, bvaList);
                    }
                } 
            }
            for(BankVirtualAccounts__c bva : corporatebankVirtualAccounts){
                if(bva.Virtual_Account_Type__c == 'Aldar Corporate'){
                    Map<String, List<BankVirtualAccounts__c>> IBANBVAMap = new Map<String, List<BankVirtualAccounts__c>>();
                    IBANBVAMap = corporateIBANBVAMap.get(bva.Virtual_Account_Type__c) != null ? corporateIBANBVAMap.get(bva.Virtual_Account_Type__c) : new Map<String, List<BankVirtualAccounts__c>>();
                    List<BankVirtualAccounts__c> bankvaList = IBANBVAMap.get(bva.EscrowIBANAccountNumber__c) != null ? IBANBVAMap.get(bva.EscrowIBANAccountNumber__c) : new List<BankVirtualAccounts__c>();
                    bankvaList.add(bva);
                    IBANBVAMap.put(bva.EscrowIBANAccountNumber__c, bankvaList);
                    corporateIBANBVAMap.put(bva.Virtual_Account_Type__c, IBANBVAMap);
                    List<BankVirtualAccounts__c> bvaList = corporateBVAMap.get(bva.Virtual_Account_Type__c) != null ? corporateBVAMap.get(bva.Virtual_Account_Type__c) : new List<BankVirtualAccounts__c>(); 
                    bvaList.add(bva);
                    corporateBVAMap.put(bva.Virtual_Account_Type__c, bvaList);
                }
            }
            for(Integer i = 0; i < unitList.size(); i++){
                Unit__c unit = new Unit__c();
                unit.Id = unitList[i].Id;
                if( projectBVAMap.ContainsKey(unitList[i].BuildingSectionName__c) || projectBVAMap.ContainsKey(unitList[i].Project__c)){
                    if(unitList[i].Bank_Virtual_Accounts__r.size() == 0 && (projectBVAMap.ContainsKey(unitList[i].BuildingSectionName__c) ? projectBVAMap.get(unitList[i].BuildingSectionName__c).size()>=unitList.size() : projectBVAMap.get(unitList[i].Project__c).size() >= unitList.size()) && unitList[i].VirtualAccountNumber__c == null){
                        
                        BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
                        bva.Id = projectBVAMap.ContainsKey(unitList[i].BuildingSectionName__c) ? projectBVAMap.get(unitList[i].BuildingSectionName__c)[i].Id : projectBVAMap.get(unitList[i].Project__c)[i].Id;
                        bva.Unit__c = unitList[i].Id;
                        bva.BufferFlag__c = false;
                        bvaListToUpdate.add(bva);
                        unit.VirtualAccountNumber__c = projectBVAMap.ContainsKey(unitList[i].BuildingSectionName__c) ? projectBVAMap.get(unitList[i].BuildingSectionName__c)[i].Id : projectBVAMap.get(unitList[i].Project__c)[i].Id; 
                    }  
                }
                if(corporateIBANBVAMap.containsKey('Aldar Corporate') && unitList[i].CorporateVirtualAccountNumber__c == null ){
                    Map<String, List<BankVirtualAccounts__c>> IBANBVAMap = corporateIBANBVAMap.get('Aldar Corporate');
                    BankVirtualAccounts__c corporatebva = new BankVirtualAccounts__c();
                    corporatebva.Id = IBANBVAMap.get(unitList[i].Project__r.IBANNoCorporate__c)[i].Id;
                    corporatebva.Unit__c = unitList[i].Id;
                    corporatebva.BufferFlag__c = false;
                    bvaListToUpdate.add(corporatebva); 
                    unit.CorporateVirtualAccountNumber__c = IBANBVAMap.get(unitList[i].Project__r.IBANNoCorporate__c)[i].Id;
                }
                unitsToUpdate.add(unit); 
                
            }
            
            
            if(!bvaListToUpdate.isEmpty()){
                update bvaListToUpdate;
            }
            if(!unitsToUpdate.isEmpty()){
                update unitsToUpdate;
            }
        }catch(Exception ex){
            
            LoggerService.save(LoggerService.addApexLog(ex,'OpportunityUnitSearchController','updateVirtualAccountToUnit',''));
        }
    }

    //Added by Mahidhar as part of SSC-372
    @AuraEnabled
    public static Integer getAssignedUnitsCount(List<Id> unitIds) {

        List<Unit_Assignment__c> inProgressUnits = [SELECT Id, Unit__r.Name FROM Unit_Assignment__c WHERE Unit__r.Status__c = 'In-progress'   AND Unit__c IN :unitIds];

        if (!inProgressUnits.isEmpty()) {
            Set<String> inProgressunitNames = new Set<String>();
            for (Unit_Assignment__c assignment : inProgressUnits) {
                inProgressunitNames.add(assignment.Unit__r.Name);
            }
            String unitNamesStr = String.join(inProgressunitNames, ', ');
            throw new AuraHandledException('The following units are already assigned to you ' + unitNamesStr);
        }
       List<Unit_Assignment__c> pendingAssignments = [SELECT Id, Unit__r.Name,ownerId FROM Unit_Assignment__c  WHERE Unit__r.Status__c = 'Available'  AND Status__c = 'Pending approval' AND Unit__r.AssignedToUser__c = '' AND Unit__c IN :unitIds];

        if (!pendingAssignments.isEmpty()) {
            Set<String> unitNames = new Set<String>();
            Boolean allOwnedByUser = true;
            Id currentUserId = UserInfo.getUserId();
            


            for (Unit_Assignment__c assignment : pendingAssignments) {
                
                unitNames.add(assignment.Unit__r.Name);
                if (assignment.OwnerId != currentUserId) {
                    allOwnedByUser = false;
                }
            }

            String unitNamesStr = String.join(unitNames, ', ');

            if (allOwnedByUser) {
                throw new AuraHandledException('The following units are still in pending approval: ' + unitNamesStr);
            } else if(!allOwnedByUser) {
                throw new AuraHandledException('Unit no longer available');
            }
        } else{  
             //added by Noor for Manager inventor
            List<Unit__c> unitInProgress = [ SELECT Id,  Name FROM Unit__c  WHERE  Status__c IN ('In-progress','Available')
            AND Id IN :unitIds
            AND AssignedToUser__c =:UserInfo.getUserId() ];
 
            if (!unitInProgress.isEmpty()) {
                Set<String> inProgressunitNames = new Set<String>();
                    for (Unit__c unit : unitInProgress) {
                    inProgressunitNames.add(unit.Name);
                    }

                String unitNamesStr = String.join(inProgressunitNames, ', ');
                throw new AuraHandledException('The Unit is already assigned to you '+ unitNamesStr);
            }
        }
        
         // Create lists from constants before the query
        List<String> unitStatuses = new List<String>{
            Constants.UNIT_STATUS_AVAILABLE, 
            Constants.UNIT_STATUS_BOOKING_INPROGRESS
        };

        List<String> statusValues = new List<String>{
            Constants.STATUS_APPROVED, 
            Constants.APPROVAL_STATUS_PENDING_APPROVAL
        };

        List<String> pendingApprovalStatus = new List<String>{
            Constants.APPROVAL_STATUS_PENDING_APPROVAL
        };

        // Now use the lists in the query
        List<Unit_Assignment__c> assignedUnits = [
            SELECT Id, Unit__c 
            FROM Unit_Assignment__c 
            WHERE Unit__r.Status__c IN :unitStatuses 
            AND (
                (Status__c IN :statusValues AND Unit__r.AssignedToUser__c = :UserInfo.getUserId()) 
                OR 
                (Status__c IN :pendingApprovalStatus AND OwnerId = :UserInfo.getUserId())
            )
        ];

        
        set<Id> setOfUnitId = new set<Id>();
        for(Unit_Assignment__c assignedUnitId : assignedUnits){
            setOfUnitId.add(assignedUnitId.Unit__c);
        }
        if((setOfUnitId.size() + unitIds.size()) > Integer.valueOf(System.Label.MaxAllowedUnitsToAssign)){
            throw new AuraHandledException('Maximum of ' + System.Label.MaxAllowedUnitsToAssign + ' units can be assigned'); 
        }
        return setOfUnitId.size();
    }

    //Added by Mahidhar SSC- 373
    @AuraEnabled
    public static void releaseUnits(list<String> unitsSelected, String opportunityId, String source){
       
        // to check from Manage inventry added by Noor if user is trying to release a unit which has no Unit Assignment record then we no alloaction group so sending error message
        /*List<Unit__c> unitInprogress = [SELECT Id, Name,AssignedToUser__c, (SELECT Id FROM Unit_Assignments__r) FROM Unit__c WHERE Status__c IN ('Available', 'In-progress','Booked')
                                        AND Id IN :unitsSelected];*/
        overrideSharing cls = new overrideSharing();
        List<Unit__c> unitInprogress = cls.getUnitInprogress(unitsSelected);
        Set<String> inProgressUnitNames = new Set<String>();
        Set<String> notAssignedUnitNames = new Set<String>();
        
        for (Unit__c ua : unitInprogress) {
            if (ua.Unit_Assignments__r.isEmpty() && ua.AssignedToUser__c == UserInfo.getUserId()) {
                    inProgressUnitNames.add(ua.Name);
                }
            if(ua.AssignedToUser__c != userInfo.getUserId()) {
                notAssignedUnitNames.add(ua.Name);
            }
        }
            
        if (!inProgressUnitNames.isEmpty() && !test.isRunningTest()) {
            String unitNamesStr = String.join(inProgressUnitNames, ', ');
            throw new AuraHandledException('Units in progress with assignments cannot be released: ' + unitNamesStr + '. Please contact sales support.');
        }    
        //if (!notAssignedUnitNames.isEmpty()) {
        if (!notAssignedUnitNames.isEmpty() && !test.isRunningTest()) {
            String unitNamesStrg = String.join(notAssignedUnitNames, ', ');
            throw new AuraHandledException('Units which are not assigned to you cannot be released: ' + unitNamesStrg + '. Please contact sales support.');
        }
        
        try {  
            Id currentUserId = UserInfo.getUserId(); 
            Set<Id> unitIds = new Set<Id>();
            List<Unit__c> lstUnitToUpdate = new List<Unit__c>();
            List<Unit_Assignment__c> unitAssList = new List<Unit_Assignment__c>();

            for(Unit_Assignment__c unitAssignment: [SELECT Id,ExistingAllocationGroup__c,Unit__r.AssignedToUser__c, Unit__c, Unit__r.LockedBy__c,Unit__r.Status__c
                                                    FROM Unit_Assignment__c
                                                    where Unit__c IN :unitsSelected AND  Unit__r.AssignedToUser__c = :currentUserId AND Opportunity__c = :opportunityId AND Unit_Release_Date__c = null AND RequestedBy__c = :currentUserId]){
                                                        Unit__c unitObj= new Unit__c();
                                                        unitObj.Id = unitAssignment.Unit__c;
                                                        unitObj.AssignedToUser__c = null;
                                                        unitObj.LockedBy__c = null;
                                                        unitObj.RelatedOpportunity__c = null;
                                                        unitObj.AllocationGroup__c = unitAssignment.ExistingAllocationGroup__c;
                                                        if (unitAssignment.Unit__r.Status__c == 'In-Progress') {
                                                            unitObj.Status__c = 'Available';  // Set the status to 'Available'
                                                        }
                                                        if(!unitIds.contains(unitAssignment.Unit__c)){
                                                            unitIds.add(unitAssignment.Unit__c);
                                                        	lstUnitToUpdate.add(unitObj);    

                                                            unitAssignment.Unit_Release_Date__c = System.now();
                                                            unitAssignment.Unit_Released_From__c = (source == 'SFDC' ? 'SFDC Unit Assignment' : 'IPAD Unit Assignment');
                                                            unitAssignment.Unit_Released_By__c = currentUserId;
                                                            unitAssList.add(unitAssignment);
                                                        }
                                                    }
            if(!unitAssList.isEmpty()){
                update unitAssList;
            }
            if(!lstUnitToUpdate.isEmpty()){
                WithoutSharingClass.updateUnits(lstUnitToUpdate);
            }
        } catch (Exception ex) {
            LoggerService.save(LoggerService.createApexLog(ex,'Unit Assignment','OpportunityUnitSearchController','sendAssignRequestEamil'));
            throw new AuraHandledException(ex.getMessage());
        }
    }

    Private without sharing class overrideSharing{
        Public List<unit__c> getUnitInprogress(list<String> unitsSelected){
            List<unit__c> units = [SELECT Id, Name,AssignedToUser__c, (SELECT Id FROM Unit_Assignments__r) FROM Unit__c 
            WHERE Status__c IN ('Available', 'In-progress','Booked')
            AND Id IN: unitsSelected];
            return units;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, Id> getUnitToOfferMap(Id opportunityId) {
    String NAME_CHANGE = 'Changing customer name or switching between the joint owners.';
        Map<Id, Id> unitToOfferMap = new Map<Id, Id>();

        if (opportunityId == null) {
            return unitToOfferMap;
        }

        // Step 1: Get cancellations for this Opportunity
        List<SalesOrderCancellation__c> cancellations = [
            SELECT Id, Unit__c
            FROM SalesOrderCancellation__c
            WHERE New_Buyer_Opportunity__c = :opportunityId
            AND ReasonforCancellation__c = :NAME_CHANGE
            AND Unit__c != null
        ];

        if (cancellations.isEmpty()) {
            return unitToOfferMap;
        }

        // Step 2: Get offers linked to this Opportunity
        List<OffersPromotions__c> offers = [
            SELECT Id
            FROM OffersPromotions__c
            WHERE New_Buyer_Opportunity__c = :opportunityId
        ];

        if (offers.isEmpty()) {
            return unitToOfferMap;
        }

        // For now, just take the first offer (if multiple exist, refine logic)
        Id offerId = offers[0].Id;

        // Step 3: Build map Unit → Offer
        for (SalesOrderCancellation__c cancel : cancellations) {
            unitToOfferMap.put(cancel.Unit__c, offerId);
        }

        return unitToOfferMap;
    }

}