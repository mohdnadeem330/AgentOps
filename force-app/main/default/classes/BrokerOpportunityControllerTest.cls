@isTest
private class BrokerOpportunityControllerTest {
    
    @isTest(SeeAllData=false)
    static void callMethods() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(1011, 'United Arab Emirates', 'V1', 'P1');
        insert acc;
        
        Account accBrokerAgency = TestObjectsFactory.getAgencyAccountRecord('SampleAgencyName', 'ABCD');
        insert accBrokerAgency;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgencyAccount__c = accBrokerAgency.Id;
        insert opp;

        Unit__c unitRec = TestObjectsFactory.unitDataSetup('Mamsha');
        unitRec.Name = 'Mamsha-B5-01-10' ;
        insert unitRec;

        SalesOrder__c orderDRec = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        orderDRec.Unit__c = unitRec.Id ;
        insert orderDRec ;
        
        List<Opportunity> opportunitiesList = BrokerOpportunityController.getOpportunities(accBrokerAgency.Id);
        BrokerOpportunityController.getOpportunityById(opportunitiesList[0].Id);
        BrokerOpportunityController.getSalesOrderByOpportunity(opportunitiesList[0].Id);
        BrokerOpportunityController.maskString('SampleString', 1 , 2, 'String');
    }
}