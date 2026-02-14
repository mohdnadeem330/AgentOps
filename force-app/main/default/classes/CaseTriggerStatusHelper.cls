/*
*********************************************************
Apex Class Name    : CaseTriggerStatusHelper
Created Date       : 
@description       : Class to handle case status Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public without sharing class CaseTriggerStatusHelper {
    //Global Variable Declaration - Start
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);    
    //Global Variable Declaration - End
    /*
    *********************************************************
    @Method Name    : caseStatusBeforeUpdate
    @author         : 
    @description    : Method to handle case status before update
    @param          : newCaseList,oldmap
    @return         : void
    ********************************************************
    */
    public static void beforeUpdateCaseStatusProcess(List<Case> newCaseList, Map<Id,Case> oldmap) {
        Set<Id> closedCaseTaskIds = new Set<Id>();        
        Set<Id> srcaseIds = new Set<Id>();
        Set<Id> casesWithOpenSR = new Set<Id>(); 
        List <String> skipResolvedQueueIds = new List <String>(System.label.Case_Skip_Resovled_Queue_ID.split(','));       
        for(Case caseRecord : newCaseList){            
            Case oldCase = oldmap.get(caseRecord.Id);
            if(caseRecord.Status != oldcase.Status) {
                String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID){                                                        
                    caseRecord.Sub_Status__c = null;
                    //Case revamp:To store resolved time, resolver group queue and user when case is resolved
                    if(caseRecord.Status == 'Resolved'  && caseRecord.FCR__c == false){
                        Caserecord.Resolved_Time__c = system.now();
                        Caserecord.Resolver_Group_Queue_Id__c = oldCase.OwnerId;
                        Caserecord.Resolver_Group_User__c = oldCase.Assigned_To__c;                   
                        if(caseRecord.Origin == 'Walk-In'){
                            caseRecord.OwnerId = System.label.Walk_in_team_queue;
                            caseRecord.Assigned_To__c = null ;
                        } else if(skipResolvedQueueIds.contains(oldCase.OwnerId)) { //Adarsh - Cases related to Handover,CFR,Baniyas and Al Saad to Shared Service Queue   
                            caseRecord.OwnerId = System.label.Shared_Service_Queue_ID;
                            caseRecord.Assigned_To__c = null ;  
                        }else if (!(caseRecord.OwnerId == System.label.Walk_in_team_queue && caseRecord.Origin == 'Email')){
                            caseRecord.OwnerId = System.label.Contact_center_team_queue;
                            caseRecord.Assigned_To__c = null ;
                        }                    
                    } 
                    // For Escalation Team Review 
                    if((Caserecord.Status == Constants.CASE_WORK_IN_PROGRESS ||Caserecord.Status == 'Escalated' || Caserecord.Status == 'Re Opened' )  && (oldCase.Status == 'Resolved' || oldCase.Status == 'Closed')){                    
                        if(Caserecord.Status == Constants.CASE_WORK_IN_PROGRESS){
                            Caserecord.Is_resolver_escalation__c = true;  
                        }
                        if(Caserecord.Resolver_Group_Queue_Id__c != null){
                            Caserecord.OwnerId = Caserecord.Resolver_Group_Queue_Id__c;
                        }
                        Caserecord.Assigned_To__c = Caserecord.Resolver_Group_User__c;                    
                    }                                       
                }
                if(caserecord.RecordTypeId == rtWrapper.amcRTypeID || caserecord.RecordTypeId == rtWrapper.dlpRTypeID) {
                    if(caseRecord.Status == Constants.Resolved ) {
                        Caserecord.Resolved_Time__c = system.now();
                        caseRecord.OwnerId = System.label.Contact_center_team_queue;
                        caseRecord.Assigned_To__c = null ;
                    }
                } 
                //Living changes Close Case looping
                if(caserecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID){
                    if(System.Label.GeneralCaseType.split(';').contains(caseRecord.Type) && caseRecord.Status == Constants.Resolved) {
                        Caserecord.Resolved_Time__c = system.now();
                        caseRecord.OwnerId = System.label.ECSS_Contact_Center_Queue;
                        caseRecord.Assigned_To__c = null ;
                    }
                }               
            }                        
        }               
    }
    /*
    *********************************************************
    @Method Name    : caseStatusBeforeUpdate
    @author         : 
    @description    : Method to handle case status before update
    @param          : newCaseList,oldmap
    @return         : void
    ********************************************************
    */
    public static void afterUpdateCaseStatusProcess(List<case> newCaseList, Map<Id,case> oldmap) {
        List<Case> closedCase = new List<Case>();
        Map<Id, Case> closedCasesMap = new Map<Id, Case>();
        List<Account> updateAccountList = new List<Account>();
        Map<Id,Account> accountMap = new Map<Id,Account>(); 
        Set<Id> accIds=new Set<Id>();
        for(Case newCase : newCaseList){ 
            if(newCase.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId) {
                accIds.add(newCase.AccountId);
            }    
        }                     
        accountMap = CaseTriggerHelper.getCaseRelAccount(accIds);
        for(Case newCase : newCaseList){            
            Case oldCase = oldmap.get(newCase.Id);
            String recordTypeName = newCase.recordTypeId != null ? Utilities.getRecordTypeName('Case', newCase.recordTypeId) : '';
            if(newCase.isClosed != oldCase.isClosed) {
                if(newCase.isClosed && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){ 
                    closedCasesMap.put(newCase.Id, newCase);
                }                               
            } 
            if (newCase.Status == Constants.CLOSED_CASE && oldCase.Status != Constants.CLOSED_CASE &&
                (newCase.StatusReason__c == Constants.WITH_RESOLUTION_CASE ||String.isBlank(newCase.StatusReason__c)) && 
                (newCase.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY || newCase.CaseCategory__c == Constants.CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR) &&
                (newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_PORTAL || newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_APP || newCase.Origin == Constants.PHONE || newCase.Origin == Constants.EMAIL)){
                Account accRecord = new Account();
                accRecord.Id = newCase.AccountId;
                /*accRecord.PersonEmail = newCase.Email__c;
                accRecord.EmailAddress__pc = newCase.Email__c;
                accRecord.MobileCountryCode__pc = newCase.MobileCountryCode__c;
                accRecord.MobilePhone__pc = newCase.MobileNumber__c;
                accRecord.PersonMobilePhone = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                accRecord.MobileNumberEnc__pc = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                accRecord.MaritalStatus__pc = newCase.MaritalStatus__c;  */      
                    
                if (newCase.Email__c != null) accRecord.PersonEmail = newCase.Email__c;
                if (newCase.Email__c != null) accRecord.EmailAddress__pc = newCase.Email__c;
                if (newCase.MobileCountryCode__c != null) accRecord.MobileCountryCode__pc = newCase.MobileCountryCode__c;
                if (newCase.MobileNumber__c != null) accRecord.MobilePhone__pc = newCase.MobileNumber__c;
                if (newCase.MobileCountryCode__c != null && newCase.MobileNumber__c != null) accRecord.PersonMobilePhone = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                if (newCase.MobileCountryCode__c != null && newCase.MobileNumber__c != null) accRecord.MobileNumberEnc__pc = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                if (newCase.MaritalStatus__c != null) accRecord.MaritalStatus__pc = newCase.MaritalStatus__c;
                
                if (newCase.PermanentStreet__c != null) accRecord.BillingStreet = newCase.PermanentStreet__c;
                if (newCase.PermanentCity__c != null) accRecord.BillingCity = newCase.PermanentCity__c;
                if (newCase.PermanentState__c != null) accRecord.BillingState = newCase.PermanentState__c;
                if (newCase.PermanentPostalCode__c != null) accRecord.BillingPostalCode = newCase.PermanentPostalCode__c;
                if (newCase.PermanentCountry__c != null) accRecord.BillingCountry = newCase.PermanentCountry__c;
                if (newCase.PassportNumber__c != null) accRecord.PassportNumber__pc = newCase.PassportNumber__c;
                if (newCase.PassportType__c != null) accRecord.PassportType__pc = newCase.PassportType__c;
                if (newCase.PlaceofIssue__c != null) accRecord.PlaceofIssue__pc = newCase.PlaceofIssue__c;
                if (newCase.PassportIssueDate__c != null) accRecord.PassportIssueDate__pc = newCase.PassportIssueDate__c;
                if (newCase.PassportExpiryDate__c != null) accRecord.PassportExpiryDate__pc = newCase.PassportExpiryDate__c;
                if (newCase.ResidentStatus__c != null) accRecord.ResidentStatus__pc = newCase.ResidentStatus__c;
                if (newCase.Current_Residential_Country__c != null) accRecord.CountryOfResidence__pc = newCase.Current_Residential_Country__c;
                if (newCase.Nationality__c != null) accRecord.Nationality__pc = newCase.Nationality__c;
                if (newCase.NationalIdNumber__c != null) accRecord.NationalIdNumber__pc = newCase.NationalIdNumber__c;
                if (newCase.NationalIdExpiryDate__c != null) accRecord.NationalIdExpiryDate__pc = newCase.NationalIdExpiryDate__c;
                if (newCase.EmploymentStatus__c != null) accRecord.EmploymentStatus__pc = newCase.EmploymentStatus__c;
                if (newCase.SourceofFunds__c != null) accRecord.SourceofFunds__pc = newCase.SourceofFunds__c;
                if (newCase.Company__c != null) accRecord.Company__pc = newCase.Company__c;
                if (newCase.Position__c != null) accRecord.Position__pc = newCase.Position__c;
                if (newCase.CompanyAddress__c != null) accRecord.CompanyAddress__pc = newCase.CompanyAddress__c;
                if (newCase.AnnualIncome__c != null) accRecord.AnnualIncome__pc = newCase.AnnualIncome__c;
                if (newCase.NumberOfYearsWithCompany__c != null) accRecord.NoofYearswithCompany__pc = newCase.NumberOfYearsWithCompany__c;
                if (newCase.Industry__c != null) accRecord.Industry = newCase.Industry__c;
                
                Account accRecordMatched = accountMap.get(newCase.AccountId);
                if(accRecordMatched!=null){
                    accRecord.isValidationBypass__c=!accRecordMatched.isValidationBypass__c;
                }
                CaseTriggerHandlerNew.updateMap.put(accRecord.id, accRecord);
                updateAccountList.add(accRecord);
            }           
        }
        if(!closedCasesMap.isEmpty()){
            CaseTriggerValidation.tasksValidation(closedCasesMap);
        }    
    }
}