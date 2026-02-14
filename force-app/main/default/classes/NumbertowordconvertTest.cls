@isTest
public class NumbertowordconvertTest {
    
    @isTest
    static void testStandardController() {
        
        Payment_Request__c pr = new Payment_Request__c();
        pr.Amount__c = 11234;
        pr.Is_VAT_Applicable__c =true;
        insert pr;
        
        Payment_Request__c pr1=[select amount__c,Amount_Exclusive_VAT__c from Payment_Request__c where id =:pr.id];
        ApexPages.StandardController sc = new ApexPages.StandardController(pr1);
        
        
        NumberToWordConvert ntwc = new NumberToWordConvert(sc);
        ntwc.totalAmount=11234.50;
        ntwc.fivePercent=0.0;
        ntwc.totalAmountInWords='';
         ntwc.recordid=pr1.id;
         PageReference resultPage =ntwc.save(); 
    }
    
}