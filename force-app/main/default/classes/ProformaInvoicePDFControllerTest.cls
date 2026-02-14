@isTest
public class ProformaInvoicePDFControllerTest {

    @TestSetup
    static void makeData(){
        SendGridTestUtils.generateTestData();
    }

    @IsTest
    static void testOne_Success_ProjectEscrow(){

        // Instantiate the controller
        ProformaInvoicePDFController controller;

        //Prepare Installment Line Record
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];

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

        InstallmentLines__c installmentRecord = installmentLines[0];
        
        Test.startTest();

        PageReference pageRef = Page.ProformaInvoicePDFPage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', installmentRecord.Id);

        controller = new ProformaInvoicePDFController();
        
        Test.stopTest();

        // Assert that the dataWrapper is populated
        System.assertNotEquals(null, controller.dataWrapper);
        // Add more assertions based on the expected behavior
        
    }

    @IsTest
    static void testOne_Success_BuildingEscrow(){

        // Instantiate the controller
        ProformaInvoicePDFController controller;

        //Prepare Installment Line Record
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Unit__r.BuildingSectionName__c FROM SalesOrder__c LIMIT 1];
        if(salesOrderRecord.Unit__r.BuildingSectionName__c != null){
            update new BuildingSection__c(  Id = salesOrderRecord.Unit__r.BuildingSectionName__c,
                                            BankNameEscrow__c = 'Test Test', 
                                            BranchEscrow__c = 'Test Test',
                                            BeneficiaryNameEscrow__c = 'Test Test',
                                            AccountNumberEscrow__c = 'Test Test',
                                            IBANNoEscrow__c = 'Test Test',
                                            SwiftCodeEscrow__c = 'Test Test'
                                        );
        }

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

        InstallmentLines__c installmentRecord = installmentLines[0];
        
        Test.startTest();

        PageReference pageRef = Page.ProformaInvoicePDFPage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', installmentRecord.Id);

        controller = new ProformaInvoicePDFController();
        
        Test.stopTest();

        // Assert that the dataWrapper is populated
        System.assertNotEquals(null, controller.dataWrapper);
        // Add more assertions based on the expected behavior
        
    }

    @IsTest
    static void testOne_Success_BuildingEscrow_Haven(){

        // Instantiate the controller
        ProformaInvoicePDFController controller;

        //Prepare Installment Line Record
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Unit__r.BuildingSectionName__c FROM SalesOrder__c LIMIT 1];
        Project__c projectRecord = [SELECT Id, Name FROM Project__c WHERE Name = 'Mayan' LIMIT 1];
        projectRecord.Name = 'Haven';
        update projectRecord;
        if(salesOrderRecord.Unit__r.BuildingSectionName__c != null){
            update new BuildingSection__c(  Id = salesOrderRecord.Unit__r.BuildingSectionName__c,
                                            BankNameEscrow__c = 'Test Test', 
                                            BranchEscrow__c = 'Test Test',
                                            BeneficiaryNameEscrow__c = 'Test Test',
                                            AccountNumberEscrow__c = 'Test Test',
                                            IBANNoEscrow__c = 'Test Test',
                                            SwiftCodeEscrow__c = 'Test Test'
                                        );
        }

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

        InstallmentLines__c installmentRecord = installmentLines[0];
        
        Test.startTest();

        PageReference pageRef = Page.ProformaInvoicePDFPage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', installmentRecord.Id);

        controller = new ProformaInvoicePDFController();
        ProformaInvoicePDFController.Wrapper srap = new ProformaInvoicePDFController.Wrapper();
        srap.virtualAccountTitle='';
        srap.virtualAccountNumber='';
        srap.virtualAccountBankName='';
        srap.virtualAccountBankIBAN='';
        srap.virtualAccountBankSwift='';
        Test.stopTest();

        // Assert that the dataWrapper is populated
        System.assertNotEquals(null, controller.dataWrapper);
        // Add more assertions based on the expected behavior
        
    }

}