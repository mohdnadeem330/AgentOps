/*
*Created By     : Sanket Kumar
*Created Date   : 01/02/2023
*Description    : Test class for verify the mandatory documents.
*/
@isTest
private class DocumentVerificationWebserviceTest {
  /*
    * Scenario 1 : With Empty Value
    */
    static testmethod void testDocumentVerificationServiceWithEmptyBody() {
        Test.startTest();
        DocumentVerificationWebService.DocumentRequest documentRequest = new DocumentVerificationWebService.DocumentRequest();
        TestObjectsFactory.initializeRestContext(null, '/document/mandatorycheck');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(documentRequest));
        DocumentVerificationWebService.doPost();
        Test.stopTest();
    }
    
    /*
    * Scenario 1 : Verify With Account Id
    */
    static testmethod void testDocumentVerificationWithAccountId() {
        Test.startTest();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;
        
        DocumentVerificationWebService.DocumentRequest documentRequest = new DocumentVerificationWebService.DocumentRequest();
        documentRequest.accountId = orgAcc.Id;
        TestObjectsFactory.initializeRestContext(null, '/document/mandatorycheck');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(documentRequest));
        DocumentVerificationWebService.doPost();
        Test.stopTest();
    }
    
    /*
    * Scenario 1 : Verify With Opportunity Id
    */
    static testmethod void testDocumentVerificationServiceWithOpportunityId() {
        Test.startTest();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opportunityRecord;
        
        DocumentVerificationWebService.DocumentRequest documentRequest = new DocumentVerificationWebService.DocumentRequest();
        documentRequest.opportunityId = opportunityRecord.Id;
        TestObjectsFactory.initializeRestContext(null, '/document/mandatorycheck');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(documentRequest));
        DocumentVerificationWebService.doPost();
        Test.stopTest();
    }
    
    /*
    * Scenario 1 : Verify With Wrong Account Id
    */
    static testmethod void testDocumentVerificationServiceWithWrongAccountId() {
        Test.startTest();
        DocumentVerificationWebService.DocumentRequest documentRequest = new DocumentVerificationWebService.DocumentRequest();
        documentRequest.opportunityId = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-'1'.length()) + '1';
        TestObjectsFactory.initializeRestContext(null, '/document/mandatorycheck');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(documentRequest));
        DocumentVerificationWebService.doPost();
        Test.stopTest();
    }
}