@isTest
public class NagwaWebServiceTest {

     @isTest
    public static void doPostTest() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonMobilePhone = '527583669';
        acc.PersonEmail = 'abc@abc.com';
        insert acc;
        Account con1 = [Select PersonContactId from account where id=:acc.id];
        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('Aldar','G123456');
        insert orgAccount;
        
        List<Account> orgAccountList = [Select Id, AccountNumber__c,NAGWA_Pin__c from Account Where Id =:orgAccount.Id];
        
        Account orgAccount2 = TestObjectsFactory.getOrganisationAccountRecord('Aldar','G123456');
        orgAccount2.NAGWA_Pin__c = '1234';
        insert orgAccount2;
        
        List<Account> orgAccount2List = [Select Id, AccountNumber__c,NAGWA_Pin__c from Account Where Id =:orgAccount2.Id];
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Contact con=  TestObjectsFactory.contactDataSetup(orgAccount.Id);
      
        
        Case cs = TestObjectsFactory.getCase(acc.Id, con1.PersonContactId, 'Compliance') ;
        insert cs;
        System.debug('case:  '+[Select Id, ContactEmail,ContactMobile, AccountId from case Where Id =: cs.id]);
        case cas = [Select Id, ContactEmail,ContactMobile, AccountId from case Where Id =: cs.id];
        
        Contact newcon = new Contact();
        newcon.Lastname='Alice';
        newcon.AccountId=orgAccount.Id;
        newcon.Email = 'test134@aldar.com';
        
        insert newcon;
        Case cs2 = TestObjectsFactory.getCase(orgAccount.Id, newcon.Id, 'Compliance');
        Test.startTest();
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('BrokerCase').getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.AccountId = acc.id;
        newCase.ContactId = newcon.Id;
        newCase.Category__c = 'Compliance';
        insert newCase;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit.Id;
        insert salesOrder2;
        
        
        TestObjectsFactory.initializeRestContext(null, '/update/NagwaUpdatePin');
        NagwaWebService.doPost(acc.PersonMobilePhone);
        NagwaWebService.doPost(null);
        GetCasesWebService.doPost(cas.ContactMobile,cas.ContactEmail );
        GetCasesWebService.doPost(null,cs2.ContactEmail );
        GetContactWebService.doPost(newCase.ContactMobile);
        NagwaGetPinWebService.doPost(orgAccountList[0].AccountNumber__c);
        NagwaGetPinWebService.doPost('');
        NagwaUpdatePinWebService.doPost(orgAccountList[0].AccountNumber__c, String.valueOf(orgAccountList[0].NAGWA_Pin__c));
        NagwaUpdatePinWebService.doPost('', '');
        NagwaUpdatePinWebService.doPost(orgAccount2List[0].AccountNumber__c, String.valueOf(orgAccount2List[0].NAGWA_Pin__c));
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        Test.stopTest();
    }
}