/*
*********************************************************
Apex Class Name    : ServiceRequestTriggerHelper
Created Date       : June 27 2025
@description       : This Class is used for ServiceRequestTriggerHandler Common Logic
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class ServiceRequestTriggerHelper {

    /*ServiceChargeFee-Start*/
    public static Set < String > serviceChargeSRTypeUtilSet = new Set < String > {
        Constants.PAYMENT_EXTENSION_TYPE,
        Constants.PAYMENT_PLAN_CHANGE_RT,
        Constants.INVESTOR_CERTIFICATE_RT,
        Constants.LPC_WAIVER_TYPE,
        Constants.INVESTOR_CERT_LETTER_ISSUE,
        Constants.INVESTOR_CERT_ATTESTED_SPA
    };    
    /*ServiceChargeFee-End*/

    /*Start - Added By Manivannan*/    
    public static final Set < String > errorMessages = new Set < String > {
        Constants.PPC_PAID_EQUITY_100_VALIDATION,
        Constants.GOLDEN_VISA_IS_APPLICABLE_FOR_PERSON_ACC,
        Constants.PPC_PAID_EQUITY_100_VALIDATION,
        Constants.PPC_PAID_EQUITY_VALIDATION,
		Constants.DUPLICATE_SR_MESSAGE,
        Constants.CUSTOMER_BLACKLISTED_COMPLIANCE,
		Constants.CUSTOMER_BLACKLISTED_DEFAULT,
		Constants.CUSTOMER_BLACKLISTED,
		Constants.SYNC_STATUS_ERROR_SR_MESSAGE    
    };

    public static Map<String, SystemMessages__mdt> systemMessagesMap;
    public static Map<String, SystemMessages__mdt> getSystemMessagesMap() {
        if (systemMessagesMap == null) {
            systemMessagesMap = AldarUtilityClass.getSystemMessages(errorMessages);
        }
        return systemMessagesMap;
    }

    public static User userDetail;    
    public static user getUserDetail() {
        if(userDetail == null) {
            userDetail = Utilities.getLoggedInUserDetail();
        }
        return userDetail;
    }
    
    public static Map<Id, InstallmentLines__c> installmentMap;
    public static Map<Id, InstallmentLines__c> getinstallmentLineMap(Set<ID> installmentLines) {
        if (installmentMap == null) {
            installmentMap = AldarUtilityClass.fetchInstallmentLines(installmentLines);
        }
        return installmentMap;
    }

    public static Map<String, ChargeRule__c> srTypeChargeDetailsMap;
    public static Map<String, ChargeRule__c> getsrTypeChargeDetailsMap(Set<String> serviceChargeSRTypeSet) {
        if (srTypeChargeDetailsMap == null) {
            srTypeChargeDetailsMap = AldarUtilityClass.fetchChargeRule(serviceChargeSRTypeSet);
        }
        return srTypeChargeDetailsMap;
    }

    public static Map<id, SalesOrder__c> saleOrderMap;
    public static Map<id, SalesOrder__c> getsaleOrderMap(Set<Id> saleorderIds) {
        if (saleOrderMap == null) {
            saleOrderMap = AldarUtilityClass.fetchSalesOrder(saleorderIds);
        }
        return saleOrderMap;
    }

    public static Map<String, HexaBPM__Status__c> stepStatusMap;
    public static Map<String, HexaBPM__Status__c> getStepStatus() {
        if (stepStatusMap == null) {
            stepStatusMap = AldarUtilityClass.fetchStepStatus();
        }
        return stepStatusMap;
    }

    public static Map<String, HexaBPM__SR_Status__c> srStatusMap;
    public static Map<String, HexaBPM__SR_Status__c> getSRStatus() {
        if (srStatusMap == null) {
            srStatusMap = AldarUtilityClass.fetchSRStatus();
        }
        return srStatusMap;
    }
	/*End - Added By Manivannan*/  

    public static Map<String, Id> recordTypeByName {
        get { if(recordTypeByName == null) recordTypeByName = AldarUtilityClass.getRecordTypeIdByParam('HexaBPM__Service_Request__c','Name'); return recordTypeByName; }
        private set; 
    }
    
    /*
    *********************************************************
    @Method Name    : updateSalesOrderAndCustomer
    @author         : 
    @description    : Updating SalesOder and Customer details on New SR
    @param          : newSRList - List of New SR
    @return         : void
    ********************************************************
    */
    public static void updateSalesOrderAndCustomer(List<HexaBPM__Service_Request__c> newSRList) {
        List<Id> unitIds = new List<Id>();
        Map<String, SalesOrder__c> unitSalesOrderMap = new Map<String, SalesOrder__c>();
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.Unit__c != null) {
                unitIds.add(srRecord.Unit__c);
            } 
        }                
        for (SalesOrder__c salesOrder: SalesOrderService.getSalesOrdersByUnitIds(unitIds)) {
            if(salesOrder.Status__c == Constants.SO_STATUS_SOLD || salesOrder.Status__c == Constants.SO_STATUS_RTO_SOLD || salesOrder.Status__c == Constants.STATUS_APPROVAL_PENDING){
                unitSalesOrderMap.put(salesOrder.Unit__c, salesOrder);
            }            
        }        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.Unit__c != null && unitSalesOrderMap.containsKey(srRecord.Unit__c) && srRecord.SRType__c != Constants.CANCELLATION && srRecord.SubType__c != Constants.SALES_CANCELLATION) {
                SalesOrder__c salesOrder = unitSalesOrderMap.get(srRecord.Unit__c);
                srRecord.HexaBPM__Customer__c = salesOrder.Account__c;
                srRecord.HexaBPM__Contact__c = salesOrder.Contact__c;
                srRecord.SalesOrder__c = salesOrder.Id;                
                if (srRecord.TotalCollectedAmount__c == null || srRecord.TotalCollectedAmount__c == 0) {
                    srRecord.TotalCollectedAmount__c = salesOrder.TotalBilled__c;
                }                
                if(srRecord.HexaBPM__Contact__c == null){
                    srRecord.HexaBPM__Contact__c = salesOrder.Account__r.PersonContactId;
                }
                //To Populate PaidEquity__c for Payment Plan Change
                if(srRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT){                    
                    srRecord.PaidEquity__c = ((salesOrder.TotalBilled__c / salesOrder.NetAmount__c) * 100).round();                    
                    if(!srRecord.Bypass_Equity_Check__c && salesOrder.NumberOfDefaults__c > 0 && srRecord.PaidEquity__c < 20 && salesOrder.HoldFlag__c == true && !srRecord.ExemptValidations__c){
                        srRecord.addError(getSystemMessagesMap().get(Constants.PPC_PAID_EQUITY_VALIDATION).Message__c);
                    }
                }
            }
        }      
    }    
    /*
    *********************************************************
    @Method Name    : updateHandoverDetail
    @author         : 
    @description    : Method to update the Handove detail on new Service Request
    @param          : newHandoverSRList, newSRList 
    @return         : void
    ********************************************************
    */
    public static void updateHandoverDetail(List<HexaBPM__Service_Request__c> newHandoverSRList, List<HexaBPM__Service_Request__c> newSRList) {
        
        List<Id> soIds = new List<Id>();
        for (HexaBPM__Service_Request__c srRecord: newHandoverSRList) {
            if (srRecord.SalesOrder__c != null) {
                soIds.add(srRecord.SalesOrder__c);
            }
        }        
        if(!soIds.isEmpty()) {
            List<HexaBPM__Service_Request__c> handoverSRList = [SELECT Id, HandoverDetail__c, SalesOrder__c, HandoverDetail__r.RFODate__c, 
                                                                HandoverDetail__r.ServiceChargeStartDate__c FROM HexaBPM__Service_Request__c 
                                                                WHERE RecordType.Name =: Constants.HANDOVER_RT AND SalesOrder__c IN: soIds 
                                                                AND HandoverDetail__c != null];            
            Map<Id, HexaBPM__Service_Request__c> handoverSRMap = new Map<Id, HexaBPM__Service_Request__c>();
            for (HexaBPM__Service_Request__c handoverSR: handoverSRList) {
                handoverSRMap.put(handoverSR.SalesOrder__c, handoverSR);
            }
            for (HexaBPM__Service_Request__c srRecord: newSRList) {
                if (srRecord.SalesOrder__c != null && handoverSRMap.containsKey(srRecord.SalesOrder__c)) {
                    srRecord.HandoverDetail__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__c;
                    srRecord.RFODate__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__r.RFODate__c;
                    srRecord.ServiceChargeStartDate__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__r.ServiceChargeStartDate__c;
                }
            }
        }
    }

     /*
    *********************************************************
    @Method Name    : updateChargeCollected
    @author         : 
    @description    : Updating the Charge Collected on the Service Request based on the charge rule
    @param          : newList,serviceRequestList
    @return         : void
    ********************************************************
    */ 
    public static void updateChargeCollected(List<HexaBPM__Service_Request__c> newList, List<HexaBPM__Service_Request__c> serviceRequestList) {
        Map<String, ChargeRuleModel> chargeMap = new Map<String, ChargeRuleModel>();
        List<ChargeRuleModel> chargeList = ChargeRuleService.getChargeRuleByType(serviceRequestList);
        for (ChargeRuleModel charge: chargeList) {
            chargeMap.put(charge.serviceRequestId, charge);
        }
        
        for(HexaBPM__Service_Request__c newRecord: newList) {
            if(!chargeMap.isEmpty() && chargeMap.containsKey(newRecord.Id)) {
                ChargeRuleModel chargeRule = chargeMap.get(newRecord.Id);
                newRecord.AmountWithoutVAT__c = chargeRule.chargeAmountPercentage;
                newRecord.ChargeCollected__c = chargeRule.chargeAmountPercentage;
                if (chargeRule.vatChanges != null && chargeRule.vatChanges != 0) {
                    newRecord.ChargeCollected__c = chargeRule.chargeAmountPercentage + ((chargeRule.chargeAmountPercentage * chargeRule.vatChanges) / 100).setScale(2);
                }
                if (chargeRule.chargeRuleId != null) {
                    newRecord.ChargeRule__c = chargeRule.chargeRuleId;
                }
                newRecord.ChargeCollectedInWords__c = Utilities.amountInWords(newRecord.ChargeCollected__c,'Dirham','Fils');
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : updateChargeColl
    @author         : 
    @description    : Method to update the SR ChargeCollected fiels
    @param          : paymentExtSR 
    @return         : void
    ********************************************************
    */
    public static void updateChargeColl(List<HexaBPM__Service_Request__c> newSRList) {
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT ){                
                srRecord.ChargeCollected__c = srRecord.TotalLPCDue__c != null ? srRecord.TotalLPCDue__c - (srRecord.WaivedAmount__c != null ? srRecord.WaivedAmount__c  : 0) : 0;                
                srRecord.ChargeCollected__c = (srRecord.ChargeCollected__c).setScale(2);
            } else if (srRecord.SRType__c == Constants.RTO_CANCELLATION_SR_TYPE) {
                srRecord.ChargeCollected__c = srRecord.LegalPenaltyFee__c != null ? srRecord.LegalPenaltyFee__c : 0;
                srRecord.ChargeCollected__c += srRecord.ExitPenaltyFee__c != null ? srRecord.ExitPenaltyFee__c : 0;
                srRecord.ChargeCollected__c += srRecord.CostofFix__c != null ? srRecord.CostofFix__c : 0;
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : updateBuyerContact
    @author         : 
    @description    : Method to update Buyer Contact on SR
    @param          : newSRList - list of new SRs
    @return         : void
    ********************************************************
    */ 
    public static void updateBuyerContact(List<HexaBPM__Service_Request__c> newList, List<Id> buyerIdList) {
        List<Account> acclist = AccountService.queryAllFieldsWithExtraFields(buyerIdList);
        Map<Id, Id> accountContactMap = new Map<Id, Id>();
        for (Account acc: acclist) {
            if (acc.isPersonAccount) {
                accountContactMap.put(acc.Id, acc.PersonContactId);
            } else {
                for (Contact con: acc.Contacts) {
                    accountContactMap.put(acc.Id, con.Id);
                }
            }
        }        
        for(HexaBPM__Service_Request__c newRecord: newList) {
            if(newRecord.BuyerName__c != null && accountContactMap.containsKey(newRecord.BuyerName__c)) {
                newRecord.BuyerContact__c = accountContactMap.get(newRecord.BuyerName__c);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : checkSRAutomation
    @author         : 
    @description    : Prevents duplicate or overlapping Service Requests for the same asset or Salesorder
    @param          : newSRList - list of new SRs, oldMap - map of old SRs
    @return         : void
    ********************************************************
    */ 
    public static void checkSRAutomation(List<HexaBPM__Service_Request__c> newSRList, Map<Id, SObject> oldMap) {
        Set<String> srTypesList = new Set<String>();   
        Map<String, SRAutomation__mdt> srAutomationMap = new Map<String, SRAutomation__mdt>();      
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SRType__c != null) {
                srTypesList.add(srRecord.SRType__c);
            }
        }                      
        if(srTypesList.size() > 0){
            srAutomationMap = Utilities.getSRAutomation(srTypesList);
        }       
        if(srAutomationMap.size() > 0){            
            Map<String,HexaBPM__Service_Request__c> openSRMap = ServiceRequestService.getOpenServiceRequestByType(srAutomationMap.keySet());                                  
            for (HexaBPM__Service_Request__c srRecord: newSRList) {                
                SRAutomation__mdt srAuto = srRecord.SRType__c != null ? srAutomationMap.get(srRecord.SRType__c) : null;
                HexaBPM__Service_Request__c openSRRecord = new HexaBPM__Service_Request__c();
                if(srRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEIN || srRecord.SRType__c == Constants.ALDAR_ESTATES_MOVEOUT){
                    openSRRecord = srAuto != null && openSRMap.get(srRecord.Asset__c + '-' + srRecord.SRType__c) != null ? openSRMap.get(srRecord.Asset__c + '-' + srRecord.SRType__c) : null;
                    if (srAuto != null && srAuto.DuplicateCheckRequired__c == true && openSRRecord != null && srRecord.Asset__c != null) {
                        SystemMessages__mdt messageDetails = getSystemMessagesMap().get(Constants.DUPLICATE_SR_MESSAGE);
                        srRecord.addError(messageDetails.Message__c);
                    }
                }else{
                    openSRRecord = srAuto != null && openSRMap.get(srRecord.SalesOrder__c + '-' + srRecord.SRType__c) != null ? openSRMap.get(srRecord.SalesOrder__c + '-' + srRecord.SRType__c) : null;                    
                    if (srAuto != null && srAuto.DuplicateCheckRequired__c == true && openSRRecord != null && srRecord.SalesOrder__c != null) {
                        SystemMessages__mdt messageDetails = getSystemMessagesMap().get(Constants.DUPLICATE_SR_MESSAGE);
                        srRecord.addError(messageDetails.Message__c);
                    }                     
                }
            }                        
        }
    }
    /*
    *********************************************************
    @Method Name    : checkSRAutoSubmitted
    @author         : 
    @description    : If the SR Type is flagged for auto-submission, then we will automatically submit those SRs
    @param          : newSRList - list of new SRs
    @return         : void
    ********************************************************
    */ 
    public static void checkSRAutoSubmitted(List<HexaBPM__Service_Request__c> newSRList) {
        Set<String> srTypesList = new Set<String>();
        Map<String, SRAutomation__mdt> srAutomationMap = new Map<String, SRAutomation__mdt>();       
        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SRType__c != null) {
                srTypesList.add(srRecord.SRType__c);
            }
        }
        if(srTypesList.size() > 0){
            srAutomationMap = Utilities.getSRAutomation(srTypesList);
        }
        if(srAutomationMap.size() > 0){
            List<Id> newSRRecordsToBeSubmitted = new List<Id>();
            for (HexaBPM__Service_Request__c srRecord: newSRList) {
                SRAutomation__mdt srAuto = srRecord.SRType__c != null ? srAutomationMap.get(srRecord.SRType__c) : null;
                if(srAuto != null && srAuto.AutoSubmission__c == true){
                    newSRRecordsToBeSubmitted.add(srRecord.Id);
                }
            }
            if(newSRRecordsToBeSubmitted.size() > 0){
                SRUtility.submitSRFuture(newSRRecordsToBeSubmitted);
            }
        }
    }                        
	/*
    *********************************************************
    @Method Name    : checkBlacklisted
    @author         : 
    @description    : If the SR Type is flagged for blacklisted customer, then we will automatically block the SR
    @param          : newSRList - list of new SRs
    @return         : void
    ********************************************************
    */ 
    public static void checkBlacklisted(List<HexaBPM__Service_Request__c> newSRList) {
        List<SRAutomation__mdt> srAutomationList = SRAutomation__mdt.getall().values();        
        Map<String, Boolean> srAutomationMap = new Map<String, Boolean>();
        User usr = getUserDetail();
        for(SRAutomation__mdt srAutomation : srAutomationList){
            srAutomationMap.put(srAutomation.SRType__c, srAutomation.AllowBlacklisted__c);
        }
        if(usr.ProfileName__c!= Constants.INTEGRATION_PROFILE){
            for (HexaBPM__Service_Request__c srRecord: newSRList) { 
                if (srRecord.HexaBPM__Record_Type_Name__c != Constants.CREDIT_NOTE_CREATION_HEXA_SR_TYPE){
                    if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && String.isNotBlank(srRecord.BlacklistedCustomer__c) && srRecord.BlacklistedCustomer__c.containsIgnoreCase(Constants.BLACKLISTED_CUSTOMER_COMPLIANCE)) {
                        srRecord.addError(getSystemMessagesMap().get(Constants.CUSTOMER_BLACKLISTED_COMPLIANCE).Message__c);
                    } else if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srAutomationMap.containsKey(srRecord.SRType__c) && srRecord.SalesOrderHoldFlag__c && srAutomationMap.get(srRecord.SRType__c) == false) {
                        srRecord.addError(getSystemMessagesMap().get(Constants.CUSTOMER_BLACKLISTED_DEFAULT).Message__c);
                    } else if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && String.isNotBlank(srRecord.BlacklistedCustomer__c) && srRecord.BlacklistedCustomer__c.equalsIgnoreCase('true')) {
                        srRecord.addError(getSystemMessagesMap().get(Constants.CUSTOMER_BLACKLISTED).Message__c);
                    }
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : checkForFailedSR
    @author         : 
    @description    : If the SR Type is flagged for failed, then we will automatically block the SR
    @param          : newSRList - list of new SRs
    @return         : void
    ********************************************************
    */
    public static void checkForFailedSR(List<HexaBPM__Service_Request__c> newSRList) {
        List<Id> soIds = new List<Id>();
        List<Id> srIds = new List<Id>();
        User usr = getUserDetail();
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            srIds.add(srRecord.Id);
            if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__External_Status_Name__c != Constants.SR_STATUS_DRAFT && srRecord.HexaBPM__External_Status_Name__c != Constants.SUBMITTED) {
                soIds.add(srRecord.SalesOrder__c);
            }
        }
        if(!soIds.isEmpty()) {
            List<HexaBPM__Service_Request__c> failedSRList = [SELECT Id, SalesOrder__c, SyncStatus__c FROM HexaBPM__Service_Request__c 
                                                            WHERE Id NOT IN: srIds AND SalesOrder__c IN: soIds AND SalesOrder__c != null
                                                            AND SyncStatus__c =: Constants.STATUS_FAILED];            
            if(usr.ProfileName__c!= Constants.INTEGRATION_PROFILE && usr.ProfileName__c!=Label.System_Admin){
                for (HexaBPM__Service_Request__c srRecord: newSRList) {
                    if (!failedSRList.isEmpty()) { // Need to Discuss
                        SystemMessages__mdt message = getSystemMessagesMap().get(Constants.SYNC_STATUS_ERROR_SR_MESSAGE);
                        srRecord.addError(message.Message__c);
                        break;
                    }
                }
            }
        }
    } 
    /*
    *********************************************************
    @Method Name    : handleComplianceStepUpdate
    @author         : 
    @description    : Method to handle the step update for compliance step
    @param          : newSRList - list of new SRs
    @return         : void
    ********************************************************
    */
    public static void handleComplianceStepUpdate(List<HexaBPM__Service_Request__c> newList, List<HexaBPM__Step__c> stepsToUpdate, List<HexaBPM__Service_Request__c> srToUpdateList) {        
        Map<ID,HexaBPM__Step__c> stepMap = new Map<ID,HexaBPM__Step__c>();
        Map<String, HexaBPM__SR_Status__c> srStatusMap = new Map<String, HexaBPM__SR_Status__c>();
        Map<String, HexaBPM__Status__c> closureStatusMap = new Map<String, HexaBPM__Status__c>();
        set<Id> srIds = new set<Id>();                                    
        srStatusMap = getSRStatus();
        closureStatusMap = getStepStatus();
        for(HexaBPM__Service_Request__c newRecord : newList) {
            srIds.add(newRecord.id);
        }        
        if(!srIds.isEmpty()){
            for(HexaBPM__Step__c step : [SELECT Id,HexaBPM__SR__c, HexaBPM__Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN:srIds AND HexaBPM__Summary__c = 'Compliance Check for Buyers' ORDER BY CreatedDate DESC LIMIT 1]) {
                stepMap.put(step.HexaBPM__SR__c,step);
            }
        }
        for(HexaBPM__Service_Request__c newRecord : newList){
            if (stepMap.containsKey(newRecord.Id) && stepMap.get(newRecord.Id) != null ) {
                HexaBPM__Step__c stepToUpdate = stepMap.get(newRecord.Id);
                String statusId = '';
                String externalStatusId = '';
                if (newRecord.Compliance_Status__c == Constants.Returned) {
                    statusId = closureStatusMap.get(Constants.Returned)?.Id;
                    externalStatusId = srStatusMap.get(Constants.Returned)?.Id;
                } else if (newRecord.Compliance_Status__c == Constants.CLEARED) {
                    statusId = closureStatusMap.get(Constants.SRCleared)?.Id;
                    externalStatusId = srStatusMap.get(Constants.Compliance_Cleared)?.Id;
                } else if (newRecord.Compliance_Status__c == Constants.Rejected) {
                    statusId = closureStatusMap.get(Constants.Rejected)?.Id;
                    externalStatusId = srStatusMap.get(Constants.Compliance_Rejected)?.Id;
                }
                if (String.isNotBlank(statusId)) {
                    stepsToUpdate.add(new HexaBPM__Step__c(Id = stepToUpdate.Id, HexaBPM__Status__c = statusId));
                    
                    HexaBPM__Service_Request__c srUpdate = new HexaBPM__Service_Request__c(
                        Id = newRecord.Id,
                        HexaBPM__External_SR_Status__c = externalStatusId
                    );
                    if(newRecord.Compliance_Status__c == Constants.Returned){
                        srUpdate.IsComplianceReturned__c = true;
                    }else{
                        srUpdate.IsComplianceReturned__c = false;
                    }
                    srToUpdateList.add(srUpdate);
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : isValidForCancellationCall
    @author         : 
    @description    : This method is used to check if the service request is in a valid state to call the cancel API
    @param          : newRecord, oldRecord
    @return         : void
    ********************************************************
    */
    public static Boolean isValidForCancellationCall(HexaBPM__Service_Request__c newRecord,HexaBPM__Service_Request__c oldRecord) {
        Boolean isCancellationDetailsChanged = false;
        
        if (Test.isRunningTest() || isCancellationSRNonClosed(newRecord)) {
            if( (newRecord.HexaBPM__Submitted_DateTime__c != oldRecord.HexaBPM__Submitted_DateTime__c && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED) || 
               newRecord.CancellationReason__c != oldRecord.CancellationReason__c ||
               newRecord.SocialReason__c != oldRecord.SocialReason__c ||
               newRecord.TotalCollectedAmount__c != oldRecord.TotalCollectedAmount__c || 
               newRecord.AgreementType__c != oldRecord.AgreementType__c ||
               newRecord.ReallocationAmount__c != oldRecord.ReallocationAmount__c ||
               newRecord.CancellationOption__c != oldRecord.CancellationOption__c ||
               newRecord.ForfeitAmount__c != oldRecord.ForfeitAmount__c ||
               newRecord.PriceRevisionRequired__c != oldRecord.PriceRevisionRequired__c)
            {
                isCancellationDetailsChanged = true;
            }
        }
        return isCancellationDetailsChanged;
    }    
    public static Boolean isCancellationSRNonClosed(HexaBPM__Service_Request__c newRecord) {
        return newRecord.SRType__c == Constants.CANCELLATION_INTEGRATION && !newRecord.HexaBPM__IsClosedStatus__c;
    }        
    //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END
    /*
    *********************************************************
    @Method Name    : saleOrderCallout
    @author         : 
    @description    : Method to call the API for the Sales Order
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */
    public static void saleOrderCallout(List<Id> salesOrderIdsForAPI) {
        List<Id> soIds = new List<Id>();
        for(SalesOrder__c salesOrder :[SELECT Id, SyncStatus__c FROM SalesOrder__c WHERE Id IN: salesOrderIdsForAPI AND SyncStatus__c =:Constants.STATUS_FAILED]) {
            soIds.add(salesOrder.Id);
        }
        if (!soIds.isEmpty()) {
            SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
        }
    }
    
    /*
    *********************************************************
    @Method Name    : updateRTORent
    @author         : 
    @description    : Method to update the RTO field on sales order line item
    @param          : salesOrderIdForRTORentCalculate,newSRList
    @return         : void
    ********************************************************
    */
    public static void updateRTORent(List<Id> salesOrderIdForRTORentCalculate, List<HexaBPM__Service_Request__c> newSRList) {
        List<SalesOrder__c> salesOrderList = [SELECT Id, Name, (SELECT Id, Name, InstallmentDate__c, RTOEndDate__c, InstallmentAmount__c 
                                                                FROM InstallmentLines__r ORDER BY InstallmentNumber__c ASC) FROM SalesOrder__c 
                                              WHERE Id IN: salesOrderIdForRTORentCalculate];        
        Map<Id, List<InstallmentLines__c>> soInstallmentLineMap = new Map<Id, List<InstallmentLines__c>>();
        for (SalesOrder__c salesOrder: salesOrderList) {
            soInstallmentLineMap.put(salesOrder.Id, salesOrder.InstallmentLines__r);
        }        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SalesOrder__c != null && soInstallmentLineMap.containsKey(srRecord.SalesOrder__c)) {
                Decimal rent = 0;
                Boolean isCurrentYear = false;
                for (InstallmentLines__c lines: soInstallmentLineMap.get(srRecord.SalesOrder__c)) {
                    if (!isCurrentYear && srRecord.TermCommencementDate__c >= lines.InstallmentDate__c && srRecord.TermCommencementDate__c < lines.RTOEndDate__c) {
                        isCurrentYear = true;
                        Integer noOfDays = srRecord.TermCommencementDate__c.daysBetween(lines.RTOEndDate__c);
                        rent = (lines.InstallmentAmount__c / 365) * noOfDays;
                        break;
                    }
                }
                srRecord.AnnualRentForTheRemainingYear__c = rent.setScale(2);
            }
        }
    }    
	
	
    //Update SO and account
    public static void updateClosedSRSOAndAccount(List<sObject> newSrList ,Map<Id, sObject> srMapNew) {
        List<SObject> recordsToUpdate = new List<SObject>();
        Map< Id, SalesOrder__c> UpdateSOMap = new Map< Id, SalesOrder__c>();
        Map<Id, HexaBPM__Service_Request__c> closedSRMap = new  Map<Id, HexaBPM__Service_Request__c>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> soIds = new Set<Id>();
        Set<Id> legalAccountSet = new Set<Id>();
        Set<Id> legalSOSet = new Set<Id>();
        Map<Id, Account> updateAccMap = new Map<Id, Account>();

        system.debug('newSrList'+newSrList );
        
        for(HexaBPM__Service_Request__c sr :  (List<HexaBPM__Service_Request__c>)newSrList ){
                    system.debug('Servive req'+sr );

            if(sr.HexaBPM__External_Status_Name__c.equalsIgnoreCase(Constants.CLOSED) && sr.SRType__c == Constants.DEFAULT_AND_TERMINATION && String.isNotBlank(sr.SalesOrder__c)){
					system.debug('SRTYpe'+sr.SRType__c );
                    //Closed SR Map....
                    closedSRMap.put(sr.Id, sr);accIds.add(sr.HexaBPM__Customer__c);soIds.add(sr.SalesOrder__c);
            }
        }

        //Get all D&T SR status is not closed by account Id....
        List<HexaBPM__Service_Request__c> closedSRList = [SELECT Id, HexaBPM__External_Status_Name__c, SalesOrder__c,HexaBPM__Customer__c,
                                                            SalesOrder__r.HoldFlag__c, SalesOrder__r.HoldReasonCode__c,HexaBPM__Internal_Status_Name__c,
                                                            HexaBPM__Customer__r.BlacklistReason__c, HexaBPM__Customer__r.Blacklisted__c
                                                            FROM HexaBPM__Service_Request__c 
                                                            WHERE HexaBPM__Customer__c IN : accIds 
                                                            AND SRType__c = : Constants.DEFAULT_AND_TERMINATION
                                                            AND SalesOrder__r.HoldFlag__c = true
                                                            AND HexaBPM__External_Status_Name__c != : Constants.CLOSED ];
		system.debug('ClsoedSRList'+closedSRList);
        if( closedSRList != null && closedSRList.size() >  0 ){
            for(HexaBPM__Service_Request__c sr : closedSRList){
                if( sr.SalesOrder__r.HoldFlag__c ){
                    if( sr.HexaBPM__Internal_Status_Name__c.equalsIgnoreCase( ALD_Constants.SENT_TO_EXTERNAL_COUNSEL )){
                        legalSOSet.add( sr.SalesOrder__c);
                        legalAccountSet.add(sr.HexaBPM__Customer__c);
                        accIds.remove(sr.HexaBPM__Customer__c);
                        soIds.remove(sr.SalesOrder__c);
                        if(UpdateSOMap.containsKey(sr.SalesOrder__c)){
                            UpdateSOMap.remove(sr.SalesOrder__c);
                        }
                        if(updateAccMap.containsKey(sr.HexaBPM__Customer__c)){
                            updateAccMap.remove(sr.HexaBPM__Customer__c);
                        }

                    }else if(!legalSOSet.contains(sr.SalesOrder__c )){
                         if(sr.SalesOrder__r.HoldReasonCode__c.startsWith('Legal')){
                            soIds.remove(sr.SalesOrder__c);
                            UpdateSOMap.put(sr.SalesOrder__c, new SalesOrder__c(
                                                                Id = sr.SalesOrder__c,
                                                                HoldReasonCode__c = sr.SalesOrder__r.HoldReasonCode__c.replaceAll('(?i)Legal', 'Default')
                                                                ));
                         }
                         if(!legalAccountSet.contains(sr.HexaBPM__Customer__c )){
                            accIds.remove(sr.HexaBPM__Customer__c);
                             updateAccMap.put( sr.HexaBPM__Customer__c , new account(Id = sr.HexaBPM__Customer__c, BlacklistReason__c = 'Default', Blacklisted__c = false));
                         }
                    }
                }
            }}

        //Clean Accounts...
        if(accIds.size() > 0 ){for(id accId : accIds ){updateAccMap.put( accId , new account(Id = accId, BlacklistReason__c = '', Blacklisted__c = false));}}
        if(soIds.size() > 0 ){
              for(id soId : soIds ){
                UpdateSOMap.put( soId , new SalesOrder__c(Id = soId, HoldReasonCode__c = null, HoldFlag__c = false ));                                   
            }}

        if (UpdateSOMap != null && !UpdateSOMap.isEmpty()) recordsToUpdate.addAll(UpdateSOMap.values());
        if (updateAccMap != null && !updateAccMap.isEmpty()) recordsToUpdate.addAll(updateAccMap.values());
        // Combine DML.....
        if (!recordsToUpdate.isEmpty()) update recordsToUpdate;
    }
}