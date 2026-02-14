@IsTest
public with sharing class SendGridTest {
    
    @TestSetup
    static void makeData(){
        SendGridTestUtils.generateTestData();
    }

    /**
     * Test First Payment Reminder when response is successful // Status Code 201
     */
    static testMethod void paymentReminder_First_Success(){

        SendGridTestUtils.generateTestData_Installment(30);
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test First Payment Reminder when response is error // Status Code 400
     */
    static testMethod void paymentReminder_First_Error(){

        SendGridTestUtils.generateTestData_Installment(30);
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder_Error();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Second Payment Reminder when response is successful // Status Code 201
     */
    static testMethod void paymentReminder_Second_Success(){

        SendGridTestUtils.generateTestData_Installment(15);
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Second Payment Reminder when response is blank // Status Code 500
     */
    static testMethod void paymentReminder_Second_Error_NoBody(){

        SendGridTestUtils.generateTestData_Installment(15);
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder_Error_NoBody();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Third Payment Reminder when response is successful // Status Code 201
     */
    static testMethod void paymentReminder_Third_Success(){

        SendGridTestUtils.generateTestData_Installment(15);
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Third Payment Reminder when response is successful and Account is picked from Building Escrow // Status Code 201
     */
    static testMethod void paymentReminder_Third_Success_BuildingEscrow(){

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
                InstallmentDate__c= System.Today(),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Third Payment Reminder when response is successful and Account is picked from Corporate Account on Project // Status Code 201
     */
    static testMethod void paymentReminder_Third_Success_CorporateProject(){

        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Unit__r.BuildingSectionName__r.BankNameEscrow__c, Unit__r.BuildingSectionName__c, Unit__r.Project__c, Unit__r.Project__r.BankNameEscrow__c FROM SalesOrder__c LIMIT 1];
        if(salesOrderRecord.Unit__r.BuildingSectionName__c != null && salesOrderRecord.Unit__r.BuildingSectionName__r.BankNameEscrow__c != null){
            update new BuildingSection__c(  Id = salesOrderRecord.Unit__r.BuildingSectionName__c,
                                            BankNameEscrow__c = ''
                                        );
        }
        if(salesOrderRecord.Unit__r.Project__c != null){
            update new Project__c(  Id = salesOrderRecord.Unit__r.Project__c,
                                    BankNameEscrow__c = '',
                                    BankNameCorporate__c = 'Test Corporate',
                                    AccountNumberCorporate__c = 'Test Corporate',
                                    BeneficiaryNameCorporate__c = 'Test Corporate',
                                    BranchCorporate__c = 'Test Corporate',
                                    IBANNoCorporate__c = 'Test Corporate',
                                    SwiftCodeCorporate__c = 'Test Corporate'
                                );
        }
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= System.Today(),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);

        Test.stopTest();
        
    }

    /**
     * Test Utility getDocumentData
     */
    @IsTest
    static void testUtility_getDocumentData_BusinessAccount_NoContact(){

        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Contact__c, Account__c, Unit__r.BuildingSectionName__r.BankNameEscrow__c, Unit__r.BuildingSectionName__c, Unit__r.Project__c, Unit__r.Project__r.BankNameEscrow__c FROM SalesOrder__c LIMIT 1];
        
        Account thisBussinessAcc = TestObjectsFactory.getOrganisationAccountRecord('Aldar', '0987654');
        insert thisBussinessAcc;

        salesOrderRecord.Contact__c = null;
        salesOrderRecord.Account__c = thisBussinessAcc.Id;
        update salesOrderRecord;
        
        if(salesOrderRecord.Unit__r.BuildingSectionName__c != null && salesOrderRecord.Unit__r.BuildingSectionName__r.BankNameEscrow__c != null){
            update new BuildingSection__c(  Id = salesOrderRecord.Unit__r.BuildingSectionName__c,
                                            BankNameEscrow__c = ''
                                        );
        }
        if(salesOrderRecord.Unit__r.Project__c != null){
            update new Project__c(  Id = salesOrderRecord.Unit__r.Project__c,
                                    BankNameEscrow__c = '',
                                    BankNameCorporate__c = 'Test Corporate',
                                    AccountNumberCorporate__c = 'Test Corporate',
                                    BeneficiaryNameCorporate__c = 'Test Corporate',
                                    BranchCorporate__c = 'Test Corporate',
                                    IBANNoCorporate__c = 'Test Corporate',
                                    SwiftCodeCorporate__c = 'Test Corporate'
                                );
        }
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= System.Today(),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);
        
        Test.stopTest();
        
    }

    /**
     * Test Utility getDocumentData
     */
    @IsTest
    static void testUtility_getDocumentData_BusinessAccount_HasContact(){

        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Contact__c, Account__c, Unit__r.BuildingSectionName__r.BankNameEscrow__c, Unit__r.BuildingSectionName__c, Unit__r.Project__c, Unit__r.Project__r.BankNameEscrow__c FROM SalesOrder__c LIMIT 1];
        
        Account thisBussinessAcc = TestObjectsFactory.getOrganisationAccountRecord('Aldar', '0987654');
        insert thisBussinessAcc;

        Contact thisContact = TestObjectsFactory.contactDataSetup(thisBussinessAcc.Id);

        salesOrderRecord.Account__c = thisBussinessAcc.Id;
        salesOrderRecord.Contact__c = null;
        update salesOrderRecord;
        
        if(salesOrderRecord.Unit__r.BuildingSectionName__c != null && salesOrderRecord.Unit__r.BuildingSectionName__r.BankNameEscrow__c != null){
            update new BuildingSection__c(  Id = salesOrderRecord.Unit__r.BuildingSectionName__c,
                                            BankNameEscrow__c = ''
                                        );
        }
        if(salesOrderRecord.Unit__r.Project__c != null){
            update new Project__c(  Id = salesOrderRecord.Unit__r.Project__c,
                                    BankNameEscrow__c = '',
                                    BankNameCorporate__c = 'Test Corporate',
                                    AccountNumberCorporate__c = 'Test Corporate',
                                    BeneficiaryNameCorporate__c = 'Test Corporate',
                                    BranchCorporate__c = 'Test Corporate',
                                    IBANNoCorporate__c = 'Test Corporate',
                                    SwiftCodeCorporate__c = 'Test Corporate'
                                );
        }
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= System.Today(),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        Database.executebatch(new CustomerPaymentNotificationBatch(), 1);
        
        Test.stopTest();
        
    }

    static testMethod void paymentReminder_Success_ButtonClick(){

        SendGridTestUtils.generateTestData_Installment(30);

        List<InstallmentLines__c> installmentLines = [SELECT Id, SalesOrder__c FROM InstallmentLines__c LIMIT 1];
        
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        ALD_IL_PaymentReminder.sendReminderEmailViaSendGrid(installmentLines[0].Id,'third',installmentLines[0].SalesOrder__c);

        Test.stopTest();
        
    }

    @IsTest
    static void testUtility_WithoutSharingService(){

        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id, Contact__c, Account__c, Unit__r.BuildingSectionName__r.BankNameEscrow__c, Unit__r.BuildingSectionName__c, Unit__r.Project__c, Unit__r.Project__r.BankNameEscrow__c FROM SalesOrder__c LIMIT 1];
        
        Account thisBussinessAcc = TestObjectsFactory.getOrganisationAccountRecord('Aldar', '0987654');
        insert thisBussinessAcc;

        Contact thisContact = TestObjectsFactory.contactDataSetup(thisBussinessAcc.Id);

        salesOrderRecord.Account__c = thisBussinessAcc.Id;
        salesOrderRecord.Contact__c = null;
        SendGridWithoutSharingUtil.doDML_SingleObject(salesOrderRecord, 'update');
        SendGridWithoutSharingUtil.doDML_List(new List<SalesOrder__c>{salesOrderRecord}, 'update');
    }
}