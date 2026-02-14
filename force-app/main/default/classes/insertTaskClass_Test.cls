@isTest
private class insertTaskClass_Test {
    @isTest
    static void testInsertTaskMethod() {

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;
        
        User testUser = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'agencyUser@aldar.com');
        testUser.Email = UserInfo.getUserEmail();
        insert testUser;

        User ownr = testUser;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Date testDate = Date.newInstance(2024, 9, 28);
        String resultTasks = insertTaskClass.insertTaskMethod('ACCOUNT_ID', 'Test Account Contacts', 'Test Task', testUser.Email, 'High', testDate, 'Create Task');
        List<Task> createdTasks = new  List<Task>();
        Task newTask = new Task();
        newTask.WhatId = testAccount.Id;  
        newTask.Subject = 'Test Task';  
        newTask.OwnerId = ownr.Id;
        newTask.Priority = 'High'; 
        newTask.Status = 'Not Started';   
        newTask.IsReminderSet = true;
        newTask.ReminderDateTime = Datetime.now().addhours(24);      
        createdTasks.add(newTask);  
        insert createdTasks;
        Test.stopTest();
        
    }

    @isTest
    static void testInsertTaskMethod_ChangeOwner() {

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        Contact con1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        con1.PrimaryContact__c = true;
        update con1;
        
        User internalUser = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'agencyUser@aldar.com');
        internalUser.Email = UserInfo.getUserEmail();
        insert internalUser;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Date testDate = Date.newInstance(2024, 9, 28);
        String resultChangeOwner = insertTaskClass.insertTaskMethod('ACCOUNT_ID', 'Test Account Contacts', 'Test Task', internalUser.Id, 'High', testDate, 'Change Owner');
        String resultCreateTask = insertTaskClass.insertTaskMethod('ACCOUNT_ID', 'Test Account Contacts', 'Test Task', internalUser.Id, 'High', testDate, 'Create Tasks');
        insertTaskClass.Wrapper result = insertTaskClass.getColumnNames('Test Account Contact');
        Test.stopTest();
    }

        private class MockHttpResponseGenerator implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"reportMetadata": {"detailColumns": ["LAST_NAME", "TITLE", "ACCOUNT.NAME", "ACCOUNT_ID", "CONTACT_ID"]}, "factMap": {"T!T": {"rows": [{"dataCells": [{"label": "Test Contact", "value": "003000000000001"}, {"label": "-", "value": null}, {"label": "Test Account", "value": "001000000000001"}, {"label": "001000000000001", "value": "001000000000001"}, {"label": "003000000000001", "value": "003000000000001"}]}]}}, "reportExtendedMetadata": {"detailColumnInfo": {"LAST_NAME": {"label": "Last Name", "dataType": "string"}, "TITLE": {"label": "Title", "dataType": "string"}, "ACCOUNT.NAME": {"label": "Account Name", "dataType": "string"}, "ACCOUNT_ID": {"label": "Account ID", "dataType": "id"}, "CONTACT_ID": {"label": "Contact ID", "dataType": "id"}}}}');
                res.setStatusCode(200);
                return res;
            }
        }
}