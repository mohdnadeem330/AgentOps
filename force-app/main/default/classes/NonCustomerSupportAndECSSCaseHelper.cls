/*
*********************************************************
Apex Class Name    : NonCustomerSupportAndECSSCaseHelper
Created Date       : 
@description       : Class to handle case other then Customer Support and ECSS RT Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class NonCustomerSupportAndECSSCaseHelper {
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());
    /*
    *********************************************************
    @Method Name    : beforeInsertSkipCustomerSupportECSSCaseType
    @author         : 
    @description    : Method to handle before Insert logic for case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertSkipCustomerSupportECSSCaseType(List<Case> newCaseRecords) {
        User loggedInUser = Utilities.getLoggedInUserDetail();
        for(Case caseRecord : newCaseRecords) {
            if(!CaseTriggerMetadata.skipCustomerSupportEcssRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                if(caseRecord.SubVertical__c == Constants.CONTACT_CENTRE_SUB_VERTICAL){                
                    if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY){
                        if(caseRecord.SubCategory__c == Constants.NO_RESPONSE_SUB_CATEGORY){
                            caseRecord.RecordTypeId = rtWrapper.standardRTypeID;
                        } else {
                            caseRecord.RecordTypeId = rtWrapper.feedbackRTypeID;
                        }
                    } else if(caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY){
                            caseRecord.RecordTypeId = rtWrapper.standardRTypeID;
                    }
                }
                if(loggedInUser.Profile.Name == Constants.CONTACT_CENTER_AGENT && caseRecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId && caseRecord.OwnerId.getsobjecttype() == User.sobjecttype){
                    caseRecord.CCAOwner__c = caseRecord.OwnerId;
                    //R3 changes by smaartt                                                          //2.2 change here
                    if(caseRecord.RecordTypeId != rtWrapper.dlpRTypeID && caseRecord.RecordTypeId != rtWrapper.amcRTypeID) {               
                        caseRecord.Status = Constants.CASE_WORK_IN_PROGRESS;
                    }
                }                
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : beforeInsertSkipCustomerSupportCaseType
    @author         : 
    @description    : Method to handle before Insert logic for case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertSkipCustomerSupportCaseType(List<Case> newCaseRecords) {
        String DevControlRTName = Label.DevControRT; 
        Set<Id> accountIds = new Set<Id>();
        Map<Id,String> caseSubVerticalMap = new Map<Id,String>();  
        Map<Id, Case> accountRecordMap = new Map<Id, Case>();      
        for(Case caseRecord : newCaseRecords) {
            if(!CaseTriggerMetadata.skipCustomerSupportRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';                          
                if (recordTypeName == Label.DM_CAFM_RecType || recordTypeName == Constants.FEEDBACK_CASE_RT|| recordTypeName ==System.Label.AMCRecTypeLabel || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.HOME_FINANCE_CASE_RT || recordTypeName ==DevControlRTName){
                    caseSubVerticalMap.put(caseRecord.Id, caseRecord.SubVertical__c);
                    if(caseRecord.SubVertical__c != Constants.DLP_SUB_VERTICAL && caseRecord.SubVertical__c != Constants.DLP_CONTRACTOR_SUB_VERTICAL && recordTypeName !=System.Label.AMCRecTypeLabel ){
                        caseRecord.EntitlementId = System.Label.DefaultEntitlementId;
                    } else {
                        if(caseRecord.Vertical__c == Constants.DLP_VERTICAL && caseRecord.CaseCategory__c != System.Label.ODCaseCategoty) {
                            caseRecord.EntitlementId = System.Label.DLPEntitlementId;
                        }
                        if(caseRecord.SubCategory__c =='Emergency') {
                            caseRecord.EntitlementId = System.Label.DLPEmergEntitlementId; 
                        } else if(caseRecord.SubCategory__c =='PPM Visit' || caseRecord.SubCategory__c =='PMA Visit') {
                            caseRecord.EntitlementId = System.Label.AMCEntitlementId ; 
                        } else if(caseRecord.CaseCategory__c == System.Label.ODCaseCategoty) {
                            caseRecord.EntitlementId = System.Label.AMC_OD_Entitlement_Id ;
                        }
                    }                                    
                    if (caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP) {
                        if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
                            caseRecord.OwnerId = queueWrapper.surveyQueue.Id;
                        } else if(((caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL) && recordTypeName == Constants.STANDARD_CASE_RT) || recordTypeName == Constants.DLP_CASE_RT){
                            caseRecord.OwnerId = queueWrapper.dlpQueue.Id;
                            if(caseRecord.ResolutionType__c == ''){
                                caseRecord.ResolutionType__c = 'Repair';
                            }
                        } else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Customer Care'){
                            caseRecord.OwnerId = queueWrapper.postSaleQueue.Id;
                        } else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='CMO'){
                            caseRecord.OwnerId = queueWrapper.admCommunityCaseQueue.Id;
                        } else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='ADM Services'){
                            caseRecord.OwnerId = queueWrapper.admRegCaseQueue.Id;
                        } else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Comms'){
                            caseRecord.OwnerId = queueWrapper.commsRegCaseQueue.Id;
                        } else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Home Finance'){
                            caseRecord.OwnerId = queueWrapper.homeFinanceQueue.Id;
                        }
                    } else {
                        if(caseRecord.ResolutionType__c == ''){
                            caseRecord.ResolutionType__c = 'Repair';
                        }
                    }
                    if(caseRecord.SubVertical__c== System.Label.Case_Subvertical_Onboarding){
                        caseRecord.ADM_Email__c = System.Label.Case_Subvertical_Onboarding_email;
                        caseRecord.OwnerId = queueWrapper.onboarding.Id;
                        if (caseRecord.AccountId != null) {                        
                            accountIds.add(caseRecord.AccountId);
                        }                    
                    }
                    else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_GCEO_Comms){
                        caseRecord.ADM_Email__c =System.Label.Case_Subvertical_GCEO_Comms_email;                                                           
                    }
                    else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_Riyadh_city){
                        caseRecord.ADM_Email__c =System.Label.Riyadh_city_Email;
                    }                    
                }            
            }             
            if(!accountIds.isEmpty()){
                for(Case matchingCase : [SELECT Id, OwnerId, Owner.IsActive, AccountId FROM Case WHERE AccountId IN :accountIds AND SubVertical__c = :System.Label.Case_Subvertical_Onboarding AND Status =: Constants.CLOSED_CASE ORDER BY CreatedDate DESC]) {
                    accountRecordMap.put(matchingCase.AccountId, matchingCase);           
                }
            }
            if(!CaseTriggerMetadata.skipCustomerSupportRecordTypeIds.contains(caseRecord.RecordTypeId)){                
                if(caseRecord.SubVertical__c==System.Label.Case_Subvertical_Onboarding && caseRecord.AccountId != null){                    
                    Case matchingCase = accountRecordMap.get(caseRecord.AccountId);                                
                    if (matchingCase != null && matchingCase.Owner.IsActive && matchingCase.OwnerId != null && String.valueOf(matchingCase.OwnerId).startsWith('005')) {                        
                        caseRecord.OwnerId = matchingCase.OwnerId;
                    }
                }
            }
        } 
        if(!caseSubVerticalMap.isEmpty()) {
            CaseTriggerHelper.populateSubVerticalDependentInfo(caseSubVerticalMap, newCaseRecords, null);
        }   
    }
    /*
    *********************************************************
    @Method Name    : beforeInsertCaseRelatedLookupFieldMapping
    @author         : 
    @description    : Method to populate fields from RecordIdField
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void beforeInsertCaseRelatedLookupFieldMapping(List<Case> newCaseList){
        Map<Id, SObject> objectIdWithRecord = new Map<Id, SObject>();
        Map<String,List<Id>> objectNameWithListOfIds = new Map<String,List<Id>>();
        for(case caseRecord : newCaseList) {
            if(!CaseTriggerMetadata.skipCustomerSupportRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                if(caseRecord.RecordId__c != null){
                    Id recId = null;
                    String sObjName = null;
                    try{
                        recId = Id.valueOf(caseRecord.RecordId__c.split('#')[0]);
                        sObjName = recId.getSObjectType().getDescribe().getName();
                    } Catch(Exception e){
                        recId = null;
                        sObjName = null;
                    }
                    if(sObjName != null && recId != null){
                        if(objectNameWithListOfIds.containsKey(sObjName)){
                            objectNameWithListOfIds.get(sObjName).add(recId);
                        } else {
                            objectNameWithListOfIds.put(sObjName, new List<Id>{(recId)});
                        }
                    }
                }
            }
        }
        for(String objectName : objectNameWithListOfIds.keySet()){
            List<Id> objectIds = objectNameWithListOfIds.get(objectName);
            if(objectName == 'HexaBPM__Service_Request__c'){
                objectIdWithRecord.putAll(new Map<Id, SObject>(ServiceRequestService.queryAllFieldsWithExtraFields(objectIds)));
            } else if(objectName == 'Lead'){
                objectIdWithRecord.putAll(new Map<Id, SObject>(LeadService.getAllLeadByIds(new Set<Id>(objectIds))));
            } else if(objectName == 'Opportunity'){
                String oppQuery = 'Select Id, Contact__c, AccountId From Opportunity Where Id in (\''+ String.join(objectIds, '\',\'')+ '\')';
                objectIdWithRecord.putAll(new Map<Id, SObject>(OpportunityService.getOpportunityQuery(oppQuery)));
            } else if(objectName == 'SalesOrder__c'){
                objectIdWithRecord.putAll(new Map<Id, SObject>(SalesOrderService.queryAllFieldsWithExtraFields(objectIds)));
            }
        }
        for(Case caseRecord : newCaseList){
            if(caseRecord.RecordId__c != null && objectIdWithRecord.containsKey(caseRecord.RecordId__c.split('#')[0])){
                SObject relatedRecord = objectIdWithRecord.get(caseRecord.RecordId__c.split('#')[0]);
                if(relatedRecord.getSObjectType().getDescribe().getName() == 'HexaBPM__Service_Request__c'){
                    HexaBPM__Service_Request__c srRecord = (HexaBPM__Service_Request__c)relatedRecord;
                    caseRecord.AccountId = srRecord.HexaBPM__Customer__c == null ? null : srRecord.HexaBPM__Customer__c;
                    if(srRecord.SalesOrder__c != null && srRecord.SalesOrder__r.Opportunity__c != null){
                        caseRecord.Opportunity__c = srRecord.SalesOrder__r.Opportunity__c;
                    }
                    caseRecord.ContactId = srRecord.HexaBPM__Contact__c == null ? null : srRecord.HexaBPM__Contact__c;
                    caseRecord.SalesOrder__c = srRecord.SalesOrder__c == null || srRecord.Unit__c == null ? null : srRecord.SalesOrder__c;
                    caseRecord.ServiceRequest__c = srRecord.Id;
                    caseRecord.Unit__c = srRecord.Unit__c == null ? null : srRecord.Unit__c;                    
                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'Lead'){                    
                    Lead leadRecord = (Lead)relatedRecord;
                    caseRecord.Lead__c = leadRecord.Id;
                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'Opportunity'){
                    Opportunity oppRecord = (Opportunity)relatedRecord;caseRecord.Opportunity__c = oppRecord.Id;caseRecord.AccountId = oppRecord.AccountId == null ? null : oppRecord.AccountId;
                    caseRecord.ContactId = oppRecord.Contact__c == null ? null : oppRecord.Contact__c;
                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'SalesOrder__c'){
                    String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                    SalesOrder__c soRecord = (SalesOrder__c)relatedRecord;
                    caseRecord.AccountId = soRecord.Account__c == null ? null : soRecord.Account__c;
                    caseRecord.Opportunity__c = soRecord.Opportunity__c == null ? null : soRecord.Opportunity__c;
                    if((recordTypeName != Constants.DLP_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.CustomerType__c == 'Owner')))
                        caseRecord.ContactId = soRecord.Contact__c == null ? null : soRecord.Contact__c;
                        caseRecord.SalesOrder__c = soRecord.Unit__c == null ? null : soRecord.Id;
                        caseRecord.Unit__c = soRecord.Unit__c == null ? null : soRecord.Unit__c;
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : beforeUpdateSkipCustomerSupportECSSCaseType
    @author         : 
    @description    : Method for before update for skipCustomerSupportECSSCaseType
    @param          : newCaseList,oldMap
    @return         : void
    ********************************************************
    */
    public static void beforeUpdateSkipCustomerSupportECSSCaseType(List<Case> newCaseList,Map<Id,Case> oldMap) {
        String caseVerticale;
        Constant__mdt constantMdt = new Constant__mdt();
        List<Case> ownershipchangeCases = new List<Case>();
        List<case> tasksToInsert = new List<case>();
        List<Case> casesWithTask = new List<Case>(); 
        Map<String, String> mapownerIds = new Map<String,String>();
        Map<Id,String> caseSubVerticalMap = new Map<Id,String>();
        User usr = CaseTriggerHelper.getCurrentUserDetails();
        for(Case caseRecord : newCaseList) {
            Case oldCase = oldMap.get(caseRecord.Id);
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(!CaseTriggerMetadata.skipCustomerSupportEcssRecordTypeIds.contains(caseRecord.RecordTypeId)) {
                if((caserecord.RecordTypeId == rtWrapper.dlpRTypeID || caserecord.RecordTypeId == rtWrapper.amcRTypeID) && caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' ){
                    tasksToInsert.add(caseRecord);
                    caseRecord.Sub_Status__c = 'Call Attempt 1';                
                }
                caseVerticale = caseRecord.Vertical__c;
                if(caseVerticale != null && String.isNotBlank(caseVerticale)){
                    caseVerticale = caseVerticale.replaceAll( '&', '');
                    if(caseRecord.Vertical__c != oldCase.Vertical__c){
                        constantMdt = Constant__mdt.getInstance(caseVerticale.replaceAll( '\\s+', ''));
                    }
                    if(constantMdt != NULL) {
                        caseRecord.VerticalHeadEmail__c = constantMdt.ConstantValue__c;
                    }
                }
                String caseSubCategory = caseRecord.SubCategory__c;
                if(caseRecord.SubVertical__c =='CMO' &&  caseSubCategory != Null && String.isNotBlank(caseSubCategory)){
                    caseSubCategory = caseSubCategory.replaceAll( ' ', '_').removeEnd('_');
                    if(caseRecord.SubCategory__c != oldCase.SubCategory__c){
                        Constant__mdt constantMdtALD = Constant__mdt.getInstance(caseSubCategory);
                        if(constantMdtALD != NULL) {
                            caseRecord.ADM_Email__c = constantMdtALD.ConstantValue__c;
                        }
                    }
                }
                if(caseRecord.SubVertical__c== System.Label.Case_Subvertical_Onboarding){
                    caseRecord.ADM_Email__c = System.Label.Case_Subvertical_Onboarding_email;                    
                } else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_GCEO_Comms){
                    caseRecord.ADM_Email__c =System.Label.Case_Subvertical_GCEO_Comms_email;
                } else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_Riyadh_city){
                    caseRecord.ADM_Email__c =System.Label.Riyadh_city_Email;
                }
                if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT) && oldCase.OwnerId != caseRecord.OwnerId && oldCase.OwnerId.getsobjecttype() != User.sobjecttype ){
                    //--- To create "Call Atempt 1" only for Survey related cases.
                    if(oldCase.OwnerId == queueWrapper.surveyQueue.Id){
                        casesWithTask.add(caseRecord);
                    }
                }                               
                if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c ){
                    caseSubVerticalMap.put(caseRecord.Id, caseRecord.SubVertical__c);
                }
                if(oldCase.OwnerId != caseRecord.OwnerId && caseRecord.OwnerId.getsobjecttype() == User.sobjecttype && caseRecord.CCAOwner__c == null && usr.Profile.Name == Constants.CONTACT_CENTER_AGENT){
                    caseRecord.CCAOwner__c = caseRecord.OwnerId;
                }
                if(caseRecord.Status != 'Closed' && oldCase.Status == 'Closed') {
                    caseRecord.CaseReopenCount__c = caseRecord.CaseReopenCount__c + 1;
                }
                if(oldCase.Ownership_Bulk_Changed__c != caseRecord.Ownership_Bulk_Changed__c) {
                    ownershipchangeCases.add(caseRecord);
                    mapownerIds.put(caseRecord.id, oldCase.OwnerId);
                    caseRecord.Ownership_Bulk_Changed__c = oldCase.Ownership_Bulk_Changed__c;
                }
            }
        }
        if(!tasksToInsert.isEmpty()){
            CaseTriggerHelper.createResolvertask(tasksToInsert);
        }
        if(!casesWithTask.isEmpty()){
            taskCreationForCase(casesWithTask);
        }
        if(!caseSubVerticalMap.isEmpty()){
            CaseTriggerHelper.populateSubVerticalDependentInfo(caseSubVerticalMap, newCaseList, oldMap);
        }
        if(!ownershipchangeCases.isEmpty()){             
            MassOwnerShipChangeLogics.updateCaseOwner(OwnershipchangeCases, MapownerIds);
        }        
    }
    /*
    *********************************************************
    @Method Name    : taskCreationForCase
    @author         : 
    @description    : Method to create the task for case
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void taskCreationForCase(List<Case> newCaseList){
        List<Task> taskToInsert = new List<Task>();
        for(Case caseRecord : newCaseList){
            Task newTask = new Task(
                Subject=Constants.CASE_CALL_ATTEMPT_1, 
                WhoId=caseRecord.ContactId, 
                WhatId=caseRecord.Id, 
                ActivityDate=Date.today(), 
                OwnerId=caseRecord.OwnerId, 
                TaskNumber__c=10);
            CaseTriggerHandlerNew.newInsertSet.add(newTask);            
        }
    }
}