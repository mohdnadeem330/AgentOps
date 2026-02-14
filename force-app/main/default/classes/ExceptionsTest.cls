/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for all Expections class
*/
@isTest
private class ExceptionsTest {
    static testmethod void testAllExceptions() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        Exceptions.WebServiceException serviceException = new Exceptions.WebServiceException();
        serviceException.statusCode = 400;

        Exceptions.UnitsAlreadyBookedException bookedException = new Exceptions.UnitsAlreadyBookedException();
        bookedException.units = new List<Unit__c>{unitRecord};
        bookedException.unitRemoved = new Set<Id>{unitRecord.Id};

        Exceptions.UnitsTimerExpiredException expired = new Exceptions.UnitsTimerExpiredException();
        expired.units = new List<Unit__c>{unitRecord};

        Exceptions.PaymentPlanException paymentexception = new Exceptions.PaymentPlanException();
        
        Exceptions.IncorrectFilterException incorrectException = new Exceptions.IncorrectFilterException();

        Exceptions.BudgetUnAvailableException budgetException = new Exceptions.BudgetUnAvailableException();
		Exceptions.InsufficientAccessException InsufficientAccessException = new Exceptions.InsufficientAccessException();
        Exceptions.UpdatingAccountsWithDifferentTypesException accountType = new Exceptions.UpdatingAccountsWithDifferentTypesException();
        
        Exceptions.DataNotCompleteException dataNotCompleteException = new Exceptions.DataNotCompleteException();
        dataNotCompleteException.messages = new List<String>();

        Test.stopTest();
    }
}