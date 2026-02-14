/*Class     : paymentGatewayHelper
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/04/24           Initial Version 
****************************************************************************************************************/
public with Sharing class paymentGatewayHelper {
    public static Payment_Gateway_Config__mdt getPaymentConfig(String Identifier){
        return [select id,Home_Page_URL__c,API_Key__c,API_Secret__c,Merchant_Ref_Id__c,Prod_End_Point_URL__c,Sandbox_End_Point_URL__c from Payment_Gateway_Config__mdt where DeveloperName=:Identifier];
    }
}