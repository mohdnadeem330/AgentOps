@isTest
public class ResaleTransferRequestConfirmTest {

    @TestSetup
    static void setupData(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        insert unit;
        
        User admin = TestObjectsFactory.getUserRecord('System Administrator', 'admin');
        admin.FirstName = 'Admin';
        insert admin;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ResaleConstants.RESALE_OPPORTUNITY_RecordTypeDeveloperName).getRecordTypeId();
        opp.OwnerManger__c = UserInfo.getUserId();
        opp.Seller__c = newAccount.Id;
        opp.unit__c = unit.Id;
        opp.Amount = 500000;
        opp.OwnerId = admin.Id;
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(Opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        salesOrder.Status__c = 'Sold';        
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAccount.Id, 'Friend Of');
        insert jointOwner;
    }
     @IsTest
    static void testInitiateTransfer(){
        Opportunity opp = [SELECT Id, AccountId, SalesOrder__c, Unit__c, Seller__c, Amount, OwnerId, Equity_Paid__c FROM Opportunity limit 1];
        
        SalesOrder__c salesOrder = [Select Id from SalesOrder__c limit 1]; 
        
        Unit__c unit = [Select Id,ListedCase__c from Unit__c limit 1];  

        HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c();
        template.HexaBPM__SR_RecordType_API_Name__c = 'PropertyTransfer';
        insert template;

        JointOwner__c jointOwner = [SELECT Id, Name, SharePercentage__c, RelationshipType__c, Account__c
                                                                             FROM JointOwner__c limit 1]; 
		HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;

        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
       
        Test.startTest();
        String str = ResaleTransferRequestConfirmController.initiateTransfer(opp.Id);
        Boolean exists = ResaleTransferRequestConfirmController.doesSRAlreadyExists(opp.Id);
        Test.stopTest();
    }
     
    
}