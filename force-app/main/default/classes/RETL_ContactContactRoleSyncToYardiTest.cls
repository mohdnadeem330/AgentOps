@IsTest
public class RETL_ContactContactRoleSyncToYardiTest {

    // Mock class to simulate MuleSoft HTTP responses dynamically
    public class MockCallout implements HttpCalloutMock {
        private Id contactId;
        private Id roleId;

        public MockCallout(Id contactId, Id roleId){
            this.contactId = contactId;
            this.roleId = roleId;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '{' +
                '"firstName":"John",' +
                '"lastName":"Doe",' +
                '"email":"john.doe@test.com",' +
                '"phone":"1234567890",' +
                '"parentAccountId":"001000000000001",' +
                '"sfRefContactId":"' + contactId + '",' +
                '"country":"USA",' +
                '"yardiContactCode":"Y12345",' +
                '"contactAssociations":[{' +
                    '"Yardi_Contact_Code":"Y12345",' +
                    '"Y_ContactAssociation_Id":"YARDI_ASSOC_001",' +
                    '"Status":"Success",' +
                    '"ErrorMessage":null,' +
                    '"SF_ContactAssociation_Id":"' + roleId + '"' +
                '}]' +
            '}';
            res.setBody(body);
            return res;
        }
    }

    // Utility method to create a Contact and a Contact Role
    public static Contact createTestContact() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Phone = '1234567890',
            AccountId = acc.Id
            //MailingCountry = 'USA'
        );
        insert con;

        RETL_Contact_role__c role = new RETL_Contact_role__c(
            RETL_Contact__c = con.Id,
            RETL_Contact_role__c = 'Primary',
            RETL_Account_Name__c = acc.Id,
            RETL_Primary__c = true
        );
        insert role;

        return con;
    }
    
    @IsTest
    static void testPushToYardiAndUpdate_Success() {
        Test.startTest();

        Contact con = createTestContact();
        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];

        // Set mock callout using real record Ids
        Test.setMock(HttpCalloutMock.class, new MockCallout(con.Id, role.Id));

        // Call synchronous method
        RETL_ContactAndContactRoleSyncToYardi.pushToYardiAsync(con.Id, true);
        
        Test.stopTest();
        // Verify Contact update
        Contact updatedCon = [SELECT RETL_Yardi_Id__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Y12345', updatedCon.RETL_Yardi_Id__c, 'Contact Yardi Id should be updated');

        // Verify Role update
        RETL_Contact_role__c updatedRole = [SELECT RETL_Yardi_Id__c FROM RETL_Contact_role__c WHERE Id = :role.Id];
        System.assertEquals('YARDI_ASSOC_001', updatedRole.RETL_Yardi_Id__c, 'Contact Role Yardi Id should be updated');

        
    }

    @IsTest
    static void testPushToYardiAsync() {
        Test.startTest();

        Contact con = createTestContact();
        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];

        // Set mock callout for future method
        Test.setMock(HttpCalloutMock.class, new MockCallout(con.Id, role.Id));

        // Call future method
        RETL_ContactAndContactRoleSyncToYardi.pushToYardiAsync(con.Id, true);

        Test.stopTest();

        // Verify updates after future execution
        Contact updatedCon = [SELECT RETL_Yardi_Id__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Y12345', updatedCon.RETL_Yardi_Id__c);

        RETL_Contact_role__c updatedRole = [SELECT RETL_Yardi_Id__c FROM RETL_Contact_role__c WHERE Id = :role.Id];
        System.assertEquals('YARDI_ASSOC_001', updatedRole.RETL_Yardi_Id__c);
    }

    @IsTest
    static void testPushToYardiAndUpdate_NullContactId() {
        Test.startTest();

        try {
            RETL_ContactAndContactRoleSyncToYardi.pushToYardiAndUpdate(null, true);
            System.assert(false, 'Expected CustomException not thrown');
        } catch (RETL_ContactAndContactRoleSyncToYardi.CustomException e) {
            System.assertEquals('Contact Id cannot be null.', e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testBuildContactWrapper() {
        Contact con = createTestContact();

        RETL_ContactAndContactRoleSyncToYardi.YardiContactRequestWrapper wrapper =
            RETL_ContactAndContactRoleSyncToYardi.buildContactWrapper(con.Id);

        System.assertEquals(con.FirstName, wrapper.firstName);
        System.assertEquals(con.LastName, wrapper.lastName);
        System.assertEquals(con.Id, wrapper.sfRefContactId);
        System.assert(wrapper.contactAssociations.size() > 0, 'Wrapper should contain at least one contact association');
    }
}