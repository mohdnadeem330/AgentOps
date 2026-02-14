@isTest
public class DocuSign_WebHookSubscriptionTest {

    @TestSetup
    static void makeData(){
        DocuSign_WebHookSubscription.doGet();
        dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
        envelopeStatus.dfsle__DocuSignId__c   = '24066dc3-2c7b-4459-90d4-83dcc349efdf';
        envelopeStatus.dfsle__SenderName__c   = 'Test Sender'; // Need to know where it is configured
        envelopeStatus.dfsle__SenderEmail__c  = 'test@test.com'; // Need to know where it is configured
        envelopeStatus.dfsle__EmailSubject__c = 'Test Subject';
        envelopeStatus.dfsle__Status__c       = 'Sent';
        envelopeStatus.dfsle__Sent__c         = system.now();
        envelopeStatus.CreatedFromAPI__c      = true;
        insert envelopeStatus;
        List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
        for(Integer i = 1; i <= 2; i++){
            dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c();
            recipientStatus.dfsle__EnvelopeStatus__c = envelopeStatus.Id;
            recipientStatus.dfsle__Email__c = 'test'+i+'@test.com';
            recipientStatus.dfsle__RoutingOrder__c = i;
            recipientStatus.dfsle__SourceId__c = '';
            recipientStatus.dfsle__Type__c = 'Signer';
            recipientStatus.dfsle__Status__c = 'Sent';
            recipientStatus.Name = 'Test Signer '+i;
            recipientStatus.dfsle__Sent__c = System.now();
            recipientStatusList.add(recipientStatus);
        }
        insert recipientStatusList;
    }
    @IsTest
    static void testHandleNotification_Pass(){
        String envelopeId = '24066dc3-2c7b-4459-90d4-83dcc349efdf';
        String completeStatus = 'completed';
        String sentStatus = 'sent';
        String jsonBody = 
        '{"event":"recipient-completed",'
            +'"data":{'
                +'"accountId":"ae2a419f-d3f8-4992-82f4-5d26a1d03508",'
                +'"userId":"52e07e81-0521-4a94-91af-dc9b33f92d2e",'
                +'"envelopeId":"'+envelopeId+'",'
                +'"envelopeSummary":{'
                    +'"status":"'+completeStatus+'","envelopeId":"'+envelopeId+'",'
                    +'"recipients":{'
                        +'"signers":['
                            +'{"name":"Meril","email":"test01@test.com","recipientId":"92880055","routingOrder":"1","status":"'+completeStatus+'","completedCount":"1","recipientType":"signer"},'
                            +'{"name":"JohnSmith","email":"test02.@test.com","recipientId":"10196175","routingOrder":"2","status":"'+completeStatus+'","completedCount":"0","recipientType":"signer"}'
                        +'],'
                        +'"carbonCopies":['
                            +'{"name":"Anita","email":"test@test.com","recipientId":"50756620","routingOrder":"3","status":"created","recipientType":"carboncopy"}'
                        +'],'
                        +'"recipientCount":"3",'
                        +'"currentRoutingOrder":"2"'
                    +'}'
                +'}'
            +'}'
        +'}';
        TestObjectsFactory.initializeRestContext(jsonBody, '/updateResaleOffer');
        Test.startTest();
            DocuSign_WebHookSubscription.handleNotification();
        Test.stopTest();
    }

    @IsTest
    static void testHandleNotification_Exception(){
        String jsonBody = '{[}';
        Test.startTest();
            try {
                DocuSign_WebHookSubscription.handleNotification();                
            } catch (Exception ex) {
                System.debug(ex);
            }
        Test.stopTest();    
    }
}