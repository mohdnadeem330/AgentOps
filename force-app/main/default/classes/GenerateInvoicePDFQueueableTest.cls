/**
* @File Name : GenerateInvoicePDFQueueableTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 13, 2025 |   | Initial Version
**/
@IsTest
public class GenerateInvoicePDFQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a Case with valid email
        Case testCase = new Case(
            Type = 'Temporary License Agreement',
            Licensee_Email__c = 'licensee@example.com',
            Development_Name__c = 'Yas Island',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Subject = 'Test NOC Application',
            Service_Price__c = 500.00
        );
        insert testCase;
        
        // Create Payment_Request__c linked to Case
        Payment_Request__c payment = new Payment_Request__c(
            Case__c = testCase.Id,
            Payment_Type__c = 'Wire Transfer',
            Transaction_No__c = 'TXN10001',
			Status__c = 'Pending'

        );
        insert payment;
    }
    
    @IsTest
    static void testQueueableExecute() {
        // Query Payment_Request__c Ids
        List<Payment_Request__c> payments = [SELECT Id FROM Payment_Request__c];
        List<Id> paymentIds = new List<Id>();
        for (Payment_Request__c p : payments) paymentIds.add(p.Id);
        
        Test.startTest();
        // Enqueue the queueable job
        System.enqueueJob(new GenerateInvoicePDFQueueable(paymentIds));
        Test.stopTest();
        
        // Assert that Document__c is created
        List<Document__c> docs = [SELECT Id, Payment_Request__c FROM Document__c WHERE Payment_Request__c IN :paymentIds];
        
        // Assert ContentVersion creation
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title = :Label.DM_ReceiptFileName];
    }
    
    @IsTest
    static void testQueueableWithEmptyList() {
        Test.startTest();
        System.enqueueJob(new GenerateInvoicePDFQueueable(new List<Id>()));
        Test.stopTest();
    }
    
    @IsTest
    static void testQueueableWithNullList() {
        Test.startTest();
        System.enqueueJob(new GenerateInvoicePDFQueueable(null));
        Test.stopTest();
    }
}