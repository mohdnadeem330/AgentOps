@isTest
public class DigitalSPACorrectionBatchTest {
	@isTest
    public static void test(){
         // Create test data for dfsle__EnvelopeStatus__c and related dfsle__RecipientStatus__c records
        dfsle__EnvelopeStatus__c envStatus = new dfsle__EnvelopeStatus__c(
            dfsle__DocuSignId__c = 'TestDocuSignId'
        );
        insert envStatus;
        
        dfsle__RecipientStatus__c recipient = new dfsle__RecipientStatus__c(
            dfsle__EnvelopeStatus__c = envStatus.Id,
            dfsle__RoutingOrder__c = 23,
            dfsle__Status__c = 'Sent',
            dfsle__Email__c = 'craiyani@aldar.com'
        );
        insert recipient;
         Test.startTest();
        String soqlstring = 'SELECT Id,dfsle__DocuSignId__c,(SELECT Id,dfsle__EnvelopeStatus__c,dfsle__RoutingOrder__c,dfsle__Status__c,dfsle__Email__c FROM dfsle__Recipients__r) FROM dfsle__EnvelopeStatus__c';
         Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());
        DigitalSPACorrectionBatch bt = new DigitalSPACorrectionBatch(soqlstring,'craiyani@aldar.com','https://eu.docusign.net/restapi/v2.1/accounts/{{accountId}}/envelopes/{{envelopeId}}/recipients/{{recipientId}}','https://eu.docusign.net/restapi//v2.1/accounts/{{accountId}}/envelopes/{{envelopeId}}/notification');
        Database.executeBatch(bt,1);
        Test.stopTest();
    }
}