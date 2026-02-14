/*
*********************************************************
Apex Class Name    : CaseTriggerValidation
Created Date       : 
@description       : Class to handle case Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public without sharing class CaseTriggerValidation {
    //Global Declaration - Start
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames); 
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());   
    //Global Declaration - End
    /*
    *********************************************************
    @Method Name    : beforeInsertCaseValidation
    @author         : 
    @description    : Method to validate before insert case
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void beforeInsertCaseValidation(List<Case> newCaseList) {
        //Local Variable Declaration - Start
        User usr = CaseTriggerHelper.getCurrentUserDetails();
        List<String> standardRecordskip = System.label.Case_Standard_record_type_skip.split(',');        
        List<Case> dlpCusMobileNumberValidation = new List<Case>();
        List<Case> emailCases = new List<Case>();
        Set<String> emailCasesSuppliedEmails = new Set<String>();
        Set<String> casestatuses = new Set<String>{'New', 'Assigned', 'Re-scheduled'};        
        Set<Id> unitIdsList = new Set<Id>();        
        Set<Id> closedCaseIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Map<Id,Id> caseWithSalesOrderMap = new Map<Id,Id>();
        Set<Id> assetIdsCaseInRestictedType = new Set<Id>();//livin Changes        
        //Local Variable Declaration - End 
        for(Case caseRecord : newCaseList) {
            if(caseRecord.AccountId != null) {
                accIds.add(caseRecord.AccountId);
            }
        }        
        for(Case caseRecord : newCaseList) {
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){ 
                if(System.Label.GeneralCaseTypeResctric.split(';').contains(caseRecord.CaseCategory__c) && caseRecord.AssetId  != null) {
                    assetIdsCaseInRestictedType.add(caseRecord.AssetId);
                }
            }
            if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID) {
                if(!Test.isRunningTest() && caseRecord.IsScreenCase__c == False && (caseRecord.origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.origin != Constants.EMAIL) && (UserInfo.GetUsername() != system.label.Integration_Username  && UserInfo.GetUsername() != system.label.Aldar_development_username && usr.Profile.Name != system.label.Case_profile_system_admin )) {
                    caseRecord.addError(System.label.Case_Creation_Via_Account_Only);
                }                
            }
            if(caseRecord.RecordTypeId == rtWrapper.standardRTypeID) {
                if (!Test.isRunningTest() && !standardRecordskip.contains(caseRecord.SubVertical__c) &&  (UserInfo.GetUsername() != system.label.Integration_Username && UserInfo.GetUsername() != system.label.Aldar_development_username && usr.Profile.Name != system.label.Case_profile_system_admin )  && system.label.Revamp_case_subvertical.tolowercase() == 'true' && caseRecord.Origin != Constants.EMAIL){
                    caseRecord.addError(System.label.Invalid_Vertical_SubVertical_Combination_Error);
                }
            }
            //Case revamp : Email validation same day 1 email with same account and subject
            if((caseRecord.RecordTypeId == rtWrapper.standardRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID) && caseRecord.Origin == Constants.EMAIL && system.label.Case_Email_Validation_Switch.tolowercase() == 'true'){
                emailCases.add(caseRecord);
                if (caseRecord.SuppliedEmail != null) {
                    emailCasesSuppliedEmails.add(caseRecord.SuppliedEmail.toLowerCase());                     
                }                     
            }
            if(!CaseTriggerMetadata.skipCustomerSupportRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                if(caseRecord.SalesOrder__c != null && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName  && caseRecord.recordTypeId != rtWrapper.corporateLegalRTypeID){
                    caseWithSalesOrderMap.put(caseRecord.Id, caseRecord.SalesOrder__c);
                }                
            }
            if(caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL) {
                dlpCusMobileNumberValidation.add(caseRecord);                             
            }
            if(recordTypeName == Constants.DLP_CASE_RT) {
                if(caseRecord.ParentId == null && caseRecord.SubCategory__c != 'Emergency' && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP && caseRecord.Single_DLP_slot__c ) {
                    unitIdsList.add(caseRecord.Unit__c);
                }
            }
        }
        if (!emailCases.isEmpty() && !emailCasesSuppliedEmails.isEmpty()) {            
            caseEmailValidation(emailCases,emailCasesSuppliedEmails);             
        } 
        if(!caseWithSalesOrderMap.isEmpty()){
            customerRelatedToUnitValidation(caseWithSalesOrderMap, newCaseList);
        }  
        if(!dlpCusMobileNumberValidation.isEmpty()) {
            validateDLPCustomerMobileNumber(dlpCusMobileNumberValidation,accIds);
        }  
        if(!unitIdsList.isEmpty()) {            
            List<Case> caseList = AldarUtilityClass.fetchCaseByUnitsonInsert(unitIdsList,casestatuses,rtWrapper.dlpRTypeID);
            duplicateCaseByUnit(newCaseList,caseList);
        } 
        //livin changes
        if(!assetIdsCaseInRestictedType.isEmpty()){                                    
            duplicateCaseByAssetAndCaseCategory(newCaseList,assetIdsCaseInRestictedType);
        }
    }
    /*
    *********************************************************
    @Method Name    : beforeUpdateCaseValidation
    @author         : 
    @description    : Method to validate before insert case
    @param          : newCaseList,oldmap
    @return         : void
    ********************************************************
    */
    public static void beforeUpdateCaseValidation(List<Case> newCaseList,Map<Id,Case> oldmap) {
        DateTime csdatetime; 
        Integer newestCaseNumber = 0;
        String newestCaseNumberString = '0';
        Id queueId;
        List<Id> unitIdsList = new List<Id>();
        List<Id> caseIdlist = new List<Id>();         
        List<case> lstOwnerChangeCases = new  List<case>();      
        Set<Id> closedCaseTaskIds = new Set<Id>();
        Set<Id> closedCaseIds = new Set<Id>();
        Set<Id> srcaseIds = new Set<Id>();
        Set<Id> casesWithOpenSR = new Set<Id>(); 
        Set<String> casestatuses = new Set<String>{'New', 'Assigned', 'Re-scheduled'};  
        Map<Id, String> casesOwnerChangedFromQueueToUser = new Map<Id, String>();  
        Map<Id,Id> caseWithSalesOrderMap = new Map<Id,Id>();  
        Map<Id,Case> transferredCases = new Map<Id,Case>(); 
        for(Case caseRecord : newCaseList){            
            Case oldCase = oldmap.get(caseRecord.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
            if(caseRecord.Status != oldcase.Status) {                
                if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID){                                    
                    //Case revamp: Added by Faaiz for validating the Cases closing without completing tasks
                    if((caseRecord.Status == Constants.CLOSED || caseRecord.Status == Constants.Resolved) && UserInfo.GetUsername() != system.label.Integration_Username) {
                        closedCaseTaskIds.add(caseRecord.Id);
                    }
                    //Case revamp: Added by Faaiz for validating the Cases closing without closing SR
                    if(caseRecord.Status == Constants.CLOSED &&  caseRecord.SRCreated__c){ 
                        srcaseIds.add(caseRecord.Id);
                    }
                    //Added by Suraj for validating the Parent Cases closing without closing child cases.
                    if(caseRecord.Status == Constants.CLOSED) {
                        closedCaseIds.add(caseRecord.Id);
                    }
                }
                if(recordTypeName == Constants.STANDARD_CASE_RT ) {
                    if(caseRecord.Status == Constants.CLOSED) {
                        closedCaseIds.add(caseRecord.Id);
                    }                
                }
                if(caserecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID){
                    if((caseRecord.Status == 'Closed'|| caseRecord.Status == 'Resolved') && UserInfo.GetUsername() != system.label.Integration_Username){ 
                        closedCaseTaskIds.add(caseRecord.Id);
                    }
                }
            }
            if((caseRecord.Status == Constants.CASE_NEW || caseRecord.Status =='Assigned' || caseRecord.Status == 'Re-scheduled') && caseRecord.OwnerId != oldCase.OwnerId && !caseRecord.isValidationBypass__c 
               && caseRecord.RecordTypeId == rtWrapper.dlpRTypeID && caseRecord.CustomerDLPStatus__c == Constants.ACTIVE && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP){
                lstOwnerChangeCases.add(caseRecord);
            }
            if(recordTypeName == Constants.DLP_CASE_RT && caseRecord.ParentId == null && caseRecord.SubCategory__c != 'Emergency' && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP && caseRecord.Single_DLP_slot__c) {
                UnitIdsList.add(caseRecord.Unit__c);
                caseIdlist.add(caseRecord.Id);
                csdatetime = caseRecord.CreatedDate;
            }
            if(!CaseTriggerMetadata.skipCustomerSupportEcssRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                if(caseRecord.SalesOrder__c != null && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName && caseRecord.recordTypeId != rtWrapper.corporateLegalRTypeID){
                    caseWithSalesOrderMap.put(caseRecord.Id, caseRecord.SalesOrder__c);
                }
            }
            if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT) && oldCase.OwnerId != caseRecord.OwnerId && oldCase.OwnerId.getsobjecttype() != User.sobjecttype ){
                if(caseRecord.OwnerId.getSObjectType() == User.sObjectType){
                    casesOwnerChangedFromQueueToUser.put(caseRecord.Id, caseRecord.CaseNumber);
                }
                if(Integer.valueOf(caseRecord.CaseNumber) > newestCaseNumber){
                    newestCaseNumberString = caseRecord.CaseNumber;
                    newestCaseNumber = Integer.valueOf(caseRecord.CaseNumber);
                }                
                queueId = oldCase.OwnerId;          
            }
            if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT) && oldCase.OwnerId != caseRecord.OwnerId && oldCase.OwnerId.getsobjecttype() != User.sobjecttype && caseRecord.OwnerId.getsobjecttype() != User.sobjecttype){
                transferredCases.put(caseRecord.Id, caseRecord);
            }            
        }
        // Case revamp : Added by Faaiz for validating the Cases closing without completing tasks    
        if (!closedCaseTaskIds.isEmpty()) {
            validateCasewithOpenTask(newCaseList, closedCaseTaskIds);
        }
        if(!caseWithSalesOrderMap.isEmpty()){
            customerRelatedToUnitValidation(caseWithSalesOrderMap, newCaseList);
        }
        if(!transferredCases.isEmpty()){
            handleTransferredCases(transferredCases);
        }
        //added by vijay for child cases must be closed before closing parent case        
        if(!closedCaseIds.isEmpty()){
            validateCasewithOpenChildCase(newCaseList,closedCaseIds);
        } 
        // Case revamp:Added by Faaiz for validating the Cases closing without closing SR 
        if (!srcaseIds.isEmpty()) {
            validateCasewithOpenSR(newCaseList,srcaseIds);
        } 
        if(unitIdsList.size() > 0) {
            List<Case> caselist = AldarUtilityClass.fetchCaseByUnitsonUpdate(caseIdlist,unitIdsList,csdatetime,casestatuses,rtWrapper.dlpRTypeID);
            if(!caselist.isEmpty()) {
                CaseTriggerValidation.duplicateCaseByUnit(newCaseList,caselist);
            }
        }
        if(!casesOwnerChangedFromQueueToUser.isEmpty()) {
            caseServerError(newCaseList,newestCaseNumberString,casesOwnerChangedFromQueueToUser,queueId);
        }
        if(!lstOwnerChangeCases.isEmpty()) {
            validateDLPCases(lstOwnerChangeCases);
        }
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateTasksValidation
    @author         : 
    @description    : Method used to update the product for On Demand Cases
    @param          : caseRecords,oldCaseMap
    @return         : 
    ********************************************************
    */
    public static void afterUpdateCaseValidation(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<Id, Case> closedCasesMap = new Map<Id, Case>();  
        for(Case newCase : newCaseList) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', newCase.recordTypeId);
            if(newCase.isClosed != oldCase.isClosed && newCase.isClosed && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){ // avoid resale support process
                closedCasesMap.put(newCase.Id, newCase);
            }
        }
        if(!closedCasesMap.isEmpty()){
            tasksValidation(closedCasesMap);
        }
    }
    /*
    *********************************************************
    @Method Name    : caseEmailValidation
    @author         : 
    @description    : Method to update KAR Changes
    @param          : emailCases,emailCasesSuppliedEmails
    @return         : void
    ********************************************************
    */
    public static void caseEmailValidation(List<Case> emailCases , Set<String> emailCasesSuppliedEmails){
        Map<String, List<String>> emailSubjectMap = new Map<String, List<String>>();
        for (Case existingCase : [SELECT Id, Subject, SuppliedEmail FROM Case WHERE SuppliedEmail IN :emailCasesSuppliedEmails AND CreatedDate = TODAY]) {
            if (existingCase.SuppliedEmail<> null) {
                if (emailSubjectMap.containsKey(existingCase.SuppliedEmail)) {
                    List<String> tempList =  new List<String>();
                    tempList.add(existingCase.Subject);
                    tempList.addAll(emailSubjectMap.get(existingCase.SuppliedEmail));
                    emailSubjectMap.put(existingCase.SuppliedEmail,tempList);
                } else {
                    emailSubjectMap.put(existingCase.SuppliedEmail,new List<String>{existingCase.Subject});
                }
            }
        }            
        for (Case newCase : emailCases) {
            String suppliedEmail = newCase.SuppliedEmail != null ? newCase.SuppliedEmail : null;
            if (suppliedEmail != null && emailSubjectMap.containsKey(suppliedEmail) && emailSubjectMap.get(suppliedEmail).contains(newCase.Subject)) {
                newCase.addError(System.label.Duplicate_Case_SameSubject_Email);                        
            }
        }
	}
    /*
    *********************************************************
    @Method Name    : customerRelatedToUnitValidation
    @author         : 
    @description    : Method to validate customer related to unit
    @param          : caseWithSalesOrderMap,caseRecords
    @return         : void
    ********************************************************
    */
    public static void customerRelatedToUnitValidation(Map<Id,Id> caseWithSalesOrderMap, List<Case> caseRecords){
        Map<Id, List<Id>> soWithRelatedAccounts = new Map<Id, List<Id>>();
        List<SalesOrder__c> soRecords = SalesOrderService.queryAllFieldsWithExtraFields(caseWithSalesOrderMap.values());

        for(SalesOrder__c so : soRecords){
            soWithRelatedAccounts.put(so.Id, new List<Id>{so.Account__c});
            for(JointOwner__c joRec : so.Joint_OwnersSalesOrder__r){
                soWithRelatedAccounts.get(joRec.SalesOrder__c).add(joRec.Account__c);
            }
        }
        User userRoleName = CaseTriggerHelper.getCurrentUserDetails();
        for(Case caseRecord : caseRecords){
            Boolean isTenantAccountBypass = false;
            List<ECSS_Case_Checks__mdt> ecsscheck = ECSS_Case_Checks__mdt.getAll().values();
                for(ECSS_Case_Checks__mdt ecss : ecsscheck){
                    if(ecss.Case_Category__c ==caseRecord.CaseCategory__c && ecss.Is_Skip_AccountId__c ==true && caseRecord.CustomerType__c ==Constants.CASE_CUSTOMER_TENANT){
                        isTenantAccountBypass = true;
                        break;
                    }
                }
            if(caseRecord.SalesOrder__c != null && caseRecord.AccountId != null && userRoleName.UserType != 'PowerPartner' && caseRecord.RecordTypeId != rtWrapper.amcRTypeID && !isTenantAccountBypass){
                List<Id> accountsList = soWithRelatedAccounts.get(caseRecord.SalesOrder__c);
                if(caseRecord.CaseCategory__c != Constants.QUALTRICS_SURVEY_CATEGORY && (accountsList == null || !accountsList.contains(caseRecord.AccountId))){
                    caseRecord.addError(CaseTriggerHelper.getSystemMessagesMap().get(Constants.CASE_ACCOUNT_RELATED_TO_UNIT_VALIDATION).Message__c);
                }
            }
        }
    }
     /*
    *********************************************************
    @Method Name    : handleTransferredCases
    @author         : 
    @description    : Error message to the user if there is no task with customer response equal 'Customer Reached'
    @param          : transferredCases
    @return         : void
    ********************************************************
    */
    public static void handleTransferredCases(Map<Id,Case> transferredCases){
        Set<Id> casesWithCustomerReached = new Set<Id>();
        Set<Id> ownersIds = new Set<Id>();        
        for(Case caseRec : transferredCases.values()){
            ownersIds.add(caseRec.OwnerId);
        }
        Map<Id, User> usersDetails = new Map<Id, User>(UserService.getUsersById(ownersIds));
        //----- Get all tasks Have Customer Response equal 'Customer Reached'.
        for(Task taskRec : TaskService.getCustomerReachedTasks(transferredCases.keySet())){
            casesWithCustomerReached.add(taskRec.WhoId);
        }        
        for(Case caseRec : transferredCases.values()){
            User userRec = usersDetails.get(caseRec.OwnerId);
            //---- Error message to the user if there is no task with customer response equal 'Customer Reached'.
            if(!casesWithCustomerReached.contains(caseRec.Id) && userRec != null && userRec.ProfileName__c != Constants.CONTACT_CENTER_AGENT){                
                caseRec.addError(CaseTriggerHelper.getSystemMessagesMap().get(Constants.TRANSFER_CASES_ERROR).Message__c);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : validateCasewithOpenTask
    @author         : 
    @description    : Added by Faaiz for validating the Cases closing without completing tasks  
    @param          : newCaseList,closedcasedIds
    @return         : void
    ********************************************************
    */
    public static void validateCasewithOpenTask(List<Case> newCaseList,Set<Id> closedcasedIds) {
        Set<Id> casesWithOpenTasks = new Set<Id>();
        for (Task t : [SELECT Id, WhatId FROM Task WHERE WhatId IN :closedcasedIds AND Status != 'Completed']) {
            casesWithOpenTasks.add(t.WhatId);
        }
        //!isPortalUser this is added by Daksh 
        Boolean isPortalUser = CaseTriggerHelper.getCurrentUserDetails().UserType == 'PowerPartner';
        for(Case caseRecord: newCaseList) {
            if (casesWithOpenTasks.contains(caseRecord.Id) && (caseRecord.Status == Constants.CLOSED ||caseRecord.Status == Constants.Resolved) && !isPortalUser) {
                caseRecord.addError(System.label.Cases_Closing_Task_Error);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : validateCasewithOpenChildCase
    @author         : 
    @description    : vijay for child cases must be closed before closing parent case 
    @param          : newCaseList,caseIds
    @return         : void
    ********************************************************
    */
    public static void validateCasewithOpenChildCase(List<Case> newCaseList,Set<Id> caseIds) {
        Map<Id, Case> casemap = new Map<Id, Case>([Select Id, CaseNumber, (Select Id, CaseNumber From Cases Where Status != 'Closed') From Case Where Id In :caseIds and (RecordType.Name = :Constants.Requests or RecordType.Name = :Constants.STANDARD_CASE_RT or RecordType.Name = :Constants.Complaints or RecordType.Name = :Constants.Queries)]);            
        for(Case cs : newCaseList){
            Case parentcs = casemap.get(cs.Id);
            if(parentcs != null && parentcs.Cases.size() > 0){                
                cs.Status.addError(System.label.Close_ChildCases_BeforeParent);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : validateCasewithOpenSR
    @author         : 
    @description    : Added by Faaiz for validating the Cases closing without closing SR
    @param          : newCaseList,srcaseIds
    @return         : void
    ********************************************************
    */
    public static void validateCasewithOpenSR(List<Case> newCaseList,Set<Id> srcaseIds) {
        Set<Id> casesWithOpenSR = new Set<Id>();
        for (HexaBPM__Service_Request__c h : [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE Case__c IN :srcaseIds AND HexaBPM__External_Status_Name__c NOT IN ('Closed','Cancelled','Rejected')]) {
            casesWithOpenSR.add(h.Case__c);
        }
        for(Case caseRecord: newCaseList) {
            if (casesWithOpenSR.contains(caseRecord.Id) && caseRecord.Status == Constants.CLOSED) {
                caseRecord.addError(System.label.Case_Closing_SR_Error);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : validateDLPCustomerMobileNumber
    @author         : 
    @description    : Method to validate DLP Customer Mobile Number
    @param          : dlpCusMobileNumberValidation,accIds
    @return         : 
    ********************************************************
    */
    public static void validateDLPCustomerMobileNumber(List<Case> dlpCusMobileNumberValidation,Set<Id> accIds) {
        //Local Variable Declaration - Start
        Map<Id,Account> accountIDToRecMap = new Map<Id,Account>();
        accountIDToRecMap = CaseTriggerHelper.getCaseRelAccount(accIds);
        //Local Variable Declaration - End                
        for(Case caseRecord : dlpCusMobileNumberValidation) {
            if(accountIDToRecMap.containsKey(caseRecord.AccountId)){
                Boolean isEmptyMobile=false;
                if(accountIDToRecMap.get(caseRecord.AccountId).IsPersonAccount){
                    isEmptyMobile=String.isBlank(accountIDToRecMap.get(caseRecord.AccountId).MobilePhone__pc);
                }else {
                    isEmptyMobile=String.isBlank(accountIDToRecMap.get(caseRecord.AccountId).MobileNumber__c);
                }
                if(isEmptyMobile){
                    caseRecord.addError(CaseTriggerHelper.getSystemMessagesMap().get(Constants.DLP_CUSTOMER_MOBILE_NUMBER_VALIDATION).Message__c);
                }                    
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : duplicateCaseByUnit
    @author         : 
    @description    : Method to validate duplicate case by unit for both before Inser and update
    @param          : caseRecords,caseList
    @return         : 
    ********************************************************
    */
    public static void duplicateCaseByUnit(List<Case> newCaseList , List<Case> caseList){        
        if(!caseList.isEmpty()) {
            for(Case csRec : newCaseList) {   
                ServiceAppointment sa = new ServiceAppointment(); 
                if(csRec.Service_Appointments__r.size() > 0) { 
                    sa = csRec.Service_Appointments__r[0];
                }
                if(!Test.isRunningTest() && (sa.SchedEndTime == null || sa.SchedEndTime > DateTime.now())) {  
                    String msg = System.label.Existing_OpenCase_For_Unit + ' ' + caseList[0].CaseNumber; 
                    csRec.ParentId.addError(msg);
                }                    
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : duplicateCaseByAssetAndCaseCategory
    @author         : 
    @description    : Method used to validate duplicate case by asset and case category
    @param          : newCaseList,caseIds
    @return         : void
    ********************************************************
    */
    public static void duplicateCaseByAssetAndCaseCategory(List<Case> newList,Set<Id> assetIdsCaseInRestictedType){
        Map<String,List<String>> accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType = new Map<String,List<String>>();
        for(Case currentCase : [Select Id,CaseCategory__c,Unit__c,AccountId, Status from Case where AssetId IN :assetIdsCaseInRestictedType AND Status NOT IN(:Constants.CLOSED,:Constants.CANCELLED,:Constants.COMPLETED) AND CaseCategory__c IN (:Constants.OUT_OF_HOME,:Constants.NOC_FOR_UNIT_MODIFICATIONS,:Constants.ACCESS_CARD,:Constants.TENANT_ONBOARDING)]){
            If(accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType.get(currentCase.AccountId) != null)
            {
                accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType.get(currentCase.AccountId).add(currentCase.CaseCategory__c);
            }
            else{
                accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType.put(currentCase.AccountId,new List<String>{currentCase.CaseCategory__c});
            }
        }
        for(Case caseRecord : newList){//livin changes //Tenant Onboarding                        
            if(!Test.isRunningTest() && (System.Label.GeneralCaseTypeResctric.split(';').contains(caseRecord.CaseCategory__c) || caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING) && accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType.get(caseRecord.AccountId)!= null){
                List<String> caseCategoryListInRestrictedType = accountIdVsCaseCategoryExistingGeneralCaseInRestrictedType.get(caseRecord.AccountId);
                
                if(caseCategoryListInRestrictedType.contains(caseRecord.CaseCategory__c)){
                    caseRecord.addError(System.label.Duplicate_General_Case_Error);
                }
                
                
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : checkAndupdateProductForOnDeamnd
    @author         : 
    @description    : Method used to update the product for On Demand Cases
    @param          : caseRecords
    @return         : 
    ********************************************************
    */
    public static void checkAndupdateProductForOnDeamnd(List<Case> caseRecords) {
        //Local variable Declaration - Start
        Map<String, String> mpCaseSubCat = new Map<String, String>();
        Map<String, String> mpCaseSO = new Map<String, String>();
        Set<String> caseSubCatSet = new Set<String>();
        Set<String> caseSOSet = new Set<String>();
        //Local variable Declaration - End
        // Populate maps and sets for efficient querying
        for (Case c : caseRecords) {
            if(c.CaseCategory__c == System.Label.ODCaseCategoty){
                mpCaseSubCat.put(c.Id, c.SubCategory__c);
                mpCaseSO.put(c.Id, c.SalesOrder__c);
                caseSubCatSet.add(c.SubCategory__c);
                caseSOSet.add(c.SalesOrder__c);
            }
        }
        if(!mpCaseSubCat.isEmpty()){
            // Query OpportunityOfferLine__c based on case SubCategory and SalesOrder
            Map<String, Set<String>> mpSOOffLines = new Map<String, Set<String>>();
            Map<String, Set<String>> mpSOOffLinesId = new Map<String, Set<String>>();
            if(!caseSOSet.isEmpty() && !caseSubCatSet.isEmpty()){
                for (OpportunityOfferLine__c offLi : [SELECT Id,Product_Item__r.Product2Id,Product_Item__r.Product2.Name, SalesOrder__c  FROM OpportunityOfferLine__c WHERE Product_Item__r.Product2.Name IN :caseSubCatSet AND SalesOrder__c IN :caseSOSet AND BalanceQuantity__c > 0]) {
                    if (!mpSOOffLines.containsKey(offLi.SalesOrder__c)) {
                        mpSOOffLines.put(offLi.SalesOrder__c, new Set<String>());
                    }
                    mpSOOffLines.get(offLi.SalesOrder__c).add(offLi.Product_Item__r.Product2.Name);
                    
                    if (!mpSOOffLinesId.containsKey(offLi.SalesOrder__c)) {
                        mpSOOffLinesId.put(offLi.SalesOrder__c, new Set<String>());
                    }
                    mpSOOffLinesId.get(offLi.SalesOrder__c).add(offLi.Product_Item__r.Product2.Name + '--' + offLi.Product_Item__r.Product2Id);
                }
            }            
            // Update cases based on the queried OpportunityOfferLine__c records
            for (Case c : caseRecords) {                
                if (c.CaseCategory__c== System.Label.ODCaseCategoty && mpSOOffLines.containsKey(c.SalesOrder__c)) {
                    Set<String> setProd = mpSOOffLines.get(c.SalesOrder__c);
                    if (!setProd.contains(c.SubCategory__c)) {
                        c.addError(System.label.OnDemand_Quantities_Consumed);
                    } else {
                        for (String prod : mpSOOffLinesId.get(c.SalesOrder__c)) {
                            if (prod.startsWith(c.SubCategory__c + '--')) {
                                c.ProductId = prod.split('--')[1];
                                break; // Exit loop early once product is found
                            }
                        }
                    }
                } else if(!Test.isRunningTest() && c.CaseCategory__c=='On Demand'){
                    c.addError(System.label.No_OnDemand_Service_found);
                }
            }
        }    
    }    
    /*
    *********************************************************
    @Method Name    : tasksValidation
    @author         : 
    @description    : Method used to update the product for On Demand Cases
    @param          : closedCasesMap
    @return         : 
    ********************************************************
    */
    public static void tasksValidation(Map<Id, Case> closedCasesMap) {
        Map<Id, Integer> caseWithNumberOfTasks = new Map<Id, Integer>();
        Integer cutomerNotReachableTasksCount = 0;
        Boolean customerReached = false;
        for (Task taskRec : [Select Id, WhatId, TaskNumber__c, CustomerResponse__c From Task Where WhatId in : closedCasesMap.keySet() AND TaskNumber__c != null]) {
            Integer tasksCount = 1;
            if(caseWithNumberOfTasks.containsKey(taskRec.WhatId)){
                tasksCount = caseWithNumberOfTasks.get(taskRec.WhatId);
                if(taskRec.CustomerResponse__c == Constants.CUSTOMER_REACHED){
                    tasksCount = tasksCount + 4;
                }
                caseWithNumberOfTasks.put(taskRec.WhatId, tasksCount + 1);
            } else {
                if(taskRec.CustomerResponse__c == Constants.CUSTOMER_REACHED){
                    tasksCount = tasksCount + 4;
                }
                caseWithNumberOfTasks.put(taskRec.WhatId, tasksCount);
            }
        }
        if(!caseWithNumberOfTasks.isEmpty()){
            for(Id caseId : caseWithNumberOfTasks.keySet()) {
                if(caseWithNumberOfTasks.get(caseId) < 4){
                    closedCasesMap.get(caseId).addError(CaseTriggerHelper.getSystemMessagesMap().get(Constants.CASE_TASKS_VALIDATION).Message__c);
                }
            }
        }                
    }
    /*
    *********************************************************
    @Method Name    : caseServerError
    @author         : 
    @description    : Error message to the user if there is no task with customer response equal 'Customer Reached'
    @param          : newCaseList,newestCaseNumberString,casesOwnerChangedFromQueueToUser,queueId
    @return         : void
    ********************************************************
    */
    public static void caseServerError(List<Case> newCaseList,String newestCaseNumberString,Map<Id, String> casesOwnerChangedFromQueueToUser,Id queueId) {
        User usr = CaseTriggerHelper.getCurrentUserDetails();
        if(!casesOwnerChangedFromQueueToUser.isEmpty() && usr.Profile.Name != Constants.INTEGRATION_PROFILE && usr.UserRole.Name != Constants.CONTACT_CENTER_MANAGER && 
           queueId != queueWrapper.dlpQueue.Id &&  queueId != queueWrapper.postSaleQueue.Id &&  queueId != queueWrapper.cmFinanceQueue.Id && queueId != queueWrapper.newSalesQueue.Id){
            List<Case> oldestCases = CaseService.getOldestCaseFromQueue(queueId, newestCaseNumberString);            
        List<String> oldestCasesNumber = new List<String>();
        for (Integer i = 0; i < oldestCases.size(); i++) {
            if(!casesOwnerChangedFromQueueToUser.containsKey(oldestCases[i].Id)){
                oldestCasesNumber.add(oldestCases[i].CaseNumber);
            }
        }    
        Id userId = UserInfo.getUserId();                                     
        String NonUser = system.label.CASE_FIRST_COME_FIRST_SERVE;              
        List<String> exemptUserIds = NonUser.split(',');    
        if(!oldestCasesNumber.isEmpty() && usr.UserRole != null && usr.UserRole.Name == system.label.Contact_Centre_Agent){                  
            if(!exemptUserIds.contains(userId)){                       
                newCaseList[0].addError(CaseTriggerHelper.getSystemMessagesMap().get(Constants.CASE_FIRST_COME_FIRST_SERVE_ERROR).Message__c + oldestCasesNumber.toString());
            }
        }
    }
    }
    /*
    *********************************************************
    @Method Name    : validateDLPCases
    @author         : 
    @description    : Added By Moh Sarfaraj for BPM-475 end
    @param          : lstOwnerChangeCases
    @return         : void
    ********************************************************
    */    
    public static void validateDLPCases(List<Case> lstOwnerChangeCases){
        // Create a map to hold CaseId and corresponding Service Appointment OwnerId
        Map<Id, Id> serviceAppointmentOwnerMap = new Map<Id, Id>();
        for (ServiceAppointment sa : [SELECT Id, FSSK__FSK_Assigned_Service_Resource__r.RelatedRecordId, Case__c  FROM ServiceAppointment  WHERE Case__c IN :lstOwnerChangeCases AND Record_Type_Name__c='Assessment' AND Status !='Closed']) {
            serviceAppointmentOwnerMap.put(sa.Case__c, sa.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecordId);
        }
        for(Case caseRecord : lstOwnerChangeCases){
            if(caseRecord.Status == Constants.CASE_NEW) {
                caseRecord.addError(Label.CaseOwnerWarning);
            } else if(caseRecord.Status == 'Assigned' || caseRecord.Status == 'Re-scheduled') {    
                Id serviceAppointmentOwnerId = serviceAppointmentOwnerMap.get(caseRecord.Id);
                // Check if Case Owner and Service Appointment Owner match
                if (caseRecord.OwnerId != serviceAppointmentOwnerId) {
                    caseRecord.addError(Label.CaseOwnerWarning);
                }
            }
        }
    }
}