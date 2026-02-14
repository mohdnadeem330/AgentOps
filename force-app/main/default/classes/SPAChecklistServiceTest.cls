/* 
* SPAChecklistControllerTest
*
* Test class for SPAChecklistController
*/
@isTest
private class SPAChecklistServiceTest{
    //Test SPAChecklist__c retrival 
    @isTest static void getSPATest() {
        List<SPAChecklist__c> records = SPAChecklistService.SPAAllChecklistRecords(null);
        System.assertEquals(records.isEmpty(),true);

    }
}