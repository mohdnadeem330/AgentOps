/*
*Created By     : Hardik Vitthani
*Description    : Test class for PriceUpdateUnitController
*/
@isTest
public class PriceUpdateUnitControllerTest {
    @isTest
    public static void testPriceUpdateUnitController() {
        Test.startTest();

        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        insert unit;

        PriceUpdateRequest__c priceUpdateRequest = TestObjectsFactory.getPriceUpdateRequestRecord();
        insert priceUpdateRequest;

        PriceUpdateUnit__c priceUpdateUnit = TestObjectsFactory.getPriceUpdateUnitRecord(priceUpdateRequest.Id, project.Id, buildingSection.Id, unit.Id);
        insert priceUpdateUnit;

        try {
            PriceUpdateUnitController priceUpdateUnitObj = new PriceUpdateUnitController();
            priceUpdateUnitObj.priceUpdReqtId = priceUpdateRequest.Id;
            PriceUpdateRequest__c puRequest = priceUpdateUnitObj.PriceUpdateRequest;
            List<PriceUpdateRequest__c> puRequestList = priceUpdateUnitObj.reqList;
            String newLine = priceUpdateUnitObj.NewLine;
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}