@istest
public class ALDVA_VirtualAccountTest {
	@isTest
    static void setupData() {
        Account account = TestObjectsFactory.getPersonAccountRecord(1111111, 'India','11111','P11111');
        insert account;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
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
        

       
        Test.startTest();
        ALDVA_VirtualAccount.callCreateVA(project.Id);
        ALDVA_VirtualAccount.checkTheProgressOfVACreation(project.Id);
        ALDVA_VirtualAccount.callCancelVAViaBatch(new List<String>{project.Id});
        ALDVA_VirtualAccount.checkTheBankName(ALD_Constants.ABUDHABI_COMMERCIAL_BANK);
        ALDVA_VirtualAccount.checkTheBankName(ALD_Constants.FIRST_ABUDHABI_BANK);
        List<BankVirtualAccounts__c> bva= [SELECT Id, EscrowAccountNumber__c, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, BankName__c FROM BankVirtualAccounts__c WHERE (Unit__r.Status__c= 'New' OR Unit__r.Status__c='Available') AND VirtualAccountNumber__c=NULL AND EscrowAccountNumber__c!=null AND CreatedDate=TODAY AND Project__c =: project.Id ];
        List<BankVirtualAccounts__c> bva2= [SELECT Id, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, VirtualAccountNumber__c, EscrowAccountNumber__c, BankName__c FROM BankVirtualAccounts__c WHERE (Unit__r.Status__c= 'New' OR Unit__r.Status__c='Available')  AND CreatedDate=TODAY AND Project__c =: project.Id ];
        String requestBody = '{"requestId":"'+bva2[0].Id+'","physicalAccountNumber":"2345678","defaultAccount":"Y","virtualAccountType":"N","splitRequired":"N","uniqueReferenceNumber":"a2S25000001ViGDEA0","remarks":""}';
        String responseBody = '{"success": "true",	"reqTimeStamp": "2020-02-21T13:55:52",	"resTimeStamp": "2020-02-21T13:55:52",	"responseId": "adf0b22-2eb4-4141-bc6c-0c56fb8cbbde",	"response": {		"requestId":"'+bva2[0].id+'",		"customerID": "1234567",		"virtualCustomerID": "12345","physicalAccountNumber": "123456789001","physicalAccountTitle": "ACDESC_123456789001","virtualAccountNumber": "12345678911111",		"defaultAccount": "Y",		"virtualAccountTitle": "Title1",		"virtualIBAN": "AE123456789111111111112",		"virtualAccountType": "N",		"splitRequired": "Y",		"virtualAccountStatus": "A",		"virtualAccountOpenDate":null ,		"virtualAccountClosureDate":null,		"uniqueReferenceNumber": "734899"	}}';
        ALDVA_VirtualAccount.updateBankVirtualAccountResponse(responseBody, requestBody);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        ALDVA_CreateVirtualAccountBatch abc = new ALDVA_CreateVirtualAccountBatch(new Set<String>{project.Id});
        ALD_Bank_Configuration__mdt bankConfig =  ALD_Bank_Configuration__mdt.getInstance('Abu_Dhabi_Commercial_Bank');
        
        Organization org = Utilities.getOrganizationDetails();
        system.debug('bva2[0].Id:'+bva2[0].Id);
        system.debug('bankConfig::'+bankConfig);
        system.debug('org::'+org);
        bva2[0].EscrowAccountNumber__c = '12345678';
        bva2[0].VirtualAccountNumber__c = '45677654';
        bva2[0].ResponseId__c = '09876578';
        bva2[0].StatusFlag__c = ALD_Constants.ALDVA_STATUS_CANCELLED;
        bva2[0].VirtualAccountClosureDate__c = null;
        update bva2[0];
       // ALDVA_VirtualAccount.callCancelVA(false,bva2[0].Id,bva2[0],bankConfig, org );
        String sch = '0 0 23 * * ?';
        system.schedule('Test Territory Check', sch, abc); 
        
        ALDVA_CancelVirtualAccountBatch batch = new ALDVA_CancelVirtualAccountBatch(new List<String>{bva2[0].Id});
        database.executeBatch(batch);
        ALDVA_ADCB_ResponseWrapper.parse(responseBody);
        Test.stopTest();
    }
        
}