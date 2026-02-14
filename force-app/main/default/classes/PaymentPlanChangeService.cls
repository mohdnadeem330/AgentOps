public with sharing class PaymentPlanChangeService {
    /*
    *********************************************************
    @Method Name    : checkPaidEquity
    @author         : 
    @description    : Method to validate the Paid Equity field value
    @param          : newRecord 
    @return         : void
    ********************************************************
    */
    public static void checkPaidEquity(HexaBPM__Service_Request__c newRecord){
        if (newRecord.PaidEquity__c == 100) {
            newRecord.addError(ServiceRequestTriggerHelper.getSystemMessagesMap().get(Constants.PPC_PAID_EQUITY_100_VALIDATION).Message__c);
        }        
    }
}