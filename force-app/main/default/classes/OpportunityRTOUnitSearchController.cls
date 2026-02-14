/**********************************************************************************************************************
* Name               : OpportunityRTOUnitSearchController                                                        
* Description        : This class is used as controller for LWC (OpportunityRTOUnitSearch)
* Usage              : OpportunityRTOUnitSearch LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                       Date            Comment                                                                       
* 1.0           ajay.thakur.tpr@pwc.com     23 Aug 2022      Initial Draft       
******************************************************************************************************************/
public without sharing class OpportunityRTOUnitSearchController{
    
    /**
    * getsObjectType 
    *
    * return sobjectType and relevent fields
    * 
    * @usage OpportunityRTOUnitSearch LWC
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
                mapToReturn.put(sobjectName,[select id,CurrencyISOCode,Project__c,CustomerResidentStatus__c,DeliveryMethod__c,Account.CorporateWealthName__c,Name,SaleType__c,DealType__c,BookingType__c,AgentType__c,ReferralType__c,BankName__c,BrokerAgentName__c,BrokerAgencyAccount__c,EmployeeName__c,SubsidyYears__c,BrokerAgencyAccount__r.Name from Opportunity where id = :recordID limit 1]);
            }
            return mapToReturn;
        }
        
    
    
        
        /**
        * fechYearValues 
        *
        * return RTOConfiguration__c.Years__c field values
        * 
        * @usage OpportunityRTOUnitSearch LWC
        *
        * @param none
        * @return    list<map<String,string>> list of select options 
        * 
        */
        @AuraEnabled(cacheable=true)
        public static list<map<String,string>> fechYearValues(){
            list<map<String,string>> filtersToReturn = new list<map<String,string>>();
            list<map<String,string>> picklistToReturn = new list<map<String,string>>();
            map<string,string> blankVal=new map<string,string>();
            Schema.DescribeFieldResult fieldResult = RTOConfiguration__c.Years__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for( Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()){
                map<string,string> tempMap=new map<string,string>();
                tempMap.put('label',pickListVal.getLabel());
                tempMap.put('value',pickListVal.getValue());
                picklistToReturn.add(tempMap);
            }
            return picklistToReturn;        
        }
        
        /**
        * getAllProjects 
        *
        * return available projects
        * 
        * @usage PpportunityRTOUnitSearch LWC
        *
        * @param none
        * @return   list<map<String,string>>  list of select options 
        * 
        */
        @AuraEnabled(cacheable=true)
        public static list<map<String,string>> getAllProjects(){
            System.debug('------>');
            list<map<String,string>> filtersToReturn = new list<map<String,string>>();
            for(Project__c tempProject: ProjectService.getAllActiveProjects() ){
                map<string,string> tempMap=new map<string,string>();
                tempMap.put('label',tempProject.Name);
                tempMap.put('value',tempProject.id);
                filtersToReturn.add(tempMap);
            }
            System.debug('------>'+ProjectService.getAllActiveProjects());
            return filtersToReturn;
        }
        
    
        
        /**
        * getAllBuildings 
        *
        * return available Buildings for given Project
        * 
        * @usage OpportunityRTOUnitSearch LWC
        *
        * @param projectId - Project Id
        * @return   list<map<String,string>>  list of select options 
        * 
        */
        @AuraEnabled(cacheable=true)
        public static list<map<String,string>> getAllBuildings(string projectId){
            list<map<String,string>> filtersToReturn = new list<map<String,string>>();
                for(BuildingSection__c  tempBuilding: BuildingSectionService.prepareBuildingsNames(projectId) ){
                map<string,string> tempMap=new map<string,string>();
                tempMap.put('label',tempBuilding.Name);
                tempMap.put('value',tempBuilding.id);
                filtersToReturn.add(tempMap);
            }
            return filtersToReturn;
        }
        
        /**
        * getRTOUnitDetails
        *
        * return available RTO Units
        * 
        * @usage OpportunityRTOUnitSearch LWC
        *
        * @param none
        * @return   list<map<String,string>>  list of select options 
        * 
        */
        @AuraEnabled(cacheable=true)
        public static list<UnitDetilsWrapper> getRTOUnitDetails(ID buildingsId){ 
            list<UnitDetilsWrapper> unitsToReturn = new list<UnitDetilsWrapper>();
            map<id,Unit__c> unitMap= new map<id,Unit__c>(getAllAvailableRTOUnitsUnderBuilding(new set<ID>{buildingsId}));
            map<id,list<RTOConfiguration__c>> rtoConfigMap = new map<id,list<RTOConfiguration__c>>();
            for(RTOConfiguration__c rtoConfig : [select id,NAme,SecurityDepositPercent__c,DiscountPercentage__c,SCWaiverApplicable__c,HomeMaintenanceWaiverApplicable__c,BuildingSectionName__c,Project__c,EndDate__c,StartDate__c,Unit__c,Years__c,(Select id,NAme, YearNumber__c,RTOConfiguration__c,UnitPrice__c,RebatePercentage__c,RebateAmount__c,Rent__c,RentEscalation__c,RentCreditRate__c,RentCredit__c,CummulativeEquity__c,TotalEquity__c,TotalEquityPercentage__c,RemainingPayment__c,Unit__c,Years__c from RTOLines__r order by YearNumber__c ) from RTOConfiguration__c where Unit__c in:unitMap.KeySet() order by Years__c]){
                if(!rtoConfigMap.containsKey(rtoConfig.Unit__c)){
                    rtoConfigMap.put(rtoConfig.Unit__c, new list<RTOConfiguration__c>() );
                }
                rtoConfigMap.get(rtoConfig.Unit__c).add(rtoConfig);
            }
            for(Id unitId : unitMap.keySet()){
                Unit__c tempUnit = (unitMap.containsKey(unitId) ? unitMap.get(unitId):null);
                list<RTOConfiguration__c> tempConfig =  (rtoConfigMap.containsKey(unitId) ? rtoConfigMap.get(unitId):new list<RTOConfiguration__c>());
                unitsToReturn.add(new UnitDetilsWrapper(tempUnit,tempConfig));
            }
            return unitsToReturn;
        }
    
        //Fetch RTOAllowed__c Units
        public static list<Unit__c> getAllAvailableRTOUnitsUnderBuilding(set<ID> buildingsIds){
            return [select id,Name,NumberOfBedrooms__c,UnitType__c,PropertyUsage__c,UnitModel__c,FloorNumber__c,UnitView__c,UnitCategory__c,TerraceArea__c,TotalArea__c,UnitPlotArea__c,SellingPrice__c,BuildingSectionName__c,Project__c,ProjectBudget__c,MarketLeaseRent__c from Unit__c where BuildingSectionName__c in :buildingsIds  and IsActive__c =true AND RTOAllowed__c = true AND ( Status__c=:Constants.UNIT_STATUS_AVAILABLE OR (Status__c=:Constants.UNIT_STATUS_BOOKING_INPROGRESS AND LockedBy__c = :UserInfo.getUserId())) order by Name];
        }
    
         /**
        * getWinReasonPickList 
        *
        * return Opportunity level WinReason__c picklist values
        * 
        * @usage OpportunityRTOUnitSearch LWC
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
    * reserveUnit
    * 
    * This method is used to book RTO based on action parameter
    *
    * @param opportunityId - Selected Opportunity
*        configID - Selected Configuration Record ID
*        startDate - RTO Start Date
*        frequency - Payment frequency
*        paymentMode - Payment mode (Cheque)
    *        winReason - Opportunity clousure reason
    *        securityDepositAmount - Security deposi amount
    *     
    * @return map<string,string> success/Failur message
    * 
    */ 
        @AuraEnabled(cacheable=false)
        public static map<string,string> bookRTO(Id opportunityId ,Id configID , Date startDate, String frequency, String paymentMode, string winReason,decimal securityDepositAmount){
            map<string,string> valueToReturn = new map<string,string>();
            Savepoint sp = Database.setSavepoint();
            try{   
                //Fetch Config Record 
                list<RTOConfiguration__c> configValues = [select id,NAme,SecurityDepositPercent__c,DiscountPercentage__c,SCWaiverApplicable__c,HomeMaintenanceWaiverApplicable__c,BuildingSectionName__c,Project__c,EndDate__c,StartDate__c,Unit__c,Unit__r.status__c,Years__c,(Select id,NAme, YearNumber__c,RTOConfiguration__c,UnitPrice__c,RebatePercentage__c,RebateAmount__c,Rent__c,RentEscalation__c,RentCreditRate__c,RentCredit__c,CummulativeEquity__c,TotalEquity__c,TotalEquityPercentage__c,RemainingPayment__c,Unit__c,Years__c from RTOLines__r order by YearNumber__c ) from RTOConfiguration__c where Id = :configID ];
                
                if(!configValues.isEmpty() && configValues[0].Unit__c !=null &&  (configValues[0].Unit__r.status__c == Constants.UNIT_STATUS_AVAILABLE || configValues[0].Unit__r.status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS)){
                    List<Unit__c> allUnitsData = UnitServiceWithoutSharing.getAllUnitsById( new set<ID>{configValues[0].Unit__c} );
                    map<id,Unit__c> unitMap = new map<Id,Unit__c>(allUnitsData);
                    //get Opportunity details
                    Opportunity opportunityDetails = OpportunityService.getOpportunityDetailsMapbyId(opportunityId).get(opportunityId);
                    //Unit recordTo update
                    Unit__c unitToUpdate = new Unit__c(id=configValues[0].Unit__c );
    
                    List<InstallmentLines__c> installmentLinesToCreate = new List<InstallmentLines__c>();
                    map<String,ReceiptAcknowledgement__c> receiptAckToInsertList = new map<String,ReceiptAcknowledgement__c>();
    
                    List<CommissionLineItem__c> internalCommission = new list<CommissionLineItem__c>();
                    List<CommissionLineItem__c> externalCommission = new list<CommissionLineItem__c>();
    
                    Id rtoRecordTypeId = Schema.SObjectType.SalesOrder__c.getRecordTypeInfosByName().get('RTO').getRecordTypeId();
                    SalesOrder__c salesOrderRecord = new SalesOrder__c();
                    Decimal SOValue = 0;
                    for(RTOLines__c tempLine: configValues[0].RTOLines__r){
                        SOValue += tempLine.Rent__c;
                    }
                    Map<Id,BrokerCommission__c> unitExternalCommissionMap = new Map<Id,BrokerCommission__c>();
                    map<Id,InternalCommission__c> unitInternalCommissionMap = new map<Id,InternalCommission__c>();
                    map<id,OffersPromotions__c> unitToOfferMap = new map<id,OffersPromotions__c>();
                    
                    unitToOfferMap.put(configValues[0].Unit__c ,null);
                    unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityDetails,allUnitsData, unitToOfferMap);
                    unitInternalCommissionMap =  CommissionService.getInternalCommissions(opportunityDetails,allUnitsData, unitToOfferMap );
    
    
                    //SALES ORDER FIELDS
                    salesOrderRecord.RecordTypeId = rtoRecordTypeId;
                    salesOrderRecord.Account__c = opportunityDetails !=null ? opportunityDetails.AccountId : null;
                    salesOrderRecord.Contact__c = opportunityDetails !=null ? opportunityDetails.Contact__c : null;
                    salesOrderRecord.CustomerType__c = opportunityDetails !=null ? opportunityDetails.Account.CustomerType__c : null;
                    salesOrderRecord.CustomerSubType__c = opportunityDetails !=null ? opportunityDetails.Account.CustomerSubType__c : null;
                    salesOrderRecord.Email__c = (opportunityDetails !=null && opportunityDetails.Contact__c!=null) ? opportunityDetails.Contact__r.Email : null;
                    salesOrderRecord.MobileNumber__c = (opportunityDetails !=null && opportunityDetails.Contact__c!=null) ? opportunityDetails.Contact__r.MobilePhone : null;                             
                    salesOrderRecord.Opportunity__c = opportunityDetails.Id;
                    salesOrderRecord.OwnerManger__c = (opportunityDetails !=null ) ? opportunityDetails.Owner.ManagerId : null;
                    salesOrderRecord.ReferralType__c = opportunityDetails.ReferralType__c;
                    salesOrderRecord.SalesManager__c = (opportunityDetails !=null ) ? opportunityDetails.OwnerId : null;                            
                    salesOrderRecord.Unit__c = configValues[0].Unit__c;   
                    salesOrderRecord.SecurityDeposit__c = securityDepositAmount.setScale(2);  
                    salesOrderRecord.RTOFrequency__c = frequency;
                    salesOrderRecord.RTOYears__c = configValues[0].Years__c;
                    salesOrderRecord.Status__c = Constants.SO_STATUS_RTO_PENDING; //STATUS WILL BE UPDATED TO APPROVE PENDING AND FINALLU TO SOLD 
                    salesOrderRecord.SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM;
                    
                    //ExternalCommissionAmount__c
                    //InternalCommissionAmount__c
                    //salesOrderRecord.RTOOriginalSellingPrice__c = unitMap.get(configValues[0].Unit__c).SellingPrice__c;
                    salesOrderRecord.SellingPrice__c = unitMap.get(configValues[0].Unit__c).SellingPrice__c;
                    salesOrderRecord.RTODiscount__c =  configValues[0].DiscountPercentage__c!=null ? ((configValues[0].DiscountPercentage__c * unitMap.get(configValues[0].Unit__c).SellingPrice__c) / 100).setScale(2) : 0;
                    salesOrderRecord.RTONetAmount__c = SOValue;
                    salesOrderRecord.BookingDate__c = Date.Today();
                    salesOrderRecord.RTOStartDate__c =startDate;
                    salesOrderRecord.RTOEndDate__c = startDate.addYears(configValues[0].RTOLines__r.size()).addDays(-1);
                    salesOrderRecord.AmountPayable__c= salesOrderRecord.SellingPrice__c - salesOrderRecord.RTODiscount__c;//salesOrderRecord.RTONetAmount__c;
                    salesOrderRecord.TaxableAmount__c = (unitMap.get(configValues[0].Unit__c).BuildingSectionName__r.TaxPercentage__c !=null ) ? (salesOrderRecord.AmountPayable__c * unitMap.get(configValues[0].Unit__c).BuildingSectionName__r.TaxPercentage__c).setScale(2) : 0;
                    salesOrderRecord.NetAmount__c = (salesOrderRecord.TaxableAmount__c+salesOrderRecord.AmountPayable__c).setScale(2);
                    salesOrderRecord.NetAmountInWords__c =Utilities.amountInWords(salesOrderRecord.NetAmount__c,'Dirham','Fils');
                    
                    salesOrderRecord.HomeMaintenanceWaivedAmount__c = (configValues[0].HomeMaintenanceWaiverApplicable__c && unitMap.get(configValues[0].Unit__c).BuildingSectionName__r.HomeMaintenanceFee__c !=null) ? (unitMap.get(configValues[0].Unit__c).BuildingSectionName__r.HomeMaintenanceFee__c * configValues[0].RTOLines__r.size()).setScale(2) :0;
                    salesOrderRecord.HomeMaintenanceWaivedYears__c = configValues[0].HomeMaintenanceWaiverApplicable__c ?configValues[0].RTOLines__r.size():0;
                    salesOrderRecord.ServiceChargeWaivedYears__c =  configValues[0].SCWaiverApplicable__c ?configValues[0].RTOLines__r.size():0;
                    salesOrderRecord.ServiceChargeWaivedAmount__c=0;
                    salesOrderRecord.OtherRebateAmount__c =  configValues[0].RTOLines__r[0].RebateAmount__c;
    
                    Decimal unitArea = unitMap.get(configValues[0].Unit__c).MeasuredArea__c!=null ? unitMap.get(configValues[0].Unit__c).MeasuredArea__c : ( unitMap.get(configValues[0].Unit__c).SaleableArea__c!=null ? unitMap.get(configValues[0].Unit__c).SaleableArea__c : 0)  ;
                    if(unitArea!=null && unitArea!=0){
                        decimal incrementalSC = unitMap.get(configValues[0].Unit__c).AnticipatedServiceCharges__c;
                        for(integer tempi = 1; tempi<= salesOrderRecord.ServiceChargeWaivedYears__c ; tempi++ ){
                            if(tempi>3 && unitMap.get(configValues[0].Unit__c).EscalationServiceCharge__c!=null){
                                incrementalSC = (incrementalSC + ( incrementalSC * (unitMap.get(configValues[0].Unit__c).EscalationServiceCharge__c/100) )).setScale(2);
                            }
                            salesOrderRecord.ServiceChargeWaivedAmount__c = (salesOrderRecord.ServiceChargeWaivedAmount__c + (incrementalSC * unitArea)).setScale(2);
                        }
                    }
                    
                    //Commission Calcualtions
                    Decimal internalCommissionValue = 0;
                    Decimal externalCommissionValue = 0;
                    if(unitInternalCommissionMap.containskey(configValues[0].Unit__c)){
                        if(opportunityDetails.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_DIRECT){
                            internalCommissionValue = unitInternalCommissionMap.get(configValues[0].Unit__c).DirectRTOCommissionPercentage__c != null ? unitInternalCommissionMap.get(configValues[0].Unit__c).DirectRTOCommissionPercentage__c  / 100: 0 ;
                        }else if(opportunityDetails.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT){
                            internalCommissionValue= unitInternalCommissionMap.get(configValues[0].Unit__c).IndirectRTOCommissionPercentage__c != null ? unitInternalCommissionMap.get(configValues[0].Unit__c).IndirectRTOCommissionPercentage__c / 100 : 0 ;
                        }
                    }
                    if(unitExternalCommissionMap.containskey(configValues[0].Unit__c)){
                        externalCommissionValue =unitExternalCommissionMap.get(configValues[0].Unit__c).RTOCommissionPercentage__c != null ? unitExternalCommissionMap.get(configValues[0].Unit__c).RTOCommissionPercentage__c / 100 : 0 ;
                    }
                    CommissionLineItem__c commissionLineExtenalRecord;
                    if(externalCommissionValue != 0 && opportunityDetails.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT){
                        commissionLineExtenalRecord = new CommissionLineItem__c();
                        commissionLineExtenalRecord.BrokerAgent__c = opportunityDetails.BrokerAgentContact__c;
                        commissionLineExtenalRecord.BrokerAgency__c = opportunityDetails.BrokerAgencyAccount__c;
                        commissionLineExtenalRecord.CommissionAmount__c = (externalCommissionValue * configValues[0].RTOLines__r[0].Rent__c).setScale(2);
                        commissionLineExtenalRecord.CommissionPercentage__c =  100;
                        commissionLineExtenalRecord.PercentageWRTNetPrice__c = externalCommissionValue * 100;
                        commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                        commissionLineExtenalRecord.SalesManager__c = opportunityDetails.OwnerId;
                        commissionLineExtenalRecord.ExternalCommissionAmountBasis__c = Constants.COMISSIONBASIS_PERCENT;
                    }
                    CommissionLineItem__c commissionLineRecord;
                    if(internalCommissionValue!=0){
                        commissionLineRecord = new CommissionLineItem__c();
                        commissionLineRecord.CommissionAmount__c =  (internalCommissionValue * configValues[0].RTOLines__r[0].Rent__c ).setScale(2);
                        commissionLineRecord.CommissionPercentage__c = 100;
                        commissionLineRecord.PercentageWRTNetPrice__c = internalCommissionValue * 100;
                        commissionLineRecord.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
                        commissionLineRecord.BrokerAgent__c = opportunityDetails.BrokerAgentContact__c;
                        commissionLineRecord.BrokerAgency__c =opportunityDetails.BrokerAgencyAccount__c;
                        commissionLineRecord.SalesManager__c = opportunityDetails.OwnerId;
                    }
    
    
                    //Unit Update
                    //TODO RTO STATUS*******
                    unitToUpdate.Status__c=  Constants.UNIT_STATUS_BOOKED;
    
                    unitToUpdate.AllocationGroup__c =null;
                    unitToUpdate.AssignedToUser__c = UserInfo.getUserId();
                    unitToUpdate.LockedBy__c = UserInfo.getUserId();
                    
                    //Opportunity Update
                    opportunityDetails.StageName =  Constants.STAGE_CLOSEDWON;
                    opportunityDetails.CloseDate = system.today();
                    opportunityDetails.WinReason__c=winReason;
                    opportunityDetails.Amount= salesOrderRecord.NetAmount__c ;
    
                    //Budget Check 
                    SalesOfferUtility.PaymentPlanWrapper unitPaymentPlanWrapper = new SalesOfferUtility.PaymentPlanWrapper();
                    unitPaymentPlanWrapper.discountAmount = salesOrderRecord.RTODiscount__c;
                    unitPaymentPlanWrapper.rebateAmount = salesOrderRecord.OtherRebateAmount__c;
                    unitPaymentPlanWrapper.serviceChargeAmount = salesOrderRecord.ServiceChargeWaivedAmount__c;
                    unitPaymentPlanWrapper.homeMaintenanceWaiverFee = salesOrderRecord.HomeMaintenanceWaivedAmount__c;
                    unitPaymentPlanWrapper.externalComissionAmount =externalCommissionValue;
                    unitPaymentPlanWrapper.internalComissionAmount = internalCommissionValue;
                    if(!performBudgetCheck(opportunityId,allUnitsData[0],unitPaymentPlanWrapper)){
                        valueToReturn.put('result','Budget check failed');
                            return valueToReturn;
                    }
    
    
                    insert salesOrderRecord;
                    update unitToUpdate;
                    update opportunityDetails;
                    //Sales Order other charges
                     SalesOrderOtherCharges__c soOtherCHarges = new SalesOrderOtherCharges__c(Amount__c = securityDepositAmount.setScale(2),TypeOfCharge__c = 'Security Deposit', Opportunity__c=salesOrderRecord.Opportunity__C , Account__c=salesOrderRecord.Account__C ,SalesOrder__c =salesOrderRecord.Id);
                     insert soOtherCHarges;
                    //Installment lines Insert
                    for(RTOLines__c tempLine: configValues[0].RTOLines__r){
                        InstallmentLines__c tempInstallmentRecord = new InstallmentLines__c();
                        tempInstallmentRecord.InstallmentNumber__c = tempLine.YearNumber__c;
                        tempInstallmentRecord.InstallmentPercentage__c = (100/configValues[0].RTOLines__r.size());                    
                        tempInstallmentRecord.InstallmentAmount__c = tempLine.Rent__c;
                        tempInstallmentRecord.InstallmentAmountintheWords__c = Utilities.amountInWords(tempLine.Rent__c,'Dirham','Fils');
                        tempInstallmentRecord.RTOLine__c = tempLine.Id;
                        tempInstallmentRecord.RTOStartDate__c = startDate.addYears(Integer.ValueOf(tempLine.YearNumber__c-1));
                        tempInstallmentRecord.RTOEndDate__c =  startDate.addYears(Integer.ValueOf(tempLine.YearNumber__c)).addDays(-1);
                        tempInstallmentRecord.InstallmentDate__c = tempInstallmentRecord.RTOStartDate__c;
                        tempInstallmentRecord.Description__c=tempLine.Name;
                        tempInstallmentRecord.RTOPaymentFrequency__c = Integer.ValueOf(frequency);
                        tempInstallmentRecord.SalesOrder__c = salesOrderRecord.Id;
                        installmentLinesToCreate.add(tempInstallmentRecord);
                    }
                    
                    if(!installmentLinesToCreate.isEmpty()){
                        insert installmentLinesToCreate;
                    }
    
                    //Creating Receipt ACK records
                    for(InstallmentLines__c tempIL : installmentLinesToCreate){
                        Integer monthAdder = 0;
                        if(Integer.ValueOf(frequency) == 12){monthAdder=1;}
                        else if(Integer.ValueOf(frequency) == 4){monthAdder=3;}
                        else if(Integer.ValueOf(frequency) == 2){monthAdder=6;}
                        Date tempInsStartDate = tempIL.RTOStartDate__c;
                        for (Integer i = 0 ; i < Integer.ValueOf(frequency) ; i++) {
                            tempInsStartDate =  i==0 ? tempInsStartDate : tempInsStartDate.addMonths(monthAdder) ;
                            receiptAckToInsertList.put(tempIL.Id+'-'+i , new ReceiptAcknowledgement__c(SalesOrder__c=salesOrderRecord.Id,
                                                        Account__c=salesOrderRecord.Account__c,
                                                        Contact__c=salesOrderRecord.Contact__c,
                                                        Opportunity__c=salesOrderRecord.opportunity__c,
                                                        Amount__c= (tempIL.InstallmentAmount__c / Integer.ValueOf(frequency)).setScale(2),
                                                        PaymentType__c=paymentMode,
                                                        MaturityDate__c= receiptAckToInsertList.isEmpty()? tempIL.RTOStartDate__c.addDays(-14) : tempInsStartDate ));
                        }
                    }
    
                    receiptAckToInsertList.put('SD' ,new ReceiptAcknowledgement__c(SalesOrder__c=salesOrderRecord.Id,
                                                        Account__c=salesOrderRecord.Account__c,
                                                        Contact__c=salesOrderRecord.Contact__c,
                                                        Opportunity__c=salesOrderRecord.opportunity__c,
                                                        Amount__c= securityDepositAmount.setScale(2),
                                                        PaymentType__c=paymentMode,
                                                        MaturityDate__c= startDate.addDays(-14) ));
    
                    //Receipt Ack Insert
                    if(!receiptAckToInsertList.isEmpty()){
                        insert receiptAckToInsertList.values();
                    }
    
                    //Receipt Allocation
                    list<ReceiptAllocation__c> allocationToinsert = new list<ReceiptAllocation__c>();
                    for(string recAllKey : receiptAckToInsertList.keySet()){
                        String installmentID = recAllKey.contains('-')? recAllKey.split('-')[0] :'';
                        ReceiptAcknowledgement__c recAckRec= receiptAckToInsertList.get(recAllKey);
                        if(installmentID !=''){
                            allocationToinsert.add(new ReceiptAllocation__c(Account__c=recAckRec.Account__c,
                                                                        AmountApplied__c=recAckRec.Amount__c,
                                                                        InstallmentLine__c=installmentID,
                                                                        ReceiptAcknowledgement__c = recAckRec.id,
                                                                        SalesOrder__c=salesOrderRecord.Id,
                                                                        TypeOfInvoice__c=Constants.INVOICE_TYPE_INSTALLMENT));
                        }else{
                            allocationToinsert.add(new ReceiptAllocation__c(Account__c=recAckRec.Account__c,
                                                                        AmountApplied__c=recAckRec.Amount__c,
                                                                        SalesOrderOtherCharges__c=soOtherCHarges.Id,
                                                                        ReceiptAcknowledgement__c = recAckRec.id,
                                                                        SalesOrder__c=salesOrderRecord.Id,
                                                                        TypeOfInvoice__c=Constants.OTHER_CHARGES_TYPE_SECURITY_DEPOSIT));
                        }
                    }
                    
                    if(!allocationToinsert.isEmpty()){
                        insert allocationToinsert;
                    }
    
                    //Insert Commission records
                    if(commissionLineExtenalRecord!=null){
                        commissionLineExtenalRecord.InstallmentLine__c = installmentLinesToCreate[0].Id;
                        commissionLineExtenalRecord.SalesOrder__c =salesOrderRecord.Id;
                        insert commissionLineExtenalRecord;
                    }
    
                    if(commissionLineRecord!=null){
                        commissionLineRecord.SalesOrder__c =salesOrderRecord.Id;
                        insert commissionLineRecord;
                    }
                    
                    
                    valueToReturn.put('result','success');
                    valueToReturn.put('id',opportunityDetails.id);
    
                }else{
                    valueToReturn.put('result','Unit not available for Booking RTO');
                    return valueToReturn;
                }
            }catch(exception e){
                System.debug('line no '+e.getLineNumber());
                System.debug('msg '+e.getMessage());
                Database.rollback(sp);
                valueToReturn.put('result','Exception : '+e.getMessage());
            }
            return valueToReturn;
        }
        
        /**
        * performBudgetCheck
        *
        * Method used to perform the bdget check for the given RTO booking
        * 
        * @usage OpportunityRTOUnitSearch LWC
        *
        * @param opportunityId - Opportunity ID
        * @param unitRecord - selected unit record
        * @param unitPaymentPlanWrapper - Payment details wrapper
        *
        * @return   boolean  returns success/Failure
        * 
        */
        public static boolean performBudgetCheck(Id opportunityId, Unit__c unitRecord,SalesOfferUtility.PaymentPlanWrapper unitPaymentPlanWrapper){
            list<ProjectBudget__c> budgetNotifications =  new list<ProjectBudget__c>();
    
            budgetNotifications.add( new ProjectBudget__c(id = unitRecord.ProjectBudget__c, NotifyDevelopment__c=true) );
            Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapperMap = new Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();
            unitPaymentPlanWrapperMap.put(unitRecord,unitPaymentPlanWrapper);
    
            Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = BudgetLinesService.checkAvailableProjectBudget(new Set<Id>{unitRecord.ProjectBudget__c},unitPaymentPlanWrapperMap);
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
        * saveConfigurations
        *
        * Method used to save RTO configuration and all the related line items
        * 
        * @usage OpportunityRTOUnitSearch LWC
        *
        * @param unitIds - Selected unit IDs
        * @param rtoConfig - RTO configuration details to be saved
        * @param rtoConfigLines - Line items to be associated with the Config
        * @param securityDeposit - Deposit percentage
        * @param discountPercetnage - Discount percetage
        * @param scApplicable - Service Charge Waiver applicable
        * @param hmApplicable -  Home Manintainance Waiver applicable
        *
        * @return   boolean  returns success/Failure
        * 
        */
        @AuraEnabled(cacheable=false)
        public static void saveConfigurations(list<ID> unitIds, list<String> years, list<RTOConfiguration__c> rtoConfig ,list<RTOLines__c> rtoConfigLines, decimal securityDeposit, decimal discountPercetnage , boolean scApplicable , boolean hmApplicable){
    
            delete [select id from RTOConfiguration__c where Unit__c in :unitIds and (not Years__c in :years) ];
            for(RTOConfiguration__c rc : rtoConfig ){
                rc.SecurityDepositPercent__c = securityDeposit;
                rc.DiscountPercentage__c=discountPercetnage;
                rc.SCWaiverApplicable__c =scApplicable;
                rc.HomeMaintenanceWaiverApplicable__c =hmApplicable;
            }
            upsert rtoConfig;
            map<string,RTOConfiguration__c> mappingData = new map<string,RTOConfiguration__c>();
            for(RTOConfiguration__c tempConfig : rtoConfig){
                mappingData.put(tempConfig.Unit__c+'_'+tempConfig.Years__c ,tempConfig);
            }
            for(RTOLines__c line : rtoConfigLines){
                line.RTOConfiguration__c = mappingData.get(line.Unit__c+'_'+line.Years__c).Id;
                line.RemainingPaymentInWords__c = Utilities.amountInWords(line.RemainingPayment__c,'Dirham','Fils');
            }
            upsert rtoConfigLines;
        }
        
    
        /**
        * UnitDetilsWrapper 
        *
        * Wrapper class used to render the Unit details on the OpportunityRTOUnitSearch Screen
        */
        public with sharing class UnitDetilsWrapper{
            @AuraEnabled
            public boolean isSelected; 
            @AuraEnabled
            public Unit__c unitDetails;
            @AuraEnabled
            public map<String,RTOConfiguration> configurations;
            
            public UnitDetilsWrapper(Unit__c tempUnit, list<RTOConfiguration__c> rtoConfigs){
                isSelected=false;
                unitDetails=tempUnit;
                configurations = new map<String,RTOConfiguration>();
                for(RTOConfiguration__c configVal : rtoConfigs){
                    configurations.put(configVal.Years__c, new RTOConfiguration(tempUnit,configVal));
                }
            }
        }
        public with sharing class RTOConfiguration{
            @AuraEnabled
            public boolean isSelected; 
            @AuraEnabled
            public RTOConfiguration__c details;
            @AuraEnabled
            public string yearConfig;
            @AuraEnabled
            public string uKey;
            public RTOConfiguration(){}
            public RTOConfiguration(Unit__c tempUnit,RTOConfiguration__c rtoConfig){
                isSelected=true;
                details = rtoConfig;
                if(details!=null && details.Years__c!=null){
                    yearConfig = rtoConfig.Years__c;
                    uKey=tempUnit.Id+'_'+rtoConfig.Years__c;
                }
            }
        }
    
        //get Current logged in user's profile
        @AuraEnabled(cacheable=true)
        public static user getCurrentUserProfile() {
            String userId = UserInfo.getUserId(); // current user
            return [SELECT ID, Profile.Name From User WHERE ID =: userId LIMIT 1];
    
        }
    
        /**
        * getConversionDetails
        *
        * Conversion Details to be displayed before conversion
        * 
        * @usage convertRTO LWC
        *
        * @param recordId - Sak=les order record ID
        *
        * @return   map<string,object>  returns conversion details
        * 
        */
        @AuraEnabled(cacheable=true)
        public static map<string,object> getConversionDetails(string recordId) {
            map<string,object> objectToReturn = new map<string,object>();
        SalesOrder__c tempTec = [select id,RTODiscount__c,SellingPrice__c,NetAmount__c,(select id,ActiveTenancyYear__c,RTOStartDate__c,RTOEndDate__c,RTOLine__c,RTOLine__r.RemainingPayment__c,RTOLine__r.CummulativeEquity__c,RTOLine__r.RebateAmount__c from InstallmentLines__r order by RTOStartDate__c) from SalesOrder__c where id = :recordId limit 1];
            InstallmentLines__c selectedLine;
            for(InstallmentLines__c iline : tempTec.InstallmentLines__r){
                if(iline.ActiveTenancyYear__c ==true){
                    selectedLine=iline;
                    break;
                }else if(iline.RTOEndDate__c < system.today()){
                    selectedLine=iline;
                }
            }
            objectToReturn.put('sellingPrice',tempTec.SellingPrice__c);
            objectToReturn.put('discount',tempTec.RTODiscount__c);
            objectToReturn.put('rebate',selectedLine.RTOLine__r.RebateAmount__c);
            objectToReturn.put('NetSellingPrice',(tempTec.SellingPrice__c - tempTec.RTODiscount__c));
            objectToReturn.put('totalEquvityPaid',selectedLine.RTOLine__r.CummulativeEquity__c);
            objectToReturn.put('totalRemaining',selectedLine.RTOLine__r.RemainingPayment__c);
            return objectToReturn;
        }
    
        /**
        * convertRTO
        *
        * Method used to perform RTO Conversion operation
        * 
        * @usage convertRTO LWC
        *
        * @param recordId - Sak=les order record ID
        *
        * @return   Id  returns converted SO ID
        * 
        */
        @AuraEnabled
        public static Id convertRTO(string recordId) {
            
            SalesOrder__c existingRecord = [select id,Account__c,Contact__c,CustomerType__c,CustomerSubType__c ,Email__c,MobileNumber__c,Opportunity__c,OwnerManger__c,
                                            ReferralType__c, NetAmount__c,SalesManager__c,Unit__c,SecurityDeposit__c,RTOFrequency__c,RTOYears__c,SellingPrice__c,RTODiscount__c,Unit__r.BuildingSectionName__r.TaxPercentage__c,
                                            HomeMaintenanceWaivedAmount__c,HomeMaintenanceWaivedYears__c,ServiceChargeWaivedYears__c,ServiceChargeWaivedAmount__c,
                                            DLPDate__c,CustomerDLPStartDate__c,
                                            (select id,ActiveTenancyYear__c,RTOStartDate__c,RTOEndDate__c,RTOLine__c,RTOLine__r.RemainingPayment__c,RTOLine__r.CummulativeEquity__c,RTOLine__r.RebateAmount__c from InstallmentLines__r order by RTOStartDate__c) from SalesOrder__c where id = :recordId limit 1];
            InstallmentLines__c selectedLine;
            for(InstallmentLines__c iline : existingRecord.InstallmentLines__r){
                if(iline.ActiveTenancyYear__c ==true){
                    selectedLine=iline;
                    break;
                }else if(iline.RTOEndDate__c < system.today()){
                    selectedLine=iline;
                }
            }
            existingRecord.Status__c = 'RTO Converted';
            update existingRecord;
    
            Id rtoRecordTypeId = Schema.SObjectType.SalesOrder__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
            SalesOrder__c salesOrderRecord = new SalesOrder__c();
             //SALES ORDER FIELDS
             salesOrderRecord.RecordTypeId = rtoRecordTypeId;
             salesOrderRecord.RTOConverted__c =true;
             salesOrderRecord.CustomerDLPStartDate__c = existingRecord.CustomerDLPStartDate__c;
             salesOrderRecord.DLPDate__c = existingRecord.DLPDate__c;

             salesOrderRecord.Account__c = existingRecord.Account__c;
             salesOrderRecord.Contact__c = existingRecord.Contact__c;
             salesOrderRecord.CustomerType__c = existingRecord.CustomerType__c;
             salesOrderRecord.CustomerSubType__c = existingRecord.CustomerSubType__c;
             salesOrderRecord.Email__c = existingRecord.Email__c;
             salesOrderRecord.MobileNumber__c =existingRecord.MobileNumber__c;
             salesOrderRecord.Opportunity__c = existingRecord.Opportunity__c;
             salesOrderRecord.OwnerManger__c = existingRecord.OwnerManger__c;
             salesOrderRecord.ReferralType__c =existingRecord.ReferralType__c;
             salesOrderRecord.SalesManager__c = existingRecord.SalesManager__c;
             salesOrderRecord.Unit__c = existingRecord.Unit__c;
             salesOrderRecord.SecurityDeposit__c = existingRecord.SecurityDeposit__c;
             salesOrderRecord.Status__c = Constants.STATUS_APPROVAL_PENDING; //STATUS WILL BE UPDATED TO APPROVE PENDING AND FINALLU TO SOLD 
             salesOrderRecord.SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM;
             
             
             salesOrderRecord.SellingPrice__c = existingRecord.SellingPrice__c;
             salesOrderRecord.Discount__c =  existingRecord.RTODiscount__c;
             //salesOrderRecord.RTONetAmount__c = existingRecord.RTONetAmount__c;
             salesOrderRecord.BookingDate__c = system.today();
    
             salesOrderRecord.AmountPayable__c=  existingRecord.NetAmount__c;//selectedLine.RTOLine__r.CummulativeEquity__c + selectedLine.RTOLine__r.RemainingPayment__c;
             salesOrderRecord.TaxableAmount__c = (existingRecord.Unit__r.BuildingSectionName__r.TaxPercentage__c !=null ) ? salesOrderRecord.AmountPayable__c * existingRecord.Unit__r.BuildingSectionName__r.TaxPercentage__c : 0;
             salesOrderRecord.NetAmount__c =  (salesOrderRecord.TaxableAmount__c+salesOrderRecord.AmountPayable__c).setScale(2);
             salesOrderRecord.NetAmountInWords__c =Utilities.amountInWords(salesOrderRecord.NetAmount__c,'Dirham','Fils');
             
             salesOrderRecord.HomeMaintenanceWaivedAmount__c = existingRecord.HomeMaintenanceWaivedAmount__c;
             salesOrderRecord.HomeMaintenanceWaivedYears__c = existingRecord.HomeMaintenanceWaivedYears__c;
             salesOrderRecord.ServiceChargeWaivedYears__c =  existingRecord.ServiceChargeWaivedYears__c;
             salesOrderRecord.ServiceChargeWaivedAmount__c=existingRecord.ServiceChargeWaivedAmount__c;
             salesOrderRecord.OtherRebateAmount__c =  selectedLine.RTOLine__r.RebateAmount__c;
             salesOrderRecord.PreviousSalesOrder__c = existingRecord.Id;
            insert salesOrderRecord;
    
            //Get RTO PAyment Plan
            PaymentPlan__c rtoPlan = [select id,(select id,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__r) from PaymentPlan__c where name='RTO Plan'];
            list<InstallmentLines__c> installmentLinesToInsert = new list<InstallmentLines__c>();
            for(PaymentInstallments__c tempPP : rtoPlan.PaymentInstallments__r){
                installmentLinesToInsert.add(new InstallmentLines__c(  BrokerPayoutPercentage__c= 0,
                Description__c= tempPP.Description__c,
                InstallmentNumber__c = tempPP.InstallmentNumber__c,
                InstallmentPercentage__c= tempPP.InstallmentPercentage__c,
                InstallmentDate__c= tempPP.InstallmentDate__c, 
                InstallmentAmount__c= (salesOrderRecord.NetAmount__c * tempPP.InstallmentPercentage__c/100).setScale(2),
                InstallmentAmountintheWords__c = Utilities.amountInWords( (salesOrderRecord.NetAmount__c * tempPP.InstallmentPercentage__c/100).setScale(2),'Dhirams','Fils'),
                PaymentInstallments__c= tempPP.Id,
                PaymentPlan__c= tempPP.PaymentPlan__c,
                salesOrder__c = salesOrderRecord.Id ));
            }
            
            insert installmentLinesToInsert;
    
            return salesOrderRecord.Id;
    
        }
    
    }