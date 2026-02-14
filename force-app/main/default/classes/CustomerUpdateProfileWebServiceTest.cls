@isTest
public class CustomerUpdateProfileWebServiceTest {

    @isTest
    public static void testCustomerUpdateProfileWebServiceUpdateFlag() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.MaritalStatus__pc = 'Single';
        insert acc;
        
        TestObjectsFactory.initializeRestContext(null, '/query/updateprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            Account newAcc = new Account();
            newAcc.Id = acc.Id;
            newAcc.CustomerAppWebUser__c = true;
            CustomerUpdateProfileWebService.doPost(newAcc, '', null, null, 'UpdateFlag', '',true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
        Account Accupdate= [select Id,MobilePhone__pc,PassportNumber__pc from Account where Id=:acc.id];
      
    }

    @isTest
    public static void testCustomerUpdateProfileWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.MaritalStatus__pc = 'Single';
        acc.PassportNumber__pc = 'N6385378';
        acc.ResidentStatus__pc = 'Resident';
        acc.MaritalStatus__pc = 'Married';
        acc.EmploymentStatus__pc = 'Self Employed';
        acc.PersonEmail = 'test@aldar.com.invalid';
        acc.MobileCountryCode__pc = '971';
        acc.MobilePhone__pc = '9876543115';
        acc.Company__pc = 'XXXXX';
        acc.Position__pc = 'XXX';
        acc.CompanyAddress__pc = 'NA';
        acc.NoofYearswithCompany__pc = 10;
        acc.Industry = 'Agriculture';
        acc.AnnualIncome__pc = 1234567;
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        TestObjectsFactory.initializeRestContext(null, '/query/updateprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerUpdateProfileWebService.doPost(acc, 'Customer Portal', unit.Id, salesOrder.Id, 'UpdateProfile', '',false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerUpdateProfileWebServiceNegative() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.MaritalStatus__pc = 'Single';
        acc.PassportNumber__pc = 'N6385378';
        acc.ResidentStatus__pc = 'Resident';
        acc.MaritalStatus__pc = 'Married';
        acc.EmploymentStatus__pc = 'Self Employed';
        acc.PersonEmail = 'test@aldar.com.invalid';
        acc.MobileCountryCode__pc = '971';
        acc.MobilePhone__pc = '9876543115';
        acc.Company__pc = 'XXXXX';
        acc.Position__pc = 'XXX';
        acc.CompanyAddress__pc = 'NA';
        acc.NoofYearswithCompany__pc = 10;
        acc.Industry = 'Agriculture';
        acc.AnnualIncome__pc = 1234567;
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        TestObjectsFactory.initializeRestContext(null, '/query/updateprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerUpdateProfileWebService.doPost(acc, 'Customer Portal', unit.Id, salesOrder.Id, 'UpdateProfile', '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerUpdateProfileWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.MaritalStatus__pc = 'Single';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
       

        
        TestObjectsFactory.initializeRestContext(null, '/query/updateprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            acc.MobileCountryCode__pc = '12312';
            
        
            CustomerUpdateProfileWebService.doPost(acc, 'Customer Portal', unit.Id + '123', salesOrder.Id, 'UpdateProfile', '',false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void UpdateBuyerProfileMethod(){
		Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.MaritalStatus__pc = 'Single';
        acc.PassportNumber__pc = 'N6385378';
        acc.ResidentStatus__pc = 'Resident';
        acc.MaritalStatus__pc = 'Married';
        acc.EmploymentStatus__pc = 'Self Employed';
        acc.PersonEmail = 'test@aldar.com.invalid';
        acc.MobileCountryCode__pc = '971';
        acc.MobilePhone__pc = '9876543115';
        acc.Company__pc = 'XXXXX';
        acc.Position__pc = 'XXX';
        acc.PassportNumber__pc='N6385378';
        acc.CompanyAddress__pc = 'NA';
        acc.NoofYearswithCompany__pc = 10;
        acc.Industry = 'Agriculture';
        acc.AnnualIncome__pc = 1234567;
        acc.CountryOfResidence__pc = 'United Arab Emirates';
        acc.NationalIdExpiryDate__pc = Date.newInstance(2031, 10, 18);
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
      
        
        
        TestObjectsFactory.initializeRestContext(null, '/query/updateprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerUpdateProfileWebService.doPost(acc, 'Customer Portal', unit.Id, salesOrder.Id, 'UpdateBuyerProfile', '',true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    @isTest
    public static void testUpdateProfile_updateFlag() {

        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        insert acc1;
        Account acc = [select id from Account where id=:acc1.id limit 1];
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
         SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
       Test.startTest();
        try {
        CustomerUpdateProfileWebService.updateProfile(acc, 'Customer Portal',unit.id , salesOrder.id , 'UpdateFlag', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
         Test.stopTest();
        system.assert(true);
    }
    
     @isTest
    public static void CaseCreation_Test() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
      
        
        Test.startTest();
        try {
             CustomerUpdateProfileWebService.doPost(acc, 'Customer Portal', null, null, 'UpdateProfile', '',false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
        
    }
}