@isTest
private class LeadServiceTest {
  
    @isTest(SeeAllData=false)
    public static void testCallMethods(){

        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        objLead1.agencyName__c = 'Address Point Properties L.L.C';
        objLead1.agentName__c = 'Brooke Reynolds';
        objLead1.offer1__c = '2020 Free for 3 offer';
        insert objLead1;

        LeadService.getLeadDetailsMapbyId(objLead1.Id);
        LeadService.getAllLeadByIds(new Set<Id>{objLead1.Id});
        LeadService.fetchLeadById(objLead1.Id);

        Test.stopTest();
    }

    @isTest
    public static void testTetchingMethods(){
        Test.startTest();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        insert personAcc;

        Lead leadRec = TestObjectsFactory.getLeadRecord(2,'Person');
        leadRec.ExistingAccount__c = personAcc.Id;
        insert leadRec;
        
        String leadNumber = [SELECT LeadNumber__c From Lead WHERE Id =: leadRec.Id].LeadNumber__c;

        LeadService.fetchLeadByAccountId(personAcc.Id);
        LeadService.fetchLeadForAPIByUser(UserInfo.getUserId());
        LeadService.fetchLeadNumber(new Set<Id>{leadRec.Id});
        LeadService.fetchLeads('FirstName != null');
        LeadService.fetchLeadByLeadNumber(leadNumber);
        LeadService.fetchLeadByMobilePhone(leadRec.MobilePhone);

        Test.stopTest();

    }

    @isTest
    public static void testConvertMethods(){

        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead objLead = TestObjectsFactory.getLeadRecord(1,'Person');
        insert objLead;
        LeadService.convertLead(new List<Id> {objLead.Id});

        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        
        insert objLead1;
        LeadService.populateOfferRecord(new List<Lead>{objLead1});
        Test.stopTest();
    }
}