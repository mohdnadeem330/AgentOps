@isTest
public class MarketingReimbursementCalloutHelperTest {
    /*
    * Purpose : To Test Covrage of Marketing Reimbursement Callout
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testMarketingReimbursementCallout() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPID__c = '12345';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        TestObjectsFactory.createContentDocumentLink(brokerRequest.Id);
        TestObjectsFactory.createContentDocumentLink(brokerRequest.Id);

        try {
            List<Id> newIds = new List<Id>();
            newIds.add(brokerRequest.Id);
            MarketingReimbursementCalloutHelper.PrepareDataForCallout(newIds);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}