@IsTest(seeAllData=false)
public class Com_ReusableMultiSelectLookupCtrl_Test {
    
    @testSetup
    public static void testDataCreation(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        String uniqueId = String.valueOf(System.now().getTime());
        
        // Generate a random number for additional uniqueness
        Integer randomNumber = (Integer) (Math.random() * 100000);
        
        // Construct a unique email address
        String uniqueEmail = 'testcontact' + uniqueId + randomNumber + '@example.com';
        
        User userObj = new User(
            Alias = 'testuser',
            Email = uniqueEmail, // Ensure this is unique
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUserTestClass',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            IsActive=true,
            UserName = uniqueEmail // Ensure this is unique
        );
        
        insert userObj;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Community_Admin_PS'];
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = userObj.Id,
            PermissionSetId = ps.Id
        );
        
        insert psa;
    }
    
    @IsTest
    static void test_returns_matches_and_excludes_selected() {
        User userObj = [Select Id from User where LastName = 'TestUserTestClass' LIMIT 1];
        
        system.runAs(userObj){
            List<Account> accs = new List<Account>{
                new Account(Name = 'John Doe'),
                    new Account(Name = 'Adam Port')
                    };
                        insert accs;
            
            List<String> selectedIds = new List<String>{ accs[1].Id }; 
                
                Test.startTest();
            List<SObject> results = Com_ReusableMultiSelectLookupCtrl.retriveSearchData(
                'Account',
                'Id, Name',
                null,
                '  Doe  ',          
                selectedIds
            );
            Test.stopTest();
            
            System.assertEquals(1, results.size(), 'Should return only John Doe');
            for (SObject so : results) {
                System.assertNotEquals(accs[1].Id, (Id)so.get('Id'), 'Excluded Id must not appear');
                System.assert(((String)so.get('Name')).contains('Doe'), 'Name should match search term');
            }
        }
        
        
    }
    
    @IsTest
    static void test_returns_empty_when_value_blank() {
        User userObj = [Select Id from User where LastName = 'TestUserTestClass' LIMIT 1];
        
        system.runAs(userObj){
            
            insert new Account(Name = 'Irrelevant');
            
            Test.startTest();
            List<SObject> results = Com_ReusableMultiSelectLookupCtrl.retriveSearchData(
                'Account',
                'Id, Name',
                null,
                '',                
                new List<String>()
            );
            Test.stopTest();
            
            System.assertEquals(0, results.size(), 'Blank search should return empty list');
        }
    }
    
    @IsTest
    static void test_handles_null_selected_list() {
        User userObj = [Select Id from User where LastName = 'TestUserTestClass' LIMIT 1];
        
        system.runAs(userObj){
            // Seed a record that should match the LIKE
            insert new Account(Name = 'NullPath Test');
            
            Test.startTest();
            List<SObject> results = Com_ReusableMultiSelectLookupCtrl.retriveSearchData(
                'Account',
                'Id, Name',
                null,          
                'NullPath',    
                null           
            );
            Test.stopTest();
            
            System.assert(results.size() > 0, 'Should return matches when value is provided and selectedRecId is null');
        }
    }
    
    @IsTest
    static void fetchLookuprecordTest() {
        User userObj = [Select Id from User where LastName = 'TestUserTestClass' LIMIT 1];
        
        system.runAs(userObj){
            // Seed a record that should match the LIKE
            insert new Account(Name = 'NullPath Test');
            
            Test.startTest();
            Com_ReusableMultiSelectLookupCtrl.SearchWrapper wrapperObj = new Com_ReusableMultiSelectLookupCtrl.SearchWrapper();
            wrapperObj.objectApiName = 'Account';
            wrapperObj.fieldApiName = 'Name';
            wrapperObj.otherFieldApiName = 'RecordTypeId';
            wrapperObj.searchString = 'Test Account';
            
            
            Com_ReusableMultiSelectLookupCtrl.fetchLookupRecords(wrapperObj);
            Test.stopTest();
        }
    }
    
}