/**
* CommunicationControllerTest
*
* Test class for CommunicationController
*/
@isTest
private class CommunicationControllerTest{
    //Create setup data
    @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        orgAcc.AgencyStatus__c ='Active' ;
        insert orgAcc;
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        orgAcc2.AgencyStatus__c ='Active' ;
        insert orgAcc2;
        
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('test agency 1', '46757869898');
        insert testAccount;
        
        Contact testContact1 = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', 
                                           MobilePhone = '1234567890', AccountId = testAccount.Id, 
                                           BrokerType__c = 'Agent', AgentStatus__c = 'Active',
                                           RecordTypeId = ALD_Constants.BROKER_AGENT_RT);
        insert testContact1;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User testUser1 = new User(Username = 'aldar.john.doe@testBp2.com', Email = 'john.doe@test.com',
                                  LastName = 'Doe', 
                                  ContactId = testContact1.Id, IsActive = true, 
                                  LocaleSidKey = 'en_US', 
                                  LanguageLocaleKey ='en_US',
                                  Alias = 'new123', EmailEncodingKey='UTF-8', 
                                  TimeZoneSidKey='Asia/Dubai',
                                  ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1].Id);
        insert testUser1;
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
        Folder myfolder = [Select Id From Folder Where Name = 'AlDar' LIMIT 1 ];
        if(myfolder != null){
            Document document = new Document();
            document.Body = Blob.valueOf('Some_Text');
            document.ContentType = 'jpg';
            document.DeveloperName = 'my_document';
            document.IsPublic = true;
            document.Name = 'MyDocument';
            document.FolderId = myfolder.Id;
            document.Keywords = 'Broker';
            insert document;
        }
        
    }
    //Testing email communication with file
    @isTest static void testCommunication() {
        Contact conRecord = [select id,AccountId from Contact limit 1];
        User userRecord = [select id,AccountId from User where Username = 'aldar.john.doe@testBp2.com' limit 1];
        
        list<Account> agencies = CommunicationController.getAllAgency('','','', '');
        //System.assertEquals(agencies.isEmpty(),false);
        list<User> userList= new List<User>();
        userList = CommunicationController.getRelatedUsers(new list<String>{agencies[0].Id});
        //System.assertEquals(userList.isEmpty(),false);
        
        list<CommunicationTemplate__c> templateList= CommunicationController.getReletedCommunicationRecords(null);
        //System.assertEquals(templateList.isEmpty(),true);
        
        Account nonRegistered = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        //nonRegistered.recordTypeID=Constants.NON_REGISTERED_TYPE_ID ;
        //nonRegistered.Name=null;
        nonRegistered.AgencyStatus__c ='Active' ;
        insert nonRegistered;
        
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c='Test';
        template.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c='Test';
        template.Status__c='Published';
        template.Title__c='Test';
        template.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        insert template;
        
        Id bannerId =  [SELECT id, Name, Keywords FROM 
                        Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                        ORDER BY CreatedDate DESC limit 1].Id;
        
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{},new list<ID>{},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'',bannerId);
        CommunicationController.sendTestEmail(template,'test@test.com',bannerId);
        CommunicationController.sendToSpecificEmirateAllAgencies('','',template.Id, null,bannerId);
        
        System.runAs(userRecord) {
            CommunicationController.getCommunicationInbox('','');
            CommunicationController.getCommunicationInbox('Test','Test');
            CommunicationController.getCommunicationInbox('','Test');
            CommunicationController.getCommunicationInbox('Test','');
            
            CommunicationTemplate__c templateOutbox = new CommunicationTemplate__c();
            templateOutbox.HTMLBody__c='Test';
            templateOutbox.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
            templateOutbox.SuspensionStartDate__c = System.today().addDays(5);
            templateOutbox.SuspensionEndDate__c = System.today().addDays(5);
            templateOutbox.PlainTextBody__c='Test';
            templateOutbox.Status__c=CommunicationTemplate__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
            templateOutbox.Title__c='Test';
            templateOutbox.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
            insert templateOutbox;
        
            
            CommunicationController.getCommunicationOutbox('','');
            CommunicationController.getCommunicationOutbox('Test','Test');
            CommunicationController.getCommunicationOutbox('','Test');
            CommunicationController.getCommunicationOutbox('Test','');
            
            test.startTest();
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, true, 'test@gmail.com', false, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, true, false, null , false, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, false, null , true, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, false, null , true, '["NFT Agent"]', 'test2@gmail.com',bannerId);
            
        }
        //Insert document
        ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.jpg',
                    VersionData    = Blob.valueOf('Test Content'),
                    IsMajorVersion = true);
         insert contentVersion;

        contentVersion cv = [SELECT Id, ContentDocumentID FROM contentVersion where id =:contentVersion.Id limit 1];
        
        list<CommunicationController.FileResponse> fileData = new list<CommunicationController.FileResponse>();
        CommunicationController.FileResponse tempRec = new CommunicationController.FileResponse('Name',cv.ContentDocumentID);
        fileData.add(tempRec);
        CommunicationController.reparentCDL(fileData,template.id);
        tempRec = new CommunicationController.FileResponse();
        CommunicationController.getExistingCDL(template.id);
        agencies = CommunicationController.getAllAgency('aa','','', 'VIP');
        agencies = CommunicationController.getAllAgency('','aa','', 'VIP');
        CommunicationController.sendTestEmail(template,'test@test.com',bannerId);
        test.stopTest();
    }
    
    /*@isTest static void testBlock() {
        list<Account> agencies = CommunicationController.getAllAgency();
        
        Contact conRecord = [select id from Contact limit 1];        
        User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
        
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c='Test';
        template.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c='Test';
        template.Status__c=CommunicationTemplate__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
        template.Title__c='Title';
        template.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        insert template;
        
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userRecord.Id},new list<ID>{});
        test.startTest();
            CommunicationController.blockUnblockRelatedAccounts(new list<String>{template.Id},'Active');
        test.stopTest();
    }*/
    
    
    @isTest static void testMassCommunication()
    {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
        
        list<Account> agencies = CommunicationController.getAllAgency('','','','');
        //System.assertEquals(agencies.isEmpty(),false);
        list<User> userList= new List<User>();
        userList = CommunicationController.getRelatedUsers(new list<String>{agencies[0].Id});
        //System.assertEquals(userList.isEmpty(),false);
        
        list<CommunicationTemplate__c> templateList= CommunicationController.getReletedCommunicationRecords(null);
        //System.assertEquals(templateList.isEmpty(),true);
        
        Account nonRegistered = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        nonRegistered.AgencyStatus__c ='Active' ;
        insert nonRegistered;
        
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c='Test';
        template.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c='Test';
        template.Status__c='Published';
        template.Title__c='Test';
        template.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        template.MassCommunication__c= true;
        insert template;
        
        Id bannerId =  [SELECT id, Name, Keywords FROM 
                        Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                        ORDER BY CreatedDate DESC limit 1].Id;
        
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{},new list<ID>{},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'',bannerId);
        CommunicationController.updateUserSelection(template.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},true,'',bannerId);
        CommunicationController.sendTestEmail(template,'test@test.com',bannerId);
        CommunicationController.sendToSpecificEmirateAllAgencies('','',template.Id, null,bannerId);
        
        System.runAs(userRecord) {
            CommunicationController.getCommunicationInbox('','');
            CommunicationController.getCommunicationInbox('Test','Test');
            CommunicationController.getCommunicationInbox('','Test');
            CommunicationController.getCommunicationInbox('Test','');
            
            CommunicationTemplate__c templateOutbox = new CommunicationTemplate__c();
            templateOutbox.HTMLBody__c='Test';
            templateOutbox.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
            templateOutbox.SuspensionStartDate__c = System.today().addDays(5);
            templateOutbox.SuspensionEndDate__c = System.today().addDays(5);
            templateOutbox.PlainTextBody__c='Test';
            templateOutbox.Status__c=CommunicationTemplate__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
            templateOutbox.Title__c='Test';
            templateOutbox.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
            insert templateOutbox;
        
            
            CommunicationController.getCommunicationOutbox('','');
            CommunicationController.getCommunicationOutbox('Test','Test');
            CommunicationController.getCommunicationOutbox('','Test');
            CommunicationController.getCommunicationOutbox('Test','');
            
            test.startTest();
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, true, 'test@gmail.com', false, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, true, false, null , false, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, false, null , true, null, 'test2@gmail.com',bannerId);
            CommunicationController.sendEmailBrokerFilterCommunication(templateOutbox.Id, false, false, null , true, '["NFT Agent"]', 'test2@gmail.com',bannerId);
            test.stopTest();
        }
    }
    
}