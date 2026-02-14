@isTest
public class ECSS_CheckIfRecordIsLockedTest {
	@testSetup
    static void dataSetup(){
        Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ECSS_Company').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Company',
            ECSS_Company_External_Id__c = 'COMP123',
            ECSS_Availability__c = 'Available for Lease',
            RecordTypeId = accRecTypeId
        );
        insert acc;
        
        Project__c proj = new Project__c(
            Name = 'Project',
            ECSS_SAPExternalId__c = 'PROJ001',
            BusinessUnitId__c = 'PROJ123',
            ProjectCode__c = 'PROJ123'
        );
        insert proj;
        
        Account landlord = new Account(
            Name = 'Landlord',
            SapAccountID__c = 'LAND123'
        );
        insert landlord;
        
        BuildingSection__c bs = new BuildingSection__c(
            Name = 'BS1',
            ECSS_Building_External_Id__c = 'BS_EXT_ID',
            BuildingSectionCode__c = 'BSCODE',
            Project__c = proj.Id
        );
        insert bs;
        
        Zone__c zone = new Zone__c(
            Name = 'Zone 1',
            Zone_External_Id__c = 'ZONE1',
            Project__c = proj.Id
        );
        insert zone;
        
        Product2 p = new Product2(Name = 'UnitType1', IsActive = true);
        insert p;
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        String UnitRTName = System.Label.ECSS_Unit;
        Id unitRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(UnitRTName).getRecordTypeId();
        
        Asset asset = new Asset(
            Name = 'Test Asset DXB',
            ECSS_Unit_Area__c = 'DXB',
            ECSS_Company_Code_External_Id__c = acc.ECSS_Company_External_Id__c,
            ECSS_Project_External_Id__c = proj.ECSS_SAPExternalId__c,
            ECSS_LandlordSAPExternalId__c = landlord.SapAccountID__c,
            ECSS_Building_Section_External_Id__c = bs.ECSS_Building_External_Id__c,
            ECSS_Zone_External_Id__c = zone.Zone_External_Id__c,
            //ECSS_Owner_Email__c = insertUser.Username,
            //OwnerId = insertUser.Id,
            ExternalIdentifier = 'EXT123',
            RecordTypeId = unitRecordTypeId
        );
        insert asset;
        
        Account mainOccupantAccount = new Account();
        mainOccupantAccount.Name = 'Main Occupant';
		insert mainOccupantAccount;

		Opportunity mainOccupantOpportunity = new Opportunity();
		mainOccupantOpportunity.Name = 'Test Opportunity';
        mainOccupantOpportunity.AccountId = mainOccupantAccount.Id;
        insert mainOccupantOpportunity;
        
        Quote mainOccupantQuote = new Quote();
        mainOccupantQuote.Name = 'TestQuote';
        mainOccupantQuote.OpportunityId = mainOccupantOpportunity.Id;
        insert mainOccupantQuote;
    }
    @isTest
    public static void testInvocableMethod(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Approval.lock(opp.Id);
        List<Id> recIds = new List<Id>();
        recIds.add(quote.Id);
        recIds.add(opp.Id);
        
        List<ECSS_CheckIfRecordIsLocked.FlowInputs> flowInputs = new List<ECSS_CheckIfRecordIsLocked.FlowInputs>();
        ECSS_CheckIfRecordIsLocked.FlowInputs input = new ECSS_CheckIfRecordIsLocked.FlowInputs();
        input.recordIds = recIds;
        flowInputs.add(input);
        Test.startTest();
        ECSS_CheckIfRecordIsLocked.checkIfRecordIsLocked(flowInputs);
        Test.stopTest();
    }
}