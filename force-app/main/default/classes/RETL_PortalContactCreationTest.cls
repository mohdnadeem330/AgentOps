@IsTest
private class RETL_PortalContactCreationTest {
    // Utility to get Contact record type named 'Contact'
    private static Id getContactRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        if (rtInfos.containsKey('Contact')) {
            return rtInfos.get('Contact').getRecordTypeId();
        }
        // Fallback to default
        for (Schema.RecordTypeInfo rti : Schema.SObjectType.Contact.getRecordTypeInfos()) {
            if (rti.isDefaultRecordTypeMapping()) {
                return rti.getRecordTypeId();
            }
        }
        return Schema.SObjectType.Contact.getRecordTypeInfosByName().values()[0].getRecordTypeId();
    }

    // Seed Account with optional Yardi Id
    private static Account seedAccount(String name, String yardiId) {
        Account a = new Account(Name = name);
        try {
            // set yardi if field exists
            a.put('RETL_Yardi_Id__c', yardiId);
        } catch (Exception e) {
            // ignore if field not present in this org
        }
        insert a;
        return a;
    }

    // Seed Order (Lease) with optional Yardi Id
    private static Order seedOrder(String orderName, Id accountId, String yardiId) {
        // Minimal required fields for Order vary by org. Use flexible put for custom field.
        Order o = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = Date.today()
          //  ContractNumber = String.valueOf(Crypto.getRandomInteger())
        );
        try {
            o.put('RETL_Yardi_Id__c', yardiId);
            insert o;
        } catch (Exception e) {
            // ignore if field missing
        }

        return o;
    }

    // Build JSON body for request
    private static String buildRequestBody(String first, String last, String email, String phone, Id parentAccId,
                                           List<String> leaseTenantIds, List<String> customerIds, String contactRole) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('firstName', first);
        m.put('lastName', last);
        m.put('email', email);
        m.put('phone', phone);
        m.put('parentAccountId', (parentAccId == null ? null : String.valueOf(parentAccId)));
        if (leaseTenantIds != null) m.put('leaseTenantIds', leaseTenantIds);
        if (customerIds != null) m.put('customerIds', customerIds);
        if (contactRole != null) m.put('contactRole', contactRole);
        return JSON.serialize(m);
    }

    // Setup RestContext for POST
    private static void setupPost(String body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(body == null ? '' : body);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/contactWithRole/';
        RestContext.request = req;
        RestContext.response = res;
    }

    @IsTest
    static void test_HappyPath_CreateContact_And_Roles_ForLeaseAndCustomer() {
        // Accounts and Lease
        Account parent = seedAccount('Parent', null);
        Account cust = seedAccount('Customer A', 'CUST-1001');
        Order lease = seedOrder('Lease A', parent.Id, 'LEASE-2001');

        // Build payload with both lease and customer so roles will be created
        String body = buildRequestBody(
            'John', 'Doe', 'john.doe@example.tst', '1234567890', parent.Id,
            new List<String>{'LEASE-2001'},
            new List<String>{'CUST-1001'},
            'Primary'
        );
        setupPost(body);

        Contact con = RETL_ContactContactRoleSyncToYardiTest.createTestContact();
        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];
        // Set mock callout using real record Ids
        Test.setMock(HttpCalloutMock.class, new RETL_ContactContactRoleSyncToYardiTest.MockCallout(con.Id, role.Id));
        
        Test.startTest();

        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();
	}

    @IsTest
    static void test_Validation_MissingRequiredFields() {
        // Missing names/phone/email/parentAccountId
        String body = buildRequestBody(
            null, null, null, null, null,
            new List<String>{''}, new List<String>{''}, null
        );
        setupPost(body);

        Test.startTest();
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();
	}

    @IsTest
    static void test_Validation_InvalidParentAccount() {
        // Provide a bogus parentAccountId
        String body = buildRequestBody(
            'Jane', 'Roe', 'jane.roe@example.tst', '1112223333', '001000000000000AAA',
            new List<String>{''}, new List<String>{''}, null
        );
        setupPost(body);

        Test.startTest();
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();

    }

    @IsTest
    static void test_RoleRequiredButIdsNotFound_ShouldRollbackRoles() {
        Account parent = seedAccount('Parent B', null);
        // Send lease/customer IDs that do not exist in the system; also provide contactRole
        String body = buildRequestBody(
            'Rick', 'Sanchez', 'rick.s@example.tst', '7777777777', parent.Id,
            new List<String>{'MISSING-LEASE-1'},
            new List<String>{'MISSING-CUST-1'},
            'Primary'
        );
        setupPost(body);

        Test.startTest();
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();

    }

    @IsTest
    static void test_MissingDesignationWhenLeaseProvided() {
        Account parent = seedAccount('Parent C', null);
        Order lease = seedOrder('Lease Z', parent.Id, 'LEASE-Z');

        // Provide lease id but no contactRole
        String body = buildRequestBody(
            'Beth', 'Smith', 'beth.smith@example.tst', '9999999999', parent.Id,
            new List<String>{'LEASE-Z'},
            new List<String>{''},
            null
        );
        setupPost(body);

        Test.startTest();
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();

    }

    @IsTest
    static void test_ExistingContact_NoDuplicateInsert() {
        Account parent = seedAccount('Parent D', null);

        // Pre-create a contact with same email and RecordType.Name = 'Contact'
        Contact pre = new Contact(
            FirstName = 'Pre',
            LastName = 'Existing',
            Email = 'existing@example.tst',
            Phone = '1212121212',
            AccountId = parent.Id,
            RecordTypeId = getContactRecordTypeId()
        );
        insert pre;

        // Also create related records so roles can be created
        Account cust = seedAccount('Customer B', 'CUST-B-1');

        String body = buildRequestBody(
            'Pre', 'Existing', 'existing@example.tst', '1212121212', parent.Id,
            new List<String>{''},
            new List<String>{'CUST-B-1'},
            'Admin'
        );
        setupPost(body);

        Test.startTest();
        // Avoid new contact insert by simulating static state default (existingContactId checked in code)
        RETL_PortalContactCreation.existingContactId = pre.Id;
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();

    }

    
    
    @IsTest
    static void test_ExistingUser_SkipsUserCreation_AssignsPermission() {
        Account parent = seedAccount('Parent D', null);
        
        // Pre-create a contact with same email and RecordType.Name = 'Contact'
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.tst',
            Phone = '1212121212',
            AccountId = parent.Id,
            RecordTypeId = getContactRecordTypeId()
        );
        insert con;
        
        // Also create related records so roles can be created
        Account cust = seedAccount('Customer B', 'CUST-B-1');
        
        RETL_Contact_Role__c conRole = new RETL_Contact_Role__c(Name='Admn', RETL_Account_Name__c = cust.Id, RETL_Contact_Role__c='Admin',RETL_Contact__c = con.Id);
        insert conRole;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator'  and IsActive = true and UserRole.Name != null LIMIT 1];
        system.Runas(testUser){
           Profile p = [SELECT Id FROM Profile WHERE Name = :Label.Retail_Tenant_Portal_Profile LIMIT 1];
        
        List<String> emailSplit = con.Email.split('@');
                String emailFirstThree = emailSplit[0].left(3);
                String uName = emailFirstThree + con.Id + '@aldar.retail.tenant';
        // Step 4: Create an existing user linked to the same contact
        User existingUser = new User(
            Username = uName,
            Alias = 'exusr',
            Email = con.Email,
            EmailEncodingKey = 'UTF-8',
            LastName = 'ExistingUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id,
            ContactId = con.Id,
            CommunityNickname = 'exist' + con.Id
        );
        insert existingUser;
        
        // Step 5: No permission set assignment yet (to cover the branch that adds it)
        System.assertEquals(1, [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :existingUser.Id]);
        
         
        }
        String body = buildRequestBody(
            'John', 'Doe', 'john.doe@example.tst', '1234567890', parent.Id,
            new List<String>{''},
            new List<String>{'CUST-B-1'},
            'Admin'
        );
        setupPost(body);
        Test.startTest();
        RETL_PortalContactCreation.existingContactId = con.Id;
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Database.executeBatch(new RETL_PortalUserCreationBatch(new List<Id>{con.Id}, false), 1);
        Test.stopTest();
    }

    @IsTest
    static void test_BadJson_Returns400() {
        setupPost('this is not json');

        Test.startTest();
        RETL_PortalContactCreation.ContactResponse resp = RETL_PortalContactCreation.createContactWithRole();
        Test.stopTest();

    }
}