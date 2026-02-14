@istest
public class AldarUtilityClassTest {
    
    @testSetup
    public static void createData(){
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;       
    }
    
    static testmethod void aldarUtilityTest(){
        AldarUtilityClass.fetchQueueMap(new Set<String>{'Group Legal Queue'},new Set<String>{'Group_Legal_Queue'});
        AldarUtilityClass.getRecordTypeIdByParam('Case','Name');
        AldarUtilityClass.fetchSRTemplate(new Set<String>{'Payment Extension'});
        AldarUtilityClass.fetchStepStatus();
        AldarUtilityClass.fetchSRStatus();   
        AldarUtilityClass.getSystemMessages(new Set<String>{Constants.DUPLICATE_SR_MESSAGE});
        List<SalesOrder__c> salesOrder = [Select id from SalesOrder__c];
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder[0].Id, 1);
        AldarUtilityClass.fetchSalesOrder(new Set<Id>{salesOrder[0].Id});
        AldarUtilityClass.fetchInstallmentLines(new Set<Id>{installmentLines1[0].Id});
        List<Unit__c> unit = [Select id, Name, Status__c from Unit__c where Status__c = 'Sold'];
        Id queriesRT =Schema.SObjectType.case.getRecordTypeInfosByName().get('Queries').getRecordTypeId();        
        Case queCase = TestObjectsFactory.getCaseRecord(queriesRT, 'Question', unit[0].Id, 'Walk-In');
        queCase.Subject='Test Subject';
        queCase.Status = 'New';
        queCase.SubCategory__c = 'Requests for extra GFA';
        insert queCase;
        AldarUtilityClass.fetchChargeRule(new Set<String>{'Test'});        
        Id dlpRecTpId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        AldarUtilityClass.fetchCaseByUnitsonInsert(new Set<Id>{unit[0].Id},new Set<String>{'New'},dlpRecTpId);
        AldarUtilityClass.fetchCaseByUnitsonUpdate(new List<Id>{queCase.Id},new List<Id>{unit[0].Id},null,new Set<String>{'New'},dlpRecTpId);
    }
}