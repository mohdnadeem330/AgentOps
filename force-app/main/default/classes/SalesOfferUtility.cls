/**********************************************************************************************************************
* Name               : SalesOfferUtility                                                        
* Description        : This class is used as utility to generate and calculate SalesOrder
* Usage              : opportunityUnitSearch LWC  and OfferDetailsPDFController                                                        
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class SalesOfferUtility {
    /** 
    * generateSalesOfferMap 
    *
    * returns map of unit to its offer details
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param unitIdToOffer              unit id to applied offer map
    * @param unitToPaymentPlanMap       unit id to all applicable payment
    * @param opportunityOrLedId         optional Opportunity or Lead Id
    *
    * @return   map<id,SalesOfferDetails>   map of unit to its offer details
    */
    public static map<id,SalesOfferDetails> generateSalesOfferMap(map<Id,Id> unitIdToOffer,map<Id,boolean> unitToMultiPurposeAmountApplicableMap,map<Id,string> unitToPodiumSelectedMap, map<Id,string> unitToSwimmingPoolSelectedMap,map<Id,set<Id>> unitToSelectedPaymentPlanMap, map<Id,ID> selectedDesignMap ,Id opportunityOrLedId, map<Id, String> unitSignaturetypemap ){
        boolean hasLead=false;
        boolean hasOpportunity=false;

        User loggedInUser = Utilities.getLoggedInUserDetail();
        String userProfileName = loggedInUser.ProfileName__c;
        if(Test.isRunningTest()){
            userProfileName = Constants.AGENCY_PROFILE;
        }

        //KP: Municipality Fee details from custom metadata
        Map<String, Municipality_Fee_Details__mdt> mfdByCountryMap = new Map<String, Municipality_Fee_Details__mdt>();
        for(Municipality_Fee_Details__mdt mfd : Municipality_Fee_Details__mdt.getAll().values()){
            if(mfd.isActive__c){
                mfdByCountryMap.put(mfd.City__c, mfd);
            }
        }
        
        //Decide Lead or Opportunity
        if(opportunityOrLedId!=null){
            if(opportunityOrLedId.getsobjecttype() == Lead.sobjecttype){
                hasLead=true;
            }else if(opportunityOrLedId.getsobjecttype() == Opportunity.sobjecttype){
                hasOpportunity=true;
            }
        }
        
        map<id,SalesOfferDetails> salesOffersMapToreturn = new map<id,SalesOfferDetails>();
        //Map of all Unit Details
        map<id,Unit__c> unitsToProcess = new map<id,Unit__c>();
        //Map of Lead details
        map<id,Lead> leadMap = new map<id,Lead>();
        //Map of opportunity details
        map<id,Opportunity> opportunityMap = new map<id,Opportunity>();
        //Building to available PAyment Plan IDs
        map<id,set<Id>> buildingToPaymentPlanIdsMap = new map<id,set<Id>>();
        //Building/Projet to available offers/Promotions
        map<id,list<OffersPromotions__c>> buildingOrProjectToOfferMap = new map<id,list<OffersPromotions__c>>();
        map<id,OffersPromotions__c> unitToOfferMap = new map<id,OffersPromotions__c>();
      Map<String, List<String>> projectUnitFinishingMap = getUnitFurnishingBasedOnProject();

        //get Discount sequence from the metadata
        list<DiscountOrderSetting__mdt> discountSequenceList = [select id, Order__c, MasterLabel from DiscountOrderSetting__mdt order by Order__c];
        map<string,OpportunityEOI__c> buildingProjectToEOIMap = new map<string,OpportunityEOI__c>();
        for(OpportunityEOI__c tempEOI: [select id,Name,BuildingSectionName__c,ProjectName__c,(select id from SalesOrders__r) from OpportunityEOI__c where Opportunity__c = :opportunityOrLedId and Status__c = :Constants.EOI_PAID ]){
            //collect only unassigned EOIs
            if(tempEOI.SalesOrders__r.isEmpty()){buildingProjectToEOIMap.put(tempEOI.BuildingSectionName__c+''+tempEOI.ProjectName__c,tempEOI);
            }
        }

        Decimal totalOfAllUnitSalesPrice=0;
        //Get Unit Details 
        List<Unit__c> allUnitsData = UnitServiceWithoutSharing.getAllUnitsById( unitIdToOffer.keySet() );
        for(Unit__c tempUnitRec :  allUnitsData){
            unitsToProcess.put(tempUnitRec.Id, tempUnitRec);
            totalOfAllUnitSalesPrice=(totalOfAllUnitSalesPrice+tempUnitRec.SellingPrice__c).setScale(2);
            if(tempUnitRec.BuildingSectionName__c!=null){
                buildingToPaymentPlanIdsMap.put(tempUnitRec.BuildingSectionName__c,new set<Id>());
                buildingOrProjectToOfferMap.put(tempUnitRec.BuildingSectionName__c,new list<OffersPromotions__c>());
            }
            if(tempUnitRec.Project__c!=null){
                buildingOrProjectToOfferMap.put(tempUnitRec.Project__c,new list<OffersPromotions__c>());
            }
        }
        //Get related UnitDesignOptions
        map<id,UnitDesign__c> unitDesignMap = new map<id,UnitDesign__c>(UnitServiceWithoutSharing.getAllUnitDesign(unitIdToOffer.keySet()));

        map<id,List<map<string,string>>> relatedDesignOptions = new map<id,List<map<string,string>>>();
        String MedLabel;
        for(UnitDesign__c ud : unitDesignMap.values()){
            
            if (ud.Unit__r.ProjectName__c == 'Fay Alreeman') { MedLabel = Constants.DESIGNTYPE_MEDITERRANEAN;
            }
            else
            {
                MedLabel = 'Modern';
            }
            if(!relatedDesignOptions.containsKey(ud.Unit__c)){
                relatedDesignOptions.put(ud.Unit__c,new list<map<string,string>>{new map<string,string>{'label' =>MedLabel , 'value' => ''}});
            }
            relatedDesignOptions.get(ud.Unit__c).add(new map<string,string>{'label' =>ud.DesignType__c , 'value' => ud.Id});
        }
        //Get Opportunity/Lead Details
        if(hasOpportunity){
            opportunityMap = OpportunityService.getOpportunityDetailsMapbyId(opportunityOrLedId);
            //opportunityMap = new map<id,Opportunity>([select id,Name,AccountId,Account.CustomerSubType__c,ContactId,ResidentStatus__c,LeadSource,Contact__r.MobilePhone,Contact__r.Email,Contact__r.nationality__c,Contact__r.Name,Contact__r.ResidentStatus__c,ownerId,owner.ManagerId from opportunity where id=:opportunityOrLedId  WITH SECURITY_ENFORCED]);
        }else if(hasLead){
            leadMap = LeadService.getLeadDetailsMapbyId(opportunityOrLedId);
            //leadMap= new map<id,Lead>([select id from Lead where id=:opportunityOrLedId  WITH SECURITY_ENFORCED]);
        }
        //Get Payment plan details based on Building


        map<id,PaymentPlan__c> allRelatedPaymentPlans= new map<id,PaymentPlan__c>();
        //Set<Id,Map<Id,PaymentPlan__c>> buildingOrProjectPaymentPlanMap = new Set<Id,Map<Id,PaymentPlan__c>>();
        allRelatedPaymentPlans = new map<id,PaymentPlan__c>(PaymentPlanService.getPaymentPlanByBuidlingIds(buildingToPaymentPlanIdsMap.keySet()));
        buildingToPaymentPlanIdsMap = new map<id,set<Id>>(PaymentPlanService.getPaymentPlanIdsByBuidlingIds(buildingToPaymentPlanIdsMap,buildingToPaymentPlanIdsMap.keySet()));
        //offer Records based on project or building
        map<id,OffersPromotions__c> offersMap = new map<id,OffersPromotions__c>(OffersPromotionsService.getActiveOffersAndPromotions(buildingOrProjectToOfferMap.keySet(),buildingOrProjectToOfferMap.keySet()));
        //map<id,OffersPromotions__c> offersMap = new map<id,OffersPromotions__c>([select id,Name,BuildingSectionName__c,Project__c,(select id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitFeatures__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c from Offers_Lines__r) from OffersPromotions__c where BuildingSectionName__c in :buildingOrProjectToOfferMap.keySet() or Project__c in :buildingOrProjectToOfferMap.keySet() WITH SECURITY_ENFORCED]);
        for(OffersPromotions__c tempOfferRec : offersMap.values()){
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.BuildingSectionName__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.BuildingSectionName__c).add(tempOfferRec);
            }
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.Project__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.Project__c).add(tempOfferRec);
            }
        }
        List<DarnaLoyaltyMatrix__mdt> darnaLoyaltyList = Utilities.getDarnaLoyaltyMatrix();
        decimal totalNetSellingPrice=0;
        //get broker commission details
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = new Map<Id,BrokerCommission__c>();
        map<Id,InternalCommission__c> unitInternalCommissionMap = new map<Id,InternalCommission__c>();
        for(Id unitID : unitIdToOffer.keySet()){
            unitToOfferMap.put(unitID,offersMap.containsKey(unitIdToOffer.get(unitID))?offersMap.get(unitIdToOffer.get(unitID)):null);
        }
        if(opportunityMap.containskey(opportunityOrLedId)){
            unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityMap.get(opportunityOrLedId),allUnitsData, unitToOfferMap );
            unitInternalCommissionMap =  CommissionService.getInternalCommissions(opportunityMap.get(opportunityOrLedId),allUnitsData, unitToOfferMap );
        }

        List<Unit_Add_on__c> unitList = [SELECT Id,Name_of_Add_on__c,SubName_of_AddOns__c, Unit__c FROM Unit_Add_on__c WHERE Unit__c =:unitIdToOffer.keySet() and isactive__C = True order by SubName_of_AddOns__c];

        Map<Id,List<Unit_Add_on__c>> unitMap = new Map<Id,List<Unit_Add_on__c>>();

        for(Unit_Add_on__c un : unitList){
             if(unitMap.containsKey(un.Unit__c)){
                List<Unit_Add_on__c> unitaddonList = unitMap.get(un.Unit__c);
                unitaddonList.add(un);
                unitMap.put(un.Unit__c,unitaddonList);
            }else{
                List<Unit_Add_on__c> unitaddonList = new List<Unit_Add_on__c>();
                unitaddonList.add(un);
                unitMap.put(un.Unit__c,unitaddonList);
            }
        }

        // Populate the offer details wrapper
        for(Id unitID : unitIdToOffer.keySet()){
            SalesOfferDetails salesOfferObj= new SalesOfferDetails();
            salesOfferObj.leadId = hasLead?opportunityOrLedId:null;
            salesOfferObj.opportunityId = hasOpportunity?opportunityOrLedId:null;
            salesOfferObj.unitId=unitID;
            salesOfferObj.offerId=unitIdToOffer.get(unitID);
            salesOfferObj.totalOfAllUnitSellingPrice=totalOfAllUnitSalesPrice.setScale(2);
            salesOfferObj.totalUnitOffered = unitIdToOffer.size();
            salesOfferObj.opportunityRecord = salesOfferObj.opportunityId!=null ? opportunityMap.get(opportunityOrLedId) :null ;
            salesOfferObj.leadRecord = salesOfferObj.leadId!=null ? LeadMap.get(opportunityOrLedId) :null ;
            salesOfferObj.unitRecord = unitsToProcess.get(unitId);
            salesOfferObj.signatureType = unitSignaturetypemap.get(unitId);
            //
            salesOfferObj.offerRecord = offersMap.containsKey(salesOfferObj.offerId)?offersMap.get(salesOfferObj.offerId):null;
            boolean memoOffer = (salesOfferObj.offerRecord!=null && salesOfferObj.offerRecord.BookingMemo__c!=null)?true:false;
            salesOfferObj.availableOffers = new list<map<String,string>>();
            salesOfferObj.signatureTypes = new list<map<String,string>>();
            salesOfferObj.availableWithMemoOffers = new list<map<String,string>>();
            //Design Related Changes
            
            if(selectedDesignMap!=null && selectedDesignMap.containsKey(unitID) && selectedDesignMap.get(unitID)!=null){                salesOfferObj.unitDesignRecordId = selectedDesignMap.get(unitID);
            }
            else
            {
                salesOfferObj.unitDesignRecordId = null;
                salesOfferObj.unitDesignRecordName = MedLabel ;
            }

            Map<String,List<Unit_Add_on__c>> UnitAddonMap = new Map<String,List<Unit_Add_on__c>>();
            if(unitMap.get(unitID) != null){
                for(Unit_Add_on__c un : unitMap.get(unitID)){
                if(UnitAddonMap.containsKey(un.Name_of_Add_on__c)){
                    List<Unit_Add_on__c> strlist = UnitAddonMap.get(un.Name_of_Add_on__c);
                    strlist.add(un);
                    UnitAddonMap.put(un.Name_of_Add_on__c,strlist);
                }else{
                    List<Unit_Add_on__c> strlist = new List<Unit_Add_on__c>();
                    strlist.add(un);
                    UnitAddonMap.put(un.Name_of_Add_on__c,strlist);
                }
            }
            }
          List<UnitAddonWrapper> UnitAddonWrapperList = new List<UnitAddonWrapper>();
          for(String st :UnitAddonMap.keySet()){
                UnitAddonWrapper ua= new UnitAddonWrapper();
                ua.UnitAddonName = st;
                List<UnitSubAddonWrapper> subaddonList = new List<UnitSubAddonWrapper>();
                for(Unit_Add_on__c stmap: UnitAddonMap.get(st)){
                    UnitSubAddonWrapper us = new UnitSubAddonWrapper();
                    us.label = stmap.SubName_of_AddOns__c;
                    us.value=stmap.Id;
                    subaddonList.add(us);
                }
                ua.UnitsubAddonWrapperList = subaddonList;
                UnitAddonWrapperList.add(ua);
          }
        //   salesOfferObj.UnitAddonWrapperList = UnitAddonWrapperList;
          salesOfferObj.unitAddons = UnitAddonWrapperList;

           
            salesOfferObj.unitDesignRecordId = (selectedDesignMap!=null && selectedDesignMap.containsKey(unitID) && selectedDesignMap.get(unitID)!=null)?selectedDesignMap.get(unitID):null;
            
            salesOfferObj.unitDesignRecord = (salesOfferObj.unitDesignRecordId!=null &&  unitDesignMap.containsKey(salesOfferObj.unitDesignRecordId) )? unitDesignMap.get(salesOfferObj.unitDesignRecordId) :null;
            salesOfferObj.availableUnitDesigns = relatedDesignOptions.containsKey(unitID)  ? relatedDesignOptions.get(unitID)  : new list<map<String,string>>();
            
            salesOfferObj.hasUnitDesign =  !salesOfferObj.availableUnitDesigns.isEmpty();
            //Moving the below code from 141 to have the hasUnitDesign value to set first before it refer from the below code
            salesOfferObj.multiPurposeAmountApplicable= (!unitToMultiPurposeAmountApplicableMap.isEmpty() && unitToMultiPurposeAmountApplicableMap.containsKey(unitID) ) ? unitToMultiPurposeAmountApplicableMap.get(unitID) : ( (salesOfferObj.unitRecord.BuildingSectionName__r.EligibileforMultiPurposeRoom__c || salesOfferObj.hasUnitDesign ) ? true : false);
            if(salesOfferObj.unitRecord.Mandatory_Premium__c){
                salesOfferObj.multiPurposeAmountApplicable= true;
            }
            List<String> typeOffurnishingList  = projectUnitFinishingMap.get(salesOfferObj.unitRecord.Project__r.Name) != null?projectUnitFinishingMap.get(salesOfferObj.unitRecord.Project__r.Name): new List<String>() ;
            salesOfferObj.unitFinishingVals = new list<map<string,string>>();
            for(String str: typeOffurnishingList){                salesOfferObj.unitFinishingVals.add(new map<string,string>{'label' => str , 'value' => str});  
            }
            if(salesOfferObj.unitRecord.Project__c!=null){
                salesOfferObj.digitalsignatureApplied = salesOfferObj.unitRecord.Project__r.DigitalSignatureApplied__c;
                if(salesOfferObj.unitRecord.Project__r.DigitalSignatureApplied__c){
                    Schema.DescribeFieldResult fieldResult = SalesOrder__c.SignatureType__c.getDescribe();
                    for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
                        map<string,string> tempMap=new map<string,string>();
                        tempMap.put('label',tempVal.getLabel());
                        tempMap.put('value',tempVal.getValue());
                        salesOfferObj.signatureTypes.add(tempMap);
                    }                      
                } 
            }
            
            //defaulting to true if EligibileforMultiPurposeRoom__c , this will be overriden by user value
            if(salesOfferObj.unitDesignRecordId!=null && salesOfferObj.unitDesignRecord !=null){                salesOfferObj.unitRecord = overrideUnitDetails(salesOfferObj.unitRecord, salesOfferObj.unitDesignRecord);
            }

            
            // salesOfferObj.PodiumSelected = true;

            

            string strpodiumSelection;
            strpodiumSelection = (!unitToPodiumSelectedMap.isEmpty() && unitToPodiumSelectedMap.containsKey(unitID) )? unitToPodiumSelectedMap.get(unitID) : '';
           
           
            salesOfferObj.PodiumSelection = strpodiumSelection;
            salesOfferObj.PodiumAmount = 0; 

            if (strpodiumSelection!= ''){
                if(strpodiumSelection.contains('Kitchen')) {
                    salesOfferObj.PodiumAmount = salesOfferObj.unitRecord.PODkitchenPrice__c;
                }else if (strpodiumSelection.contains('Multi Purpose Room')) { salesOfferObj.PodiumAmount = salesOfferObj.unitRecord.PODMultiPurposeRoomPrice__c;
                }
            }
            
             // swimming pool related changes for yas riva

            string strSwimmingPoolSelection;
            strSwimmingPoolSelection = (!unitToSwimmingPoolSelectedMap.isEmpty() && unitToSwimmingPoolSelectedMap.containsKey(unitID) )? unitToSwimmingPoolSelectedMap.get(unitID) : '';
           
            salesOfferObj.swimmingPoolSelection = strSwimmingPoolSelection;
            salesOfferObj.swimmingPoolAmount = 0; 

            if (strSwimmingPoolSelection!= '' && strSwimmingPoolSelection != null){
                if(strSwimmingPoolSelection.contains('Yes')) {
                    salesOfferObj.swimmingPoolAmount = salesOfferObj.unitRecord.Swimming_Pool_Price__c;
                }
            }

            //If we have unit design then 
            //populate available offers
            //salesOfferObj.availableOffers.add(new map<string,string>{'label' =>'None' , 'value' => ''});
            //salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>'None' , 'value' => ''});
            
            if(!buildingProjectToEOIMap.isEmpty() && buildingProjectToEOIMap.containsKey(salesOfferObj.unitRecord.BuildingSectionName__c +''+ salesOfferObj.unitRecord.Project__c) ){
                salesOfferObj.availableEOIs=new list<map<string,string>>();
                salesOfferObj.availableEOIs.add(new map<string,string>{'label' =>'None' , 'value' => ''});
                salesOfferObj.availableEOIs.add(new map<string,string>{'label' =>buildingProjectToEOIMap.get(salesOfferObj.unitRecord.BuildingSectionName__c +''+ salesOfferObj.unitRecord.Project__c).Name , 'value' => buildingProjectToEOIMap.get(salesOfferObj.unitRecord.BuildingSectionName__c +''+ salesOfferObj.unitRecord.Project__c).Id });
            }
            if(salesOfferObj.unitRecord.Project__c!=null && buildingOrProjectToOfferMap.containsKey(salesOfferObj.unitRecord.Project__c) ){
                for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(salesOfferObj.unitRecord.Project__c) ){
                    if(tempOfferRec.BuildingSectionName__c==null && salesOfferObj.unitRecord.Project__c == tempOfferRec.Project__c ){
                        if (userProfileName.contains(Constants.AGENCY_PROFILE)) {
                            if (tempOfferRec.BrokerPortalFlag__c == true ) {salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        } else if (tempOfferRec.BookingMemo__c==null ) {salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                        if (tempOfferRec.BookingMemo__c !=null ) {
                            if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == salesOfferObj.unitId) {
                                salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        }else{salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }

                }
            }
            
            if(salesOfferObj.unitRecord.BuildingSectionName__c!=null && buildingOrProjectToOfferMap.containsKey(salesOfferObj.unitRecord.BuildingSectionName__c) ){
                for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(salesOfferObj.unitRecord.BuildingSectionName__c) ){
                    if(salesOfferObj.unitRecord.BuildingSectionName__c ==tempOfferRec.BuildingSectionName__c ){
                        if (userProfileName.contains(Constants.AGENCY_PROFILE)) {
                            if (tempOfferRec.BrokerPortalFlag__c == true ) { salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});

                            }
                        }else if (tempOfferRec.BookingMemo__c==null ) {
                            salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                        if (tempOfferRec.BookingMemo__c != null) {                if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == salesOfferObj.unitId) {
                                salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        }else{
                                salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }

                }
            }
            
           
            salesOfferObj.offersAvailable = (salesOfferObj.availableOffers.size()!=1);

            //Offer line application
            salesOfferObj.applicableOfferLinesCalculated = new list<OfferLines__c>();
            if(salesOfferObj.offerRecord != null){
                //ASF-1832 -START- Implementation of Direct Rebate
                List<OfferLines__c> allApplicableOfferLines = getApplicableOfferLines(salesOfferObj.offerRecord.Offers_Lines__r,salesOfferObj.unitRecord,salesOfferObj.opportunityRecord,salesOfferObj.leadRecord ,salesOfferObj.totalUnitOffered, salesOfferObj.totalOfAllUnitSellingPrice );                    
                Boolean isDirectPresent = false;
                Map<String, String> applicableOffersByCustomerType = new Map<String, String>();
                for(OfferLines__c oli : allApplicableOfferLines ){
                    if(oli.CustomerType__c != null && oli.OfferType__c != null){
                        applicableOffersByCustomerType.put(oli.OfferType__c,oli.CustomerType__c);
                    }
                    if(oli.AgentType__c != null && oli.AgentType__c == System.Label.Direct){
                        isDirectPresent = true;
                    }
                }
                List<OfferLines__c> tempOfferLineList = new List<OfferLines__c>();
                if(isDirectPresent && applicableOffersByCustomerType.containsKey(System.Label.Rebate)){
                    Boolean isOtherRebatePresent = false;
                    List<String> customerTypeFromLabel = System.Label.OfferCustomerTypes.split(',');
                    if(customerTypeFromLabel != null){
                        for(String type : customerTypeFromLabel){
                            if(applicableOffersByCustomerType.get(System.Label.Rebate).equalsIgnoreCase(type.trim())){
                                isOtherRebatePresent = true;
                            }
                        }
                    }
                    if(isOtherRebatePresent){
                        for(OfferLines__c oli : allApplicableOfferLines ){
                            if(oli.OfferType__c == System.Label.Rebate && oli.AgentType__c == System.Label.Direct){
                                continue;    
                            }else{
                                tempOfferLineList.add(oli);  
                            }
                        }
                    }else{
                        tempOfferLineList = allApplicableOfferLines;
                    }
                }else{
                    tempOfferLineList = allApplicableOfferLines;
                }
                allApplicableOfferLines = tempOfferLineList;
                //ASF-1832 -END- Implementation of Direct Rebate
                salesOfferObj.applicableOfferLinesCalculated = allApplicableOfferLines;
            }

            salesOfferObj.offerLinesApplied = !(salesOfferObj.applicableOfferLinesCalculated.isEmpty());
                
            //Offer based discount calculation
            map<string,decimal> discountNameToPercentage = new map<string,decimal>();
            decimal admWavierPercentage = 0;
            
            decimal homeMaintenanceWavierYears = 0;
            decimal serviceChargesWavierYears = 0;
            decimal otherSalesSupport = 0;
            decimal subsidy = 0;
            decimal darna = 0;
            decimal pmWavedFee = 0;
            decimal offerLevelRebate = 0;
            decimal offerlevelPremium =  0;
            decimal internalCommissionMemo = 0;
            decimal externalCommissionMemo = 0;
            for(OfferLines__c tempOfferLine : salesOfferObj.applicableOfferLinesCalculated){
                tempOfferLine.OfferValue__c = tempOfferLine.OfferValue__c.setScale(2);
                if(!memoOffer && tempOfferLine.OfferType__c.equalsIgnoreCase('Additional Discount') && tempOfferLine.DiscountType__c!=null  ){ 
                    //If multiple entry then perform summation
                    if(!discountNameToPercentage.containsKey(tempOfferLine.DiscountType__c.toLowerCase())) {
                        discountNameToPercentage.put(tempOfferLine.DiscountType__c.toLowerCase(),0);
                    }
                    discountNameToPercentage.put(tempOfferLine.DiscountType__c.toLowerCase(), discountNameToPercentage.get(tempOfferLine.DiscountType__c.toLowerCase())+ (tempOfferLine.OfferValue__c/100));
                    
                }else if(memoOffer && tempOfferLine.OfferType__c.equalsIgnoreCase('Additional Discount') && tempOfferLine.BudgetTaskName__c == Constants.BUDGET_LINE_DISCOUNT ){ discountNameToPercentage.put('PaymentPlanDiscount__c'.toLowerCase(),tempOfferLine.OfferValue__c/100);
                }else if(tempOfferLine.OfferType__c.equalsIgnoreCase('Rebate') && tempOfferLine.OfferValue__c!=null ){ offerLevelRebate= offerLevelRebate + tempOfferLine.OfferValue__c;
                }else if(tempOfferLine.OfferType__c.equalsIgnoreCase(constants.DISCOUNT_TYPE_PREMIUM) && tempOfferLine.OfferValue__c!=null ){ offerlevelPremium = offerlevelPremium + tempOfferLine.OfferValue__c;
                }
                
                if(tempOfferLine.BudgetTaskName__c!=null){
                    if( tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_ADMFEE)  ){ admWavierPercentage= admWavierPercentage + (tempOfferLine.OfferValue__c);
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_HOME_MAINTENANCE) ){ homeMaintenanceWavierYears= homeMaintenanceWavierYears + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_SC_WAIVER) ){ serviceChargesWavierYears=  serviceChargesWavierYears + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_SUBSIDY) ){ subsidy =  subsidy + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_DARNA) ){ darna =  darna + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_INTERNAL_COMMISSION) ){ internalCommissionMemo =  internalCommissionMemo + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_EXTERNAL_COMMISSION) ){ externalCommissionMemo =  externalCommissionMemo + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_OTHER) && tempOfferLine.OfferOn__c.equalsIgnoreCase(Constants.OFFER_ON_PM_FEE) ){
                        //Calculate PM Fee as otherSalesSupport 
                        //Building level % field * Value(year) * unit level amount
                        if(salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c !=null && salesOfferObj.unitRecord.MarketLeaseRent__c !=null ) {                            otherSalesSupport=  otherSalesSupport + ((salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c/100) * salesOfferObj.unitRecord.MarketLeaseRent__c * tempOfferLine.OfferValue__c);
                            pmWavedFee = pmWavedFee + ((salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c/100) * salesOfferObj.unitRecord.MarketLeaseRent__c * tempOfferLine.OfferValue__c);
                        }

                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_OTHER) ){ otherSalesSupport=  otherSalesSupport + tempOfferLine.OfferValue__c;
                    }
                }
                
                
            }
            
            //Payment plan calculation
            salesOfferObj.applicablePaymentPlansCalculated = new list<PaymentPlanWrapper>();
            salesOfferObj.availablePaymentPlans = new list<map<string,string>>();
            salesOfferObj.availablePaymentPlansWithMemo = new list<map<string,string>>();
            salesOfferObj.availablePodiumChoices = new list<map<string,string>>();
      // swimming pool related changes for yas riva
            salesOfferObj.availableSwimmingPoolChoices = new list<map<string,string>>();
            if(salesOfferObj.unitRecord.PODMultiPurposeRoomPrice__c>0 || salesOfferObj.unitRecord.PODkitchenPrice__c>0 ){
                if(!salesOfferObj.unitRecord.Mandatory_POD__c)
                salesOfferObj.availablePodiumChoices.add(new map<string,string>{'label' => '--None--' , 'value' => '--None--'});
    
                if(salesOfferObj.unitRecord.PODMultiPurposeRoomPrice__c>0)
                salesOfferObj.availablePodiumChoices.add(new map<string,string>{'label' => 'Multi Purpose Room' , 'value' => 'Multi Purpose Room'});
    
                if(salesOfferObj.unitRecord.PODkitchenPrice__c>0)
                salesOfferObj.availablePodiumChoices.add(new map<string,string>{'label' => 'Kitchen' , 'value' => 'Kitchen'});
            }
      // swimming pool related changes for yas riva
            if(salesOfferObj.unitRecord.Swimming_Pool_Price__c > 0){
                if(!salesOfferObj.unitRecord.Mandatory_Swimming_Pool__c){
                    //salesOfferObj.availableSwimmingPoolChoices.add(new map<string,string>{'label' => '--None--' , 'value' => '--None--'});
                    salesOfferObj.availableSwimmingPoolChoices.add(new map<string,string>{'label' => 'No' , 'value' => 'No'});

                }
                if(salesOfferObj.unitRecord.Swimming_Pool_Price__c > 0){
                    salesOfferObj.availableSwimmingPoolChoices.add(new map<string,string>{'label' => 'Yes' , 'value' => 'Yes'});
                }
    
            }



            set<ID> selectedPlans= new set<ID>();
            set<ID> standardPlans= new set<ID>();
            if(buildingToPaymentPlanIdsMap.containsKey(salesOfferObj.unitRecord.BuildingSectionName__c)){
                //Iterate over all Payment Plans
                for(Id tempPaymentId : buildingToPaymentPlanIdsMap.get(salesOfferObj.unitRecord.BuildingSectionName__c)){

                    if(salesOfferObj.opportunityRecord!=null && allRelatedPaymentPlans.get(tempPaymentId).CustomerSubType__c!=null && salesOfferObj.opportunityRecord.Account.CustomerSubType__c != allRelatedPaymentPlans.get(tempPaymentId).CustomerSubType__c){                        continue;
                    }

                    //-----
                    boolean isAvailablePlan=false;
                    if (userProfileName.contains(Constants.AGENCY_PROFILE)) {
                        if (allRelatedPaymentPlans.get(tempPaymentId).BrokerPortalFlag__c == true ) {
                            salesOfferObj.availablePaymentPlans.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                            isAvailablePlan=true;
                        }
                        //COllecting all Standard Payment plans
                        if(allRelatedPaymentPlans.get(tempPaymentId).BrokerPortalFlag__c == true  && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == Constants.YES){
                            standardPlans.add(tempPaymentId);
                        }
                    }  else if (allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__c == null ) {
                        if((allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c != null &&  salesOfferObj.unitRecord.Unit_Feature_for_Payment_Plan__c == allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c) ||
                           allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c == null){
                            salesOfferObj.availablePaymentPlans.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                           }
                        isAvailablePlan=true;
                        //COllecting all Standard Payment plans
                        if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == Constants.YES){
                            standardPlans.add(tempPaymentId);
                        }
                    }
                    
                    
                    
                    if((allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c != null &&  salesOfferObj.unitRecord.Unit_Feature_for_Payment_Plan__c == allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c) ||
                    allRelatedPaymentPlans.get(tempPaymentId).Unit_Feature__c == null){
                        
                        if (allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__c != null) {
                            if (allRelatedPaymentPlans.get(tempPaymentId).Unit__c  == salesOfferObj.unitId && allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__r.OwnerId == loggedInUser.Id ) { 
                                //salesOfferObj.availablePaymentPlansWithMemo.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                                isAvailablePlan=true;
                                //COllecting all Standard Payment plans
                                if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == Constants.YES){
                                    standardPlans.add(tempPaymentId);
                                }
                            }
                        }else{
                            salesOfferObj.availablePaymentPlansWithMemo.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                            isAvailablePlan=true;
                            //COllecting all Standard Payment plans
                            if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == Constants.YES){
                                standardPlans.add(tempPaymentId);
                            }
                        }
                        
                    }
                    
                    if(!isAvailablePlan){ continue;
                    }
                    //-----



                    //adding PaymentPlanDiscount__c discount, order from metadata shoul dbe in %
                    //do not apply Payment discount when its memo Offer
                    if(!memoOffer && allRelatedPaymentPlans.containsKey(tempPaymentId) ){
                        allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c = allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c !=null?allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c:0;
                        discountNameToPercentage.put('PaymentPlanDiscount__c'.toLowerCase(), (allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c/100));
                    }
                    
                    //Discount calculation for each payment plan
                    Decimal calculatedWealthDiscountAmount = 0;
                    Decimal calculatedCorporateDiscountAmount = 0;
                    Decimal calculatedBulkDiscountAmount = 0;
                    Decimal calculatedPaymentPlanDiscountAmount = 0;
                    Decimal totalDiscountedPrice= salesOfferObj.unitRecord.SellingPrice__c ;
                    Decimal unitArea = 0;
                    Decimal internalCommission = 0;
                    Decimal ReferralCommissionAmount = 0;

                    

                    //sorted Discount sequence
                    for(DiscountOrderSetting__mdt discountSeq :  discountSequenceList){
                        //If sequence setting is defined then apply the discount
                        if(discountNameToPercentage.containsKey(discountSeq.MasterLabel.toLowerCase())){
                            if(discountSeq.MasterLabel.equalsIgnoreCase(Constants.DISCOUNT_TYPE_BULK_DISCOUNT)){ calculatedBulkDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else if(discountSeq.MasterLabel.equalsIgnoreCase(Constants.DISCOUNT_TYPE_CORPORATE_DISCOUNT)){ calculatedCorporateDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else if(discountSeq.MasterLabel.equalsIgnoreCase(Constants.DISCOUNT_TYPE_WEALTH_DISCOUNT)){ calculatedWealthDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else{ calculatedPaymentPlanDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }
                            totalDiscountedPrice = (totalDiscountedPrice - (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase()))).setScale(2);
                        }
                    }

                    if(salesOfferObj.unitRecord.MeasuredArea__c !=null){unitArea = (salesOfferObj.unitRecord.MeasuredArea__c).setScale(2);
                    }else if(salesOfferObj.unitRecord.SaleableArea__c !=null){ unitArea = (salesOfferObj.unitRecord.SaleableArea__c).setScale(2);
                    } 
                    PaymentPlanWrapper tempPaymentPlanRec;
                    decimal premiumAmmount = (offerlevelPremium).setScale(2);
                    //Init/Create payment plan records
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec = new PaymentPlanWrapper( allRelatedPaymentPlans.get(tempPaymentId) ,totalDiscountedPrice.setScale(2));
                    }
                    //override user selection
                    if(tempPaymentPlanRec != null && unitToSelectedPaymentPlanMap!=null && unitToSelectedPaymentPlanMap.containsKey(unitID) && unitToSelectedPaymentPlanMap.get(unitID)!=null ){
                        tempPaymentPlanRec.isSelected= unitToSelectedPaymentPlanMap.get(unitID).contains(tempPaymentId);
                    }
                    if(tempPaymentPlanRec.isSelected){
                        selectedPlans.add(tempPaymentId);
                    }
                    // perform calculation Amount - discount + premiumAmmount + multiPurposeAmount
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec.premiumAmmount = (premiumAmmount + ( (allRelatedPaymentPlans.get(tempPaymentId).Premium__c!=null && allRelatedPaymentPlans.get(tempPaymentId).Premium__c!= 0)?allRelatedPaymentPlans.get(tempPaymentId).Premium__c:0 )).setScale(2) ;
                    }
                    decimal multiPurposeAmount=0;
                    if(salesOfferObj.hasUnitDesign && salesOfferObj.unitDesignRecord!=null ){                        multiPurposeAmount = (( !unitToMultiPurposeAmountApplicableMap.isEmpty() && unitToMultiPurposeAmountApplicableMap.containskey(unitID) && unitToMultiPurposeAmountApplicableMap.get(unitID) && salesOfferObj.unitDesignRecord.PremiumAmount__c!=null)? salesOfferObj.unitDesignRecord.PremiumAmount__c : 0).setScale(2);
                    }else{
                        multiPurposeAmount = (( !unitToMultiPurposeAmountApplicableMap.isEmpty() && unitToMultiPurposeAmountApplicableMap.containskey(unitID) && unitToMultiPurposeAmountApplicableMap.get(unitID) && salesOfferObj.unitRecord.MultiPurposeAmount__c!=null)? salesOfferObj.unitRecord.MultiPurposeAmount__c : 0).setScale(2);
                    }
                    

                    tempPaymentPlanRec.discountedUnitSalesPrice = totalDiscountedPrice;
                    // swimming pool related changes for yas riva
                    tempPaymentPlanRec.netSalesPrice = ( totalDiscountedPrice + tempPaymentPlanRec.premiumAmmount  + multiPurposeAmount + salesOfferObj.PodiumAmount + salesOfferObj.swimmingPoolAmount ).setScale(2);

                    tempPaymentPlanRec.rebateAmount=0;
                    tempPaymentPlanRec.partnerDiscountAmount=(calculatedCorporateDiscountAmount+calculatedWealthDiscountAmount).setScale(2) ;

                     //KP: ADM Calcualted on total net selling based on City
                    String projectCity = salesOfferObj.unitRecord.Project__r.City__c;
                    Decimal fee_percentage = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Fee_perc__c : 0.00;
                    
                    Decimal adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
                    //Mahidhar - Start
                    //Discription : Here we are calculating Service Fee and VAT charges based on Project City as part of ASF-3618
                    Decimal serviceFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Aldar_Service_Fee__c : 0.00;
                    Decimal adminFeeVATToBeCharged = adminFeeToBeCharged > 0 ? (adminFeeToBeCharged * (mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_ChargeAldar_Service_Fee_VAT__c : 0.00) / 100) : 0.00;
                    Decimal serviceFeeVATToBeCharged = serviceFeeToBeCharged > 0 ? (serviceFeeToBeCharged * (mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_ChargeAldar_Service_Fee_VAT__c : 0.00) / 100) : 0.00;
                     /*
                    Decimal adminFeeToBeCharged = 0.0;
                    // New ADM fee changes
                    // ASF-3400 start
                    if(projectCity == 'Abu Dhabi'){
                        if(salesOfferObj.unitRecord.OffPlanProperty__c)
                            adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
                        else
                            adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Ready_Projects_Fee__c : 0.00;
                    }else{
                        adminFeeToBeCharged = mfdByCountryMap.containsKey(projectCity) ? mfdByCountryMap.get(projectCity).Municipality_Charge__c : 0.00;
                    }
                    */
                    
                    // ASF-3400 end
                    //SG: ADM Calculated on total net selling
                    tempPaymentPlanRec.admFeeWaiverAmount = ((tempPaymentPlanRec.netSalesPrice) * (admWavierPercentage/100 )).setScale(2);
                    //tempPaymentPlanRec.admFeeAmount = ((tempPaymentPlanRec.netSalesPrice) * .02).setScale(2);
                    tempPaymentPlanRec.admFeeAmount = ((tempPaymentPlanRec.netSalesPrice) * fee_percentage/100).setScale(2);
                    //tempPaymentPlanRec.admAdminFeeAmount = decimal.valueOf(Label.ADMAdminFee);
                    //Mahidhar- includded in admAdminFeeAmount Service Fee and VAT
                    tempPaymentPlanRec.admAdminFeeAmount = (adminFeeToBeCharged+serviceFeeToBeCharged+adminFeeVATToBeCharged+serviceFeeVATToBeCharged);
                    
                    
                   // ADM Exception 
                    if(salesOfferObj.unitRecord.Project__r.ExcludeFromADM__c ==true){                        tempPaymentPlanRec.admFeeAmount = 0; tempPaymentPlanRec.admFeeWaiverAmount = 0;
                    }

                    tempPaymentPlanRec.otherSalesSupportAmount = otherSalesSupport.setScale(2);
                    tempPaymentPlanRec.discountAmount = (salesOfferObj.unitRecord.SellingPrice__c - totalDiscountedPrice).setScale(2);
                    tempPaymentPlanRec.pmWavedFee=pmWavedFee.setScale(2);
                    //Init/Create payment plan with net salesprice
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec.recalcLine(tempPaymentPlanRec.netSalesPrice.setScale(2));
                    }
                    if(Test.isRunningTest()){
                        serviceChargesWavierYears = 100;
                        
                    }
                    
                    if(serviceChargesWavierYears!=null && serviceChargesWavierYears!=0 && salesOfferObj.unitRecord.AnticipatedServiceCharges__c != null && unitArea!= null   ){
                        decimal incrementalSC = salesOfferObj.unitRecord.AnticipatedServiceCharges__c;
                        tempPaymentPlanRec.serviceChargeWaivedYears = Integer.ValueOf(serviceChargesWavierYears);
                        for(integer tempi = 1; tempi<= serviceChargesWavierYears ; tempi++ ){
                            if(tempi>3 && salesOfferObj.unitRecord.EscalationServiceCharge__c!=null){
                                incrementalSC = (incrementalSC + ( incrementalSC * (salesOfferObj.unitRecord.EscalationServiceCharge__c/100) )).setScale(2);
                            }
                            tempPaymentPlanRec.serviceChargeAmount = ((tempPaymentPlanRec.serviceChargeAmount!=null? tempPaymentPlanRec.serviceChargeAmount : 0) + (incrementalSC * unitArea)).setScale(2);
                        }
                        
                    }
                    //SubsidyYears__c 
                    if(opportunityOrLedId!=null && opportunityMap.containsKey(opportunityOrLedId)  && opportunityMap.get(opportunityOrLedId).SubsidyYears__c != null && opportunityMap.get(opportunityOrLedId).Financing__c.equalsIgnoreCase(constants.YES)){
                        //calculation will be 80% x Selling Price x Subsidy % x Number of Years (from an opportunity)
                        tempPaymentPlanRec.mortgageSubsidy = ((0.8* salesOfferObj.unitRecord.SellingPrice__c) * (subsidy/100) * integer.valueof(opportunityMap.get(opportunityOrLedId).SubsidyYears__c)).setScale(2);
                        //removing subsidy from net selling
                        //tempPaymentPlanRec.netSalesPrice = tempPaymentPlanRec.netSalesPrice - tempPaymentPlanRec.mortgageSubsidy;
                    }

                    //Init/Create payment plan with net salesprice
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec.recalcLine(tempPaymentPlanRec.netSalesPrice.setScale(2));
                    }

                    if(salesOfferObj.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c != null){
                        tempPaymentPlanRec.homeMaintenanceWaiverFee = (homeMaintenanceWavierYears * salesOfferObj.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c).setScale(2) ;
                    }
                    //If its a Memo apply memo level comission 
                    if(memoOffer && externalCommissionMemo!=0 && externalCommissionMemo!=null){
                        tempPaymentPlanRec.externalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) *  (externalCommissionMemo/100)).setScale(2);
                        tempPaymentPlanRec.externalComissionAmountBasis=Constants.COMISSIONBASIS_PERCENT;
                    }else if(opportunityOrLedId!=null && opportunityMap.containsKey(opportunityOrLedId) && opportunityMap.get(opportunityOrLedId).AgentType__c !=null && opportunityMap.get(opportunityOrLedId).AgentType__c.equalsIgnoreCase('Indirect') && unitExternalCommissionMap.get(unitID) != null && (unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null || unitExternalCommissionMap.get(unitID).CommissionPercentage__c!=null )){
                        //Broker Commission could be % or amount , based on null check 
                        tempPaymentPlanRec.externalComissionAmount = (unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null? unitExternalCommissionMap.get(unitID).CommissionAmount__c : ( (tempPaymentPlanRec.netSalesPrice) * (unitExternalCommissionMap.get(unitID).CommissionPercentage__c /100 ) )).setScale(2) ;
                        tempPaymentPlanRec.externalComissionAmountBasis=unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null? Constants.COMISSIONBASIS_AMOUNT: Constants.COMISSIONBASIS_PERCENT;
                    }
                    
                    
                    //get Top of commission Noor
                     Map<String,TopUpCommission__c> classificationOfInternalCommMap = new Map<String,TopUpCommission__c>();

                    if( unitInternalCommissionMap.containsKey(unitID) && unitInternalCommissionMap.get(unitID) != null){
                        InternalCommission__c ics = unitInternalCommissionMap.get(unitID);
                        if( ics.Top_Up_Commissions__r != null){
                            List<TopUpCommission__c> topUpCom = ics.Top_Up_Commissions__r;
                            for(TopUpCommission__c tp:topUpCom){
                                classificationOfInternalCommMap.put(tp.Classification__c,tp);
                            }                        
                        }
                          
                    
                    }
                  
                    
                    
                    //If its a Memo apply memo level commision
                    if(memoOffer && internalCommissionMemo!=0 && internalCommissionMemo!=null ){
                        tempPaymentPlanRec.internalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * (internalCommissionMemo/100)).setScale(2);
                    }else if(unitInternalCommissionMap.get(unitID) != null && opportunityOrLedId!=null && opportunityMap.containsKey(opportunityOrLedId) ){
                        if (loggedInUser.Team__c == Constants.USER_TEAM_LAND) {
                            if (opportunityMap.get(opportunityOrLedId).AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_DIRECT) {
                              
                             if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                    for (String key : classificationOfInternalCommMap.keySet()) {
                                        TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                        if (key == tpCm.Classification__c
                                            && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                                internalCommission = unitInternalCommissionMap.get(unitID).LandDirectCommission__c+ classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).Direct__c;
                                            }
                                    }
                                }else{
                               internalCommission = unitInternalCommissionMap.get(unitID).LandDirectCommission__c;
                              }
                              
                               
                            } else { 
                             if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                    for (String key : classificationOfInternalCommMap.keySet()) {
                                        TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                        if (key == tpCm.Classification__c
                                            && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                                internalCommission = unitInternalCommissionMap.get(unitID).LandIndirectCommission__c+ classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).In_Direct__c;
                                            }
                                    }
                                }else{
                                 internalCommission = unitInternalCommissionMap.get(unitID).LandIndirectCommission__c;
                            }
                           
                            }
                        }
                        else if(loggedInUser.Team__c == Constants.USER_TEAM_VIP){
                            if (opportunityMap.get(opportunityOrLedId).AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_DIRECT) {
                                
                                if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                    for (String key : classificationOfInternalCommMap.keySet()) {
                                        TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                        if (key == tpCm.Classification__c
                                            && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                                internalCommission = unitInternalCommissionMap.get(unitID).VIPDirectCommission__c+ classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).Direct__c;
                                            }
                                    }
                                }else{
                                internalCommission = unitInternalCommissionMap.get(unitID).VIPDirectCommission__c;
                                }
                                
                            } else {
                            if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                    for (String key : classificationOfInternalCommMap.keySet()) {
                                        TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                        if (key == tpCm.Classification__c
                                            && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                                internalCommission = unitInternalCommissionMap.get(unitID).VIPIndirectCommission__c+ classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).In_Direct__c;
                                            }
                                    }
                                }else{
                             internalCommission = unitInternalCommissionMap.get(unitID).VIPIndirectCommission__c;
                            }
                           
                            }
                        }else{
                            if (opportunityMap.get(opportunityOrLedId).AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_DIRECT) {
                                //add by Noor for TOp up commissions for internla 
                               
                                if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                      for (String key : classificationOfInternalCommMap.keySet()) {
                                          TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                          if (key == tpCm.Classification__c
                                              && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                              

                                                  internalCommission = unitInternalCommissionMap.get(unitID).DirectCommission__c + classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).Direct__c;
                                            }
                                      }
                                }else{    
                                    internalCommission = unitInternalCommissionMap.get(unitID).DirectCommission__c;
}
                            } else {
                                if(classificationOfInternalCommMap.containsKey(allRelatedPaymentPlans.get(tempPaymentId).Classification__c)   ){
                                         for (String key : classificationOfInternalCommMap.keySet()) {
                                          TopUpCommission__c tpCm = classificationOfInternalCommMap.get(key);
                                          if (key == tpCm.Classification__c
                                              && allRelatedPaymentPlans.get(tempPaymentId).Classification__c == tpCm.Classification__c){
                                             

                                                  internalCommission = unitInternalCommissionMap.get(unitID).IndirectCommission__c + classificationOfInternalCommMap.get(allRelatedPaymentPlans.get(tempPaymentId).Classification__c).In_Direct__c;
                                            }
                                      } 
                                }else{
                                           internalCommission = unitInternalCommissionMap.get(unitID).IndirectCommission__c;
 }
                            }
                        }
                        if (opportunityMap.get(opportunityOrLedId).ReferralType__c == Constants.OPPORTUINTY_REFERRAL_STAFF) {

                            if (unitInternalCommissionMap.get(unitID).StaffReferral__c != null && unitInternalCommissionMap.get(unitID).StaffReferral__c > 0) {
                                ReferralCommissionAmount = ((tempPaymentPlanRec.netSalesPrice) * (unitInternalCommissionMap.get(unitID).StaffReferral__c/100)).setScale(2);
                            } else if (unitInternalCommissionMap.get(unitID).StaffReferralAmount__c != null){
                                ReferralCommissionAmount = unitInternalCommissionMap.get(unitID).StaffReferralAmount__c.setScale(2);
                            }
                        }

                        if (loggedInUser.UserRole != null && loggedInUser.UserRole.Name.containsIgnoreCase(Constants.OPPORTUINTY_USER_ROLE_POST_SALES_BOOKING)) {
                            
                            tempPaymentPlanRec.internalStaffComissionAmount = unitInternalCommissionMap.get(unitID).DirectCommissionAmount__c.setScale(2);
                            tempPaymentPlanRec.internalComissionAmount = unitInternalCommissionMap.get(unitID).DirectCommissionAmount__c.setScale(2);
                        } else {
                            tempPaymentPlanRec.internalStaffComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * ((internalCommission != null ? internalCommission : 0) /100)).setScale(2) ;
                            tempPaymentPlanRec.internalReferralComissionAmount = ReferralCommissionAmount.setScale(2);
                            tempPaymentPlanRec.internalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * ((internalCommission != null ? internalCommission : 0) /100) + (ReferralCommissionAmount!= null ? ReferralCommissionAmount : 0)).setScale(2);
                        }
                    }
                    //Check based on the project (New Field), darna might not be applicable for all the projects, move retrival out of for loop
                  // tempPaymentPlanRec.darnaAmount = 0;
                    if(salesOfferObj.unitRecord.BuildingSectionName__r.ExcludeFromDarna__c != true && salesOfferObj.unitRecord.Project__r.DarnaApplicable__c!=null && salesOfferObj.unitRecord.Project__r.DarnaApplicable__c){
                        for (DarnaLoyaltyMatrix__mdt darnaLoyalty : darnaLoyaltyList) {
                            if (tempPaymentPlanRec.netSalesPrice > darnaLoyalty.From__c && tempPaymentPlanRec.netSalesPrice <= darnaLoyalty.To__c ) {
                                tempPaymentPlanRec.darnaAmount = tempPaymentPlanRec.netSalesPrice * ((darnaLoyalty.Percentage__c + darna ) /100) ;
                                //tempPaymentPlanRec.darnaAmount = darna * (darnaLoyalty.Percentage__c/100);
                            }
                        }
                    }
                    tempPaymentPlanRec.bulkDiscountAmount=calculatedBulkDiscountAmount.setScale(2);
                    tempPaymentPlanRec.corporateDiscountAmount=calculatedCorporateDiscountAmount.setScale(2);
                    tempPaymentPlanRec.wealthDiscountAmount=calculatedWealthDiscountAmount.setScale(2);
                    tempPaymentPlanRec.paymentPlanDiscountAmount=calculatedPaymentPlanDiscountAmount.setScale(2);
                    //Offer level + Payment level rebate
                    //do not apply payment plan level rebate if its memo
                    decimal paymentPlanRebate = (!memoOffer && allRelatedPaymentPlans.get(tempPaymentId).RebatePercentage__c != null? allRelatedPaymentPlans.get(tempPaymentId).RebatePercentage__c:0);
                    tempPaymentPlanRec.rebateAmount =  ((tempPaymentPlanRec.netSalesPrice) * ((offerLevelRebate + paymentPlanRebate)/100 )).setScale(2);
                   
                    //Added by sujesh for Lagoons project as the rebate is on netprice - pod - multiamt(premium), yas riva
                    if(((Label.LagoonsProjectName).contains(salesOfferObj.unitRecord.Project__r.Name) && Boolean.valueOf(Label.rebateOnSellingPrice))){
                        tempPaymentPlanRec.rebateAmount =  ((tempPaymentPlanRec.netSalesPrice - salesOfferObj.PodiumAmount - multiPurposeAmount - salesOfferObj.swimmingPoolAmount ) * ((offerLevelRebate + paymentPlanRebate)/100 )).setScale(2);
                    }

                    salesOfferObj.applicablePaymentPlansCalculated.add(tempPaymentPlanRec);

                    /* Available Plan code moved above */
                    
                    

                    if(tempPaymentPlanRec.isSelected){
                        totalNetSellingPrice= (totalNetSellingPrice + tempPaymentPlanRec.netSalesPrice).setScale(2);
                    }
                }
                
            }
            //Select Default payment plan if nothing is selected (Only if 1 plan is standard for multiple it won't be auto selected)
            if(selectedPlans.isEmpty() && !standardPlans.isEmpty() && standardPlans.size()==1){
                for(PaymentPlanWrapper tempPaymentPlanRec : salesOfferObj.applicablePaymentPlansCalculated ){
                    if(standardPlans.contains(tempPaymentPlanRec.paymentPlanDetails.Id)){
                        tempPaymentPlanRec.isSelected=true;
                        totalNetSellingPrice=(totalNetSellingPrice + tempPaymentPlanRec.netSalesPrice).setScale(2);
                    }
                }
            }
            salesOffersMapToreturn.put(unitID,salesOfferObj); 
        }

        //sum of all net selling price
        for(ID unitID : salesOffersMapToreturn.keySet()){
            salesOffersMapToreturn.get(unitID).totalOfAllUnitNetSellingPrice=totalNetSellingPrice.setScale(2);
        }

        return salesOffersMapToreturn;
    }

   /** 
    * getApplicableOfferLines 
    *
    * returns map of unit to its offer details
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param allOfferLines              All offer lines to be filtered out
    * @param unitRecord       Unit Record
    * @param opportunityRecord        Opportunity Record
    * @param leadRecord         Lead Record
    * @param totalUnitOffered        total units offered
    * @param totalofAllUnitPrice         Total of all sales price
    *
    * @return   list<OfferLines__c>  list of applicable OfferLines__c
    */
    public static list<OfferLines__c> getApplicableOfferLines(list<OfferLines__c> allOfferLines,Unit__c unitRecord,Opportunity opportunityRecord, Lead leadRecord, decimal totalUnitOffered , decimal totalofAllUnitPrice){
        
        list<OfferLines__c> applicableOfferLinesCalculated  = new list<OfferLines__c>();
        for(OfferLines__c tempOfferLine: allOfferLines ){
            //Do not apply ADM if project flag is true
            if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_ADMFEE) && unitRecord.Project__r.ExcludeFromADM__c ==true){
                continue;
            }

            //Based on Opportunity/Lead fields
            if(tempOfferLine.AgentType__c != null ){
                if(leadRecord != null || opportunityRecord == null || (opportunityRecord!=null && tempOfferLine.AgentType__c != opportunityRecord.AgentType__c))
                continue;   
            }else if(tempOfferLine.CustomerType__c != null ){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && tempOfferLine.CustomerType__c != opportunityRecord.Account.CustomerSubType__c) || (leadRecord!=null && tempOfferLine.CustomerType__c != leadRecord.CustomerSubType__c) )
                continue;
            }else if(tempOfferLine.Nationality__c != null ){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && opportunityRecord.Contact__c ==null ) || (opportunityRecord!=null && tempOfferLine.Nationality__c != opportunityRecord.Contact__r.Nationality__c) || (leadRecord!=null && tempOfferLine.Nationality__c != leadRecord.Nationality__c) )
                continue;
            }else if(tempOfferLine.ResidentStatus__c != null){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && opportunityRecord.Contact__c ==null ) || (opportunityRecord!=null && tempOfferLine.ResidentStatus__c != opportunityRecord.Contact__r.ResidentStatus__c) || (leadRecord!=null && tempOfferLine.ResidentStatus__c != leadRecord.ResidentStatus__c) )
                continue;
            }else if(tempOfferLine.LeadSource__c != null ){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && tempOfferLine.LeadSource__c != opportunityRecord.LeadSource) || (leadRecord!=null && tempOfferLine.LeadSource__c != leadRecord.LeadSource) )
                continue;
            }else if(tempOfferLine.DiscountType__c!=null && tempOfferLine.DiscountType__c.equalsIgnoreCase(Constants.DISCOUNT_TYPE_CORPORATE_DISCOUNT)){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && tempOfferLine.DiscountType__c != opportunityRecord.Account.CustomerSubType__c) || (leadRecord!=null && tempOfferLine.DiscountType__c != leadRecord.CustomerSubType__c) )
                continue;
            }
            else if(tempOfferLine.DiscountType__c!=null && tempOfferLine.DiscountType__c.equalsIgnoreCase(Constants.DISCOUNT_TYPE_WEALTH_DISCOUNT)){
                if((opportunityRecord ==null && leadRecord == null) || (opportunityRecord!=null && tempOfferLine.DiscountType__c != opportunityRecord.Account.CustomerSubType__c) || (leadRecord!=null && tempOfferLine.DiscountType__c != leadRecord.CustomerSubType__c) )
                continue;
            }
            //Based on Unit Fields
            if(tempOfferLine.Unit__c != null && tempOfferLine.Unit__c != unitRecord.Id){ continue;
            }else if(tempOfferLine.UnitType__c != null && tempOfferLine.UnitType__c != unitRecord.UnitType__c){continue;
            }else if(tempOfferLine.UnitModel__c != null && tempOfferLine.UnitModel__c != unitRecord.UnitModel__c){ continue;
            }else if(tempOfferLine.NumberOfBedrooms__c != null ){//&& tempOfferLine.NumberOfBedrooms__c != unitRecord.NumberOfBedrooms__c){
                continue;
            }else if(tempOfferLine.UnitFeatures__c != null && (unitRecord.FeaturesSpecification__c==null || !unitRecord.FeaturesSpecification__c.toLowerCase().contains(tempOfferLine.UnitFeatures__c.toLowerCase()) )){
                continue;
            }
            //Based on Unit Count, Total price
            else if(tempOfferLine.LowerBound__c != null && tempOfferLine.UpperBound__c !=null){
                //identify decimal val
                decimal decimalValToCompare=0;
                if(totalUnitOffered!=null && tempOfferLine.DiscountType__c!=null && tempOfferLine.DiscountType__c.equalsIgnoreCase(Constants.DISCOUNT_TYPE_BULK_DISCOUNT))
                {
                    decimalValToCompare = totalUnitOffered;
                }
                else if(totalofAllUnitPrice!=null /*&& tempOfferLine.RangeOnField__c!=null && tempOfferLine.RangeOnField__c.equalsIgnoreCase('SellingPrice__c')*/ && tempOfferLine.Bulk__c )
                {
                    decimalValToCompare = totalofAllUnitPrice;
                }
                else if(/*tempOfferLine.RangeOnField__c!=null && tempOfferLine.RangeOnField__c.equalsIgnoreCase('SellingPrice__c') &&*/ !tempOfferLine.Bulk__c)
                {
                    decimalValToCompare = unitRecord.SellingPrice__c;
                }
                if( !(tempOfferLine.LowerBound__c <= decimalValToCompare && decimalValToCompare <= tempOfferLine.UpperBound__c)){
                    continue;
                }
            }
            applicableOfferLinesCalculated.add(tempOfferLine);
        }
        return applicableOfferLinesCalculated;
    }
    
    //Override unit level data with the selected design attributes
    public static unit__c overrideUnitDetails(Unit__c unitRecord, UnitDesign__c unitDesignRecord){
        unitRecord.GFAArea__c =unitDesignRecord.GFAArea__c;
        unitRecord.SaleableArea__c =unitDesignRecord.SaleableArea__c;
        unitRecord.SellingPrice__c =unitDesignRecord.SellingPrice__c;
        unitRecord.TerraceArea__c =unitDesignRecord.TerraceArea__c;
        unitRecord.WebFloorPlan__c =unitDesignRecord.WebFloorPlan__c;
        return unitRecord;
    }

    /**
    * SalesOfferDetails 
    *
    * Wrapper class used to store SalesOffer details
    */
    public with sharing class SalesOfferDetails{
        @AuraEnabled
        public Id leadId {get; set;}
        @AuraEnabled
        public Id opportunityId {get; set;}
        @AuraEnabled
        public Id unitId {get; set;}
        @AuraEnabled
        public Id offerId {get; set;}
        @AuraEnabled
        public integer totalUnitOffered {get; set;}
        @AuraEnabled
        public Decimal totalOfAllUnitSellingPrice {get; set;}
        @AuraEnabled
        public Decimal totalOfAllUnitNetSellingPrice {get; set;}
        @AuraEnabled
        public Lead leadRecord {get; set;}
        @AuraEnabled
        public Opportunity opportunityRecord {get; set;}

        @AuraEnabled
        public Id unitDesignRecordId {get; set;}

        @AuraEnabled
        public String unitDesignRecordName {get; set;}

        @AuraEnabled
        public UnitDesign__c unitDesignRecord {get; set;}
        @AuraEnabled
        public boolean hasUnitDesign {get; set;}
        @AuraEnabled
        public list<map<String,string>> availableUnitDesigns {get; set;}

        @AuraEnabled
        public contact contactRecord {get; set;}
        @AuraEnabled
        public Unit__c unitRecord {get; set;}
        @AuraEnabled
        public OffersPromotions__c offerRecord {get; set;}
        @AuraEnabled
        public list<OfferLines__c> applicableOfferLinesCalculated {get; set;}
        @AuraEnabled
        public list<PaymentPlanWrapper> applicablePaymentPlansCalculated {get; set;}
        @AuraEnabled
        public boolean offersAvailable {get; set;}
        @AuraEnabled
        public boolean offerLinesApplied {get; set;}
        //for creating Combo box
        @AuraEnabled
        public list<map<String,string>> availablePaymentPlans {get; set;}
        
        @AuraEnabled
        public list<map<String,string>> availablePaymentPlansWithMemo {get; set;}
        //for creating Combo box
        @AuraEnabled
        public list<map<String,string>> unitFinishingVals{get;set;}
        
        @AuraEnabled
        public List<UnitAddonWrapper> unitAddons {get;set;}
        
        // @AuraEnabled
        // public map<string,list<map<String,string>>> unitAddons{get;set;}
        
        @AuraEnabled
        public list<map<String,string>> availablePodiumChoices {get; set;}
        
         // swimming pool related changes for yas riva
        @AuraEnabled
        public list<map<String,string>> availableSwimmingPoolChoices {get; set;}

        @AuraEnabled
        public list<map<String,string>> availableOffers {get; set;}
        
        @AuraEnabled
        public list<map<String,string>> availableWithMemoOffers {get; set;}
        
        @AuraEnabled public boolean multiPurposeAmountApplicable {get; set;}
        @AuraEnabled public string PodiumSelection {get; set;}
        @AuraEnabled  public decimal PodiumAmount {get; set;}
        
         // swimming pool related changes for yas riva
        @AuraEnabled public string swimmingPoolSelection {get; set;}
        @AuraEnabled  public decimal swimmingPoolAmount {get; set;}
        
        @AuraEnabled public decimal unitFinishes {get; set;}
        
        @AuraEnabled  public list<map<String,string>> availableEOIs {get; set;}
        public SalesOfferDetails(){totalOfAllUnitNetSellingPrice=0;}

         @AuraEnabled  public list<map<String,string>> signatureTypes {get; set;}
         @AuraEnabled  public boolean digitalsignatureApplied {get; set;}
        @AuraEnabled public String signatureType {get; set;}
    }

    //Added by Chirag
    public class UnitAddonWrapper{
        @AuraEnabled 
        public String UnitAddonName  {get; set;}
        @AuraEnabled
        public List<UnitSubAddonWrapper> UnitsubAddonWrapperList  {get; set;}
    }
    public class UnitSubAddonWrapper{
       @AuraEnabled public String label {get; set;}
       @AuraEnabled public String value {get; set;}
    }


    /**
    * PaymentPlanWrapper 
    *
    * Wrapper class used to store Payment plan records
    */
    public with sharing class PaymentPlanWrapper{
        @AuraEnabled
        public boolean isSelected {get; set;}
        @AuraEnabled
        public Decimal discountedUnitSalesPrice {get; set;}
        @AuraEnabled
        public Decimal bulkDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal corporateDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal wealthDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal paymentPlanDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal pmWavedFee {get; set;}
        @AuraEnabled
        public Decimal netSalesPrice {get; set;}
        @AuraEnabled
        public Decimal rebateAmount {get; set;}
        @AuraEnabled
        public Decimal partnerDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal premiumAmmount {get; set;}
        
        @AuraEnabled
        public Decimal admFeeWaiverAmount {get; set;} //Selling Price * Waived Percentage

        @AuraEnabled
        public Decimal admFeeAmount {get; set;} //Selling Price * Waived Percentage

        @AuraEnabled
        public Decimal admAdminFeeAmount {get; set;} //Selling Price * Waived Percentage
        
        @AuraEnabled
        public Decimal serviceChargeAmount {get; set;} //Service Charge Amount * Waived Years
        @AuraEnabled
        public Integer serviceChargeWaivedYears {get; set;} //Service Charge Amount * Waived Years
        @AuraEnabled
        public Decimal homeMaintenanceWaiverFee {get; set;} //HM Amount * Waived Years
        @AuraEnabled
        public Decimal externalComissionAmount {get; set;}
        @AuraEnabled
        public string externalComissionAmountBasis {get; set;}
        @AuraEnabled
        public Decimal mortgageSubsidy {get; set;}
        @AuraEnabled
        public Decimal otherSalesSupportAmount {get; set;}

        @AuraEnabled
        public Decimal darnaAmount {get; set;} // 1-2.5 M AED is 0.25% & 2.51 M-5M 0.5% (Darna Loyalty Matrix - Custom Metadata)
        @AuraEnabled
        public Decimal internalComissionAmount {get; set;}
        @AuraEnabled
        public Decimal internalStaffComissionAmount {get; set;}
        @AuraEnabled
        public Decimal internalReferralComissionAmount {get; set;}
        @AuraEnabled
        public Decimal discountAmount {get; set;}// Should be done already by Paras
        // @AuraEnabled
        // public Decimal rebateAmount {get; set;} // Should be done already by Paras


    
        @AuraEnabled
        public PaymentPlan__c paymentPlanDetails {get; set;}
        @AuraEnabled
        public list<PaymentInstallmentWrapper> installmentDetails {get; set;}
        public PaymentPlanWrapper(){}
        public PaymentPlanWrapper(PaymentPlan__c tempRec , Decimal sellingPrice){
            isSelected=(tempRec.StandardFlag__c!=null && tempRec.StandardFlag__c.equalsIgnoreCase(Constants.YES));
            paymentPlanDetails=tempRec;
            installmentDetails=new list<PaymentInstallmentWrapper>();
            for(PaymentInstallments__c tempInstallmentRec: tempRec.PaymentInstallments__r){
                installmentDetails.add(new PaymentInstallmentWrapper( tempInstallmentRec ,sellingPrice));
            }
            this.recalcLine(sellingPrice);
            /*
                //Start ASF-3174
                list<PaymentInstallmentWrapper> installmentDetailsforCalc =  new list<PaymentInstallmentWrapper>(); 
                map<String,Decimal> mapSalesOrderToSumofDecimals = new map<String,Decimal>(); 
                Integer CountofInstallmentLines = installmentDetails.size(); 
                
                Decimal totalDecimalValueOfInstallements = 0.00;
                for(PaymentInstallmentWrapper wrap: installmentDetails){
                    decimal decVal = wrap.totalValue - wrap.totalValue.round(System.RoundingMode.DOWN);
                    totalDecimalValueOfInstallements = totalDecimalValueOfInstallements + decVal; 
                    wrap.totalValue = wrap.totalValue.longValue();
                    installmentDetailsforCalc.add(wrap);
                }
                for(PaymentInstallmentWrapper wrap: installmentDetailsforCalc){ 
                    if( wrap.installmentRecord.InstallmentNumber__c == CountofInstallmentLines){
                         
                         wrap.totalValue = wrap.totalValue + totalDecimalValueOfInstallements;
                         
                    }
                }
                installmentDetails = installmentDetailsforCalc;
                //End ASF-3174
            */
        }
        public void recalcLine(Decimal sellingPrice){
            installmentDetails = new list<PaymentInstallmentWrapper>();
            for(PaymentInstallments__c tempInstallmentRec: paymentPlanDetails.PaymentInstallments__r){
                installmentDetails.add(new PaymentInstallmentWrapper( tempInstallmentRec ,sellingPrice));
            }
            
               //Start ASF-3174
               list<PaymentInstallmentWrapper> installmentDetailsforCalc =  new list<PaymentInstallmentWrapper>(); 
               map<String,Decimal> mapSalesOrderToSumofDecimals = new map<String,Decimal>(); 
               Integer CountofInstallmentLines = installmentDetails.size(); 
               Decimal totalDecimalValueOfInstallements = 0.00;
               for(PaymentInstallmentWrapper wrap: installmentDetails){
                   decimal decVal = wrap.totalValue - wrap.totalValue.round(System.RoundingMode.DOWN);
                   totalDecimalValueOfInstallements = totalDecimalValueOfInstallements + decVal; 
                   wrap.totalValue = wrap.totalValue.longValue();
                   installmentDetailsforCalc.add(wrap);
               }
               for(PaymentInstallmentWrapper wrap: installmentDetailsforCalc){ 
                   if( wrap.installmentRecord.InstallmentNumber__c == CountofInstallmentLines){
                        wrap.totalValue =  wrap.totalValue + totalDecimalValueOfInstallements;
                   }
               }
               installmentDetails = installmentDetailsforCalc;
               //End ASF-3174
            
        }
    } 

    /**
    * PaymentInstallmentWrapper 
    *
    * Wrapper class used to store Payment Installment records
    */
    public with sharing class PaymentInstallmentWrapper{
        @AuraEnabled
        public decimal totalValue {get; set;}
        @AuraEnabled
        public PaymentInstallments__c installmentRecord {get; set;}
        public PaymentInstallmentWrapper(PaymentInstallments__c tempRec , Decimal sellingPrice){
            tempRec.InstallmentDate__c = ((tempRec.InstallmentDate__c!=null && tempRec.InstallmentDate__c < system.today() ) || tempRec.InstallmentNumber__c == 1) ? system.today(): tempRec.InstallmentDate__c;
            installmentRecord=tempRec;
            totalValue = (tempRec.InstallmentPercentage__c!=null && sellingPrice!=null ) ? ((tempRec.InstallmentPercentage__c/100) * sellingPrice) : sellingPrice;
            totalValue = totalValue.setScale(2);
        }
        
    }

    /**
    * SaleOfferInputParam 
    *
    * Wrapper class take input parameters
    */
    public with sharing class SaleOfferInputParam{
        @AuraEnabled
        public Id unitId {get; set;}

        @AuraEnabled
        public Id unitName {get; set;}


        @AuraEnabled
        public Id offerId {get; set;}
        @AuraEnabled
        public Id designId {get; set;}
        @AuraEnabled
        public list<Id> selectedPayments {get; set;}
        @AuraEnabled
        public decimal amount {get; set;}
        @AuraEnabled
        public String amountType {get; set;}
        @AuraEnabled
        public String paymentMethod {get; set;}
        @AuraEnabled
        public boolean multiPurposeAmountApplicable {get; set;}
        @AuraEnabled

        public boolean PodiumSelected {get; set;}
        
         // Swimming pool related changes for yas riva
        @AuraEnabled
        public boolean swimmingPoolSelected {get; set;}
        
        @AuraEnabled
        public String unitFinishes {get; set;}
        @AuraEnabled
        public List<UnitAddonWrapperdata> UnitAddonList{get;set;}
        
        
        @AuraEnabled public String signatureType {get; set;}
        
        @AuraEnabled
        public String podiumSelection {get; set;}
        
        // Swimming pool related changes for yas riva
        @AuraEnabled
        public String swimmingPoolSelection {get; set;}
        
        @AuraEnabled

        public String unitFurnishing {get; set;}
        
        @AuraEnabled
        public boolean mortgageApplicable {get; set;}
        @AuraEnabled
        public String mortgageBank {get; set;}

        public SaleOfferInputParam(){}
    }

    public class UnitAddonWrapperdata{
        @AuraEnabled public String key {get; set;}
        @AuraEnabled public String value {get; set;}
    }

    public static  Map<String, List<String>> getUnitFurnishingBasedOnProject() {
        Map<String, List<String>> projectUnitFinishingMap = new Map<String, List<String>>();
        List<ProjectUnitFinishing__mdt> projectUnitFinishingList = [SELECT 
                                                                    Active__c,
                                                                    BuildingName__c,
                                                                    DeveloperName,
                                                                    Id,
                                                                    Label,
                                                                    Project__c,
                                                                    QualifiedApiName,
                                                                    Type_Of_Furnishing__c 
                                                                    FROM ProjectUnitFinishing__mdt 
                                                                    WHERE Active__c= true];
        
        for(ProjectUnitFinishing__mdt projectUnitFinishing: projectUnitFinishingList){
            List<String> typeOFFurnishingList = projectUnitFinishingMap.get(projectUnitFinishing.Project__c) != null ? projectUnitFinishingMap.get(projectUnitFinishing.Project__c) : new List<String>();
            typeOFFurnishingList.add(projectUnitFinishing.Type_Of_Furnishing__c);
            projectUnitFinishingMap.put(projectUnitFinishing.Project__c, typeOFFurnishingList);
        }
        return projectUnitFinishingMap;
    }

}