@isTest
private class LPCFinanceEmailControllerTest {
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        insert salesOrder;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;
                        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        LPCFinanceEmailController obj = new LPCFinanceEmailController();
        obj.srId = SR.Id;
        
        List<HexaBPM__Step__c> stepRecords = obj.reqList;
        HexaBPM__Service_Request__c srDetails = obj.srDetails;
        Decimal total = obj.totalOutstanding;
		String newLine = obj.NewLine;
        Test.stopTest();
    }
}