/*
*Created By     : Hardik Vitthani
*Description    : Test class for EmailInboundController
*/
@isTest
public with sharing class EmailInboundControllerTest {
    @isTest
    public static void testEmailInboundController() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        
        email.fromAddress = 'test@aldar.coam.invalid';
        email.toAddresses = new List<String>{'test@aldar.coam.invalid'};
        email.subject = 'Confirmed Address';
        email.htmlBody = '<p>Confirmed</p><p>rId:' + salesOrder.Id + ':rId</p><p>Street:Test:Street</p><p>City:Test:City</p><p>State:Test:State</p><p>Postal Code:Test:Postal Code</p><p>Country:Test:Country</p>';
        email.plainTextBody = 'Confirmed';
        
        try {
            EmailInboundController testInbound = new EmailInboundController();
            testInbound.handleInboundEmail(email, new Messaging.InboundEnvelope());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}