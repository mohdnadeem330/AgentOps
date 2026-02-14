/*
*********************************************************
Apex Class Name    : ServiceRequestTriggerHandlerNew
Created Date       : 
@description       : Class to handle Service Request Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public with sharing class ServiceRequestTriggerHandlerNew  extends TriggerHandler{
    
    // Global variable declaration start
    public static Boolean isSkipSrRequestTrigger = false; // Added by kuhinoor...
    private static Set<String> serviceChargeSRTypeUtilSet = new Set<String>{Constants.PAYMENT_EXTENSION_TYPE,Constants.PAYMENT_PLAN_CHANGE_RT,Constants.INVESTOR_CERTIFICATE_RT,Constants.LPC_WAIVER_TYPE,Constants.INVESTOR_CERT_LETTER_ISSUE,Constants.INVESTOR_CERT_ATTESTED_SPA};
    public static List<HexaBPM__Service_Request__c> fastTrackSRDocrecordsToProcess = new List<HexaBPM__Service_Request__c>();
    // Global variable declaration end
    /*
    *********************************************************
    @Method Name    : beforeInsertMethod
    @author         : 
    @description    : Method to handle before Insert logic for Service Request
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */
    public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
        // Local variable declaration start
        List<HexaBPM__Service_Request__c> agencyRegSRList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> serviceRequestGLList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> paymentExtentionSRList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srHandoverList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> unitSwapListList = new List<HexaBPM__Service_Request__c>();
        Set<Id> customerIdSet = new Set<Id>();
        List<Id> buyerIdList = new List<Id>();
        Map<Id,HexaBPM__Service_Request__c> goldenVisaAccountsIdsWithSR = new Map<Id,HexaBPM__Service_Request__c>();
        set<Id> ptunitIds = new set<Id>(); 
        set<Id> caseIds = new set<Id>();
        set<Id> propertyTransferRecIds = new set<Id>();
        propertyTransferRecIds.add(ServiceRequestTriggerHelper.recordTypeByName.get(Constants.PROPERTY_TRANSFER_RT) );
        propertyTransferRecIds.add(ServiceRequestTriggerHelper.recordTypeByName.get(Constants.PROPERTY_TRANSFER_NOC_RT) );
        propertyTransferRecIds.add(ServiceRequestTriggerHelper.recordTypeByName.get(Constants.PROPERTY_TRANSFER_OffPlan) ); // SSR 751 OffPlan
        Map<Id, String> custIdAndFlagType = new Map<Id, String>();
        Map<Id, String> soIdAndFlagType = new Map<Id, String>();
        List<HexaBPM__Service_Request__c> moveInRequests = new List<HexaBPM__Service_Request__c>();
        // Local variable declaration end
        ServiceRequestTriggerHelper.updateSalesOrderAndCustomer(newList);
        ServiceRequestTriggerHelper.checkSRAutomation(newList, null);
        // for loop for filtration start
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            // SR Resale Case Validation
            if(newRecord.Unit__c != null && propertyTransferRecIds.contains(newRecord.recordTypeId)){
                ptunitIds.add(newRecord.Unit__c);
                if(newRecord.Case__c!=null){
                    caseIds.add(newRecord.Case__c);
                }                
            }
            if (newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEIN  || newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEOUT) {
                moveInRequests.add(newRecord);
            }
            //SS_DandT_Revamp_SP17-START
            soIdAndFlagType.put(newRecord.SalesOrder__c, '');
            custIdAndFlagType.put(newRecord.HexaBPM__Customer__c, '');
            //SS_DandT_Revamp_SP17-END
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) {
                serviceRequestList.add(newRecord);
            }
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT) {
                srHandoverList.add(newRecord);
            }
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.Golden_Visa_DEV_RT){
                if (newRecord.SRType__c == Constants.Golden_Visa_RT) {
                    goldenVisaAccountsIdsWithSR.put(newRecord.HexaBPM__Customer__c, newRecord);
                }
                customerIdSet.add(newRecord.HexaBPM__Customer__c);
                serviceRequestGLList.add(newRecord);
            }
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_EXTENSION_DEV_RT) {
                paymentExtentionSRList.add(newRecord);
            }
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT) {
                PaymentPlanChangeService.checkPaidEquity(newRecord);
            }           
            //To Populate LPC Total, LPC Collected/Paid, LPC Waived and LPC Due
            if((newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT) && newRecord.SalesOrder__c != null){
                LPCService.lpcBeforeInsertLogic(newRecord);
            }
            if (newRecord.RefundAmount__c > 0 || newRecord.ReallocationAmount__c > 0) {
                newRecord.IsRefundApplicable__c = true;
            }
            if (newRecord.BuyerName__c != null) {
                buyerIdList.add(newRecord.BuyerName__c);
            }
            //Added by Tharun to update ReferredBy Profile Name - ASF-1367
            if (newRecord.HexaBPM__Record_Type_Name__c == ALD_Constants.Agency_Registration_DEV_RT && 
                newRecord.ReferredBy__c != null &&
                newRecord.ReferredBy__c != Constants.NO_REFERRAL) {
                    agencyRegSRList.add(newRecord);
                }
            if (newRecord.SwappedUnit__c != null){
                unitSwapListList.add(newRecord);
            }
        }
        // for loop for filtration end
        if (!moveInRequests.isEmpty()) {
            ECSS_ServiceRequestTriggerHelper.estatesBeforeInsert(moveInRequests);
        }
        if(!ptunitIds.isEmpty()){
            PropertyTransferService.validatePropertyTransferSR(newList,propertyTransferRecIds, ptunitIds, caseIds);
        }
        //SS_DandT_Revamp_SP17-START
        ALD_DandTSR_Handler_CC.updateSRIfFlagged((List<HexaBPM__Service_Request__c>) newList, custIdAndFlagType, soIdAndFlagType);
        //SS_DandT_Revamp_SP17-END
        //Added by Tharun to update ReferredBy Profile Name ASF-1367
        if(!agencyRegSRList.isEmpty()){
            BrokerAgencyService.updateAgencySrReferredByProfileName(agencyRegSRList);
        }
        if(!paymentExtentionSRList.isEmpty()){
            PaymentExtensionService.paymentExtensionHelperMethod(paymentExtentionSRList);
        }
        if (!serviceRequestList.isEmpty()) {
            ServiceRequestTriggerHelper.updateChargeCollected(newList, serviceRequestList);
        }
        if (!customerIdSet.isEmpty() && !serviceRequestGLList.isEmpty()) {
            GoldenVisaService.updateGoldenVisaDetails(serviceRequestGLList, customerIdSet);
        }
        if (!goldenVisaAccountsIdsWithSR.isEmpty()) {
            GoldenVisaService.gvAccountValidation(goldenVisaAccountsIdsWithSR); //Muzammil - This should be moved to validation rule.
        }
        if (!srHandoverList.isEmpty()) {
            ServiceRequestTriggerHelper.updateHandoverDetail(srHandoverList, newList);
        }
        if (!buyerIdList.isEmpty()) {
            ServiceRequestTriggerHelper.updateBuyerContact(newList, buyerIdList);
        }
        if(!unitSwapListList.isEmpty()){
            UnitSwapService.blockTheSwappedUnit(newList, new Map<Id, SObject>());
        }
    }
    /*
    *********************************************************
    @Method Name    : beforeUpdateMethod
    @author         : 
    @description    : Method to handle before update logic for Service Request
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //Local Variable Declaration Start
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srHandoverList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> updateSalesOrdSRAutoList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> chargeCollList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> paymentDateList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> paymentExtPerList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> moveInRequests = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> calWaiverPerAmtList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> unitSwapListList = new List<HexaBPM__Service_Request__c>();
        List<Id> salesOrderIdForRTORentCalculate = new List<Id>();        
        List<Id> buyerIdList = new List<Id>();        
        Set<Id> saleorderIds= new  Set<Id>();            
        List<HexaBPM__Service_Request__c> PTOffplanSRList= new  List<HexaBPM__Service_Request__c>(); 
        Set<String> serviceChargeSRTypeSet = new Set<String>();
        Set<Id> installmentLinesIdSet = new Set<Id>();
        Map<HexaBPM__Service_Request__c,Id> submittedLPCSRWithSOMap = new Map<HexaBPM__Service_Request__c,Id>();
        Map<String,ChargeRule__c> srTypeChargeDetailsMap = new Map<String,ChargeRule__c>();
        Map<Id,InstallmentLines__c> ilDetailsOfPESRTypeMap = new Map<Id,InstallmentLines__c>();
        Map<Id,InstallmentLines__c> installmentLineMap = new Map<Id,InstallmentLines__c>();
        map<id,SalesOrder__c> saleOrderMap = new map<id,SalesOrder__c>();                                
        //Local Variable Declaration End
        ServiceRequestTriggerHelper.checkBlacklisted(newList);
        ServiceRequestTriggerHelper.checkForFailedSR(newList); 
        //To get SR Related Records 
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c)oldmap.get(newRecord.Id);        
            if(newRecord.SalesOrder__c != null && newRecord.SalesOrder__c != oldRecord.SalesOrder__c) {
                saleorderIds.add(newRecord.SalesOrder__c); 
            }
            if(newRecord.SRType__c != null) {                                                          
                serviceChargeSRTypeSet.add(newRecord.SRType__c);
            }
            if(newRecord.InstallmentLine__c != null) {                                    
                installmentLinesIdSet.add(newRecord.InstallmentLine__c);
            }
            // Added by  daksh
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_OFFPLAN_RT) && newRecord.ChargeCollected__c == 0){
                newRecord.ChargeWaivedOff__c = True;
            }
            // SSR 751 OffPlan
            if (newRecord.SRType__c == Constants.PROPERTY_TRANSFER_OffPlan && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED && newRecord.HexaBPM__External_Status_Name__c != oldRecord.HexaBPM__External_Status_Name__c) {              	
                PTOffplanSRList.add(newRecord); 
            }            
        }
        
        // SSR 751 OffPlan        
        if(!PTOffplanSRList.isempty()){            
            PropertyTransferService.checkBeforeUpdatePTOfflineValidation(PTOffplanSRList);
          }
        
        saleOrderMap = ServiceRequestTriggerHelper.getsaleOrderMap(saleorderIds);                               
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c)oldmap.get(newRecord.Id);                                                           
            if(newRecord.SalesOrder__c!=null && newRecord.SalesOrder__c!=oldRecord.SalesOrder__c && !saleOrderMap.isEmpty()) {                          
                SalesOrder__c newSaleorder = saleOrderMap.get(newRecord.SalesOrder__c);
                if(newSaleorder!=null){
                    newRecord.HexaBPM__Email__c=newSaleorder.Contact__c !=null? newSaleorder.Contact__r.Email : newSaleorder.Account__r.PersonEmail!=null?newSaleorder.Account__r.PersonEmail :newSaleorder.Account__r.Email__c;  
                }
            }
            if (newRecord.Retrive_Buyer_Acc_Docs__c == true && (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_OFFPLAN_RT)){
                newRecord.Retrive_Buyer_Acc_Docs__c = false;
                fastTrackSRDocrecordsToProcess.add(newRecord);
            }
            if(newRecord.BuyerOwnershipVerifiedDari__c == true && oldRecord.BuyerOwnershipVerifiedDari__c == false && newRecord.SRType__c == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE ){
                newRecord.HexaBPM__Required_Docs_not_Uploaded__c = false;
            }            
            //Payment Extension Date Update
            if(newRecord.PaymentExtensionDate__c <> null && newRecord.InstallmentLine__c <> null && newRecord.PaymentExtensionDate__c <> oldRecord.PaymentExtensionDate__c){
                paymentDateList.add(newRecord);                                
            }                          
            //CLOSE SR- POPULATE DATE
            if(newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE) {
                if (newRecord.HexaBPM__IsClosedStatus__c && newRecord.HexaBPM__Closed_Date_Time__c == null) {
                    newRecord.HexaBPM__Closed_Date_Time__c = system.now();
                } else if (newRecord.UnitFromSameProject__c == Constants.YES && newRecord.HexaBPM__External_Status_Name__c == Constants.EQUITY_TRANSFERRED_SR) {
                    newRecord.HexaBPM__Closed_Date_Time__c = system.now();
                } else if (newRecord.UnitFromSameProject__c == Constants.NO && newRecord.HexaBPM__External_Status_Name__c == Constants.CLOSED_SR) {
                    newRecord.HexaBPM__Closed_Date_Time__c = system.now();
                }
            }                                                 
            // SSR751
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_OFFPLAN_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_EXTENSION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) && (newRecord.ChargeCollected__c == null || oldRecord.SRType__c != newRecord.SRType__c || oldRecord.ChargeType__c != newRecord.ChargeType__c)) {
                
                serviceRequestList.add(newRecord);
            }
            if (newRecord.HandoverDetail__c == null && (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT)) {
                srHandoverList.add(newRecord);
            }            
            if (newRecord.SRType__c == Constants.RTO_CANCELLATION_SR_TYPE) {
                chargeCollList.add(newRecord);                
            }            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) && newRecord.HexaBPM__External_Status_Name__c == Constants.BUYER_PROFILE_VERIFIED_STATUS) {
                newRecord.DocumentPrintedDate__c = Date.today();
            }
            if (newRecord.RefundAmount__c > 0 || newRecord.ReallocationAmount__c > 0) {
                newRecord.IsRefundApplicable__c = true;
            }            
            if (newRecord.TermCommencementDate__c != null && newRecord.SalesOrder__c != null && newRecord.TermCommencementDate__c != oldRecord.TermCommencementDate__c) {
                salesOrderIdForRTORentCalculate.add(newRecord.SalesOrder__c);
            }            
            if (newRecord.BuyerName__c != null && newRecord.BuyerName__c != oldRecord.BuyerName__c) {
                buyerIdList.add(newRecord.BuyerName__c);
            }            
            // calculate PaymentExtensionPeriod__c 
            if (newRecord.PaymentExtensionDate__c != null && newRecord.InstallmentDate__c != null && (newRecord.PaymentExtensionDate__c != oldRecord.PaymentExtensionDate__c || newRecord.InstallmentDate__c != oldRecord.InstallmentDate__c)) {
                paymentExtPerList.add(newRecord);
            }            
            // calculate WaivedPercentage__c and WaivedAmount__c is populated or changed.
            if(newRecord.TotalLPCDue__c != null && newRecord.TotalLPCDue__c != 0) {
                calWaiverPerAmtList.add(newRecord);                
            }
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT && newRecord.HexaBPM__External_Status_Name__c != oldRecord.HexaBPM__External_Status_Name__c && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED){
                submittedLPCSRWithSOMap.put(newRecord, newRecord.SalesOrder__c);
            }
            // populate ChargeCollected__c for LPC Waiver.
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT && (newRecord.WaivedPercentage__c != oldRecord.WaivedPercentage__c || newRecord.WaivedAmount__c != oldRecord.WaivedAmount__c)){
                chargeCollList.add(newRecord);
            }            
            //To Populate LPC Total, LPC Collected/Paid, LPC Waived and LPC Due 
            if(newRecord.Unit__c != oldRecord.Unit__c || newRecord.SalesOrder__c != oldRecord.SalesOrder__c){
                updateSalesOrdSRAutoList.add(newRecord);
                if (newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEIN) {
                    moveInRequests.add(newRecord);
                }                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT) {
                    LPCService.lpcBeforeUpdateLogic(newRecord);
                }                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT) {
                    PaymentPlanChangeService.checkPaidEquity(newRecord);
                }
            }
            if (newRecord.SwappedUnit__c != null && oldRecord.SwappedUnit__c != newRecord.SwappedUnit__c && oldRecord.SwappedUnit__c == null){
                unitSwapListList.add(newRecord);
            }
        }
        if(!paymentDateList.isEmpty()) {
            PaymentExtensionService.payMentExtDaysUpdate(paymentDateList,installmentLinesIdSet);
        }         
        PaymentExtensionService.paymentExtChargeCalUpdate(newList,serviceChargeSRTypeSet,installmentLinesIdSet);
        if(!chargeCollList.isEmpty()) {
            ServiceRequestTriggerHelper.updateChargeColl(chargeCollList);                        
        }
        if(!paymentExtPerList.isEmpty()) {
            PaymentExtensionService.paymentExtPerUpdate(paymentExtPerList);
        }
        if(!calWaiverPerAmtList.isEmpty()) {
           LPCService.calculateWaiverPercentageAmount(calWaiverPerAmtList,oldMap); 
        }
        if(!updateSalesOrdSRAutoList.isEmpty()) {
            ServiceRequestTriggerHelper.updateSalesOrderAndCustomer(updateSalesOrdSRAutoList);
            ServiceRequestTriggerHelper.checkSRAutomation(updateSalesOrdSRAutoList, oldMap);
        }
        if (!moveInRequests.isEmpty()) {
            ECSS_ServiceRequestTriggerHelper.estatesBeforeUpdate(moveInRequests);
        }
        if (!serviceRequestList.isEmpty()) {
            ServiceRequestTriggerHelper.updateChargeCollected(newList, serviceRequestList);
        }                        
        if (!buyerIdList.isEmpty()) {
            ServiceRequestTriggerHelper.updateBuyerContact(newList, buyerIdList);
        }        
        if (!srHandoverList.isEmpty()) {
            ServiceRequestTriggerHelper.updateHandoverDetail(srHandoverList, newList);
        }        
        if (!salesOrderIdForRTORentCalculate.isEmpty()) {
            ServiceRequestTriggerHelper.updateRTORent(salesOrderIdForRTORentCalculate, newList);
        }        
        if (!submittedLPCSRWithSOMap.isEmpty()) {
            LPCService.submittedLPC(submittedLPCSRWithSOMap);
        }   
        if(!unitSwapListList.isEmpty()) {     
            UnitSwapService.blockTheSwappedUnit(unitSwapListList, oldMap);
        }
    }
    /*
    *********************************************************
    @Method Name    : afterInsertMethod
    @author         : 
    @description    : Method to handle after Insert logic for Service Request
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Set<Id> accountIdsForCompliance = new Set<Id>();
        List<HexaBPM__Service_Request__c> moveInSR = new list<HexaBPM__Service_Request__c>();
        ServiceRequestTriggerHelper.checkSRAutoSubmitted((List<HexaBPM__Service_Request__c>)newList);
        // Added by Adarsh for ComplainceCheck
        for(HexaBPM__Service_Request__c newRecord : (List<HexaBPM__Service_Request__c>) newList){
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT ){
                if(newRecord.BuyerName__c !=null){
                    accountIdsForCompliance.add(newRecord.BuyerName__c);
                }
            }
            if ( newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEIN ) {
                moveInSR.add(newRecord);
            }
        }
        if(!accountIdsForCompliance.isEmpty()){
            PropertyTransferService.ComplianceCheck(accountIdsForCompliance);
        }
        if(!moveInSR.isEmpty()){
            ECSS_ServiceRequestTriggerHelper.estatesAfterInsert(moveInSR); // Why do we need this?
        }
       
        
        
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateMethod
    @author         : 
    @description    : Method to handle after update logic for Service Request
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        //Local Variable Declaration - Start
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> updateSRList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> aldarMovInStatusUpd = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srUnitSwapList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> complianceStepList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> nocSRToUpdateStepList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srToCloseADMStepList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Step__c> stepsToUpdate = new List<HexaBPM__Step__c>();
        List<HexaBPM__Service_Request__c> srToUpdateList = new List<HexaBPM__Service_Request__c>();        
        List<ID> cancellationSrIds = new List<ID>();
        List<Id> lpcFreezeSRsIds = new List<Id>();
        List<Id> salesOrderIdsForAPI = new List<Id>();
        List<Unit__c> updateUnitList = new List<Unit__c>();        
        set<ID> srIDsToClose = new set<ID>();
        set<ID> custIDsToBlock = new set<ID>();
        Set<Id> accountIdsForCompliance = new Set<Id>();
        Map<ID,HexaBPM__Service_Request__c> srIDAndSrToProcess = new Map<ID,HexaBPM__Service_Request__c>();               
        Boolean isCancellationDetailsChanged = false;
        //Local Variable Declaration - End        
        for(HexaBPM__Service_Request__c newRecord : (List<HexaBPM__Service_Request__c>) newList){
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c) oldMap.get(newRecord.ID);            
            // Added by Adarsh for ComplainceCheck            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT) && newRecord.BuyerName__c != oldRecord.BuyerName__c && newRecord.BuyerName__c != null){
                accountIdsForCompliance.add(newRecord.BuyerName__c); 
            }             
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT && ((newRecord.IsComplianceReturned__c != oldRecord.IsComplianceReturned__c && newRecord.IsComplianceReturned__c == true)  ||(newRecord.HexaBPM__External_Status_Name__c == Constants.BUYER_PROFILE_VERIFIED_STATUS) || (newRecord.Compliance_Status__c != oldRecord.Compliance_Status__c))) {
                complianceStepList.add(newRecord);
            }                        
            if (newRecord.BrokerManager__c != null && newRecord.BrokerManager__c != oldRecord.BrokerManager__c) {
                serviceRequestList.add(newRecord);
            }            
            if(newRecord.LPCFreezeStatus__c != oldRecord.LPCFreezeStatus__c && newRecord.LPCFreezeStatus__c == Constants.STATUS_IN_PROGRESS){
                lpcFreezeSRsIds.add(newRecord.Id);
            }            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || (newRecord.SRType__c == Constants.CANCELLATION_SR_TYPE && newRecord.SubType__c == Constants.UNIT_SWAP_SR_TYPE)) && newRecord.HexaBPM__External_Status_Name__c == Constants.DOCUMENTS_ARCHIVED_STATUS && newRecord.HexaBPM__Parent_SR__c != null) {
                HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
                updateSR.Id = newRecord.HexaBPM__Parent_SR__c;
                updateSR.IsChildSRCompleted__c = true;
                updateSRList.add(updateSR);
            } else if (newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT && newRecord.HexaBPM__Parent_SR__c != null) {
                HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
                updateSR.Id = newRecord.HexaBPM__Parent_SR__c;
                updateSR.IsChildSRCompleted__c = true;
                updateSRList.add(updateSR);
            }
            if (newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE && newRecord.HexaBPM__External_Status_Name__c == Constants.SALES_ORDER_CANCELLATION_COMPLETED_STATUS && newRecord.HexaBPM__External_SR_Status__c != oldRecord.HexaBPM__External_SR_Status__c) {                
                srUnitSwapList.add(newRecord);
            }
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.DEFAULT_AND_TERMINATION_DEV_RT){
                if(newRecord.LegalStatus__c != oldRecord.LegalStatus__c && newRecord.LegalStatus__c==Constants.LEGAL_CLEARED) {
                    srIDsToClose.add(newRecord.Id);
                } else if(newRecord.LegalStatus__c != oldRecord.LegalStatus__c) {
                    srIDAndSrToProcess.put(newRecord.Id,newRecord);
                    custIDsToBlock.add(newRecord.HexaBPM__Customer__c);
                }
                if(newRecord.Special_Exceptional_Case__c && newRecord.Special_Exceptional_Case__c!=oldRecord.Special_Exceptional_Case__c && newRecord.LegalFees__c!=null) {
                    //If Exceptional case, then create Other Charge with the fee entered by the legal team. Then Legal will manually move the step to DnT Team for Negotiation
                    srIDAndSrToProcess.put(newRecord.Id,newRecord);
                    custIDsToBlock.add(newRecord.HexaBPM__Customer__c);
                    ALD_DandTSR_Handler_CC.Special_Exceptional_Case = true;
                }
            }
            //CLose parent            
            if (newRecord.SalesOrder__c != null && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED && newRecord.HexaBPM__Internal_SR_Status__c != oldRecord.HexaBPM__Internal_SR_Status__c) {
                salesOrderIdsForAPI.add(newRecord.SalesOrder__c);
            }
            //SS_CREDIT_NOTE_CHANGES_SARAN_23-May-START
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.CREDIT_NOTE_CREATION_DEV_RT && !newRecord.HexaBPM__IsClosedStatus__c) {          
                updateSRList.add(CC_ALDRA_CreditNoteCreationProcess.updateCreditNoteSR(newRecord));
            }
            //SS_CREDIT_NOTE_CHANGES_SARAN_23-May-END            
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-START
            if(ServiceRequestTriggerHelper.isValidForCancellationCall(newRecord,oldRecord)) {
                isCancellationDetailsChanged = true;
                cancellationSrIds.add(newRecord.Id);
            }
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END            
            //MOVE-IN_SR_APPROVED-START
            if (((newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEIN || newRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEOUT) && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED && oldRecord.HexaBPM__External_Status_Name__c != newRecord.HexaBPM__External_Status_Name__c) ){               
                aldarMovInStatusUpd.add(newRecord);                 
            }
            if((newRecord.SRType__c == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE && (newRecord.IsChargeReceiptCreated__c != oldRecord.IsChargeReceiptCreated__c) && newRecord.IsChargeReceiptCreated__c == true && (newRecord.Origin__c == Constants.CUSTOMER_PORTAL || newRecord.Origin__c == Constants.CUSTOMER_APP))){
                nocSRToUpdateStepList.add(newRecord);
            }
            if((newRecord.SRType__c == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE && (newRecord.BuyerOwnershipVerifiedDari__c != oldRecord.BuyerOwnershipVerifiedDari__c) && newRecord.BuyerOwnershipVerifiedDari__c == true)){
                srToCloseADMStepList.add(newRecord);                
            }                      
        }        
        
        
        if(!aldarMovInStatusUpd.isEmpty()) {
            ECSS_ServiceRequestTriggerHelper.afterUpdSRStatusUpd(aldarMovInStatusUpd);
        }
        if (!nocSRToUpdateStepList.isEmpty()) {
            System.enqueueJob(new CloseDigitalPaymentStepQueueable(nocSRToUpdateStepList));
        }
        if (!srToCloseADMStepList.isEmpty()) {
            PropertyTransferService.closeADMStep(srToCloseADMStepList);
        }
        if(!complianceStepList.isEmpty()) {  
            ServiceRequestTriggerHelper.handleComplianceStepUpdate(complianceStepList,stepsToUpdate,srToUpdateList);
            if (!stepsToUpdate.isEmpty()) {update stepsToUpdate;
            }
            if (!srToUpdateList.isEmpty()) {update srToUpdateList;
            }
        }        
        if(!accountIdsForCompliance.isEmpty()){PropertyTransferService.ComplianceCheck(accountIdsForCompliance);
        }
        if(!fastTrackSRDocrecordsToProcess.isEmpty()) {
            FastTRackSRDOCQueueable job = new FastTRackSRDOCQueueable(fastTrackSRDocrecordsToProcess);
            System.enqueueJob(job);
        }      
        if (!updateSRList.isEmpty()) {update updateSRList;
        }
        if (!srUnitSwapList.isEmpty()) {UnitSwapService.updateSwapUnits(srUnitSwapList);
        }        
        if (!serviceRequestList.isEmpty()) {
            // to share SR record with Broker Manager.
            ShareHelper.shareServiceRequestBrokerManager(serviceRequestList, Constants.EDIT_ACCESS);
        }
        if(!srIDsToClose.isEmpty()){DefaultAndTerminationUtility.closeDandTSRAfterLegal( srIDsToClose);
        }        
        //SS_DandT_Revamp_SP15-Start
        if(!custIDsToBlock.isEmpty()){ALD_DandTSR_Handler_CC.handleDandTSR(custIDsToBlock, srIDAndSrToProcess);
        }
        //SS_DandT_Revamp_SP15-END        
        if(!lpcFreezeSRsIds.isEmpty()){LPCCalloutHelper.getDataForFreezeCallout(lpcFreezeSRsIds, true);
        }
        if(!salesOrderIdsForAPI.isEmpty()) {ServiceRequestTriggerHelper.saleOrderCallout(salesOrderIdsForAPI);
        }
       
        // Logic For Unfreeze LPCDate
        
        if (!newList.isEmpty()) {
            Map<Id, HexaBPM__Service_Request__c> oldSRMap = new Map<Id, HexaBPM__Service_Request__c>();
            for (Id srId : oldMap.keySet()) {
                oldSRMap.put(srId, (HexaBPM__Service_Request__c) oldMap.get(srId));
            }
           List<HexaBPM__Service_Request__c> newSRList = (List<HexaBPM__Service_Request__c>) newList;
            
            PropertyTransferSRLPCUnfreezeHandler.handleServiceRequestStatusChange(newSRList, oldSRMap);
        }
        
        
        
        //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15
        doCancellationCall(isCancellationDetailsChanged, cancellationSrIds);
        SPATitleDeedRegistration.handleOfflineProceess(newList,oldMap);
        SPATitleDeedRegistration.handleOfflineProcessTDSR(newList,oldMap);
        ServiceRequestTriggerHelper.updateClosedSRSOAndAccount(newList, newMap);
    } 
    /*
    *********************************************************
    @Method Name    : doCancellationCall
    @author         : 
    @description    : Method to call the cancelation webservice
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */        
    public static void doCancellationCall(Boolean isCancellationDetailsChanged, List<Id> cancellationSrIds) {
        if(isCancellationDetailsChanged && cancellationSrIds.size() > 0) {
            CancellationCalloutHelper.ApprovalStatus = Constants.OPEN;
            CancellationCalloutHelper.getDataForCallout(cancellationSrIds);
        }
    }                 
    /*
    *********************************************************
    @Method Name    : aldarstaffPTValidation
    @author         : Tharun to update ReferredBy Profile Name ASF-1367
    @description    : IStaff Purchase Validation for Property Transfer Process : @jira:ASF-1860
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */ 
    public static String aldarstaffPTValidation(HexaBPM__Service_Request__c serviceRequest, SalesOrder__c salesOrder){
        try{
            if(serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT && serviceRequest.HexaBPM__Customer__c != null && serviceRequest.HexaBPM__Customer__r.CustomerType__c!=null && serviceRequest.HexaBPM__Customer__r.CustomerType__c.equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && serviceRequest.Unit__r.BuildingSectionName__c!=null && serviceRequest.Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c !=null){            
                List<String> installmentValues = System.Label.Staff_Purchase_PP_Validation.contains(',')?System.Label.Staff_Purchase_PP_Validation.split(','):new List<string>{System.Label.Staff_Purchase_PP_Validation};
                List<InstallmentLines__c> installmentLineList = [SELECT Id,InstallmentPercentage__c FROM InstallmentLines__c WHERE SalesOrder__c=:salesOrder.Id ORDER BY InstallmentNumber__c DESC LIMIT 1]; 
                if(!installmentLineList.isEmpty() && installmentLineList[0].InstallmentPercentage__c != null && installmentValues.contains(String.valueOf(installmentLineList[0].InstallmentPercentage__c))){
                    return System.label.Staff_Purchase_Validation_PP_Plan_Error;
                }
                if(!serviceRequest.BuyerName__r.CustomerType__c.equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && salesOrder.EquityPercentage__c != null && serviceRequest.Unit__c!=null ){
                    if(serviceRequest.Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c >= salesOrder.EquityPercentage__c){
                        return System.Label.Staff_Purchase_Validation_Threshold_Error;
                    }
                }
            } 
            return null;
        }catch(Exception ex){
            system.debug('Exception:'+ex.getMessage());
            return 'Error! Occured. Reachout your admin.';
        }
    }
}