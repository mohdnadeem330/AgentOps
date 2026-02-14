@isTest
public class UtilitiesWithoutSharingTest {

    //Create setupData
    @testSetup static void setupData() {
        // Create a user to act as current user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Property Consultant' LIMIT 1];
        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName = 'Leasing_Executive' LIMIT 1];
        PermissionSet prSet = [SELECT Id FROM PermissionSet WHERE Name = 'ECSS_Leasing_Permissions' LIMIT 1];
        List<PermissionSet> pckgPermissionSet = [SELECT Id FROM PermissionSet WHERE Name IN ('THYNK_API_Read_Write','Thynk_PMS_Connect_User','Thynk_PMS_Connect_Admin')];
        Group testGroup2 = new Group(Name='Test User', Type='Queue');
        insert testGroup2;
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = r.Id
        );
        insert u;
        
        PermissionSetAssignment perSetAssignment = new PermissionSetAssignment();
        perSetAssignment.PermissionSetId = prSet.Id;
        perSetAssignment.AssigneeId = u.Id;
        insert perSetAssignment;
        
        List<PermissionSetAssignment> prSetAssignment = new List<PermissionSetAssignment>();
        for(PermissionSet perSet: pckgPermissionSet){
            PermissionSetAssignment permissionSetAssignment1 = new PermissionSetAssignment();
            permissionSetAssignment1.AssigneeId = u.Id;
            permissionSetAssignment1.PermissionSetId = perSet.Id;
            prSetAssignment.add(permissionSetAssignment1);
        }
        if(prSetAssignment.size()>0)
        {
            insert prSetAssignment;
        }
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        
        System.runAs(u) {
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        orgAcc.UAEVATRegisterNumber__c = 'abcdqwerabcdqwe';
        insert orgAcc;
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc2;

        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__Customer__c=orgAcc.id;
        insert SR;

        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name ='Awaiting Approval';
        status1.HexaBPM__Code__c ='AWAITING_APPROVAL2';
        insert status1;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 1';
        ST.HexaBPM__Code__c = 'Require More Information';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        insert SRStep;
        
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Digital Signature by CCO';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.HexaBPM__Status__c = status1.id;
        step.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
        step.HexaBPM__Step_Notes__c = 'test area';
        step.HexaBPM__Step_No__c =30.0;
        step.ownerid = UserInfo.getUserId();
       // insert step; 
        
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
        
        

  

        
        
        try{
            Double db = UtilitiesWithoutSharing.getTotalNetAmounForDigitalSPA(docRecord);
        } catch(Exception e) {}
        }
    }
    
    @isTest
    static void convertPersonLead() {


        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;
        UtilitiesWithoutSharing.getMobileSobject(acc.Id,'Account');
        
        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        UtilitiesWithoutSharing.getMobileSobject(con.Id,'Contact');

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        UtilitiesWithoutSharing.unlockRecords(new set<Id>{con.Id});

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec;
        Lead leadRec2;

        User salesManager = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'salesManager');
        salesManager.ManagerID = UserInfo.getUserId();
        insert salesManager;
                Test.startTest();

        UtilitiesWithoutSharing.updateUserInFutureMethod(salesManager.Id,'Mr','SMfirstName','SMLastName','test@gmail.com','971 23','City',Constants.SALES_MANAGER);
        System.runAs(salesManager) {     
        
            leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec.LeadSource = 'Direct Call';
            leadRec.EnquiryCategory__c = 'Aldar Employees';
            leadRec.EnquiryTrigger__c = 'Provis';
            insert leadRec;
            UtilitiesWithoutSharing.getMobile(leadRec.Id);
            UtilitiesWithoutSharing.getMobileSobject(leadRec.Id,'Lead');
            //UtilitiesWithoutSharing.sentforApproval(acc.Id,'Test','Family/Relative');
            
            leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = 'Direct Call';
            leadRec2.EnquiryCategory__c = 'Aldar Employees';
            leadRec2.EnquiryTrigger__c = 'Provis';
       //     insert leadRec2;
        }
        try{
            Lead l = [SELECT Id,LeadNumber__c FROM Lead WHERE Id =:leadRec.Id ];
            UtilitiesWithoutSharing.convertLeadsInvocableMethod(new List<Id>{leadRec.Id});
            UtilitiesWithoutSharing.getConvertedOppBySearchLead(l.LeadNumber__c,'');

            //           UtilitiesWithoutSharing.convertLeadsInvocableMethod(new List<Id>{leadRec2.Id});
        }catch(Exception ex){
            
        }
        Test.stopTest();

    }

    @isTest
    static void convertLeadBySearchLead() {

        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PersonMobilePhone = '+918980676862';
        insert acc;

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        UtilitiesWithoutSharing.unlockRecords(new set<Id>{con.Id});

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Provis';
        insert leadRec;
        
        Test.startTest();
        
        UtilitiesWithoutSharing.checkduplicateEmail(acc.PersonEmail,acc.PersonMobilePhone);
        UtilitiesWithoutSharing.getduplicateAccountList(acc.Id);
        UtilitiesWithoutSharing.findDuplicateAccountsByEmirateIdPassport(null, acc.PassportNumber__pc,acc.Nationality__pc,String.valueOf(acc.PersonBirthdate));
        try{
        UtilitiesWithoutSharing.createMasterAccount(acc.Id, acc.Id);
        } catch(Exception ex){}
        try{
            UtilitiesWithoutSharing.sentforApproval(acc.Id,'Test','Family/Relative');
        } catch (Exception ex) {}
        try{
            UtilitiesWithoutSharing.findAccountsByEmailAndPhone(new Set<String>{acc.PersonEmail},new Set<String>{'+918980676862'});
        } catch (Exception ex) {}
        try{
            UtilitiesWithoutSharing.updateLead(leadRec);
        } catch (Exception ex) {}
        try {
            Lead leadRecord = [SELECT Id, Leadnumber__c FROM Lead WHERE Id =: leadRec.Id LIMIT 1];
            UtilitiesWithoutSharing.getConvertedOppBySearchLead(leadRecord.Leadnumber__c,'');
        } catch (Exception ex) {}

        try {
            List<WatsAppLinkGenesys__mdt> metadatas = [ SELECT DeveloperName, HSMTemplateId__c, name__c, flowId__c FROM WatsAppLinkGenesys__mdt ];//(List<WatsAppLinkGenesys__mdt>) JSON.deserialize( '', List<WatsAppLinkGenesys__mdt>.class );
            UtilitiesWithoutSharing.sendWhatsAppMessage(new Set<Id>{OrgAcc.Id}, 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', 'test', metadatas.get(0).DeveloperName);
        } catch (Exception ex) {}
        
        try{
            User sysAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'testUser');
            insert sysAdmin;
            
            System.runAs(sysAdmin) {
                Lead leadRec1 = TestObjectsFactory.getBrokerLeadRecord(1,'Person', 'Shams', null);
                leadRec1.LeadSource = 'Broker Portal';
                insert leadRec1;
                
                Lead ld = [SELECT Id, LeadNumber__c, LeadSource FROM Lead WHERE LeadSource = 'Broker Portal'];
                System.debug('?????'+ld.LeadNumber__c);
                String test = UtilitiesWithoutSharing.getConvertedOppBySearchLead(ld.LeadNumber__c, orgAcc.Id);
            }
        } catch(Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void convertOrgLead() {

        Test.startTest();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(2,'Organization');
        leadRec.OwnerId = UserInfo.getUserId();
        insert leadRec;
        

        try {
            UtilitiesWithoutSharing.convertLeadsInvocableMethod(new List<Id>{leadRec.Id});    
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }

    @isTest
    static void convertBrokerLead() {

        Test.startTest();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Account agency = TestObjectsFactory.getAgencyAccountRecord('Agency test','G123456789');
        insert agency;

        Contact con = TestObjectsFactory.contactDataSetup(agency.Id);

        Lead leadRec = TestObjectsFactory.getLeadRecord(4,'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Aldar Hospitality';
       // leadRec.BrokerAgent__c = con.Id;
       // leadRec.BrokerAgency__c = agency.Id;

        insert leadRec;

        leadRec.OwnerId = UserInfo.getUserId();
        update leadRec;

        UtilitiesWithoutSharing.convertLeadsInvocableMethod(new List<Id>{leadRec.Id});

        Test.stopTest();
    }
    
    @isTest
    static void callLeadMethods() {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRec = TestObjectsFactory.getLeadRecord(4,'Person');
        insert leadRec;
        
        Test.startTest();
        UtilitiesWithoutSharing.changeSentToYardiField(leadRec.Id);
        UtilitiesWithoutSharing.createUpdateLeadWithoutSharing(leadRec);
        UtilitiesWithoutSharing.convertLeadFromAppointment(leadRec.Id);
        Test.stopTest();
    }

    @isTest
    static void callMethods() {
        Account agency = TestObjectsFactory.getAgencyAccountRecord('Agency test','G123456789');
        insert agency;
        
        Test.startTest();
        UtilitiesWithoutSharing.getAllAccounts(new Set<String>{agency.UniqueKey__c});
        UtilitiesWithoutSharing.getUsersSimilerToUsername('ali','athamneh');

        Contact con = TestObjectsFactory.contactDataSetup(agency.Id);
        
        Map<String, Object> agentInfoObject = new Map<String, Object>();
        agentInfoObject.put('agencyName',agency.Id);
        agentInfoObject.put('title','Mr');
        agentInfoObject.put('firstName','firstName');
        agentInfoObject.put('lastName','lastName');
        agentInfoObject.put('emailId','test.test@test.com');
        agentInfoObject.put('role',Constants.AGENCY_ADMIN_PROFILE);
        agentInfoObject.put('country','country');
        agentInfoObject.put('phoneNumber','97156789');
        agentInfoObject.put('countryCode','971');
        agentInfoObject.put('realEmail','test.test@test.com');
        agentInfoObject.put('realMobile','97156789');
        agentInfoObject.put('birthdate',Date.today().addMonths(-100)+'');
        agentInfoObject.put('primaryOwner', false);
        agentInfoObject.put('primaryAgencyAdmin', true);

        String conId = UtilitiesWithoutSharing.createAgent(agentInfoObject);
        try {
            UtilitiesWithoutSharing.createUserFromContact(conId, true, Constants.PARTNER_COMMUNITY_USER);

            agentInfoObject.put('contactId', conId);
    
            User user = [Select Id From User Where ContactId =: conId limit 1];
            agentInfoObject.put('userId',user.Id);
    
            UtilitiesWithoutSharing.createAgent(agentInfoObject);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    static void createUserTest() {
        list<HexaBPM__SR_Status__c> statusList = new list<HexaBPM__SR_Status__c>();
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.Compliance_Rejected);       
        statusList.add(Submitted);
        insert statusList;

        Test.startTest();

        Account agency = TestObjectsFactory.getAgencyAccountRecord('Agency test','G123456789');
        agency.EmailAddress__c = 'test@test.com';
        insert agency;
        
        Contact con = TestObjectsFactory.contactDataSetup(agency.Id);
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        con.Email = 'test@test.com';
        con.FirstName ='Test';
        con.LastName ='Test';
        update con;
        
        HexaBPM__Service_Request__c sr = [select id from HexaBPM__Service_Request__c limit 1];
        sr.HexaBPM__External_SR_Status__c = statusList[0].Id;
        UPDATE sr;
        
        insert new AgencyTeam__c(Name='test',ServiceRequest__c=sr.id,Type__c =Constants.AGENCY_ADMIN, MobileNumber__c='971 12345');
        
        List<AgencyTeam__c> agencyTeam = [SELECT Name, Title__c, EmailAddress__c, MobileNumber__c, Country__c, ServiceRequest__c, 
                                          ServiceRequest__r.BrokerManager__c, Type__c,PrimaryOwner__c,PrimaryAgencyAdmin__c,
                                          MobileCountryCode__c
                                          FROM AgencyTeam__c 
                    WHERE Type__c =: Constants.AGENCY_ADMIN limit 1];

        List<Contact> newContact = UtilitiesWithoutSharing.createAgencyContact(agencyTeam, agency.Id, Constants.AGENCY_ADMIN, false);
        newContact[0].Email='ts@tst.com';
        newContact[0].FirstName='fn';
        newContact[0].LastName='ln';
        update newContact;

        agencyTeam[0].Name = 'Test Test';
        //update agencyTeam[0];
        List<Contact> newContact1 = UtilitiesWithoutSharing.createAgencyContact(agencyTeam, agency.Id, Constants.AGENCY_ADMIN, false);

        agencyTeam[0].Name = 'Test';
        //update agencyTeam[0];
        List<Contact> newContact2 = UtilitiesWithoutSharing.createAgencyContact(agencyTeam, agency.Id, Constants.AGENCY_ADMIN, true);

        UtilitiesWithoutSharing.sentOTP(newContact[0].Id, 'EMAIL', 'test13434@aldar.com');
        UtilitiesWithoutSharing.sentOTP(newContact[0].Id, 'SMS', '971527583669');
        UtilitiesWithoutSharing.validateOTP(newContact[0].Id);


        try {
            UtilitiesWithoutSharing.createUserFromContact(newContact[0].Id, true, Constants.AGENCY_ADMIN_PROFILE);
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try{
        UtilitiesWithoutSharing.updateLastsalesOrderDate(new List<Account>{agency});
            UtilitiesWithoutSharing.updateExistingCommunityUser(newContact[0].Id, true, Constants.AGENCY_ADMIN_PROFILE);
        }catch(Exception ex){
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest static void findDuplicateAccountsByEmirateIdPassportTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        insert acc;

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Test.startTest();        
        UtilitiesWithoutSharing.findDuplicateAccountsByEmirateIdPassport(acc.NationalIdNumber__pc, acc.PassportNumber__pc,acc.Nationality__pc,String.valueOf(acc.PersonBirthdate));
        
        Test.stopTest();
    }
}