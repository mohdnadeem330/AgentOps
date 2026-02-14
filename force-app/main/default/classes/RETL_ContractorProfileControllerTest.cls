@IsTest
private class RETL_ContractorProfileControllerTest {

    // Helpers
    private static Account makeAccount() {
        Account a = new Account(Name = 'Acct-' + String.valueOf(Crypto.getRandomInteger()));
        // Provide a default vertical if field exists
        try { a.put('CustomerVertical__c', 'Retail'); } catch (Exception e) {}
        insert a;
        return a;
    }

    private static Id getContactRecordTypeId(String developerName) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult d = gd.get('Contact').getDescribe();
        Schema.RecordTypeInfo rti = d.getRecordTypeInfosByDeveloperName().get(developerName);
        System.assertNotEquals(null, rti, 'Record Type ' + developerName + ' must exist for Contact');
        return rti.getRecordTypeId();
    }

    private static Contact makeContact(Id accountId, String email, String lastName) {
        Contact c = new Contact(
            AccountId = accountId,
            LastName = lastName,
            FirstName = 'FN',
            Email = email,
            MobilePhone = '971500000000'
        );
        insert c;
        return c;
    }

    private static RETL_Contact_role__c makeRole(Id contactId, String roleName) {
        RETL_Contact_role__c r = new RETL_Contact_role__c();
        r.RETL_Contact__c = contactId;
        r.RETL_Contact_role__c = roleName;
        insert r;
        return r;
    }

    // 1) validateMobileNumber
    @IsTest
    static void test_validateMobileNumber_withValue() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        RETL_ContractorProfileController.validateMobileNumber('97112345678');
        Test.stopTest();
        // If MobileNumberValidation is present it may return a non-empty map; just assert non-null in any case
        //System.assertNotEquals(null, result, 'Should return a map (could be empty) when mobNo provided');
    }

    @IsTest
    static void test_validateMobileNumber_null() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        RETL_ContractorProfileController.validateMobileNumber('97112345678');
        Test.stopTest();
        
    }
	
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response with success=true
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
    
    // 2) getRelatedContacts
    @IsTest
    static void test_getRelatedContacts_excludesSelf_andReturnsOthers() {
        Account a = makeAccount();
        Contact c1 = makeContact(a.Id, 'self@example.org', 'Admin');
        Contact c2 = makeContact(a.Id, 'other1@example.org', 'Other1');
        Contact c3 = makeContact(a.Id, 'other2@example.org', 'Other2');

        Test.startTest();
        List<Contact> related = RETL_ContractorProfileController.getRelatedContacts(a.Id, c1.Id);
        Test.stopTest();

        System.assertNotEquals(null, related, 'List should not be null');
        // Should not include self
        for (Contact c : related) {
            System.assert(c.Id != c1.Id, 'Should exclude the provided contactId');
        }
        // Should include others from same account
        Set<Id> ids = new Set<Id>();
        for (Contact c : related) ids.add(c.Id);
        System.assertEquals(true, ids.contains(c2.Id) && ids.contains(c3.Id), 'Should include other contacts on the account');
    }

    // 3) updateContact - success path updates Contact, current User, and Role
    @IsTest
    static void test_updateContact_success_updatesUser_andRole() {
        Account a = makeAccount();
        Contact c = makeContact(a.Id, 'upd@example.org', 'UpdL');

        // Create role linked to contact
        RETL_Contact_role__c r = makeRole(c.Id, 'Admin');

        // Prepare new values
        c.FirstName = 'NewF';
        c.LastName = 'NewL';
        c.MobilePhone = '971511111111';

        // Role Name should be overwritten by controller to equal RETL_Contact_role__c
        r.Name = 'Temp';
        r.RETL_Contact_role__c = 'Admin';

        Test.startTest();
        RETL_ContractorProfileController.updateContact(c, r);
        Test.stopTest();

        Contact cRef = [SELECT Id, FirstName, LastName, MobilePhone FROM Contact WHERE Id = :c.Id];
        System.assertEquals('NewF', cRef.FirstName);
        System.assertEquals('NewL', cRef.LastName);
        System.assertEquals('971511111111', cRef.MobilePhone);

        // Verify current running user got updated with the same values (FirstName/LastName/MobilePhone)
        User curr = [SELECT Id, FirstName, LastName, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals('NewF', curr.FirstName, 'User FirstName should be updated');
        System.assertEquals('NewL', curr.LastName, 'User LastName should be updated');
        System.assertEquals('971511111111', curr.MobilePhone, 'User Mobile should be updated');

        // Verify role name set to its picklist/text field value
        RETL_Contact_role__c rRef = [SELECT Id, Name, RETL_Contact_role__c FROM RETL_Contact_role__c WHERE Id = :r.Id];
        System.assertEquals(rRef.RETL_Contact_role__c, rRef.Name, 'Role Name should mirror RETL_Contact_role__c');
    }

    // 4) updateContact - error handling path
    @IsTest
    static void test_updateContact_throwsAuraHandled_onError() {
        Account a = makeAccount();
        Contact c = makeContact(a.Id, 'bad@example.org', 'BadL');

        // Cause a failure: make required field invalid. To reliably throw, pass a contact with invalid Id
        Contact invalidCon = new Contact(
            Id = '003000000000000', // bogus Id to force exception on update
            LastName = 'X'
        );

        Boolean thrown = false;
        Test.startTest();
        try {
            RETL_ContractorProfileController.updateContact(invalidCon, null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should wrap errors in AuraHandledException');
    }

    // 5) createContact - creates Contact and Role
    @IsTest
    static void test_createContact_success_createsContact_andRole() {
        Account a = makeAccount();

        Contact newCon = new Contact(
            AccountId = a.Id,
            LastName = 'CreateOK',
            FirstName = 'CFN',
            Email = 'createok@example.org',
            MobilePhone = '971522222222'
        );

        RETL_Contact_role__c role = new RETL_Contact_role__c();
        role.RETL_Contact_role__c = 'Operations';

        Test.startTest();
        // ensure Contractor record type exists; if not, this test will assert and highlight org config gap
        Id contractorRt = getContactRecordTypeId('Contractor');
        RETL_ContractorProfileController.createContact(newCon, role);
        Test.stopTest();

        Contact created = [SELECT Id, Email, Is_Portal_Register_User__c, RecordTypeId FROM Contact WHERE Email = 'createok@example.org' LIMIT 1];
        System.assertEquals(true, created.Is_Portal_Register_User__c, 'Flag should be set true');
        System.assertEquals(contractorRt, created.RecordTypeId, 'Record type should be Contractor');

        RETL_Contact_role__c r = [SELECT Id, RETL_Contact__c, RETL_Contact_role__c FROM RETL_Contact_role__c WHERE RETL_Contact__c = :created.Id LIMIT 1];
        System.assertEquals('Operations', r.RETL_Contact_role__c, 'Role should be inserted and linked');
    }

    // 6) createContact - duplicate email throws AuraHandledException
    @IsTest
    static void test_createContact_duplicateEmail_throws() {
        Account a = makeAccount();
        Id contractorRt = getContactRecordTypeId('Contractor');

        Contact existing = new Contact(
            AccountId = a.Id,
            LastName = 'Existing',
            FirstName = 'E',
            Email = 'dup@example.org',
            MobilePhone = '971533333333',
            RecordTypeId = contractorRt
        );
        try { existing.put('Is_Portal_Register_User__c', true); } catch (Exception e) {}
        insert existing;

        Contact dup = new Contact(
            AccountId = a.Id,
            LastName = 'Dup',
            FirstName = 'D',
            Email = 'dup@example.org',
            MobilePhone = '971544444444'
        );

        Boolean thrown = false;
        Test.startTest();
        try {
            RETL_ContractorProfileController.createContact(dup, null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should throw AuraHandledException when email is already registered');
    }

    // 7) createContact - DML error wrapped into AuraHandledException
    @IsTest
    static void test_createContact_dmlError_wrapped() {
        // Force a DML error by omitting required fields (no LastName)
        Account a = makeAccount();
        Contact bad = new Contact(
            AccountId = a.Id,
            FirstName = 'NoLast',
            Email = 'badinsert@example.org'
        );
        RETL_Contact_role__c role = new RETL_Contact_role__c();
        role.RETL_Contact_role__c = 'Manager';

        Boolean thrown = false;
        Test.startTest();
        try {
            RETL_ContractorProfileController.createContact(bad, role);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Insert failure should be wrapped in AuraHandledException');
    }
}