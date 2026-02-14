@isTest
private class PaymentRequestTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Base Case
        Case testCase = new Case(
            Type = 'NOC',
            Status = 'New',
            Development_Name__c = 'Yas Island',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Subject = 'Test NOC Application',
            Service_Price__c = 500.00
        );
        insert testCase;

        // Online Payment (no encrypted id)
        Payment_Request__c pr1 = new Payment_Request__c(
            Payment_Type__c = System.Label.DM_Online,
            Case__c = testCase.Id,
            Amount__c = 100,
            Status__c = 'Pending'
        );
        insert pr1;

        // Online Payment with encrypted id
        Payment_Request__c pr2 = new Payment_Request__c(
            Payment_Type__c = System.Label.DM_Online,
            Case__c = testCase.Id,
            Amount__c = 500,
            Status__c = 'Pending',
            Encrypted_Id__c = 'abc123'
        );
        insert pr2;

        // Case for PDC
        Case testCaseTla = new Case(
            Type = 'Temporary License Agreement',
            Status = 'New',
            Development_Name__c = 'Yas Island',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
            Subject = 'Test Case TLA',
            Service_Price__c = 500
        );
        insert testCaseTla;

        // PDC Payment
        Payment_Request__c pr3 = new Payment_Request__c(
            Payment_Type__c = 'Wire Transfer',
            Case__c = testCaseTla.Id,
            Amount__c = 100,
            Status__c = 'Unconfirmed'
        );
        insert pr3;
         Payment_Request__c pr5 = new Payment_Request__c(
            Payment_Type__c = 'CDC',
            Case__c = testCaseTla.Id,
            Amount__c = 100,
            Status__c = 'Pending'
        );
        insert pr5;
        
        
        Payment_Request__c pr4 = new Payment_Request__c(
            Payment_Type__c = 'Wire Transfer',
            Case__c = testCaseTla.Id,
            ERP_Id__c = '98282',
            ERP_Invoice_Number__c = '38404904',
            Amount__c = 100,
            Status__c = label.DM_Received 
        );
        insert pr4;
       
    }

    @isTest
    static void testAfterInsertMethod() {
        Payment_Request__c pr = new Payment_Request__c(
            Payment_Type__c = 'Online',
            Amount__c = 200,
            Status__c = 'Pending'
        );
        insert pr;

        Payment_Request__c recheck = [
            SELECT Id, Encrypted_Id__c
            FROM Payment_Request__c
            WHERE Id = :pr.Id
        ];
        System.assertNotEquals(null, recheck.Encrypted_Id__c, 'Encrypted Id should be populated');
    }

    @isTest
    static void testAfterUpdateOnlineTransaction() {
        try{
         //PaymentRequestTriggerHandler.skipGuestCheckInTest = true;
        Payment_Request__c pr = [SELECT Id, Transaction_No__c,Status__c,Payment_Type__c FROM Payment_Request__c WHERE  Status__c = 'Pending'  and  Payment_Type__c = 'Online'  LIMIT 1];
        pr.Transaction_No__c = 'TXN123';
        update pr;    
        }Catch(Exception e){
            
        }
        
        

    }
    
     @isTest
    static void testAfterUpdateOnlineTransaction1() {
         PaymentRequestTriggerHandler.skipGuestCheckInTest = false;
        Payment_Request__c pr = [SELECT Id, Transaction_No__c,Status__c,Payment_Type__c FROM Payment_Request__c WHERE  Status__c = 'Pending'  and  Payment_Type__c = 'Online'  LIMIT 1];
        pr.Transaction_No__c = 'TXN123';
        update pr;
        

    }
    
    
    @isTest
    static void testAfterUpdateOnlineTransactionelse() {
          PaymentRequestTriggerHandler.skipGuestCheckInTest = false;
        String statusValue = System.Label.DM_Received;
        
        // Query using that variable
        Payment_Request__c pr = [
            SELECT Id, Transaction_No__c, ERP_Id__c, ERP_Invoice_Number__c, Status__c, Payment_Type__c
            FROM Payment_Request__c
            WHERE Status__c = :statusValue
            LIMIT 1
        ];
        
      
    }


    @isTest
    static void testAfterUpdatePDC() {
          PaymentRequestTriggerHandler.skipGuestCheckInTest = true;
        Payment_Request__c pr = [SELECT Id,Status__c,Payment_Type__c,Payment_Reference_No__c FROM Payment_Request__c WHERE Payment_Type__c = 'Wire Transfer'  and Status__c = 'Unconfirmed' LIMIT 1];
        pr.Payment_Reference_No__c = 'PDC123';
        update pr;
       

    }
      @isTest
    static void testAfterUpdatePDC1() {
          PaymentRequestTriggerHandler.skipGuestCheckInTest = false;
        Payment_Request__c pr = [SELECT Id,Status__c,Payment_Type__c,Payment_Reference_No__c FROM Payment_Request__c WHERE Payment_Type__c = 'Wire Transfer'  and Status__c = 'Unconfirmed' LIMIT 1];
        pr.Payment_Reference_No__c = 'PDC123';
        update pr;
       

    }
    
    @isTest
    static void testAfterUpdatePDC2() {
          PaymentRequestTriggerHandler.skipGuestCheckInTest = false;
        Payment_Request__c pr = [SELECT Id,Status__c,Payment_Type__c,Payment_Reference_No__c FROM Payment_Request__c WHERE Payment_Type__c = 'CDC'  and Status__c = 'Pending' LIMIT 1];
        pr.Payment_Reference_No__c = 'PDC123';
        update pr;
       

    }


    @isTest
    static void testAfterUpdateCDC() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Payment_Request__c pr = new Payment_Request__c(
            Payment_Type__c = 'CDC',
            Case__c = c.Id,
            Amount__c = 100,
            Status__c = 'Pending'
        );
        insert pr;

        pr.Payment_Reference_No__c = 'CDC123';
        update pr;
    }

    @isTest
    static void testAfterUpdateWireTransfer() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Payment_Request__c pr = new Payment_Request__c(
            Payment_Type__c = 'Wire Transfer',
            Case__c = c.Id,
            Amount__c = 100,
            Status__c = 'Unconfirmed'
        );
        insert pr;

        pr.Payment_Reference_No__c = 'WIRE123';
        update pr;
    }

    @isTest
    static void testAfterUpdateReceivedERP() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Payment_Request__c pr = new Payment_Request__c(
            Payment_Type__c = System.Label.DM_Online,
            Case__c = c.Id,
            Amount__c = 500,
            Status__c = 'Pending',
            ERP_Id__c = 'ERP001',
            ERP_Invoice_Number__c = 'INV001'
        );
        insert pr;

        pr.Status__c = System.Label.DM_Received;
        update pr;
    } 
    
     

    

    @isTest
    static void testUpdateCaseReceivedAmount() {
        Case c = new Case(
            Type = 'NOC',
            Status = 'New',
            Development_Name__c = 'Yas Island',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Subject = 'Case with full amount',
            Service_Price__c = 300
        );
        insert c;

        Payment_Request__c pr = new Payment_Request__c(
            Payment_Type__c = System.Label.DM_Online,
            Case__c = c.Id,
            Amount__c = 300,
            Status__c = 'Remitted'
        );
        insert pr;

        Test.startTest();
        PaymentRequestTriggerHandler.updateCaseReceivedAmount(new List<Case>{c});
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status, Sub_Status__c, Received_Amount__c FROM Case WHERE Id = :c.Id];
        //System.assertEquals(300, updatedCase.Received_Amount__c);
    }
}