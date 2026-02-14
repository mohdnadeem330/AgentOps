/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for CommissionService
*/
@isTest
private class CommissionServiceTest {

    static Opportunity opportunityRecord ;
    static List<Unit__c> unitRecords ;
    static Map<Id,OffersPromotions__c> unitToOfferMap = new Map<Id,OffersPromotions__c>();
    static InternalCommission__c internalCommission ;
    static BrokerCommission__c brokerCommission ;

    static void init(){

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        opportunityRecord = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opportunityRecord;

        Unit__c unitRec = TestObjectsFactory.unitDataSetup('1234');
        insert unitRec ;

        unitRecords = UnitService.getAllUnitsById(new Set<Id>{unitRec.Id});
        OffersPromotions__c offerRec = TestObjectsFactory.getOfferPromotion(null,unitRec.Project__c);
        insert offerRec ;
        unitToOfferMap.put(unitRec.Id,offerRec);

        internalCommission = TestObjectsFactory.getInternalCommission();
        internalCommission.ResidentStatus__c = 'All';
        insert internalCommission;

        brokerCommission = TestObjectsFactory.getBrokerCommission(unitRec.Project__c);
        brokerCommission.BuildingSection__c = unitRec.BuildingSectionName__c ;
        insert brokerCommission;

        InternalCommission__c internalCommissionProject = TestObjectsFactory.getInternalCommission();
        internalCommissionProject.Project__c = unitRec.Project__c;
        internalCommissionProject.ResidentStatus__c = 'All';
        insert internalCommissionProject;
    }
    /*
    * Scenario 1 : Check Internal Commission
    */
    private static testMethod void testInternalCommissions() {
        Test.startTest();
        init();
        Map<Id,InternalCommission__c> unitCommissionMap =  CommissionService.getInternalCommissions(opportunityRecord,unitRecords,unitToOfferMap);
        Test.stopTest();
    }

    /*
    * Scenario 2 : Check External Commission
    */
    private static testMethod void testExternalCommissions() {
        Test.startTest();
        init();
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityRecord,unitRecords,unitToOfferMap); 
        Test.stopTest();
    }

    /*
    * Scenario 3 : Check External Commission for Project
    */
    private static testMethod void testProjectExternalCommissions() {
        Test.startTest();
        init();
        brokerCommission.BuildingSection__c = null;
        update brokerCommission;
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityRecord,unitRecords,unitToOfferMap); 
        Test.stopTest();
    }

    /*
    * Scenario 4 : Check External Commission for Sale Type
    */
    private static testMethod void testSaleTypeExternalCommissions() {
        Test.startTest();
        init();
        opportunityRecord.SaleType__c = 'CPC';
        update opportunityRecord;
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityRecord,unitRecords,unitToOfferMap); 
        Test.stopTest();
    }

    /*
    * Scenario 5 : Check External Commission for Unit View
    */
    private static testMethod void testUnitViewExternalCommissions() {
        Test.startTest();
        init();
        Unit__c unitRec = unitRecords[0];
        unitRec.UnitView__c = 'Beach View';
        update unitRec;
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityRecord,unitRecords,unitToOfferMap); 
        Test.stopTest();
    }

    /*
    * Scenario 6 : Check Internal Commission for Unit View
    */
    private static testMethod void testInternalCommissionsForUnit() {
        Test.startTest();
        init();
        Map<Id,InternalCommission__c> unitCommissionMap =  CommissionService.getInternalCommissionsForUnit(unitRecords);
        Test.stopTest();
    }

    /*
    * Scenario 7 : Check External Commission for Unit View
    */
    private static testMethod void testGetExternalCommissions() {
        Test.startTest();
        init();
        Map<Id,Decimal> unitCommissionMap =  CommissionService.getExternalCommissions(opportunityRecord,unitRecords,unitToOfferMap);
        Test.stopTest();
    }
}