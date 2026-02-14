@isTest
public class CustomerServiceUtilityTest {
    
    @isTest
    public static void testCustomerServiceUtility() {
        
        String responseBody = '{"success":true,"statusCode":"200"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;
        
        Test.startTest();
        try {
            CustomerServiceUtility.getAccountDetail('');
            CustomerServiceUtility.getProjectDetail('');
            CustomerServiceUtility.getSalesOrderDetail('');
            CustomerServiceUtility.getSalesOrderDetailForProfile('');
            CustomerServiceUtility.getInstallmentLineDetail('');
            CustomerServiceUtility.getSalesOrderOtherChargeDetail('');
            CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{acc.Id});
            CustomerServiceUtility.getSalesOrderIdsFromJointOwnerWithEmail(acc.PersonEmail);
            CustomerServiceUtility.getReceiptAcknowledgementDetail('');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerServiceUtility2() {
        
        String responseBody = '{"success":true,"statusCode":"200"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Document__c document = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert document;
 
        ContentVersion cv = new ContentVersion(
        Title = 'TestFile', 
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Test content')
    );
    insert cv;

   
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

  
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = cv.ContentDocumentId,
        LinkedEntityId = document.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;

        
        
        TestObjectsFactory.createContentDocumentLink(document.Id);
        
        Test.startTest();
        try {
            CustomerServiceUtility.getDocumentDetail('');
            CustomerServiceUtility.getCaseDetail('');
            // CustomerServiceUtility.getLeadDetail('');
            // CustomerServiceUtility.getOpportunityDetail('');
 //           CustomerServiceUtility.getContentVersion(document.Id);
            CustomerServiceUtility.getAppointmentDetail('');
              ContentVersion result = CustomerServiceUtility.getContentVersion(document.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerServiceUtility3() {
        
        String responseBody = '{"success":true,"statusCode":"200"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
         
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        case caseRec = new Case();
        caseRec.AccountId = acc.Id;
      //  caseRec.ContactId = conRecord.Id;
        caseRec.Unit__c = unit.Id;
        caseRec.CustomerType__c = 'Owner';
        caseRec.Origin = 'Web';
        caseRec.Status = 'New';
        caseRec.Priority = 'Medium';
        //insert caseRec;
        
         Appointment__c app = new Appointment__c();
        app.CaseNumber__c = '2345';
        app.AppointmentType__c = Constants.ASSESSMENT;
        insert app;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt;
        
        Test.startTest();
        try {
            CustomerServiceUtility.getSRDocDetail('');
            CustomerServiceUtility.getSalesOrderDetailWithSR('');
            CustomerServiceUtility.getServiceRequestDetail('');
              CustomerServiceUtility.getAppointmentDetail('');
        //    ContentVersion result = CustomerServiceUtility.getContentVersion(document.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}