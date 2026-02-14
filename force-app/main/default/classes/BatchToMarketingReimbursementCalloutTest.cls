@isTest
public class BatchToMarketingReimbursementCalloutTest {
    /*
    * Purpose : To Test Covrage of Marketing Reimbursement Callout Batch
    * Created by : Hardik Vitthani
    */
    @isTest
    public static void testBatchToMarketingReimbursement() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.AgencyCategory__c = 'Broker';
        acc.ERPId__c = '12345';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursementCallout(), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct: [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Marketing Reimbursement Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('Test Marketing Reimbursement Batch', '0 0 23 * * ?', new BatchToMarketingReimbursementCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testBatchToMarketingReimbursementQ1() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter1MarketingBudgetIntl__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 2;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q1', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testBatchToMarketingReimbursementQ2() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter2MarketingBudgetIntl__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 5;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q2', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testBatchToMarketingReimbursementQ3() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter3MarketingBudgetIntl__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 8;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q3', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testBatchToMarketingReimbursementQ4() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter4MarketingBudgetIntl__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 12;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q4', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testDomesticBatchToMarketingReimbursementQ1() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.BillingStreet = 'AD';
        acc.BillingCity = 'Abu Dhabi';
        acc.BillingState = 'Abu Dhabi';
        acc.BillingCountry = 'United Arab Emirates';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter1MarketingBudget__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 1;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q1', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testDomesticBatchToMarketingReimbursementQ2() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.BillingStreet = 'AD';
        acc.BillingCity = 'Abu Dhabi';
        acc.BillingState = 'Abu Dhabi';
        acc.BillingCountry = 'United Arab Emirates';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter2MarketingBudget__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 4;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q2', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    @isTest
    public static void testDomesticBatchToMarketingReimbursementQ3() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.BillingStreet = 'AD';
        acc.BillingCity = 'Abu Dhabi';
        acc.BillingState = 'Abu Dhabi';
        acc.BillingCountry = 'United Arab Emirates';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter3MarketingBudget__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 7;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q3', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    @isTest
    public static void testDomesticBatchToMarketingReimbursementQ4() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        acc.BillingStreet = 'AD';
        acc.BillingCity = 'Abu Dhabi';
        acc.BillingState = 'Abu Dhabi';
        acc.BillingCountry = 'United Arab Emirates';
        acc.AgencyCategory__c = 'Broker';
        insert acc;
        
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Envoy',AnnualSalesTargetFrom__c=0,
                                                                  AnnualSalesTargetTo__c=150000000,
                                                                  AnnualSalesTargetFromInternational__c=0,
                                                                  AnnualSalesTargetToInternational__c=150000000,
                                                                  Quarter4MarketingBudget__c = 15000,
                                                                  Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        Broker_Classification_Details__c bcd = new Broker_Classification_Details__c();
        bcd.AgencyName__c = acc.Id;
        bcd.Classification__c = bc1.id;
        bcd.Year__c = '2024';
        bcd.Month__c = 12;
        bcd.Total_number_of_Sales_in_month__c = 150000000;
        insert bcd;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        brokerRequest.ERPID__c = '';
        update brokerRequest;

        try {
            database.executeBatch(new BatchToMarketingReimbursement('Q4', '2024'), 1);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}