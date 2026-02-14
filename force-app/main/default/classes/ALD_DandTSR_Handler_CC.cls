/**********************************************************************************************************************
* Name               : D and T Supportive Class for the Enhanced Process                                               
* Description        : This custom code is used to handle the revamp process of D&T. Without sharing as we want to check for all the SR in failed status
* Usage              : D and T Process                                                          
* Created By         : Saravanan Sekar                                               
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Saravanan Sekar     16 Aug 2023      Initial Draft       
******************************************************************************************************************/
public without sharing class ALD_DandTSR_Handler_CC {
    //Exception Class-START
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}
    //Exception Class-END

    //Public attribute-START
    public static Boolean Special_Exceptional_Case = FALSE;
    public static Set<Id> soIdSet = new Set<Id>(); //Salesorder Id Set
    public static List<String> srLegalStatusList = new List<String>{ALD_Constants.TRANSFER_TO_LEGAL,ALD_Constants.SENT_TO_EXTERNAL_COUNSEL};
        public static List<String> srStatusList = new List<String>{ALD_Constants.REFERRED_TO_DandT_BY_LEGAL, ALD_Constants.PULLED_BACK_BY_DandT};
            public static List<String> statusList = new List<String>{ALD_Constants.PENDING, ALD_Constants.TRANSFER_TO_LEGAL, ALD_Constants.PULLED_BACK_BY_DandT, ALD_Constants.REFERRED_TO_DandT_BY_LEGAL, ALD_Constants.SENT_TO_EXTERNAL_COUNSEL};
                @AuraEnabled public String dummyAttributeforCodeAlignment;
    //Public attribute-END
    
    public static void handleDandTSR(Set<Id> customerIds, Map<Id,HexaBPM__Service_Request__c> srIDAndSrToProcess) {
        //Push the Records here, this method will take care
        try{
            Map<Id, HexaBPM__Service_Request__c> srExternalCounselDandT = new Map<Id, HexaBPM__Service_Request__c>();
            Map<Id, HexaBPM__Service_Request__c> srInternalDandT = new Map<Id, HexaBPM__Service_Request__c>();
            
            if(ALD_DandTSR_Handler_CC.Special_Exceptional_Case) {
                //Creating Other Charges in case of exceptional case, 
                //After this, Legal will manually move the step to D&T Team for the Negotiation
                createOtherCharge(srIDAndSrToProcess);
            } else {
                //Block the customer immediate
                //CC_BlockAccount.blockCustomer(customerIds); //When Moved to Sent to external counsel or Court case filed, 1st Flag the customer
                CC_ALD_DandTSR_Handler.blockCustomerForDnT(customerIds);
                //Check for Budget
                checkBudget(srIDAndSrToProcess); //If Sent to external counsel, check the Budget
                
                //Check for failed SRs
                Map<Id, String> srIdWithError = checkForSyncFailedSR(srIDAndSrToProcess.keySet());
                
                //Map<Id,HexaBPM__Status__c> statusMap = new Map<Id,HexaBPM__Status__c>(pvStepStatusSoql(new List<String>{ALD_Constants.PENDING}));//PENDING
                //List<HexaBPM__Service_Request__c> srListWithSteps = pvSrSoql(srIDAndSrToProcess.keySet(), statusMap.keySet());
            }

            for(HexaBPM__Service_Request__c sr : srIDAndSrToProcess.values()) {
                if(sr.LegalStatus__c == ALD_Constants.SENT_TO_EXTERNAL_COUNSEL) {
                    //To create new Step for External Counsel
                    srExternalCounselDandT.put(sr.Id, sr);
                } else if(String.isEmpty(sr.LegalStatus__c)) {
                    //To do Unflagging
                    srInternalDandT.put(sr.Id, sr);
                    soIdSet.add(sr.SalesOrder__c);
                }
            }
            if(!srExternalCounselDandT.IsEmpty() && !ALD_DandTSR_Handler_CC.Special_Exceptional_Case) {
                //To create new Step for External Counsel
                pushPullTheSr(ALD_Constants.SENT_TO_EXTERNAL_COUNSEL, new List<Id>(srExternalCounselDandT.keySet()), 'Push To External Counsel');
            }
            if(!srInternalDandT.IsEmpty()) {
                //Try to Unblock the Unit and Customer in case of Legal Status Empty on change
                checkAndAutoUnflag(srExternalCounselDandT.keySet(), ALD_Constants.LEGAL_FLAG, soIdSet);
            }
            
        } catch(Exception ex) {
            createLog(ex, 'DnT SR Process', 'ALD_DandTSR_Handler_CC', 'handleDandTSR');
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> shouldPushOrPullApx(String recordId) {
        System.debug('recordId > '+recordId);
        
        Profile prof = [select Name from profile where Id= :UserInfo.getProfileId()];
        
        Map<String, String> pushPullMap = new Map<String, String>();
        try {
            Map<Id,HexaBPM__Status__c> statusMap = new Map<Id,HexaBPM__Status__c>(pvStepStatusSoql(new List<String>{ALD_Constants.PENDING}));//PENDING
            List<HexaBPM__Step__c> stepList = pvStepsSoql(new Set<Id>{Id.valueOf(recordId)}, statusMap.keySet());//Get Pending Steps List
            if(stepList.size()>0) {
                for(HexaBPM__Step__c step:stepList) {
                    if(step.HexaBPM__Summary__c == ALD_Constants.DandT_STEP_Summary) {
                        pushPullMap.put('ProcessOne',ALD_Constants.pushLabel);
                        pushPullMap.put('ProcessOneLabel',ALD_Constants.pushTransferToLegalTitle);
                        
                    } else if(step.HexaBPM__Summary__c == ALD_Constants.LEGAL_STEP_Summary) {
                        if(prof.Name!=ALD_Constants.LEGAL_PROFILE_NAME) { // == LEGAL_PROFILE_NAME) {
                            pushPullMap.put('ProcessOne',ALD_Constants.pushReferToDandTLabel);
                            pushPullMap.put('ProcessOneLabel',ALD_Constants.pushReferToDandTTitle);
                        } else {
                            pushPullMap.put('ProcessOne',ALD_Constants.pullFromLegalLabel);
                            pushPullMap.put('ProcessOneLabel',ALD_Constants.pullFromLegalTitle);
                        }
                    }
                }
                pushPullMap.put('Success','Success');
            } else {
                pushPullMap.put('Error','Error');
                pushPullMap.put('ErrorMessage','You cannot recall this step!');
            }
            
        } catch (Exception e) {
            pushPullMap.put('Error','Error');
            pushPullMap.put('ErrorMessage','ErrorMessage');
            //throw new AuraHandledException(e.getMessage());
        }
        
        return pushPullMap;
    }
    
    @AuraEnabled
    public static string pushPullTheSr(String eventName, List<Id> recordIds, String stepComment) {
        System.debug('> recordIds > '+recordIds);
        //Find PUSH --> PENDING => TRANSFER_TO_LEGAL and PULL --> Find TRANSFER_TO_LEGAL => PULLED_BACK_BY_DandT
        System.debug('> eventName > '+eventName);
        //Check for failed SRs
        checkForSyncFailedSR(new Set<Id>(recordIds));
        try {
            List<HexaBPM__Step__c> stepListToUpdate = new List<HexaBPM__Step__c>();
            Map<String, HexaBPM__Status__c> nameAndStatusMap = new Map<String, HexaBPM__Status__c>();
            Map<String, HexaBPM__SR_Status__c> srStatusNameAndStatusMap = new Map<String, HexaBPM__SR_Status__c>();
            
            Map<Id,HexaBPM__Status__c> statusMap = new Map<Id,HexaBPM__Status__c>(pvStepStatusSoql(statusList));
            
            srStatusList = mergeStatuses();
            Map<Id,HexaBPM__SR_Status__c> srStatusMap = new Map<Id,HexaBPM__SR_Status__c>(pvSrStatusSoql(srStatusList));
            
            List<HexaBPM__Step__c> stepList = new List<HexaBPM__Step__c>();//pvStepsSoql(new Set<Id>(recordIds), statusMap.keySet());//Get Pending Steps List
            List<HexaBPM__Service_Request__c> srList = new List<HexaBPM__Service_Request__c>();
            Map<Id, HexaBPM__Service_Request__c> srMapToUpdate = new Map<Id, HexaBPM__Service_Request__c>();
            
            Map<Id,Id> budgetIdSrIdMap = new Map<Id,Id>();
            Map<Id,String> srIdTaskNumber = new Map<Id,String>();
            Map<Id, String> soIdStatus = new Map<Id, String>();//SS_KEEP SO Id to update the Hold Reason Code

            System.debug('eventName > '+eventName);
            if(eventName == ALD_Constants.SENT_TO_EXTERNAL_COUNSEL) {
                srList = pvSrSoql(new Set<Id>(recordIds), statusMap.keySet());//Get Pending Steps List
                for(HexaBPM__Service_Request__c sr : srList) {
                    stepList.addAll(sr.HexaBPM__Steps_SR__r);
                    budgetIdSrIdMap.put(sr.Unit__r.Project__r.ProjectBudget__c, sr.Id);
                }
                System.debug('budgetIdSrIdMap > '+budgetIdSrIdMap);
                srIdTaskNumber = pvGetTaskNumber(budgetIdSrIdMap);
            } else {
                stepList = pvStepsSoql(new Set<Id>(recordIds), statusMap.keySet());//Get Pending Steps List
            }
            
            

            if(stepList.size()>0) {
                for(HexaBPM__Status__c status : statusMap.values()) {
                    nameAndStatusMap.put(status.HexaBPM__Code__c,status);
                }
                
                for(HexaBPM__SR_Status__c status : srStatusMap.values()) {
                    srStatusNameAndStatusMap.put(status.Name,status);
                }
                //List<HexaBPM__Service_Request__c> srToUpdate = new List<HexaBPM__Service_Request__c>();
                for(HexaBPM__Step__c step : stepList) {
                    
                    String HexaBPM_SR_Status = '';
                    String HexaBPM_Step_Status = '';
                    
                    HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
                    
                    step.HexaBPM__Step_Notes__c = stepComment;
                    
                    if(eventName == ALD_Constants.pushTransferToLegalTitle) {
                        if(step.HexaBPM__Status__r.Name == ALD_Constants.PENDING) {
                            HexaBPM_Step_Status = nameAndStatusMap.get(ALD_Constants.TRANSFER_TO_LEGAL).Id;
                            HexaBPM_SR_Status = srStatusNameAndStatusMap.get(ALD_Constants.TRANSFER_TO_LEGAL).Id;
                        }
                        soIdStatus.put(step.HexaBPM__SR__r.SalesOrder__c,ALD_Constants.LEGAL_FLAG);//SS_KEEP SO Id to update the Hold Reason Code as Legal Submitted to External Counsel 260923
                    } else if(eventName == ALD_Constants.pullFromLegalTitle || eventName == ALD_Constants.pushReferToDandTTitle) {
                        if(step.HexaBPM__Status__r.Name == ALD_Constants.PENDING) {
                            HexaBPM_Step_Status = eventName == ALD_Constants.pushReferToDandTTitle ? nameAndStatusMap.get(ALD_Constants.REFERRED_TO_DandT_BY_LEGAL).Id : nameAndStatusMap.get(ALD_Constants.PULLED_BACK_BY_DandT).Id;
                            HexaBPM_SR_Status = eventName == ALD_Constants.pushReferToDandTTitle ? srStatusNameAndStatusMap.get(ALD_Constants.REFERRED_TO_DandT_BY_LEGAL).Id : srStatusNameAndStatusMap.get(ALD_Constants.PULLED_BACK_BY_DandT).Id;
                        }
                        soIdStatus.put(step.HexaBPM__SR__r.SalesOrder__c,ALD_Constants.DEFAULT_FLAG);//SS_KEEP SO Id to update the Hold Reason Code as Legal Submitted to External Counsel 260923
                    } else if(eventName == ALD_Constants.SENT_TO_EXTERNAL_COUNSEL) {
                        HexaBPM_Step_Status = nameAndStatusMap.get(ALD_Constants.SENT_TO_EXTERNAL_COUNSEL).Id;
                        HexaBPM_SR_Status = srStatusNameAndStatusMap.get(ALD_Constants.SENT_TO_EXTERNAL_COUNSEL).Id; 
                        soIdStatus.put(step.HexaBPM__SR__r.SalesOrder__c,ALD_Constants.LEGAL_FLAG);//SS_KEEP SO Id to update the Hold Reason Code as Legal Submitted to External Counsel 260923
                    }
                    
                    if(HexaBPM_Step_Status!=null || HexaBPM_Step_Status!='') {
                        step.HexaBPM__Status__c = HexaBPM_Step_Status;
                        stepListToUpdate.add(step);
                    }
                    if(HexaBPM_SR_Status!=null || HexaBPM_SR_Status!='') {
                        sr.Id=step.HexaBPM__SR__c;
                        sr.HexaBPM__Internal_SR_Status__c = HexaBPM_SR_Status;
                        sr.HexaBPM__External_SR_Status__c = sr.HexaBPM__Internal_SR_Status__c;
                        if(srIdTaskNumber.containsKey(sr.Id)) {
                            sr.Task_Number__c = srIdTaskNumber.get(sr.Id);
                        }
                        srMapToUpdate.put(step.HexaBPM__SR__c,sr);
                    }
                    //soIdSet.add(step.HexaBPM__SR__r.SalesOrder__c);
                }
                if(srMapToUpdate.values().size()>0) {
                    update srMapToUpdate.values();
                }
                
                if(stepListToUpdate.size()>0) {
                    update stepListToUpdate;
                }
                System.debug('#$#$ soIdStatus > '+soIdStatus);                
                if(!soIdStatus.keySet().isEmpty()) {
                    updateSalesOrderHoldReason(soIdStatus);
                }
            }
            
        } catch (Exception e) {
            String exceptionStr = e.getMessage()+e.getLineNumber()+e.getStackTraceString()+e.getCause();
            throw new OtherException(exceptionStr);
            //throw new AuraHandledException(e.getMessage()+e.getLineNumber()+e.getStackTraceString()+e.getCause());
        }
        return 'Success';
    }
    
    public static string updateSalesOrderHoldReason(Map<Id, String> soIdStatus) {
        List<SalesOrder__c> soToUpdate = new List<SalesOrder__c>();
        for(SalesOrder__c so:[SELECT Id,HoldReasonCode__c FROM SalesOrder__c WHERE Id IN :soIdStatus.keySet()]) {
            String oldReasonCode = so.HoldReasonCode__c;
            String newReasonCode = so.HoldReasonCode__c!=null && so.HoldReasonCode__c.startsWith(ALD_Constants.DEFAULT_FLAG) ? oldReasonCode.substring(7,oldReasonCode.length()) : oldReasonCode.substring(5,oldReasonCode.length()); //Default => 7 and Legal => 5
            so.HoldReasonCode__c = soIdStatus.get(so.Id)+newReasonCode;
            soToUpdate.add(so);
        }
        if(!soToUpdate.isEmpty()) {
            update soToUpdate;
        }
        return '';
    }
    
    public static Map<Id, Boolean> checkBudget(Map<Id,HexaBPM__Service_Request__c> srIDAndSrToProcess) {
        Map<Id, Boolean> srIdByBudgetStatus= new Map<Id, Boolean>();
        //Logic To Be Implemented here
        // srIdByBudgetStatus - Prepare this map for Budget calculation and then handle beow for loop
        // Logic to be implemented
        
        for(Id srId : srIdByBudgetStatus.keySet()) {
            if(!srIdByBudgetStatus.get(srId)) {
                throw new OtherException('Budget Not available for this Unit');
            }
        }
        return srIdByBudgetStatus;
    }
    
    public static Map<Id, String> checkForSyncFailedSR(Set<Id> newSRIdSet) {
        Map<Id, String> srIdWithError = new Map<Id, String>();
        List<Id> soIds = new List<Id>();
        List<Id> srIds = new List<Id>();
        User usr = Utilities.getLoggedInUserDetail();
        List<HexaBPM__Service_Request__c> srList = [SELECT Id,HexaBPM__External_Status_Name__c,HexaBPM__Record_Type_Name__c,SalesOrder__c 
                                                    FROM HexaBPM__Service_Request__c 
                                                    WHERE Id IN:newSRIdSet];
        System.debug('FF srList > '+srList.size()+' > newSRIdSet > '+newSRIdSet);
        
        for (HexaBPM__Service_Request__c srRecord: srList) {
            srIds.add(srRecord.Id);
            
            //if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__External_Status_Name__c != Constants.SR_STATUS_DRAFT && srRecord.HexaBPM__External_Status_Name__c != Constants.SUBMITTED) {
            soIds.add(srRecord.SalesOrder__c);
            //}
        }
        
        List<HexaBPM__Service_Request__c> failedSRList = [SELECT Id, SalesOrder__c, SyncStatus__c FROM HexaBPM__Service_Request__c 
                                                          WHERE Id NOT IN: srIds AND SalesOrder__c IN: soIds AND SalesOrder__c != null
                                                          AND SyncStatus__c =: Constants.STATUS_FAILED AND HexaBPM__Record_Type_Name__c !=:Constants.HANDOVER_RT 
                                                          AND HexaBPM__External_Status_Name__c !=:Constants.SR_STATUS_DRAFT AND HexaBPM__External_Status_Name__c !=:Constants.SUBMITTED];
        System.debug('FF failedSRList > '+failedSRList.size());
        
        if(usr.ProfileName__c!='Integration Profile' && usr.ProfileName__c!=Label.System_Admin){
            for (HexaBPM__Service_Request__c srRecord: srList) {
                if (!failedSRList.isEmpty()) {
                    SystemMessages__mdt message = Utilities.getSystemMessages('SYNC_STATUS_ERROR_SR_MESSAGE');
                    srIdWithError.put(srRecord.Id, message.Message__c);
                    break;
                }
            }
        }
        System.debug('FF srIdWithError keySet > '+srIdWithError.keySet());
        for(Id srId : srIdWithError.keySet()) {
            if(srIdWithError.get(srId)!='' && srIdWithError.get(srId)!=null) {
                System.debug('#$# srIdWithError.get(srId) > '+srId+' >>>> '+srIdWithError.get(srId));
                throw new OtherException(srIdWithError.get(srId));
            }
        }
        return srIdWithError;
    }
    
    
    public static void checkAndAutoUnflag(set<Id> srSetVals, string flagType, Set<Id> soIdSet){
        //(If its default treating it as blank)
        flagType = flagType.equalsIgnoreCase('Default')?'':flagType;
        if(flagType == ALD_Constants.COURT_ORDER_FLAG) {
            
        }
        
        Set<Id> legalStatuses = new Map<Id,HexaBPM__SR_Status__c>(ALD_DandTSR_Handler_CC.pubSrStatusSoql(ALD_DandTSR_Handler_CC.srLegalStatusList)).keySet();
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);
        Map<Id,Account> accToUpdate = new Map<Id,Account>();
        Map<Id,SalesOrder__c> soTOUpdate = new Map<Id,SalesOrder__c>();
        //Check for all legal SR to remove legal flag from Acc
        Map<Id,Integer> accIdCountOfLegalSR = new Map<Id,Integer>(); // If legal sr count is 0 => accIdCountOfLegalSR.get(accId) == 0, then remove Legal Flag, else Dont Remove
        //Map<Id,Integer> soIdCountOfDandTSR = new Map<Id,Integer>(); // If D&T sr count is 0 => soIdCountOfDandTSR.get(soId) == 0, then remove Hold Flag, else Dont Remove
        
        for(SalesOrder__c so:[SELECT Id, Account__c, HoldFlag__c, (Select Id, HexaBPM__Customer__c, HexaBPM__Customer__r.BlacklistReason__c  
                                                      From ServiceRequests__r 
                                                      Where RecordTypeId= :DandTRecordTypeId and HexaBPM__IsClosedStatus__c=false) 
                              FROM SalesOrder__c 
                              WHERE Id IN:soIdSet and Status__c!=:Constants.SO_STATUS_CANCELLED]) 
        {
            //Count of non closed DnT sr by Sales Order Id
            //soIdCountOfDandTSR.put(so.Id, so.ServiceRequests__r.size());//To keep SO on Hold 
            //For ALD_Constants.COURT_ORDER_FLAG, ignore salesorder flag update
            if(so.ServiceRequests__r.size() == 0 && flagType != ALD_Constants.COURT_ORDER_FLAG) {
                soTOUpdate.put(so.Id, new SalesOrder__c(Id = so.Id, HoldFlag__c=false, HoldReasonCode__c='', NumberOfDefaults__c=0));
            } else if(flagType != ALD_Constants.COURT_ORDER_FLAG){
                soTOUpdate.put(so.Id, new SalesOrder__c(Id = so.Id, NumberOfDefaults__c=so.ServiceRequests__r.size()));
            }
            System.debug('#$## soTOUpdate >>> '+soTOUpdate.get(so.Id));
            accIdCountOfLegalSR.put(so.Account__c, 0);//Create account set and process with account query below
        }
        
        //If the account is flagged due to the External Reason, then we are not unflagging the customer as part of this.
        for(Account acc : [SELECT Id,ALDnT_Sub_Legal_Reason__c, (Select Id 
                                       From HexaBPM__Service_Requests__r 
                                       Where RecordTypeId=:DandTRecordTypeId and HexaBPM__IsClosedStatus__c=false and 
                                       LegalStatus__c IN (:ALD_Constants.SUBMITTED_TO_COURT, :ALD_Constants.SENT_TO_EXTERNAL_COUNSEL)) 
                           FROM Account 
                           WHERE Id IN :accIdCountOfLegalSR.keySet()]) //HexaBPM__Internal_SR_Status__r.name IN (:TRANSFER_TO_LEGAL,:SENT_TO_EXTERNAL_COUNSEL)
        {
            //accIdCountOfLegalSR.put(acc.Id,acc.HexaBPM__Service_Requests__r.size()); 
            if(acc.HexaBPM__Service_Requests__r.size() == 0 || flagType == ALD_Constants.COURT_ORDER_FLAG) {
                Account accUpdate = new Account();
                accUpdate.Id= acc.Id;
                if(acc.HexaBPM__Service_Requests__r.size() == 0) {
                    accUpdate.Blacklisted__c =false;
                    accUpdate.BlacklistReason__c='';
                }
                if(flagType == ALD_Constants.COURT_ORDER_FLAG) {
                    accUpdate.ALDnT_Sub_Legal_Reason__c = null;
                }
                accToUpdate.put(acc.Id, accUpdate);
            }
            System.debug('#$## accToUpdate >>> '+accToUpdate.get(acc.Id));

        }
        
        
        if(!accToUpdate.isEmpty()) { 
            update accToUpdate.values();
        }
        if(!soTOUpdate.isEmpty()) { 
            update soTOUpdate.values();
        }
        //Call the Default ERP Integration with SR IDs
        if(flagType != ALD_Constants.COURT_ORDER_FLAG) {
            DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest( srSetVals);
        }
    }
    
    public static void createOtherCharge(Map<Id, HexaBPM__Service_Request__c> srIdWithSR) {
        try{
            //Create Other charge
            //Amount__c = AmountWithoutVAT__c + VATAmount__c
            list<SalesOrderOtherCharges__c> otherChargeToInsert = new list<SalesOrderOtherCharges__c>();
            for(HexaBPM__Service_Request__c tempSRRecord : srIdWithSR.values()){
                Decimal vatAmount = (tempSRRecord.LegalFees__c != null && tempSRRecord.LegalFees__c != 0) ? (tempSRRecord.LegalFees__c * 5) / 100 : 0;
				vatAmount = vatAmount.setScale(2, RoundingMode.CEILING);

                otherChargeToInsert.add(new SalesOrderOtherCharges__c(
                    Account__c = tempSRRecord.HexaBPM__Customer__c,
                    SalesOrder__c = tempSRRecord.SalesOrder__c,
                    AmountWithoutVAT__c = tempSRRecord.LegalFees__c,
                    //AmountWithoutVAT__c = tempSRRecord.LegalFees__c - vatAmount,
                    VATAmount__c = vatAmount,
                    Amount__c = tempSRRecord.LegalFees__c + vatAmount,
                    TypeOfCharge__c = Constants.OTHERCHARGE_LEGAL,
                    ServiceRequest__c = tempSRRecord.Id,
                    Description__c = tempSRRecord.Exceptional_Reason__c, 
                    SyncStatus__c = 'In Progress'
                ) );
            }
            if(!otherChargeToInsert.isEmpty()){
                insert otherChargeToInsert;
                ALDOC_OtherChargesHelper.doOtherChargeCallout(new List<Id>{otherChargeToInsert[0].Id}, null);

            }
        } catch(Exception ex) {
            createLog(ex, 'DnT SR Process', 'ALD_DandTSR_Handler_CC', 'createOtherCharge');
        }
    }
    
    public static void updateSRIfFlagged(List<HexaBPM__Service_Request__c> newSRList, Map<Id, String> custIdAndFlagType, Map<Id, String> soIdAndFlagType) {
        Map<Id,SalesOrder__c> soMap = new Map<Id,SalesOrder__c>([SELECT Id,Account__c, Account__r.Blacklisted__c, Account__r.BlacklistReason__c, HoldReasonCode__c, HoldFlag__c, 
                                                                 (Select Id From ServiceRequests__r Where SRType__c ='Default And Termination' and (LegalStatus__c =:ALD_Constants.SENT_TO_EXTERNAL_COUNSEL or LegalStatus__c =:ALD_Constants.SUBMITTED_TO_COURT) Limit 1)
                                                                 FROM SalesOrder__c 
                                                                 WHERE Id IN :soIdAndFlagType.keySet()]);
        for (HexaBPM__Service_Request__c newRecord: newSRList) {
            
            String flagLevels = '';
            if(soMap.containsKey(newRecord.SalesOrder__c) && String.isNotBlank(soMap.get(newRecord.SalesOrder__c).Account__c) && soMap.get(newRecord.SalesOrder__c).Account__r?.Blacklisted__c) {
                flagLevels = ALD_Constants.CUSTOMER_LEGAL_FLAG;
            }
            if(soMap.containsKey(newRecord.SalesOrder__c) && soMap.get(newRecord.SalesOrder__c).HoldFlag__c) {
                if(soMap.get(newRecord.SalesOrder__c).HoldReasonCode__c!=null && soMap.get(newRecord.SalesOrder__c).HoldReasonCode__c.startsWithIgnoreCase(ALD_Constants.DEFAULT_FLAG) && soMap.get(newRecord.SalesOrder__c).ServiceRequests__r.isEmpty()) {
                    flagLevels = flagLevels!='' ?flagLevels+';'+ALD_Constants.UNIT_DEFAULTED : ALD_Constants.UNIT_DEFAULTED;
                } 
                if(soMap.get(newRecord.SalesOrder__c).HoldReasonCode__c!=null && soMap.containsKey(newRecord.SalesOrder__c) && soMap.get(newRecord.SalesOrder__c).HoldReasonCode__c.startsWithIgnoreCase(ALD_Constants.LEGAL_FLAG) && soMap.get(newRecord.SalesOrder__c).ServiceRequests__r.isEmpty()) {
                    //Add Error, it should be moved to D&T Team for any new SR Creation
                    newRecord.addError(ALD_Constants.PUSH_OR_PULL_SR_TO_DnTQueue_FROM_LEGAL);
                }
                if(soMap.containsKey(newRecord.SalesOrder__c) && !soMap.get(newRecord.SalesOrder__c).ServiceRequests__r.isEmpty()) {
                    flagLevels = flagLevels!=''? flagLevels+';'+ALD_Constants.UNIT_LEGAL_FLAG : ALD_Constants.UNIT_LEGAL_FLAG;
                }
            }
            newRecord.ALDnT_Flag_Level__c = flagLevels;
        }
        //if Unit is = Legal and Customer  = legal, then it will goto Fiona's approval
        //  newRecord.Is_Customer_Flagged__c = true and newRecord.Is_Unit_Flagged__c = true
        //if Unit is = default and Customer  != legal, then it will goto Abdulla Chabli's approval
        //  newRecord.Is_Customer_Flagged__c = false and newRecord.Is_Unit_Flagged__c = true
        //if Unit is != Legal and Customer  = legal, then it will goto CCC's approval
        //  newRecord.Is_Customer_Flagged__c = false and newRecord.Is_Unit_Flagged__c = true
    }
    
    public static List<String> mergeStatuses() {
        srStatusList.addAll(srLegalStatusList);//include legal status as well    
        return srStatusList;
    }
    
    public static List<HexaBPM__SR_Status__c> pubSrStatusSoql(List<String> srStatusList) {
        return pvSrStatusSoql(srStatusList);
    }
    
    public static List<HexaBPM__Status__c> pubStepStatusSoql(List<String> stepStatusList) {
        return pvStepStatusSoql(stepStatusList);
    }
    
    private static Map<Id,String> pvGetTaskNumber(Map<Id, Id> budgetIdSrIdMap) {
        Map<Id,String> srIdTaskNumber = new Map<Id,String>();
        for(ProjectBudget__c pb:[SELECT Id,(Select Id,TaskNumber__c From BudgetsLinesProjectName__r Where Name=:ALD_Constants.BUDGET_LINE_ITEM_LEGAL_NAME Limit 1) 
         FROM ProjectBudget__c 
         WHERE Id IN :budgetIdSrIdMap.keySet()])
        {
            srIdTaskNumber.put(budgetIdSrIdMap.get(pb.Id),pb.BudgetsLinesProjectName__r[0].TaskNumber__c);
        }
        return srIdTaskNumber;
    }
    
    private static List<HexaBPM__Service_Request__c> pvSrSoql(Set<Id> recordIds, Set<Id> stepStatusIds) {
        return [SELECT Id,HexaBPM__Customer__c,SalesOrder__c, LegalStatus__c, LegalFees__c, Special_Exceptional_Case__c,
                Unit__r.Project__r.ProjectBudget__c,
                (Select Id, HexaBPM__SR__c, HexaBPM__SR__r.SalesOrder__c, HexaBPM__Summary__c, HexaBPM__Status__c, HexaBPM__Status__r.Name, HexaBPM__Step_Notes__c 
                 From HexaBPM__Steps_SR__r 
                 Where HexaBPM__Status__c IN :stepStatusIds and HexaBPM__Closed_Date__c = null) 
                FROM HexaBPM__Service_Request__c 
                WHERE Id IN :recordIds];
    }
    
    private static List<HexaBPM__Step__c> pvStepsSoql(Set<Id> recordIds, Set<Id> statusIds) {
        return [SELECT Id, HexaBPM__SR__c, HexaBPM__Summary__c, HexaBPM__Status__c, HexaBPM__Status__r.Name, HexaBPM__Step_Notes__c,
                HexaBPM__SR__r.SalesOrder__c
                FROM HexaBPM__Step__c 
                WHERE HexaBPM__SR__r.LegalStatus__c='' and HexaBPM__SR__c IN :recordIds and HexaBPM__Status__c IN :statusIds and HexaBPM__Closed_Date__c = null];
    }
    
    private static List<HexaBPM__Status__c> pvStepStatusSoql(List<String> stepStatusList) {
        return [SELECT Id, Name, HexaBPM__Code__c 
                FROM HexaBPM__Status__c 
                WHERE HexaBPM__Code__c IN:stepStatusList];
    }
    
    private static List<HexaBPM__SR_Status__c> pvSrStatusSoql(List<String> srStatusList) {
        return [SELECT Id, Name, HexaBPM__Code__c 
                FROM HexaBPM__SR_Status__c 
                WHERE Name IN:srStatusList];
    }
    
    private static void createLog(Exception ex, String ProcessName, String ClassName, String MethodName) {
        Logger__c lg = LoggerService.addApexLog(ex, ProcessName, ClassName, MethodName);
        insert lg;
        System.debug('EXCEPTION '+ClassName+' ** '+lg.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
    }
    
    public static boolean pvGetDocumentsPBLink(Map<String, String> soAndSrIds) {
        return true;
    }
    
    
}