@isTest
private class CalloutToMulesoftForRealTimeSyncTest {
    
    @isTest
    static void testSendToMuleSoft() {
        // Insert test data
        Account testAcc = TestObjectsFactory.getPersonAccountRecord();
        insert testAcc;
        
        Account testAcc3 = TestObjectsFactory.getPersonAccountRecord();
        insert testAcc3;
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        project.EligibleforResale__c  = true;
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        insert unit;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(testAcc.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;

        SalesOrder__c order = TestObjectsFactory.getSalesOrderRecord(opp.Id, testAcc.Id);
        order.Unit__c = unit.Id;
        order.IsBookingCompleted__c = true;
        order.NetAmount__c = 100000;
        order.Account__c = testAcc.Id;
        order.Status__c = 'Sold';
        insert order;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(testAcc.Id, 20, 'Third Party');
        jointOwner.SalesOrder__c = order.Id;
        insert jointOwner;
        
        JointOwner__c jointOwner2 = TestObjectsFactory.getJointOwner(testAcc3.Id, 20, 'Joint Owner P-P');
        jointOwner2.SalesOrder__c = order.Id;
        insert jointOwner2;

        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(order.Id, 3);

        // Register mock response
        Test.setMock(HttpCalloutMock.class, new MuleSoftMockResponse());

        // Call method
        Test.startTest();
        CalloutToMulesoftForRealTimeSync.sendToMuleSoft(new List<Id>{testAcc.Id});
        Test.stopTest();

        // Verify update
        Account updatedAcc = [SELECT Compliance_Risk_Score__c, Compliance_Risk_Level__c,
                              Compliance_Risk_Date_Time__c, Compliance_Risk_Error_Reason__c
                              FROM Account WHERE Id = :testAcc.Id];
                              
        Assert.areEqual(85, updatedAcc.Compliance_Risk_Score__c);
        Assert.areEqual('High', updatedAcc.Compliance_Risk_Level__c);
        Assert.areEqual('None', updatedAcc.Compliance_Risk_Error_Reason__c);
    }
}