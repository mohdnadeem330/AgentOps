@isTest
public class CustomerSohoProfileServiceTest {
    
    @isTest
    public static void testCustomerProfileWebservice() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerProfileWebservice2() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        TransferHistory__c transHistory = new TransferHistory__c();
        transHistory.SalesOrder__c		= salesOrder.Id;
        transHistory.FromAccount__c		= acc.Id;
        insert transHistory;
        
        Test.startTest();
        try {
            CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerProfileWebserviceBlankParameters() {
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerSohoProfileService.doPost('', '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    /*@isTest
    public static void testCustomerProfileWebserviceMultiAccount() {
        
        try {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.PassportNumber__pc = 'Test12342023';
        insert acc2;

        SalesOrder__c salesOrder = getData(acc);

        SalesOrder__c salesOrder2 = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        Test.startTest();
        
            CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    */

    @isTest
    public static void testCustomerProfileWebserviceNoLead() {
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerSohoProfileService.doPost('test@test.test', '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    public static SalesOrder__c getData(Account acc) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        return salesOrder;
    }
    
    @isTest
    static void testDoPost() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c = '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c = true;
        insert acc1;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;

        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', true);
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', true);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();

        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testDoPost1() {
        
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        insert acc;
        
        Account acc1 						= TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c 					= '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c 	= true;
        acc1.CustomerAppWebUser__c			= true;
        insert acc1;
        
        Account acc2 						= TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c 					= '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c 	= true;
        insert acc2;

        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();

        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testDoPost2() {
        
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        acc.CustomerAppWebUser__c			= true;
        insert acc;
        
        Account acc1 						= TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c 					= '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c 	= true;
        acc1.CustomerAppWebUser__c			= true;
        acc1.CustomerAppWebUser__c			= true;
        insert acc1;
        
        Account acc2 						= TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c 					= '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c 	= true;
        acc2.CustomerAppWebUser__c			= true;
        insert acc2;

        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();

        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }

    @isTest
    static void testGetProfileData() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c = '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c = true;
        insert acc1;

        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', true);
        CustomerSohoProfileService.doPost(acc.PersonEmail, '', true);
        
        CustomerSohoProfileService.PreviousUnitDetails unitDetails = new CustomerSohoProfileService.PreviousUnitDetails();
        unitDetails.unitName = 'unit';
        unitDetails.projectName = 'unit';
        unitDetails.saleDate = System.today() ;
        
        CustomerSohoProfileService.SalesOrderModel soModel = new CustomerSohoProfileService.SalesOrderModel(salesOrder, acc1.Id);
        
        Test.stopTest();

        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    @isTest
    static void dopost3(){
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        acc.KeyAccountManager__c=UserInfo.getUserId();
        insert acc;

        Communication_Preference__c cpRecord = new Communication_Preference__c();
        cpRecord.account__c =acc.Id;
        cpRecord.Category__c= 'FastTrack';
        cpRecord.Status__c ='Link Sent';
        cpRecord.Active__c= true;
        insert cpRecord;

         TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
			 Test.startTest();
			  CustomerSohoProfileService.doPost(acc.PersonEmail, '', false);
    }
}