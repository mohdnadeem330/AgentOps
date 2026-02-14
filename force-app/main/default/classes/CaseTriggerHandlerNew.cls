/*
*********************************************************
Apex Class Name    : CaseTriggerHandlerNew
Created Date       : 
@description       : Class to handle case Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class CaseTriggerHandlerNew extends TriggerHandler{
    // Global variable declaration start
    public static Boolean isSkipCaseTrigger = false;
    public static Set<SObject> newInsertSet = new Set<SObject>();
    public static Map<Id, SObject> updateMap = new Map<Id, SObject>();
    // Global variable declaration End    
    /*
    *********************************************************
    @Method Name    : beforeInsertMethod
    @author         : 
    @description    : Method to handle before Insert logic for case
    @param          : newList, newMap
    @return         : void
    ********************************************************
    */
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        //Local Variable declaration - Start
        List<Case> newCaseRecords = (List<Case>)newList;
        Map<Id, Case> newCaseMap = (Map<Id, Case>)newMap;
        //Local Variable declaration - End

        /*** Method to Update Salesorder and Account on Case ***/
        CaseTriggerHelper.updateSalesOrderAndCustomer(newCaseRecords, null);
        
        /*** Method to validate case on before Insert ***/
        CaseTriggerValidation.beforeInsertCaseValidation(newCaseRecords);

        /*** Update Salesorder and Account on Case ***/
        CaseTriggerValidation.checkAndupdateProductForOnDeamnd(newCaseRecords);        

        /*** Method for ResaleCase ***/
        ResaleServiceNew.beforeActionsOnResaleCase(newCaseRecords, null);

        /*** Update Salesorder and Account on Case ***/
        DevControlValidation.DevcontrolUnitValidation(newCaseRecords);

        /*** Method for Account Share ***/
        DevControlValidation.AccountShare(newCaseRecords);     
        
        /*** Logic common for all RecordTypes ***/
        CaseTriggerService.beforeInsertCaseFieldMapping(newCaseRecords);

        /*** Logic for Queries, Complaints and Requests RT's ***/
        CustomerServiceCaseTriggerHelper.beforeInsertCustomerService(newCaseRecords);

        /*** Logic for ECSSQueries, ECSSComplaints and ECSSRequests RT's ***/
        ECSS_CaseTriggerHelper.beforeInsertECSSRT(newCaseRecords);

        /*** Logic for Standard RT ***/
        StandardCaseTriggerHelper.beforeInsertStandardRT(newCaseRecords);

        /*** Logic to populate Lead, AccountId, ContactId, Opportunity, Salesorder__c, ServiceRequest__c, Unit__c 
         * for other than Queries,Complaints and Request Case RT ***/
        NonCustomerSupportAndECSSCaseHelper.beforeInsertCaseRelatedLookupFieldMapping(newCaseRecords);

        /*** Logic for other than Queries,Complaints and Request && ECCS Queries, ECCS Complaints and ECCS Request RT***/
        NonCustomerSupportAndECSSCaseHelper.beforeInsertSkipCustomerSupportECSSCaseType(newCaseRecords);

        /*** Logic for Corporate Legal RT ***/
        CorporateLegalCaseTriggerHelper.beforeInsertCorporateLegalRT(newCaseRecords);

        /*** Logic for other than Queries,Complaints and Request ***/
        NonCustomerSupportAndECSSCaseHelper.beforeInsertSkipCustomerSupportCaseType(newCaseRecords); 

        /*** Logic to update contact ***/
        CaseTriggerHelper.populateCustomerAndContactDetail(newCaseRecords,null);

        /*** Commit DML ***/
        commitCaseDML();

    }
    /*
    *********************************************************
    @Method Name    : beforeUpdateMethod
    @author         : 
    @description    : Method to handle before update logic for case
    @param          : newList, newMap, oldList, oldMap
    @return         : void
    ********************************************************
    */
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //Local Variable Declaration - Start       
        List<Case> newCaseRecords = (List<Case>)newList;
        Map<Id, Case> newCaseMap = new Map<Id, Case>(); 
        List<Case> oldCaseRecords = (List<Case>)oldList;
        Map<Id, Case> oldCaseMap = new Map<Id, Case>();
        for (SObject sobj : oldList) {
            Case c = (Case)sobj;
            oldCaseMap.put(c.Id, c);
        }
        //Local Variable Declaration - Start 

        /*** Logic for  before case validation ***/
        CaseTriggerValidation.beforeUpdateCaseValidation(newCaseRecords, oldCaseMap);

        /*** Method to Update Salesorder and Account on Case ***/
        CaseTriggerHelper.updateSalesOrderAndCustomer(newCaseRecords, oldCaseMap);

        /*** Logic to Update Salesorder and Account on Case ***/
        ResaleServiceNew.beforeActionsOnResaleCase(newCaseRecords, oldCaseMap);

        /*** Logic for DM case type ***/
        DMcaseMilestonehandlerNew.milestone(newCaseRecords,oldCaseMap);

        /*** Logic to update the Survey_Point__c***/
        CaseTriggerService.updateSurveyPoint(newCaseRecords,oldCaseMap);

        /*** Logic for Queries,Complaints and Request ***/
        CustomerServiceCaseTriggerHelper.beforeUpdateCustomerService(newCaseRecords,oldCaseMap);

        /*** Logic for case status change ***/
        CaseTriggerStatusHelper.beforeUpdateCaseStatusProcess(newCaseRecords,oldCaseMap);

        /*** Logic for ECSSQueries, ECSSComplaints and ECSSRequests RT's ***/
        ECSS_CaseTriggerHelper.beforeUpdateECSSCase(newCaseRecords,oldCaseMap);

        /*** Logic for other than Queries,Complaints and Request && ECCS Queries, ECCS Complaints and ECCS Request RT ***/
        NonCustomerSupportAndECSSCaseHelper.beforeUpdateSkipCustomerSupportECSSCaseType(newCaseRecords,oldCaseMap);

        /*** Logic to populate EntitlementId and populateSubVerticalDependentInfo***/
        CaseTriggerService.beforeUpdateEntitlementAndOwnerIdMapping(newCaseRecords,oldCaseMap);

        /*** Logic to update contact and customer Detail ***/
        CaseTriggerHelper.populateCustomerAndContactDetail(newCaseRecords,oldCaseMap);

        /*** Commit DML ***/
        commitCaseDML();
         
    }
    /*
    *********************************************************
    @Method Name    : afterInsertMethod
    @author         : 
    @description    : Method to handle after Insert logic for case
    @param          : newList, newMap
    @return         : void
    ********************************************************
    */
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //Local Variable declaration - Start
        List<Case> newCaseRecords = (List<Case>)newList;
        //Local Variable declaration - End

        /*** Logic for ECSSQueries, ECSSComplaints and ECSSRequests RT's ***/
        ECSS_CaseTriggerHelper.afterInsertECSSRT(newCaseRecords); 
        
        /*** Logic to create a share record ***/
        ResaleServiceNew.getInfoFromResaleCases_Insert(newCaseRecords);

        /*** Logic for CAFM Case ***/
        CaseTriggerService.callCAFMCase(newCaseRecords);

        /*** Logic for AMC RT's ***/
        AMCCaseTriggerHelper.afterInsertAMCCaseRT(newCaseRecords);

        /*** Logic for Homefinance RT's ***/
        HomeFinanceCaseTriggerHelper.afterInsertHomeFinanceCase(newCaseRecords); //Flow needs to be updated

        /*** Commit DML ***/
        commitCaseDML();
          
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateMethod
    @author         : 
    @description    : Method to handle after update logic for case
    @param          : newList, newMap, oldList, oldMap
    @return         : void
    ********************************************************
    */
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        //Local Variable declaration - Start
        List<Case> newCaseRecords = (List<Case>)newList;
        Map<Id, Case> newCaseMap = new Map<Id, Case>(); 
        List<Case> oldCaseRecords = (List<Case>)oldList;
        Map<Id, Case> oldCaseMap = new Map<Id, Case>();
        for (SObject sobj : oldMap.values()) {
            Case c = (Case)sobj;
            oldCaseMap.put(c.Id, c);
        }               
        //Local Variable declaration - End

        /*** Logic to validate the task ***/
        CaseTriggerValidation.afterUpdateCaseValidation(newCaseRecords,oldCaseMap);

        /*** Logic to create a Task on Owner Change***/
        CaseTriggerService.afterUpdateTaskCreationForCase(newCaseRecords,oldCaseMap);

        /*** Logic to create a Case Document ***/
        CaseTriggerHelper.afterUpdateCreateCaseDocument(newCaseRecords,oldCaseMap);

        /*** Logic to send Service Report Email ***/
        CaseTriggerService.afterUpdateSendServiceReport(newCaseRecords,oldCaseMap);

        /*** Logic for case status related functions, updateing account by case detail ***/
        CaseTriggerStatusHelper.afterUpdateCaseStatusProcess(newCaseRecords,oldCaseMap);

        /*** Logic for Resale Case Type ***/
        ResaleServiceNew.getInfoFromResaleCases_Update(newCaseRecords,oldCaseMap);
        
        /*** Logic for ECSSQueries, ECSSComplaints and ECSSRequests RT's ***/
        ECSS_CaseTriggerHelper.afterUpdateECSSRT(newCaseRecords,oldCaseMap); 

        /*** Logic for AMC Case Type ***/
        AMCCaseTriggerHelper.afterUpdateAMCCase(newCaseRecords,oldCaseMap);

        /*** Logic for Home finance Case Type ***/
        HomeFinanceCaseTriggerHelper.afterUpdateHomeFinanceCase(newCaseRecords,oldCaseMap);

        /*** Commit DML ***/
        commitCaseDML();
    }

    public static void commitCaseDML() {
        if (!newInsertSet.isEmpty()) {insert new List<Sobject>(newInsertSet);newInsertSet.clear();}
        if (!updateMap.isEmpty()) {update updateMap.values();updateMap.clear();}
    }
}