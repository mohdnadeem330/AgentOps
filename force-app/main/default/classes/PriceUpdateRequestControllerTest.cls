/*
*Created By     : Hardik Vitthani
*Description    : Test class for PriceUpdateRequestController
*/
@isTest
public class PriceUpdateRequestControllerTest {
    @isTest
    public static void testPriceUpdateRequestController() {
        Test.startTest();

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        Map<String, String> newpriceMap = new  Map<String, String>();
        newpriceMap.put(unit.id, '70000');
        
        try {
           List<PriceUpdateRequest__c> lstPU = PriceUpdateRequestController.createPriceUpdateReq('Test Comment', newpriceMap);
            PriceUpdateRequestController.getuUnitCodes(new List<String>{unit.name});
            PriceUpdateRequestController.recallApproval(new List<Id>{lstPU[0].Id});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}