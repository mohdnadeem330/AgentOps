@isTest
public class ReceiptAcknowledgementControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create all common test data in setup
        //Dummy commit New as part of FIN-147
        Account personAccount = TestObjectsFactory.getPersonAccountRecord(1234, 'United Arab Emirates', 'v123', 'p123');
        insert personAccount;

        Account unidentifiedAccount = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        unidentifiedAccount.Name = Label.UnidentifiedCustomerName;
        insert unidentifiedAccount;

        Account orgAccount1 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAccount1;

        Account orgAccount2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220213');
        insert orgAccount2;
        
        Contact con = TestObjectsFactory.contactDataSetup(orgAccount1.Id);
        /*con.Email = 'test@test.com';
        con.Id = null;
        insert con;*/
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(personAccount.Id);
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.Id;
        insert unit;

        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = projectRecord.id;
        va1.Unit__c = unit.id;
        va1.BufferFlag__c = false;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.VirtualAccountName__c = 'Test';
        insert va1;

        unit.VirtualAccountNumber__c = va1.id;
        update unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, personAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        insert salesOrder;
        
        PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlan;
        
        list<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallment(paymentPlan.Id);
        insert paymentInstallmentList;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.getInstallmentLines(salesOrder.id, paymentPlan.Id, paymentInstallmentList);
        // Set validation bypass for all test InstallmentLines__c
        for (InstallmentLines__c il : installmentLines) {
            il.isValidationBypass__c = true;
        }
        insert installmentLines;

        BankVirtualAccounts__c va = TestObjectsFactory.getBankVirtualAccounts();
        va.Project__c = projectRecord.id;
        va.Unit__c = unit.id;
        va.BufferFlag__c = false;
        va.Virtual_Account_Type__c = 'Escrow';
        va.VirtualAccountName__c = 'Test';
        insert va;
        
        // Create Service Request Template and related records
        HexaBPM__SR_Template__c srTemplate = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert srTemplate;

        HexaBPM__Step_Template__c stepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert stepTemplate;

        HexaBPM__SR_Steps__c srSteps = TestObjectsFactory.getSRStep(srTemplate.Id, stepTemplate.Id);
        insert srSteps;

        List<HexaBPM__SR_Status__c> statuses = new List<HexaBPM__SR_Status__c>{
            TestObjectsFactory.getSRStatus('Draft'),
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus('Approved by Finance')
        };
        insert statuses;
    }

    @IsTest
    static void testCreateReceiptFromSR() {
        // Get pre-created test data
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
            HexaBPM__SR_Template__c srTemplate = [SELECT Id FROM HexaBPM__SR_Template__c LIMIT 1];
            HexaBPM__SR_Status__c draftStatus = [SELECT Id FROM HexaBPM__SR_Status__c WHERE HexaBPM__Code__c = 'Draft' LIMIT 1];

            Test.startTest();

            // Create SR
            HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(
                draftStatus.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, 
                mortgageRegistrationId, srTemplate.Id
            );
            newSR.ChargeCollected__c = 2000;
            newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Request');
            newSR.SRType__c = 'Rebate Request';
            insert newSR;

            // Create SRUnitSelected
            SRUnitSelected__c srUnit = new SRUnitSelected__c(
                ServiceRequest__c = newSR.Id,
                Unit__c = unit.Id,
                SalesOrder__c = salesOrder.Id,
                OutstandingAmount__c = 900000.00,
                Previous_Rebate_Offered__c = 70005.00,
                Rebate_Percentage__c = 20
            );
            insert srUnit;

            Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;

            // Create Receipt Acknowledgement
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, opp.Id, 'Cash'
            );
            receipt.ServiceRequest__c = newSR.Id;
            receipt.Virtual_Account_Name__c = 'Test';

            // Create test file
            ReceiptAcknowledgementController.FileInfo fi = new ReceiptAcknowledgementController.FileInfo();
            fi.Title = 'test.png';
            fi.FileContent = Blob.valueOf('Test Content');
            List<Object> filedata = new List<Object>{fi};

            // Test methods
            ReceiptAcknowledgementController.createReceiptFromSR(receipt, filedata);
            ReceiptAcknowledgementController.getInstallmentDetails(installmentLine.Id);
            ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(newSR.Id);
            ReceiptAcknowledgementController.getCorporateAccounts();
            ReceiptAcknowledgementController.getBuildingsByProject(projectRecord.Id);
            ReceiptAcknowledgementController.getBuildingEscrowAccount(buildingRecord.Id);
            //ReceiptAcknowledgementController.createReceiptFromSR(receipt, fileToInsert);

            Test.stopTest();
        }
    }

    @IsTest
    static void testOtherScenarios() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            //Added by Sai Kumar as part of DFC-4 story
            Inward_Remittance__c remittance = new Inward_Remittance__c(
                Sales_Order__c = salesOrder.Id,
                Amount__c = 500.0,
                Request_DateTime__c = System.now(),
                Status__c = 'Unprocessed'
            );
            insert remittance;

            // Create Receipt Acknowledgement
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, Constants.MORTGAGE_CHEQUE
            );
            //Added by Sai Kumar as part of DFC-4 story
            receipt.Inward_Remittance__c = remittance.Id;
            receipt.PaymentType__c = 'Cheque';
            receipt.Virtual_Account_Name__c = 'Test';
            insert receipt;

            // Create Other Charges
            SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
            otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE;
            otherCharges.AmountReceived__c = 1500;
            update otherCharges;

            // Test additional scenarios
            ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(remittance.Id);
            ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(otherCharges.Id);
            ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(receipt.Id);
            ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(installmentLine.Id);
            
            // Test update method
            receipt.Amount__c = 2000;
            ReceiptAcknowledgementController.updatedReceiptAcknowledgementRecord(receipt);

            // Test utility methods
            ReceiptAcknowledgementController.getCurrentUserProfileName();
            Test.stopTest();
        }
    } 
    @IsTest
    static void testCreateReceiptAcknowledgementRecord() {
        // Set static variables to skip triggers before any DML
        SalesOrderTriggerHandler.skipSalesOrderTrigger = true;
        CalloutToMuleSoft.updateSOSyncStatus = true; // Set to true to skip callouts/triggers

        // Get pre-created test data
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            // Set static variables again inside runAs context to ensure they are set for the user context
            SalesOrderTriggerHandler.skipSalesOrderTrigger = true;
            CalloutToMuleSoft.updateSOSyncStatus = true; // Set to true to skip callouts/triggers

            // Get test accounts
            Account personAccount =TestObjectsFactory.getPersonAccountRecord(1234, 'United Arab Emirates', 'v123', 'p123');
            insert personAccount;
            Account unidentifiedAccount = [SELECT Id FROM Account WHERE Name = :Label.UnidentifiedCustomerName LIMIT 1];
            
            // Get test sales order and installment line
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id, InstallmentAmount__c, AmountReceived__c, isValidationBypass__c, PendingAmount__c FROM InstallmentLines__c LIMIT 1];
            installmentLine.InstallmentAmount__c = 2000;
            installmentLine.AmountReceived__c = 100;
            // Toggle isValidationBypass__c to bypass validation
            installmentLine.isValidationBypass__c = !installmentLine.isValidationBypass__c;
            update installmentLine;

            // Create Inward Remittance
         Inward_Remittance__c remittance = new Inward_Remittance__c(
                Sales_Order__c = salesOrder.Id,
                Amount__c = 500.0,
                Request_DateTime__c = System.now(),
                Status__c = 'Unprocessed'
            );
            insert remittance; 
            // Use List<Object> to allow both Ids and String values like 'ADM_FEE'
            List<Object> selectedInstallmentIds = new List<Object>{installmentLine.Id};
            selectedInstallmentIds.addAll(new List<Id>{installmentLine.Id});

            // Create ADM Fee for SalesOrder
            SalesOrderOtherCharges__c admFee = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, personAccount.Id);
            //admFee.Id = null; // Clear Id to avoid DMLException on insert
            admFee.TypeOfCharge__c = 'ADM Fee';
            admFee.Amount__c = 250;
            admFee.AmountReceived__c = 0;
            update admFee;
            selectedInstallmentIds.add('ADM_FEE');
            
            // Create Payment Plan and Installments
            PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlanRecord();
            insert paymentPlan;
            
            List<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallment(paymentPlan.Id);
            insert paymentInstallmentList;

            // Create additional installment lines for bulk allocation
            List<InstallmentLines__c> extraInstallments = new List<InstallmentLines__c>();
            for (Integer i = 0; i < 2; i++) {
                InstallmentLines__c extra = TestObjectsFactory.getInstallmentLines(salesOrder.Id, paymentPlan.Id, paymentInstallmentList)[0].clone(false, true, false, false);
                extra.SalesOrder__c = salesOrder.Id;
                extra.InstallmentAmount__c = 2000;
                extra.AmountReceived__c = 1900;
                extra.isValidationBypass__c = true;
                extraInstallments.add(extra);
            }
            insert extraInstallments;

            // Prepare selected IDs
            List<Id> SelectIlIds = new List<Id>{installmentLine.Id};

            // Create ADM Fee and prepare charge IDs
            SalesOrderOtherCharges__c af = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, personAccount.Id);
            af.TypeOfCharge__c = 'ADM Fee';
            af.Amount__c = 250;
            af.AmountReceived__c = 0;
            update af ;

            List<Id> selectedChargeIds = new List<Id>{installmentLine.Id, af.Id};

            Test.startTest();
            
            // Scenario 1: Bulk Installment Allocation with ADM Fee
            ReceiptAcknowledgement__c receipt1 = new ReceiptAcknowledgement__c(
                Account__c = personAccount.Id,
                SalesOrder__c = salesOrder.Id,
                Amount__c = 2250,
                PaymentType__c = 'Cash'
            ); 
            
            Map<String, Object> wrapperMap = new Map<String, Object>{
                'installmentRec' => new Map<String, Object>{
                    'Id' => installmentLine.Id,
                    'InstallmentAmount__c' => 2000,
                    'AmountReceived__c' => 1900,
                    'PendingAmount__c' => 100,
                    'isValidationBypass__c' => true
                },
                'salesOrderRecord' => salesOrder,
                'objectName' => 'InstallmentLines__c',
                'selectedInstallmentIds' => SelectIlIds,
                'selectedChargeIds' => selectedChargeIds,
                'isInwardRemittanceForUnidentified' => true
            };
            String wrap = JSON.serialize(wrapperMap);
            
            // Prepare file info
            ReceiptAcknowledgementController.FileInfo fileInfo = new ReceiptAcknowledgementController.FileInfo();
            fileInfo.Title = 'test.png';
            fileInfo.FileContent = Blob.valueOf('Test Content');
            List<Object> filesToInsert = new List<Object>{fileInfo};
            
            ReceiptAcknowledgement__c createdReceipt = ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt1, 
                installmentLine.Id, 
                filesToInsert, 
                wrap,
                true
            );
            
