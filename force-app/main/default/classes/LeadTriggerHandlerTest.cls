//sales
@isTest
private class LeadTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        Test.startTest();
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232376');
        personAcc.PersonEmail = 'dupecheck_0001@testemail.com';
        insert personAcc;
        List<Group> brokerQueue = [select id,name,developerName from group where type='Queue' and Name=:Constants.BROKER_QUEUE];
        
        // Create Lead From Account Record 
        Lead leadRec = TestObjectsFactory.getLeadRecord(1234562461,'Person');
        leadRec.FirstName = 'broker Lead';
        leadRec.LastName = 'broker Lname';
        leadRec.Email = 'dupecheck_0001@testemail.com';
        leadRec.MobilePhone = '9898445566';
        leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
        leadRec.BuyRent__c = 'Rent' ;
        leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
        leadRec.Project__c = 'Al Bandar Plaza';
        leadRec.CustomerBudget__c = '25K-AED 50K';
        leadRec.LeadSource = 'Broker Portal';
        leadRec.EnquiryCategory__c = 'Exhibition';
        leadRec.EnquiryTrigger__c = 'Cityscape-Abu Dhabi';
        leadRec.Status = Constants.WORKING_LEAD;
        leadRec.ExistingAccount__c = personAcc.Id;
        leadRec.OwnerId = brokerQueue[0].Id;
        insert leadRec;
        Test.stopTest();

        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Mamsha Gardens';
        insert proj;
        
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('25083');
        newUnit.Status__c = 'Available';
        newUnit.Project__c = proj.Id;
        newUnit.DigitalSales__c = true;
        insert newUnit;
    }
    
    @isTest
    public static void explicitCallToMethods (){
        Test.startTest();
        
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        
        System.runAs(salesManager) {
            try{
                Utilities.userDetail = null;
                LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
                
                User userDetail = Utilities.getLoggedInUserDetail();
                Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
                leadRec2.LeadSource = 'Direct Call';
                leadRec2.EnquiryCategory__c = 'Aldar Employees';
                leadRec2.EnquiryTrigger__c = 'Provis';
                leadRec2.CountryOfResidence__c = 'United Arab Emirates';
                insert leadRec2;
              //  leadRec2.Status = Constants.QUALIFIED;
               // Update leadRec2;
                system.debug('++leadRec2 '+leadRec2.Status);
                LeadTriggerhandler lth = new LeadTriggerhandler();
                lth.qualifiedLeadsProcessing(new Map<Id,Lead>{leadRec2.Id => leadRec2});
                lth.retiredLeadsProcessing(new Map<Id,Lead>{leadRec2.Id => leadRec2});
                //            LeadTriggerhandler.checkAndCreateTask(new Map<Id,Lead>{leadRec2.Id => leadRec2});
                LeadTriggerhandler.updateExistingAccounts(new List<Lead>{leadRec2});
             ECSS_LeadTriggerHelper.LeadRotation(new List<Lead>{leadRec2},true);
                //            LeadTriggerHandler.leadUpdateTasksFuture(newLead1.Id);
            }catch(Exception ex){
                System.debug('Exception Occured' + ex.getMessage());
            }            
        }
        Test.stopTest();
    }
    
    
    @isTest
    public static void createLeadAsCCA (){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
        User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca');
        System.runAs(cca) {
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
            
            User userDetail = Utilities.getLoggedInUserDetail();
            Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = '800-Aldar';
            leadRec2.EnquiryCategory__c = 'Aldar Database';
            leadRec2.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadRec2.ECSS_EmiratesId__c = '784200155555552';
            insert leadRec2;
            System.debug('leadRec2: '+ leadRec2);
            
            TriggerHandler.processedIds = new Set<Id>();
            Lead newLead = new Lead();
            
            newLead.Id = leadRec2.Id;
            // Added By Moh Sarfaraj for ASF-1782 starts
            Appointment__c appt = new Appointment__c();
            appt.Lead__c = leadRec2.Id;
            appt.Date__c = System.Today();
            insert appt;
            // Added By Moh Sarfaraj for ASF-1782 end
            newLead.Status = Constants.QUALIFIED;
            
            Task taskForLead = TestObjectsFactory.getLeadActivity(newLead.Id);
            taskForLead.CustomerResponse__c = 'Customer Reached';
            update taskForLead;
            
            update newLead;
            Unit__c unit = TestObjectsFactory.unitDataSetup('Balghaiylam');
            insert unit;
            Lead leadRec3 = TestObjectsFactory.getLeadRecord(5,'Person');
            leadRec3.LeadSource = '800-Aldar';
            leadRec3.EnquiryCategory__c = 'Aldar Database';
            leadRec3.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadRec3.Project__c = 'Balghaiylam';
            leadRec3.Unit__c = unit.Id;
            leadRec3.ECSS_EmiratesId__c = '784200155555552';
           insert leadRec3;
             ECSS_LeadTriggerHelper.LeadRotation(new List<Lead>{leadRec3},true);
             ECSS_LeadTriggerHelper.verifyPhoneNumbers(new List<Lead>{leadRec3},null);

            TriggerHandler.processedIds = new Set<Id>();
            Lead newLead1 = new Lead();
            newLead1.Id = leadRec3.Id;
            newLead1.Status=Constants.RETIRED;
            newLead1.RetiredReason__c = Constants.LEAD_LOST_NO_REAL_POTENTIAL;
            newLead1.RetirementComments__c =  Constants.DUPLICATE_LEAD;

            Task taskForLead1 = TestObjectsFactory.getLeadActivity(newLead1.Id);
            taskForLead1.CustomerResponse__c = 'Customer Reached';
            
            update taskForLead1;
            
            update taskForLead1;
            TriggerHandler.processedIds = new Set<Id>();
           update newLead1;
            
            map<id,lead> leadRecords = new map<id,lead>();
            List<Lead> lstLeads = new List<Lead>();
            leadRecords.put(leadRec3.Id,leadRec3);
            lstLeads.add(leadRec3);
            try{
                LeadTriggerHandler.checkAndCreateTask(leadRecords);
            }catch(Exception ex){
                System.debug('Exception Occured' + ex.getMessage());
            }
            try{
                LeadTriggerHandler.updateExistingAccounts(lstLeads);
            }catch(Exception ex){
                System.debug('Exception Occured' + ex.getMessage());
            }
            LeadTriggerHelper.populateUniqueKeyForResale(leadRec3);
            LeadTriggerHelper.getSalesOrdersForUnits(new Set<Id>{leadRec3.Id});
            LeadTriggerHelper.assignResaleLeads(new List<Lead>{leadRec3});
        }
        Test.stopTest();
        
    }
    
      @isTest
    public static void createLead1(){

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
        User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca');
        System.runAs(cca) {
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();

            User userDetail = Utilities.getLoggedInUserDetail();
            Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = '800-Aldar';
            leadRec2.EnquiryCategory__c = 'Aldar Database';
            leadRec2.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadrec2.ECSS_EmiratesId__c = '784200155555552';
            insert leadRec2;
            System.debug('leadRec2: '+ leadRec2);
            

             ECSS_LeadTriggerHelper.LeadRotation(new List<Lead>{leadRec2},true);
             ECSS_LeadTriggerHelper.verifyPhoneNumbers(new List<Lead>{leadRec2},null);


        }
        Test.stopTest();
        
    }
    
    @isTest
    public static void createLeadAsSalesManager (){
        Test.startTest();
        
        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        Account personAcc1 = [SELECT Id FROM Account WHERE PersonEmail = 'dupecheck_0001@testemail.com' LIMIT 1];
        insert salesManager;
        List<PermissionSet> pckgPermissionSet = [SELECT Id FROM PermissionSet WHERE Name IN ('THYNK_API_Read_Write','Thynk_PMS_Connect_User','Thynk_PMS_Connect_Admin')];
        List<PermissionSetAssignment> prSetAssignment = new List<PermissionSetAssignment>();
        for(PermissionSet perSet: pckgPermissionSet){
            PermissionSetAssignment permissionSetAssignment1 = new PermissionSetAssignment();
            permissionSetAssignment1.AssigneeId = salesManager.Id;
            permissionSetAssignment1.PermissionSetId = perSet.Id;
           	prSetAssignment.add(permissionSetAssignment1);
        }
        if(prSetAssignment.size()>0)
        {
            insert prSetAssignment;
        }
        //Account personAcc = [SELECT Id FROM Account WHERE PersonEmail = 'dupecheck_0001@testemail.com' LIMIT 1];
        System.runAs(salesManager) {
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
            personAcc.Email__c = 'Henry.Wong1@gmail.com';   
            personAcc.MobileCountryCode__pc = '971' ;
            personAcc.MobilePhone__pc = '52887687' ;
            personAcc.Emirates_ID__c = '784200155555552';
            insert personAcc;
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
            
            User userDetail = Utilities.getLoggedInUserDetail();
            Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = 'Direct Call';
            leadRec2.EnquiryCategory__c = 'Aldar Employees';
            leadRec2.EnquiryTrigger__c = 'Provis';
            leadRec2.ExistingAccount__c = personAcc.Id;
            leadRec2.ECSS_EmiratesId__c = '784200155555552';
            insert leadRec2;
            
            TriggerHandler.processedIds = new Set<Id>();
            Lead newLead1 = new Lead();
            newLead1.Id = leadRec2.Id;
            newLead1.Status=Constants.QUALIFIED;
            
            Task taskForLead1 = TestObjectsFactory.getLeadActivity(newLead1.Id);
            taskForLead1.CustomerResponse__c = 'Customer Reached';
           update taskForLead1;
            
            //leadRec2.IsConverted = true;
            //leadRec1.ExistingAccount__c = personAccDup.Id;
            //update leadRec2;
                       
            LeadTriggerHandler.updateExistingAccounts(new List<Lead>{leadRec2});
            
            //            LeadTriggerHandler.leadUpdateTasksFuture(newLead1.Id);
            
        }
        Test.stopTest();
    }
    
    @isTest
    public static void createLeadAsIntegrationProfile (){
        Test.startTest();
        User integrationProfile = TestObjectsFactory.getUserRecord(Constants.INTEGRATION_PROFILE, 'integrationProfile');
        insert integrationProfile;
        System.runAs(integrationProfile) {
            
            
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStatusCode(200);
            mock.setStaticResource('GetBitlyShortenURLSuccess');
            Test.setMock(HttpCalloutMock.class, mock);
            
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
            
            User userDetail = Utilities.getLoggedInUserDetail();
            System.debug('Test class 2 userDetail: '+ userDetail);
            Lead leadRec3 = TestObjectsFactory.getLeadRecord(4,'Person');
            leadRec3.LeadSource = 'Online';
            leadRec3.EnquiryCategory__c = 'Aldar Database';
            leadRec3.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadRec3.ECSS_EmiratesId__c = '784200155555552';
            System.debug('leadRec3: '+ leadRec3);
            insert leadRec3;
            System.debug('ownerId: '+ leadRec3.OwnerId);
            
            User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
            System.runAs(systemAdmin) {
                User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca');
                insert cca;
                
                TriggerHandler.processedIds = new Set<Id>();
                Utilities.userDetail = null;
                LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();
                userDetail = Utilities.getLoggedInUserDetail();
                
                Lead newLead = new Lead();
                newLead.Id = leadRec3.Id;
                newLead.OwnerId = cca.Id;
                update newLead;
                System.debug('leadRec3: after'+ newLead);
                System.debug('ownerId: '+ newLead.OwnerId);
            }
            
            
            
        }
        
        Test.stopTest();
    }
    

    @isTest
    public static void testLeadInsertUpdate (){
        
        
        Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
        
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        personAcc.MobilePhone__pc = '9898445566';
        personAcc.Emirates_ID__c = '784200155555552';
        insert personAcc;
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        orgAcc.Emirates_ID__c = '784200155555552';
        insert orgAcc;
        
        // Create Lead From Account Record
        Lead leadRec = TestObjectsFactory.getLeadRecord(1234562230,'Person');
        leadRec.ExistingAccount__c = personAcc.Id;
        leadRec.IsCreateFromExistingAccount__c = true;
        leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
        leadRec.BuyRent__c = 'Rent' ;
        leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
        leadRec.Project__c = 'Al Bandar Plaza';
        leadRec.CustomerBudget__c = '25K-AED 50K';
        leadRec.LeadSource = 'Online';
        leadRec.EnquiryCategory__c = 'Aldar Database';
        leadRec.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec.Status = Constants.WORKING_LEAD;
        leadRec.ECSS_EmiratesId__c = '784200155555552';
        insert leadRec;
        
        LeadTriggerHandler.leadUpdateTasks(new List<Id>{leadRec.Id});
        TriggerHandler.processedIds = new Set<Id>();
        
        Lead leadRec1 = TestObjectsFactory.getLeadRecord(2,'Organization');
        leadRec1.ExistingAccount__c = personAcc.Id;
        leadRec1.IsCreateFromExistingAccount__c = true;
        leadRec1.AssignToRoundRobin__c = true;
        leadRec1.LeadSource = 'Online';
        leadRec1.EnquiryCategory__c = 'Aldar Websites';
        leadRec1.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec1.Offer1__c = 'Q1 Support Promo 2021';
        leadRec1.ECSS_EmiratesId__c = '784200155555552';
        insert leadRec1;
        
        TriggerHandler.processedIds = new Set<Id>();
        
        Account personAccDup = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        
        Lead leadRecDup = TestObjectsFactory.getLeadRecord(2,'Person');
        leadRecDup.LeadSource = 'Online';
        leadRecDup.EnquiryCategory__c = 'Aldar Database';
        leadRecDup.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRecDup.ECSS_EmiratesId__c = '784200155555552';
        
        personAccDup.FirstName = leadRecDup.FirstName;
        personAccDup.MiddleName = leadRecDup.MiddleName;
        personAccDup.LastName = leadRecDup.LastName;
        personAccDup.PersonEmail = leadRecDup.Email;
        personAccDup.MobilePhone__pc = '9898989898';
        personAccDup.PersonMobilePhone = leadRecDup.MobileCountryCode__c + leadRecDup.MobileNumber1__c;
        personAccDup.Emirates_ID__c = '784200155555552';
        insert personAccDup;
        System.debug('personAccDup.UniqueKey__c: '+ personAccDup.UniqueKey__c);
        
        
        Opportunity opportunity = TestObjectsFactory.getOpportunityRecord(personAccDup.Id);
        opportunity.SaleType__c = 'New Sale';
        insert opportunity;
        Test.startTest();
        insert leadRecDup;
        
        TriggerHandler.processedIds = new Set<Id>();
        
        Lead leadRecDup1 = TestObjectsFactory.getLeadRecord(2,'Person');
        leadRecDup1.NotForAssignment__c = false;
        leadRecDup1.LeadSource = 'Online';
        leadRecDup1.EnquiryCategory__c = 'Aldar Database';
        leadRecDup1.EnquiryTrigger__c = 'Aldar SMS Campaign';
        
        //insert leadRecDup1;
        //LeadTriggerHandler.leadUpdateTasksFuture(leadRecDup.Id);
        
        Document__c objDoc = new Document__c();
        objDoc.DocumentType__c = 'Aldar Signed SPA';
        objDoc.Account__c = personAccDup.Id;
        insert objDoc;
        
        leadRecDup1.IsConverted = true;
        leadRec1.ExistingAccount__c = personAccDup.Id;
        //update leadRecDup1;
                       
        
        //LeadTriggerHandler.updateExistingAccounts(new List<Lead>{leadRec1});
        
        Test.stopTest();
    } 
    
    
    @isTest
    public static void updateExistingAccountsTest(){
        // This code runs as the system user
        //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        //User dataMig = new User(Alias = 'standt', Email='standarduser@testorg.com', 
           // EmailEncodingKey='UTF-8', LastName='Data Migration', LanguageLocaleKey='en_US', 
           // LocaleSidKey='en_US', ProfileId = p.Id, 
            //TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1122@testorg.com');
        User dataMig = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        
        System.runAs(dataMig) {
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232376');
            personAcc.MobilePhone__pc = '9898445566';
            personAcc.Emirates_ID__c = '784200155555552';
            insert personAcc;
        
           // Create Lead From Account Record
            Lead leadRec = TestObjectsFactory.getLeadRecord(1234562461,'Person');
            leadRec.ExistingAccount__c = personAcc.Id;
            leadRec.IsCreateFromExistingAccount__c = true;
            leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
            leadRec.BuyRent__c = 'Rent' ;
            leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
            leadRec.Project__c = 'Al Bandar Plaza';
            leadRec.CustomerBudget__c = '25K-AED 50K';
            leadRec.LeadSource = 'Online';
            leadRec.EnquiryCategory__c = 'Aldar Database';
            leadRec.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadRec.Status = Constants.WORKING_LEAD;
            leadRec.OwnerId = dataMig.Id;
            leadRec.ECSS_EmiratesId__c = '784200155555552';
            insert leadRec;
            
            LeadTriggerHandler.updateExistingAccounts(new List<Lead> {leadRec});
        }
    }
    
    @isTest
    public static void fastTrackAccountsTest(){
        Test.startTest();
        User sysadmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        List<Group> brokerQueue = [select id,name,developerName from group where type='Queue' and Name=:Constants.BROKER_QUEUE];
        System.debug('QId** '+brokerQueue[0].Id);
        System.runAs(sysadmin) {
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232376');
            personAcc.MobilePhone__pc = '9898445566';
            personAcc.Emirates_ID__c = '784200155555552';
            insert personAcc;
            
            // Create Lead From Account Record 
            Lead leadRec = TestObjectsFactory.getLeadRecord(1234562461,'Person');
            leadRec.FirstName = 'broker Lead';
            leadRec.LastName = 'broker Lname';
            leadRec.Email = 'test123@aldar.com';
            leadRec.MobilePhone = '9898445566';
            leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
            leadRec.BuyRent__c = 'Rent' ;
            leadRec.ExistingAccount__c = personAcc.Id;
            leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
            leadRec.Project__c = 'Al Bandar Plaza';
            leadRec.CustomerBudget__c = '25K-AED 50K';
            leadRec.LeadSource = 'Broker Portal';
            leadRec.EnquiryCategory__c = 'Exhibition';
            leadRec.EnquiryTrigger__c = 'Cityscape-Abu Dhabi';
            leadRec.Status = Constants.WORKING_LEAD;
            leadRec.OwnerId = brokerQueue[0].Id;
            leadRec.ECSS_EmiratesId__c = '784200155555552';
            insert leadRec;  
            Account acc = LeadFastTrackAccountService.creatAccount(leadRec);
            Lead ldRec = [SELECT ExistingAccount__c FROM Lead WHERE Id=:leadRec.Id Limit 1];
            Assert.areNotEqual(ldRec.ExistingAccount__c, null);
            LeadFastTrackAccountService.updateFastTrackSentTime(new List<Id>{personAcc.Id});
        }
        Test.stopTest();
    }
    @isTest
    public static void fastTrackAccountsExceptionTest(){
        Test.startTest();
        try{
            LeadFastTrackAccountService.updateBrokerLeads(null);
            LeadFastTrackAccountService.updateAccount(null);
        }catch(Exception e){}
        Test.stopTest();
    }
    @isTest
    public static void fastTrackDuplicateAccountsTest(){
        Test.startTest();
        User sysadmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        List<Group> brokerQueue = [select id,name,developerName from group where type='Queue' and Name=:Constants.BROKER_QUEUE];
        System.debug('QId** '+brokerQueue[0].Id);
        System.runAs(sysadmin) {
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232376');
            personAcc.PersonEmail = 'dupecheck_001@testemail.com';
            personAcc.MobilePhone__pc = '9898445566';
            personAcc.Emirates_ID__c = '784200155555552';
            insert personAcc;
            
            // Create Lead From Account Record 
            Lead leadRec = TestObjectsFactory.getLeadRecord(1234562461,'Person');
            leadRec.FirstName = 'broker Lead';
            leadRec.LastName = 'broker Lname';
            leadRec.Email = 'dupecheck_001@testemail.com';
            leadRec.MobilePhone = '9898445566';
            leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
            leadRec.BuyRent__c = 'Rent' ;
            leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
            leadRec.Project__c = 'Al Bandar Plaza';
            leadRec.CustomerBudget__c = '25K-AED 50K';
            leadRec.LeadSource = 'Broker Portal';
            leadRec.EnquiryCategory__c = 'Exhibition';
            leadRec.EnquiryTrigger__c = 'Cityscape-Abu Dhabi';
            leadRec.CountryOfResidence__c = 'United Arab Emirates';
            leadRec.Status = Constants.WORKING_LEAD;
            leadRec.OwnerId = brokerQueue[0].Id;
            leadRec.ECSS_EmiratesId__c = '784200155555552';
            
            insert leadRec;  
            leadRec.Status = Constants.QUALIFIED;
            Update leadRec;
            system.debug('++leadRec2 '+leadRec.Status);
            LeadTriggerhandler lth = new LeadTriggerhandler();
            lth.qualifiedLeadsProcessing(new Map<Id,Lead>{leadRec.Id => leadRec});
            lth.retiredLeadsProcessing(new Map<Id,Lead>{leadRec.Id => leadRec});
            //            LeadTriggerhandler.checkAndCreateTask(new Map<Id,Lead>{leadRec2.Id => leadRec2});
            leadRec.ExistingAccount__c = personAcc.Id;
            update leadRec;
            LeadTriggerhandler.updateExistingAccounts(new List<Lead>{leadRec});            
            LeadTriggerhandler.leadUpdateTasksFuture(leadRec.Id);
            LeadTriggerhandler.leadUpdateTasks(new List<Id>{leadRec.Id});
            Lead ldRec = [SELECT ExistingAccount__c FROM Lead WHERE Id=:leadRec.Id Limit 1];
            //Arvind test
            Assert.areNotEqual(ldRec.ExistingAccount__c, null);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void brokerDigitalSalesTest(){
        Test.startTest();
        // Fetch lead from testSetup
        Lead existingLead = [SELECT Id, InitiateDigitalBooking__c FROM Lead WHERE InitiateDigitalBooking__c = false LIMIT 1];
        // Update field to true (new value)
        existingLead.InitiateDigitalBooking__c = true;
        update existingLead;
        Test.stopTest();
    }

    @isTest
    public static void checkUnitStatusTest(){
       
        Test.startTest();
        Lead lead = [Select Id,Project__c,Unit__c,ExistingAccount__c From Lead Where FirstName = 'broker Lead' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c From Unit__c Where Status__c = 'Available' Limit 1];
        lead.InitiateDigitalBooking__c = true;
        lead.Unit__c = unit.Id;
        update lead;
        LeadDigitalBookingHelper.checkUnitStatus(new List<Lead>{lead},new List<Lead>{lead});
        Test.stopTest();
    }
    
 /*   @isTest
    public static void updateExistingAccountsTestd(){
        User dataMig = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(System.Label.ECSS_LeadRecordType_AlDarEstate).getRecordTypeId();
        
        System.runAs(dataMig) {
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account', true, '1232376');
            insert personAcc;
            
            // Create Lead From Account Record
            Lead leadRec = TestObjectsFactory.getLeadRecord(1234562461, 'Person');
            leadRec.ExistingAccount__c = personAcc.Id;
            leadRec.IsCreateFromExistingAccount__c = true;
            leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
            leadRec.BuyRent__c = 'Rent' ;
            leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
            leadRec.Project__c = 'Al Bandar Plaza';
            leadRec.CustomerBudget__c = '25K-AED 50K';
            leadRec.LeadSource = 'Online';
            leadRec.EnquiryCategory__c = 'Aldar Database';
            leadRec.EnquiryTrigger__c = 'Aldar SMS Campaign';
            leadRec.Status = Constants.WORKING_LEAD;
            leadRec.OwnerId = dataMig.Id;
            leadRec.RecordTypeId = recordTypeId;
            insert leadRec;
        }
        LeadTriggerHelper ld = new LeadTriggerHelper();
        Group leadAutoDialerQueue = ld.leadAutoDialerQueue;
        Group leadDuplicateQueue = ld.leadDuplicateQueue;
    }*/
}