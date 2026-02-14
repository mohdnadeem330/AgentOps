/*
*Created By     : Hardik Vitthani
*Description    : Test class for BrokerRequestService
*/
@isTest
public class BrokerRequestServiceTest {
    @isTest
    public static void testBrokerRequestService() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        try {
            BrokerRequestService.queryAllFieldsWithExtraFields(new List<Id>{brokerRequest.Id});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        } 
    }
}