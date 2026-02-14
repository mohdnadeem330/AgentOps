@isTest
public class DMCaseSendDocToCustomerTest {
    @isTest
    static void test() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Case cs = new Case(Type = 'Temporary License Agreement',
                           Status = 'New',
                           Subject = 'Test TLA Application',
                           AccountId = acc.Id, 
                           ContactId = con.Id,
                           Licensee_Email__c = 'sadhana.pachigolla@smaartt.com',
                           recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
                           Development_Name__c='Saadiyat Island');
        insert cs;        
        DMCaseSendDocToCustomer.sendEvacutionchklst(cs.Id);
        DMCaseSendDocToCustomer.SendOverstayDetails(cs.Id); 
        
    }
    @isTest
    static void test1() {
        // Create a Case record with necessary fields
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Case cs = new Case(Type = 'Temporary License Agreement',
                           Status = 'New',
                           Subject = 'Test TLA Application',
                           AccountId = acc.Id, 
                           ContactId = con.Id,
                           recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
                           Development_Name__c='Saadiyat Island');
        insert cs;
        Document__c document = new Document__c();
        document.DocumentType__c = 'Evacuation Checklist';
        document.Case__c = cs.Id; 
        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        document.Other_Document_Name__c = 'aldarDocName';
        insert document;
        Payment_Request__c paymentRequest = new Payment_Request__c(Case__c = cs.Id, Amount__c = 500,Payment_Type__c = 'CDC');
        insert paymentRequest;
        List<Payment_Request__c> paymentRequests = new list<Payment_Request__c>();
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        Loop__DDP__c loopdd = New Loop__DDP__c();
        loopdd.Name = 'Temporary License Agreement';
        insert loopdd;
        Loop__DDP_Integration_Option__c loopdrec = new Loop__DDP_Integration_Option__c();
        loopdrec.Loop__DDP__c = loopdd.id;
        loopdrec.Name = 'TLA';
        insert loopdrec;
        Test.StartTest();
        DMCaseSendDocToCustomer.generateDocument(loopdd.id,loopdrec.id,document.id);
        //DMCaseSendDocToCustomer.PaymentReqforGenerationOfOverStayInvoice(cs.Id,false);
        // DMCaseSendDocToCustomer.generatePdf(paymentRequest.Id, true, 'payment');
        try{
            DMCaseSendDocToCustomer.createAndLinkDocument(cs.id,'draft TLA');}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        } 
        
        DMCaseSendDocToCustomer.CommaseparatedValues(paymentRequest.Amount__c);
        try{
            DMCaseSendDocToCustomer.caseCloseRequest(cs.Id);}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }        
        try{
            DMCaseSendDocToCustomer.createAndLinkDocument(cs.id,'draft CAS');}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }
        Test.StopTest();
        
        
    }
     @isTest
    static void test2() {
        // Create a Case record with necessary fields
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Case cs = new Case(Type = 'Temporary License Agreement',
                           Status = 'New',
                           Subject = 'Test TLA Application',
                           AccountId = acc.Id, 
                           ContactId = con.Id,
                           recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId(),
                           Development_Name__c='Saadiyat Island');
        insert cs;
        Document__c document = new Document__c();
        document.DocumentType__c = 'Evacuation Checklist';
        document.Case__c = cs.Id; 
        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        document.Other_Document_Name__c = 'aldarDocName';
        insert document;
        List<Payment_Request__c> paymentRequests = new list<Payment_Request__c>();
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        paymentRequests.add(new Payment_Request__c(Case__c = cs.Id, Amount__c = 500, Payment_Type__c = 'PDC'));
        insert paymentRequests;
        Loop__DDP__c loopdd = New Loop__DDP__c();
        loopdd.Name = 'Temporary License Agreement';
        insert loopdd;
        Loop__DDP_Integration_Option__c loopdrec = new Loop__DDP_Integration_Option__c();
        loopdrec.Loop__DDP__c = loopdd.id;
        loopdrec.Name = 'TLA';
        insert loopdrec;
        Test.StartTest();
        DMCaseSendDocToCustomer.generateDocument(loopdd.id,loopdrec.id,document.id);
        //DMCaseSendDocToCustomer.PaymentReqforGenerationOfOverStayInvoice(cs.Id,false);
        // DMCaseSendDocToCustomer.generatePdf(paymentRequest.Id, true, 'payment');
        try{
            DMCaseSendDocToCustomer.createAndLinkDocument(cs.id,'draft TLA');}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        } 
        
       // DMCaseSendDocToCustomer.CommaseparatedValues(paymentRequest.Amount__c);
        try{
            DMCaseSendDocToCustomer.caseCloseRequest(cs.Id);}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }        
        try{
            DMCaseSendDocToCustomer.createAndLinkDocument(cs.id,'draft CAS');}
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }
        Test.StopTest();
        
        
    }
}