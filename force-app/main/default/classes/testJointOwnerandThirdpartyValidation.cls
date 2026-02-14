@IsTest
public class testJointOwnerandThirdpartyValidation {
    
    
    @IsTest
    static void testMethod1() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        
        List<ValidationFields__mdt> metaList = [
            SELECT FieldAPI__c 
            FROM ValidationFields__mdt
            WHERE ObjectName__c = 'Account'
            AND RecordType__c = 'Person'
            AND Required_For_Account_Type__c LIKE '%Joint Owner%'
        ];
        System.assert(!metaList.isEmpty(), 'Metadata records should exist for validation');
        
        
        JointOwnerandThirdpartyValidation.ValidationResult resultJoint =
            JointOwnerandThirdpartyValidation.validateJointOwner(acc.Id);
        System.assertNotEquals(null, resultJoint, 'Should return a ValidationResult');
        
        JointOwnerandThirdpartyValidation.ValidationResult resultThird =
            JointOwnerandThirdpartyValidation.validateThirdParty(acc.Id);
        System.assertNotEquals(null, resultThird, 'Should return a ValidationResult');
        
        
        Id fakeId = Id.valueOf('001000000000000AAA');
        JointOwnerandThirdpartyValidation.ValidationResult result1 =
            JointOwnerandThirdpartyValidation.validateJointOwner(fakeId);
        System.assert(!result1.isValid, 'Expected validation failure');
        System.assert(result1.errorMessage.contains('Validation failed'), 'Error message check');
        
        Id fakeId2 = Id.valueOf('001000000000000AAA');
        JointOwnerandThirdpartyValidation.ValidationResult result2 =
            JointOwnerandThirdpartyValidation.validateThirdParty(fakeId2);
        System.assert(!result2.isValid, 'Expected validation failure');
        System.assert(result2.errorMessage.contains('Validation failed'), 'Error message check');
        
    }
    

 @IsTest
static void testDocumentsValidation() {
    // --- Scenario 1: All documents uploaded (Resident) ---
    Account accResident = TestObjectsFactory.getPersonAccountRecord();
    accResident.ResidentStatus__pc = 'Resident';
    insert accResident;

    List<Document__c> docsResident = new List<Document__c>{
        new Document__c(Account__c = accResident.Id, DocumentType__c='Passport Copy', Status__c='Uploaded'),
        new Document__c(Account__c = accResident.Id, DocumentType__c='Signed KYC Form', Status__c='Uploaded'),
        new Document__c(Account__c = accResident.Id, DocumentType__c='National ID Back Copy', Status__c='Uploaded'),
        new Document__c(Account__c = accResident.Id, DocumentType__c='National ID Front Copy', Status__c='Uploaded')
    };
    insert docsResident;

    ContentVersion cv = TestObjectsFactory.getContentVersion();
    cv.VersionData = Blob.valueOf('test');
    insert cv;

    for (Document__c doc : docsResident) {
        TestObjectsFactory.insertContentDocumentLink(doc.Id, cv.Id);
    }

    JointOwnerandThirdpartyValidation.ValidationResult result1 =
        JointOwnerandThirdpartyValidation.validateAccountDocumentsLWC(accResident.Id);
    System.assert(result1.isValid, 'All documents uploaded → should pass');

    // --- Scenario 2: Resident missing a document ---
    Account accResidentMissing = TestObjectsFactory.getPersonAccountRecord();
    accResidentMissing.ResidentStatus__pc = 'Resident';
    insert accResidentMissing;

    List<Document__c> docsMissing = new List<Document__c>{
        new Document__c(Account__c = accResidentMissing.Id, DocumentType__c='Passport Copy', Status__c='Uploaded'),
        new Document__c(Account__c = accResidentMissing.Id, DocumentType__c='Signed KYC Form', Status__c='Uploaded'),
        new Document__c(Account__c = accResidentMissing.Id, DocumentType__c='National ID Back Copy', Status__c='Uploaded')
        // Missing 'National ID Front Copy'
    };
    insert docsMissing;

    JointOwnerandThirdpartyValidation.ValidationResult result2 =
        JointOwnerandThirdpartyValidation.validateAccountDocumentsLWC(accResidentMissing.Id);
    System.assert(!result2.isValid, 'Missing document → should fail');
    System.assert(result2.errorMessage.contains('National ID Front Copy'));

    // --- Scenario 3: Non-Resident missing a document ---
    Account accNonResident = TestObjectsFactory.getPersonAccountRecord();
    accNonResident.ResidentStatus__pc = 'Non-Resident';
    insert accNonResident;

    List<Document__c> docsNonResident = new List<Document__c>{
        new Document__c(Account__c = accNonResident.Id, DocumentType__c='Passport Copy', Status__c='Uploaded')
        // Missing 'Signed KYC Form'
    };
    insert docsNonResident;
         

    JointOwnerandThirdpartyValidation.ValidationResult result3 =
        JointOwnerandThirdpartyValidation.validateAccountDocumentsLWC(accNonResident.Id);
    System.assert(!result3.isValid, 'Missing Non-Resident doc → should fail');
    System.assert(result3.errorMessage.contains('Signed KYC Form'));
}


    @isTest
static void testThirdPartyValidationError() {
    Test.startTest();
    
    // Create a fake account Id (not inserted)
    Id fakeAccId = Id.valueOf('001000000000000AAA');
    
    Sales_Order_Relationship__c sorError = new Sales_Order_Relationship__c(
        Account__c = fakeAccId,
        Relationship_Sub_Type__c = 'child',
        Expected_amount__c = 1000
    );

    try {
        insert sorError;
        System.assert(false, 'Expected insert to fail due to validation error');
    } catch (DmlException ex) {
        System.assert(ex.getMessage().contains('Validation failed'), 'Error message should contain validation failure');
    }

    Test.stopTest();
}

}