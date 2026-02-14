/*
*Created By     : Pavithra Gajendra
*Created Date   : 30/07/2022
*Description    : Test class for SendToeSignWebService
*/
@isTest 
private class SendToeSignWebServiceTest {
    
    /*
    * Scenario 1 : Send to eSign
    */
    static testmethod void testeSign() {
        Test.startTest();

        Account accountRec = TestObjectsFactory.getPersonAccountRecord();
        insert accountRec ;
        
        Document__c documentRec = TestObjectsFactory.getAccountDocument(accountRec.Id);
        insert documentRec ; 

        TestObjectsFactory.initializeRestContext(null, '/sendto/eSign');
        SendToeSignWebService.doPost(documentRec.Id);

        Test.stopTest();
    }

    /*
    * Scenario 2 : Send to eSign with no document id
    */
    static testmethod void testeSignException1() {
        Test.startTest();

        TestObjectsFactory.initializeRestContext(null, '/sendto/eSign');
        SendToeSignWebService.doPost(null);
        
        Test.stopTest();
    }

    /*
    * Scenario 3 : Send to eSign with wrong end point
    */
    static testmethod void testeSignException2() {

        try {   
            TestObjectsFactory.initializeRestContext(null, '/sendto/eSign');
            SendToeSignWebService.throwException = true;
            SendToeSignWebService.doPost(null);
        }catch(Exception ex){
            
        }
    }

}