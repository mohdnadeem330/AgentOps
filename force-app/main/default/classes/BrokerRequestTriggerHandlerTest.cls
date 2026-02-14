/*
*Created By     : Hardik Vitthani
*Description    : Test class for BrokerRequestTriggerHandler
*/
@isTest
public class BrokerRequestTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        insert acc;

        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter1MarketingBudgetIntl__c = 15000,
                                                                  Year__c = '2025');
        Insert bc1;

        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2025';
        bcd.Month__c = 6;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;
       
        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        brokerRequest.Remark__c = 'Test';
        brokerRequest.RequestQuarter__c = 'Q2';
        brokerRequest.RequestYear__c = '2025';
        insert brokerRequest;
    }
     
    @isTest
    public static void testBrokerRequestTriggerHandler() {
        BrokerRequest__c brokerRequest = [SELECT Id,Remark__c,ApprovalStatus__c,SyncStatus__c FROM BrokerRequest__c LIMIT 1];

        Test.startTest();
        brokerRequest.Remark__c = 'Test Update';
        brokerRequest.ApprovalStatus__c = Constants.APPROVED_STATUS;
        brokerRequest.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
        update brokerRequest;
        update brokerRequest;
        Test.stopTest();
    }

    @isTest
    public static void testMarketingReimbursement() {
        BrokerRequest__c brokerRequest = [SELECT Id,InvoiceStatus__c,RequestQuarter__c,RequestYear__c FROM BrokerRequest__c LIMIT 1];
            
        Test.startTest();
        brokerRequest.InvoiceStatus__c = 'Ready for Submission';
        update brokerRequest;
        Test.stopTest();
    }
}