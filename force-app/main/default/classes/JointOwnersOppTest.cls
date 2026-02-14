/**
* JointOwnersOppTest
*
* Test class for JointOwnersOppController
*/
@isTest
public class JointOwnersOppTest {
    @TestSetup
    static void makeData(){
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            unitrecord.ResaleListed__c = true;
            unitRecord.Listing_Price__c = 10000000;
            // unitRecord.Offer_Accepted__c = false;
            unitRecord.ResaleStatus__c = '';
        insert unitrecord;
        
        List<Account> accList = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.LastName += ' Main';
        accList.add(acc);
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.LastName += ' Related';
        accList.add(acc2);
        insert accList;
        System.debug(accList[0]);

        AccountRelationship__c accRelationship = TestObjectsFactory.getAccountRelationship(acc.Id, acc2.Id, 'Friend Of');
        insert accRelationship;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.SharePercentage__c = 80;
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unitrecord.Id;
            salesOrder.IsBookingCompleted__c = true;
            salesOrder.NetAmount__c = 10000000;
            salesOrder.Account__c = acc.Id;
            salesOrder.Status__c = 'Sold';
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');
        insert jointOwner;
    }

    @IsTest
    static void getRelatedAccountNamesTest(){
        // Id mainAccId = [SELECT Id FROM Account WHERE IsPersonAccount = true AND LastName LIKE '%Main' LIMIT 1][0].Id;
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1][0].Id;
        Test.startTest();
            try {
                JointOwnersOppController.getRelatedAccountNames(oppId);
            } catch (Exception ex) {
                System.debug(ex);
            }
        Test.stopTest();
    }

    @IsTest
    static void getTotalSharePercentageTest(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1][0].Id;
        Id relatedAccId = [SELECT Id FROM Account WHERE IsPersonAccount = true AND LastName LIKE '%Related' LIMIT 1][0].Id;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(null, relatedAccId, 'Friend Of');
        jointOwner.Opportunity__c = oppId;
        jointOwner.SalesOrder__c = null;
        JointOwnersOppController.saveJointOwner(jointOwner);
        
        Test.startTest();
            try {
                JointOwnersOppController.getTotalSharePercentage(oppId);
            } catch (Exception ex) {
                System.debug(ex);
            }
        Test.stopTest();
    }

    @IsTest
    static void getRelationTypeTest(){
        // Id mainAccId = [SELECT Id FROM Account WHERE IsPersonAccount = true AND LastName LIKE '%Main' LIMIT 1][0].Id;
        Id soId = [SELECT Id FROM SalesOrder__c LIMIT 1][0].Id;
        Test.startTest();
            try {
                JointOwnersOppController.getRelationType(soId);
            } catch (Exception ex) {
                System.debug(ex);
            }
        Test.stopTest();
    }
    
    @IsTest
    static void saveJointOwnerTest(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Id relatedAccId = [SELECT Id FROM Account WHERE IsPersonAccount = true AND LastName LIKE '%Related' LIMIT 1][0].Id;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(null, relatedAccId, 'Friend Of');
        jointOwner.Opportunity__c = oppId;
        Test.startTest();
        try {
            JointOwnersOppController.saveJointOwner(jointOwner);
        } catch (Exception ex) {
            System.debug(ex);
        }
        Test.stopTest();
    }    
}