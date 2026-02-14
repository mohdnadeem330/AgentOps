/*
*********************************************************
Apex Class Name    : CaseTriggerHelper
Created Date       : 
@description       : Class to handle case Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class CaseTriggerHelper {

    // Global variable declaration start         
    public static Map<String, Id> recordTypeByNames {
        get { if(recordTypeByNames == null) recordTypeByNames = AldarUtilityClass.getRecordTypeIdByParam('Case','Name'); return recordTypeByNames; }
        private set; 
    }

    // Static map to hold already-fetched Accounts (singleton cache)
    public static Map<Id, Account> caseRelAccMap = new Map<Id, Account>();

    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());

    public static Map<String, Group> queueMap;
    public static Map<String, Group> getQueueMap() {
        if (queueMap == null) {
            queueMap = AldarUtilityClass.fetchQueueMap(CaseTriggerMetadata.queuenames,new Set<String>());
        }
        return queueMap;
    }

    public static User currentUsrDetail;
    public static User getCurrentUserDetails() {
        if (currentUsrDetail == null) {
            currentUsrDetail = Utilities.getLoggedInUserDetail();
        }
        return currentUsrDetail;
    }

    public static Map<String, SystemMessages__mdt> systemMessagesMap;
    public static Map<String, SystemMessages__mdt> getSystemMessagesMap() {
        if (systemMessagesMap == null) {
            systemMessagesMap = AldarUtilityClass.getSystemMessages(CaseTriggerMetadata.errorMessages);
        }
        return systemMessagesMap;
    }
    // Global variable declaration End    
    /*
    *********************************************************
    @Method Name    : updateSalesOrderAndCustomer
    @author         : 
    @description    : Method to handle before Insert logic for case
    @param          : newCaseList, oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void updateSalesOrderAndCustomer(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Id> unitIds = new List<Id>();
        for (Case caseRecord: newCaseList) {
            Case oldCase = (oldCaseMap != null  && !oldCaseMap.isEmpty()) ? oldCaseMap.get(caseRecord.Id) : null;
            if ((caseRecord.Unit__c != null || (oldCase != null && oldCase.Unit__c == null)) && caserecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId && caseRecord.recordTypeId != ResaleService.getRecordTypeId('Case', 'Corporate_Legal')) {
                unitIds.add(caseRecord.Unit__c);
            }
        }        
        if (!unitIds.isEmpty()) {
            Map<String, SalesOrder__c> unitSalesOrderMap = new Map<String, SalesOrder__c>();
            for (SalesOrder__c salesOrder: [SELECT Id, Unit__c, Account__c, Account__r.PersonContactId, Status__c, Contact__c, TotalInstallmentReceived__c, TotalOutstanding__c, NetAmount__c, TotalBilled__c, NumberOfDefaults__c, HoldFlag__c, Unit__r.Project__r.AsiteProjectName__c  
                                            FROM SalesOrder__c 
                                            WHERE Unit__c IN: unitIds and Status__c != :System.Label.Cancelled]) {
                unitSalesOrderMap.put(salesOrder.Unit__c, salesOrder);
            }            
            for (Case caseRecord: (List<Case>)newCaseList) {
                Boolean isTenantAccountBypass = false;
                List<ECSS_Case_Checks__mdt> ecsscheck = ECSS_Case_Checks__mdt.getAll().values();
                for(ECSS_Case_Checks__mdt ecss : ecsscheck){
                    if(ecss.Case_Category__c ==caseRecord.CaseCategory__c && ecss.Is_Skip_AccountId__c ==true && caseRecord.CustomerType__c ==Constants.CASE_CUSTOMER_TENANT){
                        isTenantAccountBypass = true;
                        break;
                    }
                }
                if (caseRecord.Unit__c != null && unitSalesOrderMap.containsKey(caseRecord.Unit__c)) {
                    SalesOrder__c salesOrder = unitSalesOrderMap.get(caseRecord.Unit__c);
                    if(caseRecord.CaseCategory__c != Constants.CONTACT_DETAILS_UPDATE_CATEGORY && !isTenantAccountBypass){
                        caseRecord.AccountId = caseRecord.AccountId != null && (caseRecord.Origin == Constants.CASE_ORIGIN_CUSTOMER_PORTAL || caseRecord.Origin == Constants.CASE_ORIGIN_CUSTOMER_APP) ? caseRecord.AccountId : salesOrder.Account__c;
                        caseRecord.AccountId = salesOrder.Account__c;//need to verify
                    }
                    caseRecord.SalesOrder__c = salesOrder.Id;
                }
            }
        }
    }                             
    /*
    *********************************************************
    @Method Name    : populateCustomerDetailAndContact
    @author         : 
    @description    : Method to populate CustomerDetail And Contact
    @param          : newCaseList,oldMap
    @return         : void
    ********************************************************
    */
    public static void populateCustomerAndContactDetail(List<Case> newCaseList,Map<Id,Case> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id,account> accountIDToRecMap = new Map<Id,account>();
        for(Case caseRecord : newCaseList) {
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(oldMap == null && caseRecord.AccountId != null) {
                accountIds.add(caseRecord.AccountId);
            }
            if (oldMap != null) {
                Case oldCase = oldMap.get(caseRecord.Id);
                if(caseRecord.AccountId != null && caseRecord.AccountId != oldCase.AccountId){
                    accountIds.add(caseRecord.AccountId);
                }   
                if((recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.DLP_CASE_RT ) && caseRecord.AccountId != null && (oldCase.CaseCategory__c != caseRecord.CaseCategory__c || oldCase.AccountId != caseRecord.AccountId) && caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY){
                    accountIds.add(caseRecord.AccountId);
                }
            }
        }
        if(!accountIds.isEmpty()) {
            accountIDToRecMap = CaseTriggerHelper.getCaseRelAccount(accountIds);   
        } 
        if(!accountIDToRecMap.isEmpty()) {
            updateContact(newCaseList, accountIDToRecMap);
        }
        if(!accountIDToRecMap.isEmpty()){
            populateCustomerDetailsFromAccount(newCaseList, accountIDToRecMap);
        }
    }
    /*
    *********************************************************
    @Method Name    : updateKARChanges
    @author         : 
    @description    : Method to update KAR Changes
    @param          : newCaseList, caseUnitSet
    @return         : void
    ********************************************************
    */
    public static void updateKARChanges(List<Case> newCaseList,Set<Id> caseUnitSet) {
        Map<Id, String> karMap = new Map<Id, String>();
        for(HexaBPM__Service_Request__c sr : [SELECT Id, Unit__c, HOKAR__c FROM HexaBPM__Service_Request__c 
                                                WHERE HexaBPM__Record_Type_Name__c =: Constants.HANDOVER_RT
                                        AND Unit__c IN :caseUnitSet 
                                        AND HOKAR__c != null]) {
            karMap.put(sr.Unit__c, sr.HOKAR__c);
        }
        for(Case caseRecord : newCaseList) {
            if(karMap.containsKey(caseRecord.Unit__c)) {
                caseRecord.KAR__c = karMap.get(caseRecord.Unit__c);
            }
        }
    } 
    /*
    *********************************************************
    @Method Name    : updateContact
    @author         : 
    @description    : Method to populate contact
    @param          : newCaseList, accountIDToRecMap
    @return         : void
    ********************************************************
    */
    public static void updateContact(List<Case> newCaseList,Map<Id, Account> accountIDToRecMap) {
        for(Case caseRecord : newCaseList) {
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(caseRecord.AccountId != null){
                if(accountIDToRecMap.containsKey(caseRecord.AccountId) && accountIDToRecMap.get(caseRecord.AccountId) != null &&
                    accountIDToRecMap.get(caseRecord.AccountId).RecordType.Name == Constants.PERSON_ACCOUNT_RT &&
                    ((recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.AMC_CASE_RT ) && caseRecord.CustomerType__c == 'Owner')){
                        caseRecord.ContactId = accountIDToRecMap.get(caseRecord.AccountId).PersonContactId;
                }
            }
        }
    } 
    /*
    *********************************************************
    @Method Name    : populateCustomerDetailsFromAccount
    @author         : 
    @description    : Method to populate Customer Details From Account 
    @param          : caseRecords,accountIDToRecMap
    @return         : void
    ********************************************************
    */
    public static void populateCustomerDetailsFromAccount(list<Case> caseRecords, Map<Id,account> accountIDToRecMap){
        for(Case caseRecord : caseRecords){
            if(caseRecord.AccountId != null && (caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY || caseRecord.SubCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY)){
                Account accRecord = accountIDToRecMap.get(caseRecord.AccountId);
                if(accRecord != null && accRecord.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                    caseRecord.PassportNumber__c = accRecord.PassportNumber__pc;
                    caseRecord.ResidentStatus__c = accRecord.ResidentStatus__pc;
                    caseRecord.MaritalStatus__c = accRecord.MaritalStatus__pc;
                    caseRecord.EmploymentStatus__c = accRecord.EmploymentStatus__pc;
                    caseRecord.Email__c = accRecord.PersonEmail;
                    caseRecord.MobileCountryCode__c = accRecord.MobileCountryCode__pc;
                    caseRecord.MobileNumber__c = accRecord.MobilePhone__pc;
                    caseRecord.Company__c = accRecord.Company__pc;
                    caseRecord.Position__c = accRecord.Position__pc;
                    String workplaceAddress = accRecord.Workplace_Street__pc + ' ,'+ accRecord.Workplace_Country__pc + ' ,'+ accRecord.Workplace_Postalcode__pc;
                    string trimmedWorkplaceAddress = workplaceAddress != null ? workplaceAddress.substring(0, Math.min(255, workplaceAddress.length())) : '';
                    caseRecord.CompanyAddress__c = trimmedWorkplaceAddress;
                    caseRecord.NumberOfYearsWithCompany__c = accRecord.NoofYearswithCompany__pc;
                    caseRecord.Industry__c = accRecord.Industry;
                    caseRecord.AnnualIncome__c = accRecord.AnnualIncome__pc;
                }
            }
        }
    }  
    /*
    *********************************************************
    @Method Name    : CreateResolvertask
    @author         : 
    @description    : Method to create the Resolver task
    @param          : caserec
    @return         : void
    ********************************************************
    */
    public static void createResolvertask(list<case> caserec){
        String RecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Resolver Task').getRecordTypeId();
        List<Task> tasksToInsert = new List<Task>();
        for(case caseRecord : caserec){
            Task newTask = new Task();
            newTask.Subject = Constants.CASE_CALL_ATTEMPT_1;
            newTask.OwnerId = caseRecord.Assigned_To__c;
            newTask.WhatId = caseRecord.Id;
            newTask.Task_Name__c = Constants.CASE_CALL_ATTEMPT_1;
            newTask.RecordTypeId = RecordTypeID;
            newTask.Type__c = Constants.Task_type_Resolver;
            newTask.Case_Resolved_Time__c =caseRecord.Resolved_Time__c; 
            CaseTriggerHandlerNew.newInsertSet.add(newTask);
        }         
    }      
    /*
    *********************************************************
    @Method Name    : populateSubVerticalDependentInfoNew
    @author         : 
    @description    : Method to populate fields from RecordIdField
    @param          : caseSubVerticalMap,newList,oldMap
    @return         : void
    ******************************************************** 
    */
    public static void populateSubVerticalDependentInfoNew(Map<Id, String> caseSubVerticalMap, List<Case> newList, Map<Id, Case> oldMap){        
        try {
            List<Case_Field_Dependency_Revised__mdt> caseFieldDependencyList = Case_Field_Dependency_Revised__mdt.getall().values() != null ? Case_Field_Dependency_Revised__mdt.getall().values() : new List<Case_Field_Dependency_Revised__mdt>();
            Map<String, List<Case_Field_Dependency_Revised__mdt>> caseFieldDependencyMap = new Map<String, List<Case_Field_Dependency_Revised__mdt>>();
            Map<String, String> locationLabelMap = new Map<String, String>{'Yas Island' => System.Label.YasIsland_Queue_Label,'Saraya & Shams'  => System.Label.SarayaShams_Queue_Label,'North Baniyas'   => System.Label.NorthBaniyas_Queue_Label,'Merief' => System.Label.Merief_Queue_Label,'Al Wathba' => System.Label.AlWathba_Queue_Label, 'AL Raha' => System.Label.AlRaha_Queue_Label,'Al Falah' => System.Label.AlFalah_Queue_Label};            
            Map<Id, Case> caseMapForAutoAssign = new Map<Id, Case>();
            Map<Id, Case_Field_Dependency_Revised__mdt> dependencyMapForAutoAssign = new Map<Id, Case_Field_Dependency_Revised__mdt>();
            
            for(Case_Field_Dependency_Revised__mdt caseDependency : caseFieldDependencyList) {
                String key = caseDependency.Category__c + '-' + caseDependency.Sub_Category__c;
                if(!caseFieldDependencyMap.containsKey(key)){
                    caseFieldDependencyMap.put(key, new List<Case_Field_Dependency_Revised__mdt> {caseDependency});
                } else {
                    List<Case_Field_Dependency_Revised__mdt> fieldMapList = caseFieldDependencyMap.get(key);
                    fieldMapList.add(caseDependency);
                    caseFieldDependencyMap.put(key, fieldMapList);
                }           
            }
            for(Case caseRecord : (List<Case>)newList) {                
                if(caseSubVerticalMap.containsKey(caseRecord.Id)) {
                    String casekey = caseRecord.CaseCategory__c + '-' + caseRecord.SubCategory__c;
                    List<Case_Field_Dependency_Revised__mdt> fieldList = caseFieldDependencyMap.get(casekey) != null ? caseFieldDependencyMap.get(casekey) : new List<Case_Field_Dependency_Revised__mdt>();                    
                    for(Case_Field_Dependency_Revised__mdt caseFieldDependency : fieldList) {                        
                        if(oldMap != null) {
                            Case oldCase = (Case)oldMap.get(caseRecord.Id);
                            if(caseRecord.Origin == Constants.WALK_IN || oldcase.OwnerId == System.label.Walk_in_team_queue){
                                caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                            } else {
                                caseRecord.OwnerId = System.label.Contact_center_team_queue;
                            }      
                        } else {
                            if(caseRecord.Origin == Constants.WALK_IN){
                                caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                            }
                            else {
                                caseRecord.OwnerId = System.label.Contact_center_team_queue;
                            } 
                        }
                        if((caseRecord.Recordtype_Name__c == constants.Requests && caseRecord.FCR__c == false) || caseRecord.Recordtype_Name__c == constants.Complaints ){
                            caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c; 
                        }
                        if(caseFieldDependency.Location_Required__c && caseRecord.Location__c != null && locationLabelMap.containsKey(caseRecord.Location__c)){                            
                            caseRecord.OwnerId = locationLabelMap.get(caseRecord.Location__c);
                        }
                        if(caseRecord.Recordtype_Name__c == constants.Requests && caseRecord.FCR__c == true){
                            caseRecord.Assigned_To__c = UserInfo.getUserId();
                        }  
                        caseRecord.Organization__c = caseFieldDependency.Organization__c;
                        caseRecord.Department__c = caseFieldDependency.Department__c;
                        caseRecord.Vertical__c = caseFieldDependency.Vertical__c; 
                        caseRecord.SubVertical__c = caseFieldDependency.Sub_Vertical__c;
                        if (caseRecord.Customer_Type__c == System.label.Select_Customer && (caseRecord.RecordTypeId == rtWrapper.requestsRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID)) {
                            caseRecord.Priority = 'P1';
                        }else {
                            caseRecord.Priority = caseFieldDependency.Priority__c;
                        }                        
                        caseRecord.Escalation_level_1_Email__c = caseFieldDependency.Senior_Agent_Escalation__c;
                        caseRecord.Escalation_level_2_Email__c = caseFieldDependency.senior_associate_escalation__c;
                        caseRecord.Escalation_level_3_Email__c = caseFieldDependency.AVP_Escalation__c;
                        caseRecord.Escalation_level_4_Email__c = caseFieldDependency.Department_Head_Level_4__c;
                        caseRecord.Qualtrics_Survey_Required__c= caseFieldDependency.Customer_Survey__c; 
                        caseRecord.Email_Not_Triggered__c = caseFieldDependency.Email_Not_Triggered__c;
                        caseRecord.Service_request_Creation__c = caseFieldDependency.Is_Service_Created__c;                      
                        if((caseRecord.origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.origin != Constants.CASE_ORIGIN_CUSTOMER_APP && caseRecord.origin != Constants.EMAIL)) {
                             caseRecord.Subject = caseRecord.CaseCategory__c +'-'+ caseRecord.SubCategory__c;
                        }
                        //For populating ADM email for riyadh city
                        if (caseRecord.CaseCategory__c == System.Label.Case_Subvertical_Riyadh_city){
                            caseRecord.ADM_Email__c = System.Label.Riyadh_city_Email;
						}
                        if (oldMap != null) {
                            Case oldCase = (Case)oldmap.get(caseRecord.Id);               
                            
                            if(oldCase.OwnerId != caseRecord.OwnerId && caseRecord.FCR__c == false){
                                caseRecord.Assigned_To__c = null;
                            }
                        }
                        //By Adarsh for case auto assingment
                        if(caseFieldDependency.Auto_Assingment__c != null){
                            caseMapForAutoAssign.put(caseRecord.Id, caseRecord);
                            dependencyMapForAutoAssign.put(caseRecord.Id, caseFieldDependency);
                        }
                    }                
                    if((caseRecord.Recordtype_Name__c == constants.Requests) || caseRecord.Recordtype_Name__c == constants.Complaints){
                        if(caseRecord.Priority == 'P1'){
                            caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                        } else if(caseRecord.Priority == 'P2'){
                            caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                        } else if(caseRecord.Priority == 'P3'){
                            caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                        }                    
                    }                             
                }
            }
            // For case auto assingment
            if(!caseMapForAutoAssign.isEmpty()) {
                autoassigmentBulk(caseMapForAutoAssign, dependencyMapForAutoAssign);
            }
        } catch (Exception e) {            
            System.debug('Error in populateSubVerticalDependentInfo: ' + e.getMessage());
        }
    }
    /*
    *********************************************************
    @Method Name    : autoassigmentBulk
    @author         : 
    @description    : Added be adarsh for case auto assingment
    @param          : 
    @return         : caseMap,dependencyMap
    ********************************************************
    */    
    public static void autoassigmentBulk(Map<Id, Case> caseMap,Map<Id, Case_Field_Dependency_Revised__mdt> dependencyMap){        
        List<case> autoSaleCases = new List<case>();
        List<case> autoBrokerCases = new List<case>();
        List<case> autoResaleCases = new List<case>();
        List<ID> autoResaleCasesUnit = new List<ID>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> unitToCaseMap = new Map<Id, Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();        
        Map<Id, Opportunity> accountToOppMap = new Map<Id, Opportunity>();
        for (Id caseId : caseMap.keySet()) {
            Case caseRec = caseMap.get(caseId);
            Case_Field_Dependency_Revised__mdt fieldDep = dependencyMap.get(caseId);
            
            if (fieldDep != null && fieldDep.Auto_Assingment__c != null) {
                if (fieldDep.Auto_Assingment__c == Constants.SALES_QUEUE) {
                    autoSaleCases.add(caseRec);
                    accountIds.add(caseRec.AccountId);
                } else if (fieldDep.Auto_Assingment__c == Constants.BROKER_QUEUE) {
                    autoBrokerCases.add(caseRec); 
                    accountIds.add(caseRec.AccountId);
                }
                else if (fieldDep.Auto_Assingment__c == Constants.RESALE_QUEUE) {
                    autoResaleCases.add(caseRec);
                    autoResaleCasesUnit.add(caseRec.Unit__c);                   
                }                
            }
        }
        if(!autoResaleCasesUnit.isempty()){
            for(case rsc : [Select id,OwnerId,Unit__c from case where Unit__c IN :autoResaleCasesUnit And Recordtype_Name__c =: Constants.CASE_RECORD_TYPE_RESALE AND Status != :Constants.CLOSED_CASE ORDER BY LastModifiedDate DESC  ]){
                unitToCaseMap.put(rsc.Unit__c,rsc.OwnerId);  
            }
        }
        if(!accountIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, AccountId, SalesManager__c,SalesManager__r.Team__c FROM Opportunity WHERE AccountId IN :accountIds ORDER BY LastModifiedDate DESC]) {
                if (!accountToOppMap.containsKey(opp.AccountId)) {
                    accountToOppMap.put(opp.AccountId, opp);
                }
            }        
            accountMap = new Map<Id, Account>([SELECT Id, OwnerId,Owner.Team__c FROM Account WHERE Id IN :accountIds]);
        }        
        if(!autoSaleCases.isEmpty()){
            Map<id,String> salesGroupUser = checkUserQueue(Constants.SALES_QUEUE);
            for (Case cs : autoSaleCases) {
                Opportunity opp = accountToOppMap.get(cs.AccountId);
                if (opp != null && opp.SalesManager__c != null && salesGroupUser.containsKey(opp.SalesManager__c)) {
                    cs.Assigned_To__c = opp.SalesManager__c;
                    cs.User_Location__c = opp.SalesManager__r.Team__c;
                    
                } else {
                    Account acc = accountMap.get(cs.AccountId);
                    if (acc != null && acc.OwnerId !=null && salesGroupUser.containsKey(acc.OwnerId)) {
                        cs.Assigned_To__c = acc.OwnerId;
                        cs.User_Location__c = acc.Owner.Team__c;                        
                    }
                }
            }
        }
        else if (!autoBrokerCases.isEmpty()){
            Map<Id, String> brokerGroupUser = checkUserQueue (Constants.BROKER_QUEUE);
            for(Case cs : autoBrokerCases){
                Account acc = accountMap.get(cs.AccountId);
                if (acc != null && acc.OwnerId !=null && brokerGroupUser.containsKey(acc.OwnerId)) {
                    cs.Assigned_To__c = acc.OwnerId;
                    cs.User_Location__c = acc.Owner.Team__c;                    
                }
            }
        }
        else if (!autoResaleCases.isEmpty()){
            Map<id,String> resaleGroupUser = checkUserQueue (Constants.RESALE_QUEUE);
            for(Case cs : autoResaleCases){
                Id assignedUserId = unitToCaseMap.get(cs.Unit__c);
                if (assignedUserId != null && resaleGroupUser.containsKey(assignedUserId)) {
                    cs.Assigned_To__c = assignedUserId;
                }
            }
        }              
    }
    /*
    *********************************************************
    @Method Name    : checkUserQueue
    @author         : 
    @description    : Method used to get userIds from a queue
    @param          : grpName
    @return         : 
    ********************************************************
    */
    public static Map<id,String> checkUserQueue (String grpName){
        Map<Id, String> userGroupMap = new Map<Id, String>();
        for (GroupMember gm : [SELECT Id, UserOrGroupId, Group.Name FROM GroupMember WHERE Group.Name =: grpName]) {
            if (gm.UserOrGroupId != null && gm.Group != null) {
                userGroupMap.put(gm.UserOrGroupId, gm.Group.Name);
            }
        }
        return userGroupMap;
    }    
    /*
    *********************************************************
    @Method Name    : populateSubVerticalDependentInfo
    @author         : 
    @description    : Method used to populate the subvertical dependent fields
    @param          : caseSubVerticalMap,newList,oldMap
    @return         : 
    ********************************************************
    */
    public static void populateSubVerticalDependentInfo(Map<Id,String> caseSubVerticalMap, List<SObject> newList, Map<Id, SObject> oldMap){

        List<CaseFieldDependency__mdt> caseFieldDependencyList = Utilities.getCaseFieldDependency() != null ? Utilities.getCaseFieldDependency() : new List<CaseFieldDependency__mdt>();
        Map<String,List<CaseFieldDependency__mdt>> caseFieldDependencyMap = new Map<String,List<CaseFieldDependency__mdt>>();        
        for(CaseFieldDependency__mdt caseDependency : caseFieldDependencyList)
        {
            if(!caseFieldDependencyMap.containsKey(caseDependency.SubVertical__c)) {
                caseFieldDependencyMap.put(caseDependency.SubVertical__c, new List<CaseFieldDependency__mdt> {caseDependency});
            } else {
                List<CaseFieldDependency__mdt> fieldMapList = caseFieldDependencyMap.get(caseDependency.SubVertical__c);
                fieldMapList.add(caseDependency);
                caseFieldDependencyMap.put(caseDependency.SubVertical__c, fieldMapList);
            } 
        }
        //ASF-892
        String loggedInUserEmail=UserInfo.getUserEmail();
        //ASF-1351  
        Group handoverCaseQueue = queueWrapper.handoverCaseQueue;
        List<String> codeRedUsersEmailList=new  List<String>();
        for(Case_Code_Red_Allow_Users__mdt codeRedConfig : Case_Code_Red_Allow_Users__mdt.getall().values()) {
            codeRedUsersEmailList.add(codeRedConfig.User_Email__c);
        }
        //ASF-892
        for(Case caseRecord : (List<Case>)newList){
            //ASF-1351   
            if(caseRecord.Id!=null){
                Case oldCaseRecord = (Case)oldMap.get(caseRecord.Id);
                if((oldCaseRecord==null && caseRecord.SubVertical__c != null && caseRecord.SubVertical__c == Constants.Property_Handover) ||
                    oldCaseRecord!=null && caseRecord.SubVertical__c!=oldCaseRecord.SubVertical__c && 
                    caseRecord.SubVertical__c != null && caseRecord.SubVertical__c == Constants.Property_Handover) {
                    caseRecord.OwnerId = handoverCaseQueue.Id;
                }
            }else if (caseRecord.Id==null && caseRecord.SubVertical__c == Constants.Property_Handover){
                caseRecord.OwnerId = handoverCaseQueue.Id;
            }                    
            if(caseSubVerticalMap.containsKey(caseRecord.Id)){
                List<CaseFieldDependency__mdt> fieldList = caseFieldDependencyMap.get(caseRecord.SubVertical__c) != null ? caseFieldDependencyMap.get(caseRecord.SubVertical__c) : new List<CaseFieldDependency__mdt>();                                                               
                for(CaseFieldDependency__mdt caseFieldDependency : fieldList){
                    caseRecord.Organization__c = caseFieldDependency.Organization__c;
                    caseRecord.Department__c = caseFieldDependency.Department__c;
                    caseRecord.Vertical__c = caseFieldDependency.Vertical__c;   
                    //2.2 START
                    if(caseRecord.SubCategory__c ==   caseFieldDependency.SubCategory__c && caseFieldDependency.Skills_Required__c != null) {
                        caseRecord.Skills_Required__c = caseFieldDependency.Skills_Required__c; 
                    }
                    //2.2 END
                    if(caseRecord.SubVertical__c == Constants.Comms){
                        caseRecord.Vertical__c = caseRecord.CaseCategory__c;
                    }  
                    //For Emergency cases
                    /*if(caseRecord.SubCategory__c == Constants.EMERGENCY && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c){
                        caseRecord.Priority = caseFieldDependency.Priority__c;  caseRecord.EscalationPriority__c = caseFieldDependency.EscalationPriority__c;
                        caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c; caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                        caseRecord.MilestoneStatus__c = Constants.WITHIN_SLA;
                    }*/                   
                    //Added by Adarsh       
                    if((caseRecord.CaseCategory__c == label.DM_CAFM || caseRecord.CaseCategory__c ==system.label.Case_Etihad_mile || caseRecord.CaseCategory__c == system.label.Case_CEO_Comms) && caseFieldDependency.Case_Owner_Queue__c != null ){
                        caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c;
                    }                                                      
                    if (caseFieldDependency.Case_Owner_Queue__c != null && caseRecord.SubVertical__c == system.label.Case_Subvertical_Riyadh_city) {
                        caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c;
                    }                      
                    // to populate DLP priority fields depends on 
                    if((caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL || caseRecord.SubVertical__c == 'New Sale'  ) && (caseRecord.CaseCategory__c == 'Civil' || caseRecord.CaseCategory__c == 'MEP')){
                        if(caseFieldDependency.SubVertical__c == caseRecord.SubVertical__c && caseFieldDependency.CaseCategory__c == caseRecord.CaseCategory__c && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c && caseFieldDependency.ProblemCode__c == caseRecord.ProblemCode__c && caseFieldDependency.IncidentDescription__c == caseRecord.IncidentDescription__c && caseFieldDependency.ResolutionType__c == caseRecord.ResolutionType__c){
                            caseRecord.Priority = caseFieldDependency.Priority__c; 
                            caseRecord.EscalationPriority__c = caseFieldDependency.EscalationPriority__c;
                            //Ticket ASF-516
                            //Added below condition for ASF-1598 do not send survey & Email for child cases
                            if(caseRecord.ParentId == null) {
                                caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c;
                                caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                            } else {
                                caseRecord.Qualtrics_Survey_Required__c = false;
                                caseRecord.Email_Not_Triggered__c=true;
                            }                           
                            //ASF-892
                            if(caseRecord.Priority==Constants.CODE_RED_PRIORITY){
                                if(!codeRedUsersEmailList.contains(loggedInUserEmail)){
                                    caseRecord.addError(System.label.Error_CodeRed_Case_NotAllowed);
                                }
                            }
                        }
                    } else{
                        if(caseFieldDependency.SubVertical__c == caseRecord.SubVertical__c && caseFieldDependency.CaseCategory__c == caseRecord.CaseCategory__c 
                            && ( String.isNotBlank( caseRecord.SubCategory__c) && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c)
                            && ( String.isNotBlank(caseRecord.IncidentDescription__c) && caseFieldDependency.IncidentDescription__c.equalsIgnoreCase( caseRecord.IncidentDescription__c )) ){
                            caseRecord.Priority = caseFieldDependency.Priority__c; 
                            //ASF-892
                             if(caseRecord.Priority==Constants.CODE_RED_PRIORITY) {
                                if(!codeRedUsersEmailList.contains(loggedInUserEmail)){
                                    caseRecord.addError(System.label.Error_CodeRed_Case_NotAllowed);
                                }
                            }
                            //Ticket ASF-516
                            //Added below condition for ASF-1598 do not send survey for child cases
                            if(caseRecord.ParentId == null){
                              caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c;
                                caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                            } else {
                                caseRecord.Qualtrics_Survey_Required__c = false;
                            caseRecord.Email_Not_Triggered__c=true;
                            }
                            if(oldMap == null){
                                caseRecord.ResolutionType__c = caseFieldDependency.ResolutionType__c; 
                            }
                        }
                    }
                }                  
            }
            Constant__mdt constantMdt = new Constant__mdt();
            String caseVerticale;
            caseVerticale = caseRecord.Vertical__c;
            if(caseVerticale != Null || String.isNotBlank(caseVerticale)){
                caseVerticale = caseVerticale.replaceAll( '&', '');
                constantMdt = Constant__mdt.getInstance(caseVerticale.replaceAll( '\\s+', ''));
                if(constantMdt != NULL) {
                    caseRecord.VerticalHeadEmail__c = constantMdt.ConstantValue__c;
                }
            }            
            //Ticket ASF-516
            String caseSubCategory = caseRecord.SubCategory__c;
            if(caseRecord.SubVertical__c == Constants.CMO &&  caseSubCategory != Null && String.isNotBlank(caseSubCategory)){
                caseSubCategory = caseSubCategory.replaceAll( ' ', '_').removeEnd('_');
                Constant__mdt constantMdtALD = Constant__mdt.getInstance(caseSubCategory);
                if(constantMdtALD != NULL) {
                    caseRecord.ADM_Email__c = constantMdtALD.ConstantValue__c;
                }
            }  
        }
    } 
    /*
    *********************************************************
    @Method Name    : UpdateOffLineQtyInprogress
    @author         : 
    @description    : Method used to update the offline qty inprogress in the OpportunityOfferLine__c
    @param          : mapSOProdId,event
    @return         : 
    ********************************************************
    */
    public static void updateOffLineQtyInprogress(Map<Id,Set<Id>> mapSOProdId,String event){
        List<OpportunityOfferLine__c> lstOffLines = new List<OpportunityOfferLine__c>();            
        for(OpportunityOfferLine__c oppOff: [SELECT Id,QuantityInProgress__c,SalesOrder__c,ConsumedQuantity__c,Product_Item__r.Product2Id FROM OpportunityOfferLine__c WHERE SalesOrder__c=: mapSOProdId.keySet() AND Product_Item__r.Product2.Type__c = 'On Demand' AND Product_Item__r.Product2.isActive = True]){
            Set<Id> setprods = mapSOProdId.get(oppOff.SalesOrder__c);
            if(setprods != null && setprods.contains(oppOff.Product_Item__r.Product2Id)){
                if(event == Constants.CREATE) {
                    oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c + 1 : 1);   
                } else if(event == Constants.CLOSED)    {
                    oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c - 1 : 0);   
                    oppOff.ConsumedQuantity__c = (oppOff.ConsumedQuantity__c != null ? oppOff.ConsumedQuantity__c + 1 : 1);   
                }
                else if(event == Constants.CANCELLED){
                    oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c - 1 : 0);   
                }
                CaseTriggerHandlerNew.updateMap.put(oppOff.id,oppOff);
            }    
        }    
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateCreateCaseDocument
    @author         : 
    @description    : Method used to create case documents
    @param          : newCaseList,oldCaseMap
    @return         : 
    ********************************************************
    */
    public static void afterUpdateCreateCaseDocument(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<case> caseToProcess = new List<case>();
        for(Case newCase : newCaseList) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', newCase.recordTypeId);
            if((recordTypeName == Constants.DLP_CASE_RT  || recordTypeName == Constants.STANDARD_CASE_RT || newCase.Recordtype_Name__c == constants.Requests || newCase.Recordtype_Name__c == constants.Complaints ) && newCase.CustomerInformationConfirmed__c != oldCase.CustomerInformationConfirmed__c && newCase.CustomerInformationConfirmed__c == true){
                caseToProcess.add(newCase);
            }
        }
        if(!caseToProcess.isEmpty()) {
            createCaseDocuments(caseToProcess);
        }
    }
    /*
    *********************************************************
    @Method Name    : createCaseDocuments
    @author         : 
    @description    : Method used to create case documents
    @param          : caseRecords
    @return         : 
    ********************************************************
    */
    public static void createCaseDocuments(List<Case> caseRecords){
        Map<Id,Document__c> documentMapToInsert = new Map<Id,Document__c>();
        Map<String,ID> documentRecordTypeMap = new Map<String,ID>();
        Map<String,List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_CASE, ResaleConstants.DOCUMENT_PLACEHOLDER_CATEGORY_RESALE_CASE});
        Map<Id,Case> caseIDToRecMap = new Map<Id,Case>(caseRecords);
        if(!documentMap.isEmpty() && !caseIDToRecMap.isEmpty()){
            //get Existing Documents
            Map<String,Document__c> existingDocMap = new Map<String,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,Case__c from Document__c where Case__c in :caseIDToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Case__c+tempDoc.DocumentType__c,tempDoc);
            }
            for(Case caseRecord : caseRecords){
                String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                String documentTypeToProcess; 
                if( recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || caseRecord.Recordtype_Name__c == constants.Requests || caseRecord.Recordtype_Name__c == constants.Complaints ){
                    documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_CASE;
                }else if(recordTypeName == ResaleConstants.Resale_Case_RecordTypeName){
                    documentTypeToProcess = ResaleConstants.DOCUMENT_PLACEHOLDER_CATEGORY_RESALE_CASE;
                }
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    String recordTypeID=null;                    
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }                        
                    if(!existingDocMap.containsKey(caseRecord.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                        documentRecord.Case__c = caseRecord.Id;
                        if(recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){
                            documentRecord.Account__c = caseRecord.AccountId;
                        }else{
                            if(ResaleService.ResaleRRQueue != null && caseRecord.OwnerId != ResaleService.ResaleRRQueue.Id){
                                documentRecord.OwnerId = caseRecord.OwnerId;
                            }
                        }
                        CaseTriggerHandlerNew.newInsertSet.add(documentRecord); 
                        existingDocMap.put(caseRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }    
            }
        }        
    }    
    /*
    *********************************************************
    @Method Name    : getCaseRelAccount
    @author         : 
    @description    : Method to fetch case related Account
    @param          : accountIDs
    @return         : 
    ********************************************************
    */
    public static Map<Id, Account> getCaseRelAccount(Set<Id> accountIDs) {
        // Collect IDs not already in the map
        Set<Id> missingIds = new Set<Id>();
        for (Id accId : accountIDs) {
            if (!caseRelAccMap.containsKey(accId)) {
                missingIds.add(accId);
            }
        }
        // Query only missing Accounts
        if (!missingIds.isEmpty()) {
            for (Account acc : [SELECT Id,
                                NoofYearswithCompany__pc, Industry, AnnualIncome__pc, Name,RecordType.Name, PersonContactId, FirstName, MiddleName, 
                                LastName, PassportNumber__pc, ResidentStatus__pc, MaritalStatus__pc, EmploymentStatus__pc, PersonEmail, MobilePhone__pc, 
                                MobileCountryCode__pc,IsPersonAccount,MobileNumber__c, isValidationBypass__c,Company__pc, Position__pc, Workplace_Country__pc,Workplace_Postalcode__pc,Workplace_Street__pc
                                FROM Account 
                                WHERE ID IN:missingIds]) {
                caseRelAccMap.put(acc.Id, acc);
            }
        }
        // Return the full map (old + newly fetched)
        return caseRelAccMap;
    }
}