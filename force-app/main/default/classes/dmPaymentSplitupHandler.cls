/***
Class       : dmPaymentSplitupHandler
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0               20/04/2024          Initial Version 
****************************************************************************************************************/

public class dmPaymentSplitupHandler {
    
    @AuraEnabled
    public static Case getCaseInfo(String recId){
        return [SELECT Id,Request_split_payment__c,Total_Amount__c,Number_Of_Installments__c,(select id,Amount__c,Instalment_Date__c,Payment_Type__c,Instalment_Percentage__c,Instalment_No__c from Payment_Requests__r where Pay_For__c != 'Overstay' ORDER BY Instalment_No__c) from Case WHERE Id=:recId];
    }
    @AuraEnabled
    public static void createPaymentReqs(list<Payment_Request__c> payments){
        try {
            upsert payments;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}