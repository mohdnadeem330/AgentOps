@isTest
private class DarnaCheckControllerTest {
  
    //Create setupData 
    @testSetup static void setupData() {


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
        
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, '', unit.Id, 'Phone');
        caseRecord.subject='Test';
        insert caseRecord;
       
    }
    
    @isTest
    public static void addPointsAPITest (){
        Test.startTest();
        
        Case caseRec = [select Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.DarnaMembershipNumber__c, AccountId, SalesOrder__c, SalesOrder__r.Opportunity__c  From Case Limit 1];
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('123','123456');
        insert acc1;

        DarnaCheckController.getCaseDetails(caseRec.Id);
        
		Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        DarnaCheckController.updateContactMembershipNumber(con, '123456789');
       // DarnaServices.RedeemPointsResponseModel response = new DarnaServices.RedeemPointsResponseModel();
       // DarnaCheckController.createReceiptAcknowledgementForRedemption(caseRec, 'Online', 1000, 'referenceNumber', 'receiptNumber', 'remarks', response);

        Test.stopTest();
    }

}