@isTest
public class ECSS_CongaDocumentGenerator_Test {
    @testSetup
    static void testSetup()
    {
        APXTConga4__Conga_Solution__c congaSol = new APXTConga4__Conga_Solution__c ();
        congaSol.Name = 'Residential Leasing Offer Letter';
        congaSol.APXTConga4__Button_body_field__c = '/apex/APXTConga4__Conga_Composer?SolMgr=1';
		congaSol.APXTConga4__Button_body_field__c+= '&serverUrl={!API.Partner_Server_URL_520}';
		congaSol.APXTConga4__Button_body_field__c+='&Id={!Quote.Id}';
		congaSol.APXTConga4__Button_body_field__c+='&QueryId=[Quote]0Q_0152A2774380%3Fpv0%3DId';
        congaSol.APXTConga4__Button_body_field__c+='&TemplateId=0T_0102A2132792';
        insert congaSol;
        
    } 
    @isTest
    static void testGenerateCongaComposerLink (){
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'test Opp';
        insert testOpp;
        Quote q = new Quote();
        q.OpportunityId = testOpp.Id;
        q.Name = 'testQuote';
        insert q;
        Test.startTest();
        String link = ECSS_CongaDocumentGenerator.generateCongaComposerLink('Residential Leasing Offer Letter',q.Id,null);
        String queryString = ECSS_CongaDocumentGenerator.generateCongaQueryString('Residential Leasing Offer Letter',q.Id);
        Test.stopTest();
    }
}