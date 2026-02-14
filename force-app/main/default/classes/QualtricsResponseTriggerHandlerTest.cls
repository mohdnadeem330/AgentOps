/**
* QualtricsResponseTriggerHandlerTest
*
* Test class for QualtricsResponseTriggerHandler
*/
@isTest
private class QualtricsResponseTriggerHandlerTest{
    //Create test data
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CSAT__c = 0.00;
        acc.NPS__c = 0.00;
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount ; 

        Opportunity opp1 = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp1;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp1.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, newAccount.Id, opp1.Id, 'Cheque');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, newAccount.Id, installmentLineList[0].Id);
        insert receiptAllocation;

        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Feedback Case');
        Case newCase = TestObjectsFactory.getCaseRecord(recordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
        //insert newCase;
        
        
        
        
    }
    //Create Qualtrics Response
    @isTest static void testResponse() {
        Test.startTest();
        Opportunity opportunityRecord =[select id from Opportunity limit 1];
        SalesOrder__c soRecord =[select id from SalesOrder__c limit 1];
       
        QualtricsResponse__c qtr1 = new QualtricsResponse__c(sObjectID__c=soRecord.Id, SurveyName__c='Test',
                                                          //  SurveyName__c = 'HomeFinance',
                                                            Answer1__c = '8',
                                                            Answer2__c = '9',
                                                            Answer3__c = '8',
                                                            Answer4__c = '4',
                                                            Answer5__c = '6',
                                                            Question1Impact__c = 'NPS',
                                                            Question2Impact__c = 'Low',
                                                            Question3Impact__c = 'Medium',
                                                            Question4Impact__c = 'CSAT',
                                                            Question5Impact__c = 'Low1');
        insert qtr1;
        
        QualtricsResponse__c qtr = new QualtricsResponse__c(sObjectID__c=opportunityRecord.Id, SurveyName__c='Test',
                                                          //  SurveyName__c = 'HomeFinance',
                                                            Answer1__c = '8',
                                                            Answer2__c = '9',
                                                            Answer3__c = '7',
                                                            Answer4__c = '4',
                                                            Answer5__c = '9',
                                                            Question1Impact__c = 'NPS',
                                                            Question2Impact__c = 'Low',
                                                            Question3Impact__c = 'Medium',
                                                            Question4Impact__c = 'CSAT',
                                                            Question5Impact__c = 'Low1');
        insert qtr;
       
        
        qtr = [select id,Opportunity__c from QualtricsResponse__c where id = :qtr.Id];
        System.assertEquals(qtr.Opportunity__c, opportunityRecord.Id);
        Test.stopTest();
    }
    @isTest static void ExceptionalHandling() {
        Test.startTest();
        Opportunity opportunityRecord =[select id from Opportunity limit 1];
        SalesOrder__c soRecord =[select id from SalesOrder__c limit 1];
        
        QualtricsResponse__c qtr = new QualtricsResponse__c(sObjectID__c=opportunityRecord.Id, SurveyName__c='Test',
                                                          //  SurveyName__c = 'HomeFinance',
                                                            Answer1__c = '8',
                                                            Answer2__c = '9',
                                                            Answer3__c = '7',
                                                            Answer4__c = '4',
                                                            Answer5__c = '9',
                                                            Question1Impact__c = 'NPS',
                                                            Question2Impact__c = 'Low',
                                                            Question3Impact__c = 'Medium',
                                                            Question4Impact__c = 'CSAT',
                                                            Question5Impact__c = 'Low1');
        QualtricsResponseTriggerHandler.forceException = true; 
       
        try{
            insert qtr;
        }
        catch(Exception e){
            
        }      	
        Test.stopTest();
    }
    
   
    @isTest static void brokerAgencyCSATCalculationTest() {
        Test.startTest();
        Opportunity opportunityRecord =[select id from Opportunity limit 1];
        SalesOrder__c soRecord =[select id from SalesOrder__c limit 1];
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('TestAgency21213', 'G132344');
        testAccount.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        insert testAccount;
        QualtricsResponse__c qtr1 = new QualtricsResponse__c(sObjectID__c=soRecord.Id, SurveyName__c='Test',
                                                          //  SurveyName__c = 'HomeFinance',
                                                            Answer1__c = '8',
                                                            Answer2__c = '9',
                                                            Answer3__c = '8',
                                                            Answer4__c = '4',
                                                            Answer5__c = '6',
                                                            Question1Impact__c = 'NPS',
                                                            Question2Impact__c = 'Low',
                                                            Question3Impact__c = 'Medium',
                                                            Question4Impact__c = 'CSAT',
                                                            Question5Impact__c = 'Low1',
                                                            BrokerAgency__c = testAccount.Id);
        insert qtr1;
        
        QualtricsResponse__c qtr = new QualtricsResponse__c(sObjectID__c=opportunityRecord.Id, SurveyName__c='Test',
                                                          //  SurveyName__c = 'HomeFinance',
                                                            Answer1__c = '8',
                                                            Answer2__c = '9',
                                                            Answer3__c = '7',
                                                            Answer4__c = '4',
                                                            Answer5__c = '9',
                                                            Question1Impact__c = 'NPS',
                                                            Question2Impact__c = 'Low',
                                                            Question3Impact__c = 'Medium',
                                                            Question4Impact__c = 'CSAT',
                                                            Question5Impact__c = 'Low1');
        insert qtr;
       
        
        qtr = [select id,Opportunity__c from QualtricsResponse__c where id = :qtr.Id];
        System.assertEquals(qtr.Opportunity__c, opportunityRecord.Id);
        Test.stopTest();
    }
    
       
    
}