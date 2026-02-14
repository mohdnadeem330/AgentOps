@isTest
public class SendAlertsForInvoiceBundlesTest {
    @TestSetup
    static void makeData(){
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
		con.FirstName = 'Test';
        con.LastName = 'User';
        con.BrokerType__c = 'Agency Admin';
        update con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE_LOGIN, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'test@gmail.com';
        agencyAdmin.isActive = true;
        insert agencyAdmin;

        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = accountRecord.Id;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Ready for Submission';
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        invoiceBundle.InitiatedDate__c = System.today().addDays(-2);
        invoiceBundle.InvoiceDate__c = System.today().addDays(-2);
        update invoiceBundle;
        
    }
    @IsTest
    static void testSendAlertsForInvoiceBundles(){
        Test.startTest();
        String jobID = System.schedule('SendAlertsForInvoiceBundles', '0 0 * * * ?', new SendAlertsForInvoiceBundles());
        Test.stopTest();
    }
}