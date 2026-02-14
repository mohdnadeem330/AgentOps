@isTest
public class BankVirtualAccountControllerTest { 

    @TestSetup
    static void makeData(){
        Account account = TestObjectsFactory.getPersonAccountRecord(1111111, 'India','11111','P11111');
        account.MobileNumber__c = '123456789';
        account.SourceofFunds__pc = 'Employment Income';
        account.Company__pc = 'AbuDhabi investment Authority';
        account.Position__pc = 'Manager';
        account.CompanyAddress__pc = 'AbuDhabi investment 211 corniche AD';
        account.AnnualIncome__pc = 130000;
        account.NoofYearswithCompany__pc = 32;
        account.Industry = 'Government';
        account.CustomerBankName__c = 'Abhu Dhabi';
        account.CustomerBankCountry__c = 'United Arab Emirates';
        account.EmploymentStatus__pc  = 'Employed';
        insert account;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
      
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(project.id);
        insert buildingRecord;
        project.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberEscrow__c = '10503791920050';
        project.IBANNoEscrow__c = 'AE220030010503791920050';
        
        project.BankNameCorporate__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberCorporate__c = '10503791920050';
        project.IBANNoCorporate__c = 'AE120354031221018122005';
        update project;
        
        List<Unit__c> unList = new List<Unit__c>();
        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.Status__c = 'New';
        unList.add(unit);
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('Mayan');
        unit1.Project__c = project.Id;
        unit1.Name = 'MAYAN-B1-101096';
        unit1.Status__c = 'New';
      
        unList.add(unit1);
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('Mayan');
        unit2.Project__c = project.Id;
        unit2.Name = 'MAYAN-B1-101097';
        unit2.status__c = 'New';
        unList.add(unit2);
        
        insert unList;
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = project.id;
        va1.BufferFlag__c = true;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.Statusflag__c = 'Available';
        va1.EscrowAccountNumber__c = '123123121';
        va1.BankName__c = 'Abu Dhabi Commercial Bank';
        va1.VirtualAccountNumber__c = null;
        insert va1;

        BankVirtualAccounts__c va2 = TestObjectsFactory.getBankVirtualAccounts();
        va2.Project__c = project.id;
        va2.BufferFlag__c = true;
        va2.Virtual_Account_Type__c = 'Escrow';
        va2.EscrowAccountNumber__c = '1231233321';
        va2.Statusflag__c = 'Available';
        va2.BankName__c = 'First Abu Dhabi Bank';
        va2.VirtualAccountNumber__c = null;
        insert va2;
        BankVirtualAccounts__c va3 = TestObjectsFactory.getBankVirtualAccounts();
        va3.Project__c = project.id;
        va3.BufferFlag__c = true;
        va3.Virtual_Account_Type__c = 'Escrow';
        va3.EscrowAccountNumber__c = '1231233321';
        va3.Statusflag__c = 'Available';
        va3.VirtualAccountNumber__c = null;
        va3.BankName__c = 'First Abu Dhabi Bank';
        insert va3;
    }
    @isTest
    static void testCreateVirtualAccounts() {
        test.startTest();
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BankVirtualAccountController.createVirtualAccounts(project.id, 'Abu Dhabi Commercial Bank', 5, true, false);
        BankVirtualAccountController.createVirtualAccounts(project.id, 'Abu Dhabi Commercial Bank', 5, false, true);
        BankVirtualAccountController.retryVACallout(project.id, 'Abu Dhabi Commercial Bank', true, false);
        //BankVirtualAccountController.retryVACallout(project.id, 'Abu Dhabi Commercial Bank', false, true);
        BankVirtualAccountController.getVirtualAccountStatistics(project.id);
        List<BankVirtualAccounts__c> bva2= [SELECT Id, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, VirtualAccountNumber__c, EscrowAccountNumber__c, BankName__c FROM BankVirtualAccounts__c limit 1];
        String requestBody = '{"requestId":"'+bva2[0].Id+'","physicalAccountNumber":"2345678","defaultAccount":"Y","virtualAccountType":"N","splitRequired":"N","uniqueReferenceNumber":"a2S25000001ViGDEA0","remarks":""}';
        String responseBody = '{"success": "true",  "reqTimeStamp": "2020-02-21T13:55:52",  "resTimeStamp": "2020-02-21T13:55:52",  "responseId": "adf0b22-2eb4-4141-bc6c-0c56fb8cbbde",    "response": {       "requestId":"'+bva2[0].id+'",       "customerID": "1234567",        "virtualCustomerID": "12345","physicalAccountNumber": "123456789001","physicalAccountTitle": "ACDESC_123456789001","virtualAccountNumber": "12345678911111",        "defaultAccount": "Y",      "virtualAccountTitle": "Title1",        "virtualIBAN": "AE123456789111111111112",       "virtualAccountType": "N",      "splitRequired": "Y",       "virtualAccountStatus": "A",        "virtualAccountOpenDate":null ,     "virtualAccountClosureDate":null,       "uniqueReferenceNumber": "734899"   }}';
        ALDVA_ADCB_ResponseWrapper.parse(requestBody);
        BankVirtualAccountController.updateBankVirtualAccountResponse(responseBody, requestBody, 'BankIntegrationVA');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        BuildingSection__c buildingRecord = [SELECT Id FROM BuildingSection__c LIMIT 1];
        BankVirtualAccountController.createVirtualAccounts(buildingRecord.id, 'First Abu Dhabi Bank', 5, true, false);
        BankVirtualAccountController.createVirtualAccounts(buildingRecord.id, 'First Abu Dhabi Bank', 5, false, false);
        test.StopTest();
    }
    @isTest static void validatebatchForADCB() {
        List<BankVirtualAccounts__c> bva2= [SELECT Id, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, VirtualAccountNumber__c, EscrowAccountNumber__c, BankName__c FROM BankVirtualAccounts__c limit 1];
        test.startTest();
        BatchToCreateBankVirtualAccount batch = new BatchToCreateBankVirtualAccount(bva2,'Escrow', 'Abu Dhabi Commercial Bank');
        database.executeBatch(batch);
        test.stopTest();
    }
    @isTest static void validatebatchforFAB() {
        List<BankVirtualAccounts__c> bva2 = [SELECT Id, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, VirtualAccountNumber__c, EscrowAccountNumber__c, BankName__c FROM BankVirtualAccounts__c WHERE VirtualAccountNumber__c = null AND EscrowAccountNumber__c != null AND Virtual_Account_Type__c = 'Escrow' AND BankName__c = 'First Abu Dhabi Bank'];
        System.debug('bva2 :' + bva2);
        test.startTest();
        String requestBodyFab = '{"serviceName":"vaIBANCreation","serviceCode":"SVC0010","requestId":"'+bva2[0].Id+'","requestDateTime":"20231130071435","message":{"vaIBANList":[{"virtualAccountType":"B","virtualAccountNo":null,"virtualAccountName":"'+bva2[0].Id+'","vaRequestId":"a2S25000001Wk2E","vaIban":"","vaEntityId":"70000060","requestType":"N","remarks":null,"primaryID":"","parentMapping":"","hierarchyType":"P","hierarchyName":"'+bva2[0].Id+'","enrichmentField3":"","enrichmentField2":"","enrichmentField1":"","emailAddress":"smanohar@aldar.com","contactNumber":"971525783669","alias":"","addressLine3":"Abu dhabi","addressLine2":"Yas island","addressLine1":"ALdar square"}]},"langCode":"EN","customerCode":"ALDARPROPERTIES"}';
        String responseBodyFab = '{"requestId":"'+bva2[0].Id+'","responseDateTime":"20231130111537","serviceName":"vaIBANCreation","serviceCode":"SVC0010","customerCode":"ALDARPROPERTIES","serviceStatusCode":"S","serviceStatusDesc":"Successfully received the VA Registration request","totalRecords":"1","successRecords":"1","failedRecords":"0","langCode":"EN","message":{"vaIBANList":[{"vaRequestId":"a2S25000001Wk2E","statusCode":"A","statusDescription":"Request accepted for Virtual Account Registration","errorCode":"000","virtualAccountID":"00022","vaIban":"AE170355417000006000022"}]}}';
        BankVirtualAccountController.updateBankVirtualAccountResponse(responseBodyFab, requestBodyFab, 'FABBankIntegrationVA');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFab));
        BatchToCreateBankVirtualAccount batch = new BatchToCreateBankVirtualAccount(bva2,'Escrow', 'First Abu Dhabi Bank');
        database.executeBatch(batch);
        //FAB_MandateResponseWrapper.parse(requestBodyFab);
        test.stopTest();
    }
    @isTest static void validatebatchforADIB() {
        List<BankVirtualAccounts__c> bva2 = [SELECT Id, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, VirtualAccountNumber__c, EscrowAccountNumber__c, BankName__c FROM BankVirtualAccounts__c WHERE VirtualAccountNumber__c = null AND EscrowAccountNumber__c != null AND Virtual_Account_Type__c = 'Escrow' AND BankName__c = 'First Abu Dhabi Bank'];
        System.debug('bva2 :' + bva2);
        test.startTest();
        String requestBodyFab = '{"serviceName":"vaIBANCreation","serviceCode":"SVC0010","requestId":"'+bva2[0].Id+'","requestDateTime":"20231130071435","message":{"vaIBANList":[{"virtualAccountType":"B","virtualAccountNo":null,"virtualAccountName":"'+bva2[0].Id+'","vaRequestId":"a2S25000001Wk2E","vaIban":"","vaEntityId":"70000060","requestType":"N","remarks":null,"primaryID":"","parentMapping":"","hierarchyType":"P","hierarchyName":"'+bva2[0].Id+'","enrichmentField3":"","enrichmentField2":"","enrichmentField1":"","emailAddress":"smanohar@aldar.com","contactNumber":"971525783669","alias":"","addressLine3":"Abu dhabi","addressLine2":"Yas island","addressLine1":"ALdar square"}]},"langCode":"EN","customerCode":"ALDARPROPERTIES"}';
        String responseBodyFab = '{"context":{"userId":"ALDAR","interfaceId":"VADYNAMICCREATE_E_VALIDATION","groupCustomerCode":"","customerGuid":"","customerCode":"798413","channelRefNumber":"a2S25000001WpyzEAC","channelId":"API","branchCode":"","bankEntityId":"EBI","bankCode":"","entityCode":"IGTBAE","status":"SUCCESS","errorCode":"","errorMessage":"","authChannelId":null,"authChannelRefNumber":null},"payload":{"rangeUpTo":"5100000000018","referenceNo":"240290000029991","vaIbanRangeUpto":"AE750500005100000000018","vaIbanRangeFrom":"AE750500005100000000018","rangeFrom":"5100000000018"}}}';
        BankVirtualAccountController.updateBankVirtualAccountResponse(responseBodyFab, requestBodyFab, 'ADIBBankIntegrationVA');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFab));
        BatchToCreateBankVirtualAccount batch = new BatchToCreateBankVirtualAccount(bva2,'Escrow', 'First Abu Dhabi Bank');
        database.executeBatch(batch);
        
        //FAB_MandateResponseWrapper.parse(requestBodyFab);
        test.stopTest();
    }
}