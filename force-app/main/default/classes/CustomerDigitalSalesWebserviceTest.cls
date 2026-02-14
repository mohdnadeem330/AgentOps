@isTest
public class CustomerDigitalSalesWebserviceTest {
    
    private static void setupRestRequest(String requestBody,String accountId,String projectName, String unitId){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createFasttrack';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerDigitalSalesWebservice.doPost(accountId,projectName,unitId);
        Test.stopTest();
    }
    
    @testSetup
    public static void testSetupData(){
        
        Profile pro = [SELECT Id,Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User dmUser = new User(
            Alias = 'dmu',
            Email = 'datamigration@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'dmuser@example.com.test',
            FirstName = 'Data',
            LastName = 'Migration',
            profileId = pro.Id 
        );
        insert dmUser;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OwnerId = dmUser.Id;
        acc.ResidentStatus__pc = 'Non-Resident';
        acc.CountryOfResidence__pc = 'India';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Gate';
        proj.LeadProjectName__c = 'Gate';
        proj.Damascus_Community_Name__c = 'Gate';
        insert proj;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Available';
        unit.Project__c = proj.Id;
        insert unit;
        
        Lead lead = TestObjectsFactory.getLeadRecord(1,'Person');
        lead.FirstName = 'Testing';
        lead.LastName = 'Lead';
        lead.OwnerId = userInfo.getUserId();
        lead.ExistingAccount__c= acc.Id;
        lead.ResidentStatus__c = 'Non-Resident';
        lead.Lead_Type__c = 'Options and Upgrades';
        lead.Unit__c = unit.Id;
        lead.EnquiryTrigger__c ='Damascus';
        lead.Project__c = 'Gate';
        lead.UnitType__c = 'Apartment';
        lead.BuyRent__c = 'Buy';
        lead.CustomerBudget__c = '700,000 - 999,000';
        lead.NumberOfBedrooms__c = '1 Bed';
        lead.PurposeOfUse__c = 'End User';
        lead.PropertyReadiness__c = 'Ready';
        lead.Financing__c = 'No';
        
        insert lead;
    }
    
    @isTest
    public static void negativeTesting_InvalidProjectName(){
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'projectName' => 'InvalidProjectName',
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,'','InvalidProjectName',Unit.Id);
    }
    
    @isTest
    public static void negativeTesting_InvalidInput(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'projectName' => proj.Name,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,'',proj.Name,Unit.Id);
    }
    
    @isTest
    public static void negativeTesting_Account_notFound(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'projectName' => proj.Name,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,'001FW000008ozABCDE',proj.Name,Unit.Id);
    }
    
    @isTest
    public static void positiveTesting(){
        
        Account acc = [Select Id, PersonContactId From Account Where Name = 'Test Account' Limit 1];   
        Project__c proj = [Select Id,Name,LeadProjectName__c From Project__c Where LeadProjectName__c = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        Opportunity opp = [Select Id From Opportunity Where AccountId =: acc.Id Limit 1];
        Lead lead = [Select Id,Project__c,UnitType__c, BuyRent__c, CustomerBudget__c, NumberOfBedrooms__c, PurposeOfUse__c, PropertyReadiness__c, Financing__c From Lead Where Name = 'Testing Lead' and ExistingAccount__c =: acc.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'projectName' => proj.Name,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,acc.Id,proj.Name,Unit.Id);
        CustomerDigitalSalesWebservice.createCPRecord(acc,lead,opp.Id,proj.Name,unit.Id);
    }
    @isTest
    public static void positiveTesting_cpRecordFound(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Lead lead = [Select Id,Project__c,BuyRent__c From Lead Where Name = 'Testing Lead' and ExistingAccount__c =: acc.Id Limit 1];
        Project__c proj = [Select Id,Name,LeadProjectName__c From Project__c Where LeadProjectName__c = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOwnerId(Userinfo.getuserid());
        lc.setDoNotCreateOpportunity(false);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Communication_Preference__c cpRecord = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Live Aldar',
            Status__c = 'Fasttrack Completed',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Lead__c = lead.Id,
            Opportunity__c = lcr.getOpportunityId(),
            Sent_Email_Date_Time__c = DateTime.now());
        insert cpRecord;
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'projectName' => proj.Name,
                'unitId' => unit.Id
                });
        setupRestRequest(requestBody,acc.Id,proj.Name,Unit.Id);
    }
}