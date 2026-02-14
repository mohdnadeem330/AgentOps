@isTest
public class OpportunityServiceTest {
    
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        opp.Amount = 50000;
        insert opp;
        
        OpportunityService.updateOpportunityStage(opp.Id, Constants.ALDAR_SALES_OFFER);
        OpportunityService.updateOpportunityStage(opp.Id, Constants.MEETING);
        // opp.WinReason__c = 'Won - Aldar Brand Value';
        // update opp;
        // OpportunityService.updateOpportunityStage(opp.Id, Constants.CLOSEDWON);

        OpportunityService.fetchOpportunityForAPIByUser(UserInfo.getUserId());
        OpportunityService.getAllOpportunitys(new Set<Id>{acc.Id}, new List<Account>{acc});

        Map<Id,Account> accMap = new Map<Id,Account>();
        accMap.put(acc.Id,acc);
        OpportunityService.getOpportunityForAccount(accMap);
        OpportunityService.getOpportunityDetailsbyId(opp.Id);
        OpportunityService.getOpportunityDetailsMapbyId(opp.Id);
        OpportunityService.getOpportunityQuery('Select Id From Opportunity');
        OpportunityService.opportunityFieldsValidation(opp.Id);
        OpportunityService.fetchOpportunitiesByAccountId(acc.Id);
        OpportunityService.cancelOpportunityReservation(new Set<String>{opp.Id});
        OpportunityService.fetchOpportunityNumber(new Set<Id>{opp.Id});
        OpportunityService.fetchOpportunityById(opp.Id);
        OpportunityService.fetchOpportunities('Name != null');
        OpportunityService.getValidationFields();





        /*Account ac = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        Contact con = TestObjectsFactory.contactDataSetup(ac.Id);
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        Opportunity op = TestObjectsFactory.getOpportunityRecord(ac.Id);
        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(op.Id,ac.Id);
        SalesOrder__c SalesOrderRecord = new SalesOrder__c();
        SalesOrderRecord .Opportunity__c ='0062600000KplyWAAR' ;
        SalesOrderRecord .Unit__c = 'a012600000Np8uOAAR';
        SalesOrderRecord .Status__c = Constants.SALES_STATUS;
        insert SalesOrderRecord ;
        Opportunity oppToUpdate = [SELECT Id,ExpectedEndDate__c FROM Opportunity WHERE Id =: op.Id];
        oppToUpdate.Id=op.Id;
        oppToUpdate.ExpectedEndDate__c=System.Today().addDays(10);
        oppUpdate.add(oppToUpdate);
        Map<Id,Opportunity> oldOpp = new  Map<Id,Opportunity>();
        oldopp.put(op.Id,op);
        
        
        Test.startTest();
        update oppUpdate[0]; 
        
        //OpportunityService.restrictSpecialConditionFieldChange(oppUpdate,oldopp);
        // OpportunityService.callApprovalProcess(oppUpdate2,ol2);
        Test.stopTest();*/
        
    }
    
}