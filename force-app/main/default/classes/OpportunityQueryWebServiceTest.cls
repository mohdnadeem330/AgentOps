@istest
    public class OpportunityQueryWebServiceTest {
    
    static Opportunity opportunityRec ;
    static Account AbuDhabiAcc;
    static Account DubaiAcc;
    
    static void init(){
        List<Account> lstAcc = new List<Account>();
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.PersonEmail = 'dupecheck@test.com';
        newAccount.BillingState ='Abu Dhabi';
        ////newAccount.FastTrackedAccount__c = True;
        lstAcc.add(newAccount);
        Account newDubaiAccount = TestObjectsFactory.getPersonAccountRecord();
        newDubaiAccount.PersonEmail = 'dupecheck@test.com';
        newDubaiAccount.BillingState ='Dubai';
        newDubaiAccount.FastTrackedAccount__c = false;
        newDubaiAccount.ProspectAccount__c = true;
        
        Account newDubaiAccount1 = TestObjectsFactory.getPersonAccountRecord();
        newDubaiAccount1.PersonEmail = 'dupecheck@test.com';
        newDubaiAccount1.BillingState ='Dubai';
        newDubaiAccount1.FastTrackedAccount__c = false;
        newDubaiAccount1.ProspectAccount__c = true;
        lstAcc.add(newDubaiAccount1);
        insert lstAcc ; 
        AbuDhabiAcc = lstAcc[0];
        DubaiAcc = lstAcc[1]; 
        
        opportunityRec = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opportunityRec ;
    }
    
    static testmethod void testAllOpportunity(){
        
        //init();
          
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.PersonEmail = 'dupecheck@test.com';
        newAccount.BillingState ='Abu Dhabi';
        insert newAccount ; 
        
        opportunityRec = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opportunityRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/opportunity');
        OpportunityQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        OpportunityQueryWebService.doPost();
    }
    
    static testmethod void testOpportunitybyId(){
        
        init();
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('Id', opportunityRec.Id);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        OpportunityQueryWebService.doPost();
    }
    
    
    static testmethod void testOpportunitybybrokerLeadException(){
        
        init();
        Lead leadRec = new Lead();
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupecheck@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        leadRec.BrokerAgency__c = AbuDhabiAcc.Id;
        insert leadRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        Lead lead = [SELECT LeadNumber__c FROM Lead where Id=: leadRec.Id];
        System.debug('lead num '+leadRec.Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('brokerLeadNumber', lead.LeadNumber__c);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        OpportunityQueryWebService.doPost();
    }
    
    static testmethod void testOpportunitybybrokerLead(){
        
        init();
        Lead leadRec = new Lead();
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupecheck@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        leadRec.BrokerAgency__c = DubaiAcc.Id;
        insert leadRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        Lead lead = [SELECT LeadNumber__c FROM Lead where Id=: leadRec.Id];
        System.debug('lead num '+leadRec.Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('brokerLeadNumber', lead.LeadNumber__c);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        OpportunityQueryWebService.doPost();
    }
     static testmethod void testOpportunitybybrokerLeadException2(){
        
        init();
        Lead leadRec = new Lead();
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupecheck@test.com';
        leadRec.LeadSource = 'Broker Portal' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        leadRec.BrokerAgency__c = AbuDhabiAcc.Id;
        leadRec.ExistingAccount__c = DubaiAcc.Id;
        insert leadRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        Lead lead = [SELECT LeadNumber__c,SkipDuplicateApprovalStatus__c,IsConverted FROM Lead where Id=: leadRec.Id];
        System.debug('lead num '+leadRec.Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('brokerLeadNumber', lead.LeadNumber__c);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        OpportunityQueryWebService.doPost();
    }
    static testmethod void testOpportunitybybrokerLeadException3(){
        
        init();
        Lead leadRec = new Lead();
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupecheck@gmail.com';
        leadRec.CustomerType__c = 'VIP';
        leadRec.CustomerSubType__c = 'VIP TIER 1';
        leadRec.LeadSource = 'Broker Portal' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        leadRec.BrokerAgency__c = DubaiAcc.Id;
        leadRec.ExistingAccount__c = AbuDhabiAcc.Id;
        insert leadRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        Lead lead = [SELECT LeadNumber__c,SkipDuplicateApprovalStatus__c,IsConverted FROM Lead where Id=: leadRec.Id];
        System.debug('lead num '+leadRec.Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('brokerLeadNumber', lead.LeadNumber__c);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        OpportunityQueryWebService.LeadVIpResponse lr = new OpportunityQueryWebService.LeadVIpResponse();
        lr.showVIPException = true;
        OpportunityQueryWebService.doPost();
    }
    static testmethod void testOpportunitybybrokerLeadException4(){
        
        init();
        Lead leadRec = new Lead();
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupecheck@gmail.com';
        leadRec.LeadSource = 'Broker Portal' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        leadRec.BrokerAgency__c = AbuDhabiAcc.Id;
        leadRec.ExistingAccount__c = DubaiAcc.Id;
        insert leadRec ;
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        Lead lead = [SELECT LeadNumber__c,Approval_Status__c,IsConverted FROM Lead where Id=: leadRec.Id];
        lead.Approval_Status__c = 'In Progress';
        System.debug('lead num '+leadRec.Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('brokerLeadNumber', lead.LeadNumber__c);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        //OpportunityQueryWebService.ConvertedLead cl = new OpportunityQueryWebService.ConvertedLead();
        //cl.isBrokerLead = false;
        OpportunityQueryWebService.doPost();
    }
    
    
}