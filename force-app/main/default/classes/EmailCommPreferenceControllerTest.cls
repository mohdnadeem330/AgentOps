@isTest
private class EmailCommPreferenceControllerTest {

    @TestSetup
    static void makeData(){
        SendGridTestUtils.generateTestData();
    }

    @isTest
    static void testGenerateURL() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String responseURL;
        Test.startTest();
        responseURL = EmailCommPreferenceController.generateURL(testAccount.Id);
        Test.stopTest();
        System.assertNotEquals(null, responseURL, 'Test');
    }

    @IsTest
    static void testConstructor(){

        //Prepare Installment Line Record
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Account__c FROM SalesOrder__c LIMIT 1];
		Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c = salesOrderRecord.Account__c;
        cp.AccountId__c = salesOrderRecord.Account__c;
        cp.Category__c = 'Communication preference';
        insert cp;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= System.Today().addDays(30),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        

        System.debug('####salesOrderRecord.Account__c: '+salesOrderRecord.Account__c);

        // Encrypt the accountId
        String encryptedAccountId = EmailCommPreferenceController.encryptAccountId(salesOrderRecord.Account__c);
        String refreshToken = EmailCommPreferenceController.generateToken(salesOrderRecord.Account__c);

        System.debug('####encryptedAccountId: '+encryptedAccountId);
        System.debug('####refreshToken: '+refreshToken);

        Test.startTest();
        // Construct the URL
        PageReference pageRef = Page.EmailCommPreferencePage;
        pageRef.getParameters().put('id', encryptedAccountId);
        pageRef.getParameters().put('token', refreshToken);

        Test.setCurrentPage(pageRef);

        EmailCommPreferenceController controller = new EmailCommPreferenceController();
        
        Test.stopTest();
        
    }

    @IsTest
    static void testGetCheckboxValues(){

        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Account__c FROM SalesOrder__c LIMIT 1];

        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= System.Today().addDays(30),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;

        Map<String, Boolean> payload = new Map<String, Boolean>{'Call' => true, 'Email' => false, 'SMS' => false, 'Whatsapp' => false};
        String response;
        Test.startTest();

        response = EmailCommPreferenceController.getCheckboxValues(payload, salesOrderRecord.Account__c, null);
        
        Test.stopTest();
        
    }

}