/*            // Scenario 2: Unidentified Customer
            ReceiptAcknowledgement__c receipt2 = new ReceiptAcknowledgement__c(
                Account__c = unidentifiedAccount.Id,
                SalesOrder__c = salesOrder.Id,
                Amount__c = 500,
                PaymentType__c = 'Cheque',
                Virtual_Account_Name__c = 'ABC',
                Inward_Remittance__c = remittance.Id
            );
            
            String wrapperJson2 = JSON.serialize(new Map<String, Object>{
                'isInwardRemittanceForUnidentified' => true,
                'isInwardRemittance' => true,
                'salesOrderRecord' => salesOrder
            });
            
            ReceiptAcknowledgement__c unidentifiedReceipt = ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt2, 
                salesOrder.Id, // Pass salesOrder.Id instead of null
                null, 
                wrapperJson2,
                true
            );*/
            
            Test.stopTest();
        }
    }

    @IsTest
    static void testWireTransferScenario() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            // Create Receipt Acknowledgement with Wire Transfer
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, 'Wire Transfer'
            );
            receipt.ReferenceNumber__c = 'WIRE123';
            receipt.Customer_Transfer_Reference__c = 'WIRE123';
            receipt.Virtual_Account_Name__c = 'Test';

            // Create test file
            ReceiptAcknowledgementController.FileInfo fileInfo = new ReceiptAcknowledgementController.FileInfo();
            fileInfo.Title = 'test.png';
            fileInfo.FileContent = Blob.valueOf('Test Content');
            List<Object> fileToInsert = new List<Object>{fileInfo};

            // Test methods
            ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt, 
                installmentLine.Id, 
                fileToInsert, 
                JSON.serialize(new Map<String, Object>{
                    'installmentRec' => new Map<String, Object>{
                        'Id' => installmentLine.Id,
                        'PendingAmount__c' => 2000
                    },
                    'salesOrderRecord' => salesOrder,
                    'objectName' => 'InstallmentLines__c'
                }),
                false
            );

            Test.stopTest();
        }
    }

    @IsTest
    static void testDirectDebitScenario() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            // Create Receipt Acknowledgement with Direct Debit
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, 'Direct Debit'
            );
            receipt.DDCollectionStatus__c = 'Collection Initiated';
            receipt.ChequeReceived__c = true;
            receipt.Virtual_Account_Name__c = 'Test';

            // Test methods
            ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt, 
                installmentLine.Id, 
                null, 
                JSON.serialize(new Map<String, Object>{
                    'installmentRec' => new Map<String, Object>{
                        'Id' => installmentLine.Id,
                        'PendingAmount__c' => 2000
                    },
                    'salesOrderRecord' => salesOrder,
                    'objectName' => 'InstallmentLines__c'
                }),
                false
            );

            Test.stopTest();
        }
    }

    @IsTest
    static void testThirdPartyPaymentScenario() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            // Create Receipt Acknowledgement with Third Party Payment
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, 'Cheque'
            );
            receipt.Remarks__c = 'Third Party Payment';
            receipt.Virtual_Account_Name__c = 'Test';

            // Test methods
            ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt, 
                installmentLine.Id, 
                null, 
                JSON.serialize(new Map<String, Object>{
                    'installmentRec' => new Map<String, Object>{
                        'Id' => installmentLine.Id,
                        'PendingAmount__c' => 2000
                    },
                    'salesOrderRecord' => salesOrder,
                    'objectName' => 'InstallmentLines__c'
                }),
                true
            );

            Test.stopTest();
        }
    }

    @IsTest
    static void testErrorScenarios() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();

            // Test with invalid data
            try {
                ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                    null, 
                    null, 
                    null, 
                    'invalid json',
                    false
                );
            } catch(Exception e) {
                System.assert(e.getMessage() != null);
            }

            // Test with invalid installment line
            try {
                ReceiptAcknowledgementController.getInstallmentDetails('invalid_id');
            } catch(Exception e) {
                System.assert(e.getMessage() != null);
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void testRebateRequestScenario() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            // Create Receipt Acknowledgement for Rebate Request
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, 'Cash'
            );
            receipt.Virtual_Account_Name__c = 'Test';

            // Prepare wrapper for rebate request
            Map<String, Object> wrapperMap = new Map<String, Object>{
                'installmentRec' => new Map<String, Object>{
                    'Id' => installmentLine.Id,
                    'PendingAmount__c' => 2000
                },
                'salesOrderRecord' => salesOrder,
                'objectName' => 'InstallmentLines__c',
                'SRType' => 'Rebate Request',
                'AccountId' => acc.Id
            };

            // Test methods
            ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt, 
                installmentLine.Id, 
                null, 
                JSON.serialize(wrapperMap),
                false
            );

            Test.stopTest();
        }
    }

    @IsTest
    static void testInwardRemittanceScenario() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account WHERE Name != :Label.UnidentifiedCustomerName LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            InstallmentLines__c installmentLine = [SELECT Id FROM InstallmentLines__c LIMIT 1];

            Test.startTest();

            // Create Inward Remittance
            Inward_Remittance__c remittance = new Inward_Remittance__c(
                Sales_Order__c = salesOrder.Id,
                Amount__c = 500.0,
                Request_DateTime__c = System.now(),
                Status__c = 'Unprocessed'
            );
            insert remittance;

            // Create Receipt Acknowledgement with Inward Remittance
            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
                salesOrder.Id, acc.Id, null, 'Cash'
            );
            receipt.Inward_Remittance__c = remittance.Id;
            receipt.Virtual_Account_Name__c = 'Test';

            // Prepare wrapper for inward remittance
            Map<String, Object> wrapperMap = new Map<String, Object>{
                'installmentRec' => new Map<String, Object>{
                    'Id' => installmentLine.Id,
                    'PendingAmount__c' => 2000
                },
                'salesOrderRecord' => salesOrder,
                'objectName' => 'InstallmentLines__c',
                'isInwardRemittance' => true,
                'inwardRemittanceRec' => remittance
            };

            // Test methods
            ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(
                receipt, 
                installmentLine.Id, 
                null, 
                JSON.serialize(wrapperMap),
                false
            );

            Test.stopTest();
        }
    }
}