/*
*********************************************************
Apex Class Name    : PropertyTransferService
Created Date       : June 27 2025
@description       : This Class is used for Specfic for Property Transfer Service Requests
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class PropertyTransferService {
    /*
*********************************************************
@Method Name    : validatePropertyTransferSR
@author         : 
@description    : Method to validate SR Resale case
@param          : serviceRequests,propertyTransferRecIds,unitIds,caseIds
@return         : void
********************************************************
*/ 
    public static void validatePropertyTransferSR(List<HexaBPM__Service_Request__c> serviceRequests, set<Id> propertyTransferRecIds, set<Id> ptunitIds, set<Id> caseIds){         
        Map<ID,case> unitCaseMap=new Map<ID,case>();
        Map<ID,Case> listResaleCaseMap =new   Map<ID,Case>();
        Map<Id,HexaBPM__Service_Request__c> pTOffplanMap = new Map<Id,HexaBPM__Service_Request__c>();
       // List<HexaBPM__Service_Request__c> listPtOffplan = [Select Id,Name,HexaBPM__External_SR_Status__r.Name From HexaBPM__Service_Request__c where SRType__c ='Property Transfer (Off Plan)' and HexaBPM__External_SR_Status__r.Name Not In ('Closed','Cancelled') and Unit__c In :ptunitIds];
        for(HexaBPM__Service_Request__c sr :[Select Id,Name,HexaBPM__External_SR_Status__r.Name,Unit__c From HexaBPM__Service_Request__c where SRType__c ='Property Transfer (Off Plan)' and HexaBPM__External_SR_Status__r.Name Not In ('Closed','Cancelled') and Unit__c In :ptunitIds]){
            pTOffplanMap.put(sr.Unit__c,sr);
        }
        for (Case cs : [select Id,Recordtype_Name__c, Unit__c,Opportunity__c,CaseNumber,CaseCategory__c,SubCategory__c,Status  from case where (ID IN : caseIds OR (CaseCategory__c IN ('Property Transfer', 'Property Transfer NOC') and Opportunity__c !=null and status!='Closed' and Unit__c  IN :ptunitIds))]) {
            if (caseIds.contains(cs.Id)) {
                unitCaseMap.put(cs.Unit__c, cs);
            }
            if ((cs.CaseCategory__c == Constants.PROPERTY_TRANSFER_RT || cs.CaseCategory__c == Constants.PROPERTY_TRANSFER_NOC_RT) 
                && cs.Opportunity__c != null && cs.Status != Constants.CLOSED && ptunitIds.contains(cs.Unit__c)) {
                    listResaleCaseMap.put(cs.Unit__c, cs);
                }
        }        
        
        for(HexaBPM__Service_Request__c sr: serviceRequests){
            
            // SSR 751 OffPlan
            if(sr.SRType__c == Constants.PROPERTY_TRANSFER_OffPlan && pTOffplanMap.containsKey(sr.Unit__c)){
                sr.addError('Kindly note that there is already an open request for the selected Unit.');
            }
            
            if(propertyTransferRecIds.contains(sr.recordTypeId) && listResaleCaseMap.get(sr.Unit__c)!=null){             
                case matchedCase=unitCaseMap.get(sr.Unit__c);
                if(matchedCase==null || matchedCase.CaseNumber!=listResaleCaseMap.get(sr.Unit__c).CaseNumber){
                    String casenumber= listResaleCaseMap.get(sr.Unit__c).CaseNumber;
                    sr.addError(System.label.Resale_Listed_SR_Error + ' ' +casenumber);
                }             
            }          
        }
    }
    /*
*********************************************************
@Method Name    : ComplianceCheck
@author         : 
@description    : Method to trigger screening case to check compliance
@param          : List of new serviceRequests
@return         : void
********************************************************
*/
    // Added by Adarsh for buyers complaince check 
    public static void ComplianceCheck(Set<Id> accIds) {
        List<Account> accountsToUpdateLst = new List<Account>();
        for(Id accId : accIds){
            Account accountToUpdate = new Account(Id = accId, Trigger_screening_Case__c = true);
            accountsToUpdateLst.add(accountToUpdate);
        } 
        if(!accountsToUpdateLst.isEmpty()){
            AccountTriggerHandler.skipAccountTrigger = true;
            update accountsToUpdateLst;
            AccountTriggerHandler.skipAccountTrigger = false;
        }
    }
    /*
*********************************************************
@Method Name    : closeADMStep
@author         : 
@description    : Method to close ADM Step
@param          : List of new serviceRequests
@return         : void
********************************************************
*/ 
    public static void closeADMStep(List<HexaBPM__Service_Request__c> newSRList ){
        List<Id> srIdList = new List<Id>();
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
        List<HexaBPM__Step__c> titleDeedStepsToClose  = new List<HexaBPM__Step__c>();
        Map<string, HexaBPM__Status__c> stepStatusMap = new Map<string, HexaBPM__Status__c>();
        for( HexaBPM__Service_Request__c sr: newSRList){
            srIdList.add(sr.Id);
        }
        stepStatusMap = ServiceRequestTriggerHelper.getStepStatus();
        for (HexaBPM__Step__c srStep : [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c =:Constants.TRANSFER_EXEC_STATUS_ADM AND HexaBPM__Step_Status__c =: Constants.PENDING_STATUS]) {
            srStep.HexaBPM__Status__c = stepStatusMap.get(Constants.COMPLETED).Id;
            srStepsToUpdateList.add(srStep); 
        }
        if(!srStepsToUpdateList.IsEmpty()){
            update srStepsToUpdateList;            
            //Opening Title Deed Steps          
            List<HexaBPM__Step__c> stepList = new List<HexaBPM__Step__c>();  
            Set<String> templateNames =new Set<String>();
            templateNames.add(Constants.TITLE_DEED_APPROVAL);
            Map<string,HexaBPM__SR_Steps__c> stepTemplateMap =new Map<string,HexaBPM__SR_Steps__c>();
            for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,
                                                    HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name from HexaBPM__SR_Steps__c 
                                                    where HexaBPM__SR_Template__r.Name =: Constants.PROPERTY_TRANSFER_NOC_RT and HexaBPM__Step_Template__r.Name IN :templateNames]){  
                stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
            }            
            for(Id srId:srIdList){
                for(String tpStepname : templateNames){
                    if(stepTemplateMap.containsKey(tpStepname)){
                        HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
                        HexaBPM__Step__c tempRec = new HexaBPM__Step__c( 
                            ExecuteCustomCode__c =tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c, 
                            HexaBPM__SR_Step__c = tempStep.Id,
                            OwnerId = tempStep.OwnerId, 
                            HexaBPM__SR__c = srId,
                            HexaBPM__Start_Date__c = System.today(), 
                            HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c, 
                            HexaBPM__Status__c =  stepStatusMap.get(Constants.PENDING_STATUS).Id,
                            HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                            HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name, 
                            HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1');
                        stepList.add(tempRec);   
                    }
                }                
            }
            if(!stepList.isEmpty()){
                insert stepList;
            }
            for (HexaBPM__Step__c titleStep : [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c =:Constants.TITLE_DEED_APPROVAL AND HexaBPM__Step_Status__c = :Constants.PENDING_STATUS]) {
                titleStep.HexaBPM__Status__c = stepStatusMap.get(Constants.STATUS_APPROVED).Id;
                titleDeedStepsToClose.add(titleStep); 
            }
            if(!titleDeedStepsToClose.IsEmpty()){
                update titleDeedStepsToClose;
            }
        }                
    }
    
    
    // SSR 751 OffPlan
    public static void PtOffplanSRStepOpen(List<HexaBPM__Service_Request__c> newSRList){       
        
        Id completedSts = ServiceRequestTriggerHelper.getStepStatus().get(Constants.COMPLETED_STATUS)?.Id;
        Id pendingStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
        Map<String,HexaBPM__SR_Steps__c> stepMap = new Map<String,HexaBPM__SR_Steps__c>();
        List<HexaBPM__Step__c> stepsToInsert = new  List<HexaBPM__Step__c>();
        List<HexaBPM__Step__c> digitalPendingSteps = new List<HexaBPM__Step__c>();
        List<Communication_Preference__c> fastrackToInsert = new List<Communication_Preference__c>();
        
        List<HexaBPM__SR_Steps__c> tempStepCode = [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
                                                   from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Property Transfer (Off Plan)' and
                                                   HexaBPM__Step_Template__r.Name IN ('Digital Step Pending','Verification of Buyer Profile','Verification of Seller Profile','Compliance Check for Buyers')];
        for(HexaBPM__SR_Steps__c step : tempStepCode){
            stepMap.put(step.HexaBPM__Step_Template__r.Name,step);	
        }
        
        Set<Id> allFastTrackCPAccIds = new Set<Id>();
        for (HexaBPM__Service_Request__c sr : newSRList) {
            if (sr.SRType__c == Constants.PROPERTY_TRANSFER_OffPlan && (sr.Origin__c == 'Customer Portal' || sr.Origin__c == 'Customer App')){
                if (sr.HexaBPM__Customer__c != null)
                    allFastTrackCPAccIds.add(sr.HexaBPM__Customer__c);
                
                if (sr.BuyerName__c != null)
                    allFastTrackCPAccIds.add(sr.BuyerName__c);
            }
        } 
        system.debug('allFastTrackCPAccIds--> '+allFastTrackCPAccIds);
        Set<Id> fastTrackCPAccountIds = new Set<Id>();
        for (Communication_Preference__c cp : [SELECT Id, Account__c FROM Communication_Preference__c WHERE Account__c IN :allFastTrackCPAccIds AND Category__c = 'FastTrack']) {
            fastTrackCPAccountIds.add(cp.Account__c);
        }
        system.debug('fastTrackCPAccountIds--> '+fastTrackCPAccountIds);
        for(HexaBPM__Service_Request__c sr : newSRList){
            if((sr.Origin__c == 'Customer Portal' || sr.Origin__c =='Customer App') && sr.SRType__c == Constants.PROPERTY_TRANSFER_OffPlan){ 
                Boolean sellerKyc = UnitAvailabilityWebService.checkCustomerKYCStatus(sr.HexaBPM__Customer__c); 
                Boolean buyerKyc = UnitAvailabilityWebService.checkCustomerKYCStatus(sr.BuyerName__c); 
                system.debug('sellerKyc--> '+sellerKyc);
                system.debug('buyerKyc--> '+buyerKyc);
                if(stepMap.containsKey('Digital Step Pending')){
                    HexaBPM__SR_Steps__c temp = stepMap.get('Digital Step Pending');
                    HexaBPM__Step__c tempRec = new   HexaBPM__Step__c( ExecuteCustomCode__c =
                                                                      temp.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                                      HexaBPM__SR_Step__c = temp.Id,
                                                                      OwnerId = temp.OwnerId,
                                                                      HexaBPM__SR__c = sr.Id,
                                                                      HexaBPM__Start_Date__c = System.today(),
                                                                      HexaBPM__Step_No__c = temp.HexaBPM__Step_No__c,
                                                                      HexaBPM__Status__c = pendingStatus,
                                                                      HexaBPM__Step_Template__c =  temp.HexaBPM__Step_Template__c,
                                                                      HexaBPM__Summary__c =temp.HexaBPM__Step_Template__r.Name,
                                                                      HexaBPM__Sys_Step_Loop_No__c = temp.HexaBPM__Step_No__c +'_1' );
                    digitalPendingSteps.add(tempRec);  
                }
                if(stepMap.containsKey('Verification of Buyer Profile')){
                    HexaBPM__SR_Steps__c temp = stepMap.get('Verification of Buyer Profile');
                    HexaBPM__Step__c tempRec = new   HexaBPM__Step__c( ExecuteCustomCode__c =
                                                                      temp.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                                      HexaBPM__SR_Step__c = temp.Id,
                                                                      OwnerId = temp.OwnerId,
                                                                      HexaBPM__SR__c = sr.Id,
                                                                      HexaBPM__Start_Date__c = System.today(),
                                                                      HexaBPM__Step_No__c = temp.HexaBPM__Step_No__c,
                                                                      HexaBPM__Status__c = buyerKyc ? completedSts : pendingStatus,
                                                                      HexaBPM__Step_Template__c =  temp.HexaBPM__Step_Template__c,
                                                                      HexaBPM__Summary__c =temp.HexaBPM__Step_Template__r.Name,
                                                                      HexaBPM__Sys_Step_Loop_No__c = temp.HexaBPM__Step_No__c +'_1' );
                    stepsToInsert.add(tempRec);  
                }
                if(stepMap.containsKey('Verification of Seller Profile')){
                    HexaBPM__SR_Steps__c temp = stepMap.get('Verification of Seller Profile');
                    HexaBPM__Step__c tempRec = new   HexaBPM__Step__c( ExecuteCustomCode__c =
                                                                      temp.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                                      HexaBPM__SR_Step__c = temp.Id,
                                                                      OwnerId = temp.OwnerId,
                                                                      HexaBPM__SR__c = sr.Id,
                                                                      HexaBPM__Start_Date__c = System.today(),
                                                                      HexaBPM__Step_No__c = temp.HexaBPM__Step_No__c,
                                                                      HexaBPM__Status__c = sellerKyc ? completedSts : pendingStatus,
                                                                      HexaBPM__Step_Template__c =  temp.HexaBPM__Step_Template__c,
                                                                      HexaBPM__Summary__c =temp.HexaBPM__Step_Template__r.Name,
                                                                      HexaBPM__Sys_Step_Loop_No__c = temp.HexaBPM__Step_No__c +'_1' );
                    stepsToInsert.add(tempRec);  
                }
                if(buyerKyc){
                    if(stepMap.containsKey('Compliance Check for Buyers')){
                        HexaBPM__SR_Steps__c temp = stepMap.get('Compliance Check for Buyers');
                        HexaBPM__Step__c tempRec = new   HexaBPM__Step__c( ExecuteCustomCode__c =
                                                                          temp.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                                          HexaBPM__SR_Step__c = temp.Id,
                                                                          OwnerId = temp.OwnerId,
                                                                          HexaBPM__SR__c = sr.Id,
                                                                          HexaBPM__Start_Date__c = System.today(),
                                                                          HexaBPM__Step_No__c = temp.HexaBPM__Step_No__c,
                                                                          HexaBPM__Status__c = pendingStatus,
                                                                          HexaBPM__Step_Template__c =  temp.HexaBPM__Step_Template__c,
                                                                          HexaBPM__Summary__c =temp.HexaBPM__Step_Template__r.Name,
                                                                          HexaBPM__Sys_Step_Loop_No__c = temp.HexaBPM__Step_No__c +'_1' );
                        stepsToInsert.add(tempRec);  
                    }
                }
                
                if (!sellerKyc && !fastTrackCPAccountIds.contains(sr.HexaBPM__Customer__c)) {
                    fastrackToInsert.add(new Communication_Preference__c(Account__c = sr.HexaBPM__Customer__c,Category__c = 'FastTrack',Status__c = 'Link Sent',Active__c = True));
                }
                
                if (!buyerKyc && !fastTrackCPAccountIds.contains(sr.BuyerName__c)) {
                    fastrackToInsert.add(new Communication_Preference__c(Account__c = sr.BuyerName__c,Category__c = 'FastTrack',Status__c = 'Link Sent',Active__c = True));
                }
            }
        }
        if(!digitalPendingSteps.isEmpty()){
            insert digitalPendingSteps;
            digitalPendingSteps[0].HexaBPM__Status__c = completedSts;
			update digitalPendingSteps[0];
        }
        
        if(!stepsToInsert.isEmpty()){
            insert stepsToInsert;
        }
        if(!fastrackToInsert.isEmpty()){
            insert fastrackToInsert;
        }
    }
    
    // SSR 751 OffPlan
    public static void checkBeforeUpdatePTOfflineValidation(List<HexaBPM__Service_Request__c> newSRList){        
        for(HexaBPM__Service_Request__c sR : newSRList){
            if(sR.TransferSellingPrice__c ==null || sR.TransferSellingPrice__c == 0){
               sR.addError('Please Enter Transfer Selling Price'); 
            }
            
        }
        
    }
        
    //Start by Daksh Sharma
    public static void updatePTOffPlanVerificationSteps(Set<Id> recordIds){
        Id completedSts  = ServiceRequestTriggerHelper.getStepStatus().get(Constants.COMPLETED_STATUS)?.Id;
        Id pendingStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
        List<HexaBPM__Service_Request__c> ptOffPlanSr = [ SELECT Id, HexaBPM__Customer__c, BuyerName__c,HexaBPM__External_SR_Status__r.Name 
                                                         FROM HexaBPM__Service_Request__c
                                                         WHERE SRType__c = :Constants.PROPERTY_TRANSFER_OffPlan 
                                                         AND HexaBPM__External_SR_Status__r.Name NOT IN ('Cancelled','Draft','Closed')
                                                         AND Origin__c IN ('Customer Portal','Customer App') 
                                                         AND (HexaBPM__Customer__c IN :recordIds OR BuyerName__c IN :recordIds)
                                                        ];
        
        Map<String, Set<Id>> stepNameToSrIds = new Map<String, Set<Id>>();
        stepNameToSrIds.put('Verification of Seller Profile', new Set<Id>());
        stepNameToSrIds.put('Verification of Buyer Profile', new Set<Id>());
        
        Set<Id> allSrIdsToUpdate = new Set<Id>();
        for (HexaBPM__Service_Request__c sr : ptOffPlanSr) {
            if (recordIds.contains(sr.HexaBPM__Customer__c)) {
                stepNameToSrIds.get('Verification of Seller Profile').add(sr.Id);
            }
            if (recordIds.contains(sr.BuyerName__c)) {
                stepNameToSrIds.get('Verification of Buyer Profile').add(sr.Id);
            }
            allSrIdsToUpdate.add(sr.Id);
        }
        
        if (!allSrIdsToUpdate.isEmpty()) {
            
            List<HexaBPM__Step__c> pendingSteps = [
                SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c, 
                HexaBPM__SR_Step__r.HexaBPM__Step_Template__r.Name
                FROM HexaBPM__Step__c 
                WHERE HexaBPM__SR__c IN :allSrIdsToUpdate 
                AND HexaBPM__Status__c = :pendingStatus 
                AND HexaBPM__SR_Step__r.HexaBPM__Step_Template__r.Name
                IN ('Verification of Seller Profile', 'Verification of Buyer Profile')
            ];
            
            List<HexaBPM__Step__c> stepsToUpdate = new List<HexaBPM__Step__c>();
            
            for (HexaBPM__Step__c step : pendingSteps) {
                String templateName = step.HexaBPM__SR_Step__r.HexaBPM__Step_Template__r.Name;
                if (stepNameToSrIds.get(templateName).contains(step.HexaBPM__SR__c)) {
                    step.HexaBPM__Status__c = completedSts;
                    stepsToUpdate.add(step);
                }
            }
            
            if (!stepsToUpdate.isEmpty()) {
                try{
                    update stepsToUpdate;
                }catch(Exception e){
                    System.debug('Error occurred while updating records: ' + e.getMessage());
                }
            }
        }
    }
    //Start by Daksh Sharma
}