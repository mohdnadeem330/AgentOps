@isTest
public with sharing class MassOwnerShipChangeLogicsTest {

    @testSetup static void setupData() {

        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        insert salesOrder;
        
        Id standardRecordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');

        Case case1 = TestObjectsFactory.getCaseRecord(standardRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
        case1.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
        case1.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        case1.Unit__c = unit.Id;
        case1.subject='Test';
        case1.CustomerType__c = 'Owner';
        case1.OwnerId = Userinfo.getUserId();
        insert case1;

        Case case2 = TestObjectsFactory.getCaseRecord(standardRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Email');
        case2.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
        case2.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        case2.Unit__c = unit.Id;
        case2.subject='Test2';
        case2.CustomerType__c = 'Owner';
        case2.OwnerId = Userinfo.getUserId();
        insert case2;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c(
        Name = 'Additional Rebate Request',
        HexaBPM__SR_RecordType_API_Name__c = 'Rebate_Request'
        );
        insert SR_Template;

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c(
        RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Request'),
        SRType__c =  'Rebate Request',
        HexaBPM__Customer__c = newAccount.Id,
        HexaBPM__Contact__c = newAccount.PersonContactId,
        HexaBPM__SR_Template__c = SR_Template.Id,
        Unit__c = unit.Id,
        SalesOrder__c = salesOrder.Id,
        StepClosureDate__c = Date.today(),
        Rebate_to_be_Offered__c = 0.00,
        Additional_Rebate_Offered__c = 0.00
        );
        insert SR;


        HexaBPM__Step_Template__c[] stepTemplates = new HexaBPM__Step_Template__c[]{
            new HexaBPM__Step_Template__c(Name = 'Approval of the Request By D&T', HexaBPM__Code__c = 'Approval of the Request By D&T', HexaBPM__Step_RecordType_API_Name__c = 'General'),
            new HexaBPM__Step_Template__c(Name = 'Verification by Finance', HexaBPM__Code__c = 'Verification by Finance', HexaBPM__Step_RecordType_API_Name__c = 'General'),
            new HexaBPM__Step_Template__c(Name = 'Payment Step', HexaBPM__Code__c = 'Payment Step', HexaBPM__Step_RecordType_API_Name__c = 'General')
        };
        insert stepTemplates;
    
        HexaBPM__Status__c[] statusList = new HexaBPM__Status__c[]{
            new HexaBPM__Status__c(Name = Constants.PENDING_STATUS, HexaBPM__Code__c = Constants.PENDING_STATUS),
            new HexaBPM__Status__c(Name = Constants.STATUS_APPROVED, HexaBPM__Code__c = Constants.STATUS_APPROVED),
            new HexaBPM__Status__c(Name = Constants.COMPLETED_STATUS, HexaBPM__Code__c = Constants.COMPLETED_STATUS)
        };
        insert statusList;
    
        HexaBPM__SR_Steps__c[] SRstepsList = new HexaBPM__SR_Steps__c[]{
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 2,
                HexaBPM__Step_Template__c = stepTemplates[1].Id,
                HexaBPM__Summary__c = 'Verification by Finance',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ),
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 1,
                HexaBPM__Step_Template__c = stepTemplates[2].Id,
                HexaBPM__Summary__c = 'Payment Verification',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ),
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 1,
                HexaBPM__Step_Template__c = stepTemplates[0].Id,
                HexaBPM__Summary__c = 'Approval of the Request By D&T',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            )
        };
        insert SRstepsList;
    
        HexaBPM__Step__c[] stepList = new HexaBPM__Step__c[]{
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Verification by Finance',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[0].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[0].id
            ),
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Payment Verification',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[1].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[2].id
            ),
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Approval of the Request By D&T',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[2].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[1].id
            )
        };
        insert stepList;

    }


    @isTest
    public static void CaseMassOwnerShip() {       

        // Define the User details
        String username = 'testcase67user@example.com';
        String alias = 'test67';
        String email = 'testcase67user@example.com';
        String lastName = 'TestCase67';
        String firstName = 'User';
        String profileName = 'Standard User'; // Replace with actual Profile Name
        String userRoleId = null; // Optional: Replace with Role Id if assigning a role

        // Create a new User record
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1]; // Retrieve the Profile Id
        User newUser = new User(
            Username = username,
            Alias = alias,
            Email = email,
            LastName = lastName,
            FirstName = firstName,
            ProfileId = profile.Id,
            UserRoleId = userRoleId,
            TimeZoneSidKey = 'America/Los_Angeles', // Replace with appropriate timezone
            LocaleSidKey = 'en_US', // Replace with appropriate locale
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        // Insert the new User record
        insert newUser;
       // List<Case> OwnershipchangeCases = new List<Case>();
        Map<String, String> MapownerIds = new Map<String,String>();
        Test.startTest(); 

       // List<Case> updateCase = new List<Case>();
        List<case> OwnershipchangeCases = [Select id, OwnerId,Vertical__c,SubVertical__c from Case];
        OwnershipchangeCases[0].OwnerId = newUser.Id;
        OwnershipchangeCases[1].OwnerId = newUser.Id;
       // updateCase.add(caseList);
       // updateCase.add(case2);
       MapownerIds.put(OwnershipchangeCases[0].id,newUser.Id);
       MapownerIds.put(OwnershipchangeCases[1].id,newUser.Id);
       Case_Ownership_Change_Users__mdt casedt = [SELECT Sub_Vertical_Val__c, Vertical_Val__c,UserEmailIds__c,QueueName__c FROM Case_Ownership_Change_Users__mdt];
        MassOwnerShipChangeLogics.updateCaseOwner(OwnershipchangeCases, MapownerIds);
        update OwnershipchangeCases;

        Test.stopTest();

    }


    // @isTest
    // public static void SRMassOwnerShipFalse() {  
    //     Test.startTest();  
        
    //     List<HexaBPM__Service_Request__c> ownershipchangeSR = [Select id from HexaBPM__Service_Request__c];
    //     MassOwnerShipChangeLogics.updateSROwner(ownershipchangeSR);
        
    //     Test.stopTest();
    // }

 /* commented   @isTest
    public static void SRMassOwnerShip() { 
        Test.startTest();  
        
        List<HexaBPM__Service_Request__c> ownershipchangeSR = [Select id from HexaBPM__Service_Request__c];
        List<Mass_Ownership_Change_Access__mdt> mdta = [SELECT ValidEmails__c,SR_Type__c FROM Mass_Ownership_Change_Access__mdt limit 1];
        MassOwnerShipChangeLogics.updateSROwner(ownershipchangeSR);
        Test.stopTest();
    }

    @isTest
    public static void StepMassOwnerShip() { 
        Test.startTest();  
        Map<String, HexaBPM__Step__c> ownershipStep = new Map<String, HexaBPM__Step__c>();
        Map<HexaBPM__Step__c,String> ownershipchangeStep = new Map<HexaBPM__Step__c, String>();
        HexaBPM__Step__c stepRecord = [Select id,HexaBPM__SR__r.SRType__c  from HexaBPM__Step__c limit 1];
        ownershipStep.put(stepRecord.id,stepRecord);

        for(HexaBPM__Step__c stp: [Select id, HexaBPM__SR__r.SRType__c  from HexaBPM__Step__c where ID IN: ownershipStep.keySet()])
            {
                ownershipchangeStep.put(ownershipStep.get(stp.id), stp.HexaBPM__SR__r.SRType__c );
            }
        
        new MassOwnerShipChangeLogics(ownershipchangeStep);
        Test.stopTest();
    }*/
}