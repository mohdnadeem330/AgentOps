@isTest
public class PremPark_OrderIntegrationUtilsTest {
     @testSetUp
    public static void testData(){
        
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        insert acc;
        
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Opportunity' ;
        newOppty.Lead_Type__c ='New Sale';
        //newOppty.Buyerservicecharge__c =1;
       // newOppty.Sellerservicecharge__c =1;
        newOppty.AccountId = acc.Id ; 
        newOppty.CloseDate = system.today().adddays(10);
        newOppty.StageName = 'New';
        newOppty.ExpectedEndDate__c=System.Today();
        newOppty.EnquiryCategory__c = 'Aldar Employees';
        newOppty.EnquiryTrigger__c = 'Aldar';
        newOppty.SalesTypefromLead__c = 'Commercial Land';
        newOppty.PropertyUsage__c = 'Land';
        newOppty.Project__c = 'Al Falah';
        newOppty.LeadSource = 'Direct Call';
        insert newOppty ;
	
    ReceiptAcknowledgement__c newReceiptAcknowledgement = new ReceiptAcknowledgement__c();
        newReceiptAcknowledgement.PaymentType__c = 'Online';
        newReceiptAcknowledgement.Amount__c = 100000;
        
        newReceiptAcknowledgement.Opportunity__c = newOppty.Id;
        
        newReceiptAcknowledgement.Remarks__c = 'Test Remark';
        newReceiptAcknowledgement.CustomerBankAccount__c = '1234567890';
        newReceiptAcknowledgement.ReferenceNumber__c = '1234567890';
        newReceiptAcknowledgement.MortgageCheque__c = true;
        newReceiptAcknowledgement.MaturityDate__c = Date.today();
        insert newReceiptAcknowledgement;
	}
    @isTest
    static void OrderIntegrationUtils(){
    
    }
    @isTest
    static void WholeReceiptAsMap(){
        list<ReceiptAcknowledgement__c> receiptToPas= [SELECT Id,Name FROM ReceiptAcknowledgement__c ];
        Set<Id> receiptIdSet = new set<id>();
        
        for (ReceiptAcknowledgement__c record : receiptToPas) {
			receiptIdSet.add(record.Id);
		}
        Test.startTest();
        PremPark_OrderIntegrationUtils.getWholeReceiptAsMap(receiptIdSet);
        Test.stopTest();
        
    
    }

}