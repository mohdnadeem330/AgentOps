@isTest(SeeAllData=false)
public class UpdateSalesOrderWebserviceTest {
    @isTest static void setupMethod() {
        
        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord;
        
        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord1;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        //acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerManger__c = userRecord.id;
        insert salesOrder;

        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, salesOrder.Id);
        insert document;
        
        String JSONBodyMortageRequest = '{"mortageRequest" : {"MortgageAmount__c":"100000","MortgageApplicationNumber__c" : "9383627292","MortgageApplicable__c":"Yes","MortgageBank__c" : "ADCB","MortgageStartDate__c":"2022-12-23", "MortgageEndDate__c" : "2024-12-23"},"orderSubStatus" : "", "generateDocuments" : "false", "salesOrderId" : "'+salesOrder.id+'"}';
        
        UpdateSalesOrderWebservice.SalesOrderUpdateModel convertedData = (UpdateSalesOrderWebservice.SalesOrderUpdateModel)JSON.deserialize(JSONBodyMortageRequest,UpdateSalesOrderWebservice.SalesOrderUpdateModel.Class);
        SalesOrder__c specialCondition = convertedData.specialCondition;
        SalesOrder__c mortageRequest = convertedData.mortageRequest;
        Id salesOrderId = convertedData.salesOrderId;
        String orderSubStatus = convertedData.orderSubStatus;
        String generateDocuments = convertedData.generateDocuments;
        String customerSignedtheSPA = 'True';
        Date customerSignedtheSPADate = Date.today();
        String spaSignatureType = 'Physical Signature';
        String spaSignatureTypeReason = 'Test'; 
         
        UpdateSalesOrderWebservice.SalesOrderUpdateModel salesOrderUpdateModel = new UpdateSalesOrderWebservice.SalesOrderUpdateModel(specialCondition, mortageRequest, orderSubStatus, salesOrderId, generateDocuments, customerSignedtheSPA, customerSignedtheSPADate,spaSignatureType, spaSignatureTypeReason,'test', false, 'Test OptOut','test','test' );

        
        //ring JSONBodyMortageRequest = '{"specialCondition":{},"mortageRequest" : {"MortgageAmount__c":"100000","MortgageApplicationNumber__c" : "9383627292","MortgageApplicable__c":"Yes","MortgageBank__c" : "ADCB","MortgageStartDate__c":"2022-12-23", "MortgageEndDate__c" : "2024-12-23"},"orderSubStatus" : "", "generateDocuments" : "false", "salesOrderId" : "'+salesOrder.id+'"}';
        TestObjectsFactory.initializeRestContext(JSONBodyMortageRequest, '/some/path', '1.0', 'ios', '13', 'iphone x');

        TestObjectsFactory.initializeRestContext(null, '/update/SalesOrder');       
        
        UpdateSalesOrderWebservice.doPost();
        RestContextHandler handler = new RestContextHandler(false);
        String JSONBodySpecialCondition = '{"specialCondition":{"ExpectedEndDate__c":"2022-12-23","SpecialConditionApplicable__c" : "Yes","SpecialConditionRemarksComments__c" : "test specialCondition","SpecialConditionReason__c" : "Cheque Book"},"mortageRequest" : {},"orderSubStatus" : "", "generateDocuments" : "TRUE", "customerSignedtheSPA" : "TRUE", "customerSignedtheSPADate" : "2022-06-20", "spaSignatureTypeReason":"test", "salesOrderId" : "'+salesOrder.id+'"}';
        TestObjectsFactory.initializeRestContext(JSONBodySpecialCondition, '/some/path', '1.0', 'ios', '13', 'iphone x');
        
        Test.startTest();

        
        UpdateSalesOrderWebservice.doPost();
        TestObjectsFactory.initializeRestContext(JSONBodyMortageRequest, '/some/path', '1.0', 'ios', '13', 'iphone x');

        Test.stopTest();

    }
}