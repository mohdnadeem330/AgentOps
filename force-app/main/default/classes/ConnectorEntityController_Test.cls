@isTest
private class ConnectorEntityController_Test {

     static testMethod void myUnitTest() {
         ConnectorEntityController cec = new ConnectorEntityController();
         
         Task a = new Task();
         a.Subject='test';
         a.CallType = 'Inbound';
         ConnectorEntityController.createTask(a, 'Email', 'abc@it.it'); 
         
         Case c = new Case();
         c.Subject ='test';
         ConnectorEntityController.createCase(c, 'Email', 'abc@it.it');  
         
         Case c1 = new Case();
         c1.Subject ='test';
         ConnectorEntityController.createSObject(c1);  
         
         ConnectorEntityController.updateCase(c1.Id, '0033i00002Jj8tkAAB');
         ConnectorEntityController.updateCase('5003i00000Gp2A8AAK', '0033i00002Jj8tkAAB');
         
         String ou = ConnectorEntityController.ERCOmniUtilsPath;
         String iwss = ConnectorEntityController.ERCiwsscriptomniPath;
         String su = ConnectorEntityController.ERCsyncUtilsPath;

 		ConnectorEntityController.findContactId('Phone', '+123123123');
                  
         Map<String, Object> objCreate = new Map<String, Object>{
          
             'interactionId' => '1234567890'};
         
         ConnectorEntityController.createConnectorEventTimeLog(objCreate);
         
         Map<String, Object> obj = new Map<String, Object>{
             'callTime'=> 1234567890, 
             'field' => 'softphone_it__Established_Time__c', 
             'interactionId' => '1234567890'};
        
            ConnectorEntityController.updateConnectorEventTimeLog(obj);
         
         
         Map<String, Object> obj2 = new Map<String, Object>{
             'callTime'=> 1234567890, 
             'field' => 'Released_Time__c', 
             'state' => 'answered', 
             'disposition' => 'disposition', 
             'interactionDuration' => 2,
             'totalAcdDuration' => 2,
             'totalIvrDuration' => 2,
             'dispositionDuration' => 2,
             'disposition' => 'disposition', 
             'interactionId' => '1234567890'};
         
         ConnectorEntityController.updateConnectorEventTimeLog(obj2);
    }
    
    static testMethod void myUnitTest2() {
        Contact c = new Contact();
        c.LastName = 'test';
        c.Phone = '123';
        insert c;
        
        Map<String,List<sObject>> fr = ConnectorEntityController.findRecords('123');
        List<SObject> fcl = ConnectorEntityController.findContactAndLead('Phone', '123');
        List<SObject> fcl2 = ConnectorEntityController.findContactAndLead('Email', 'test@test.com');
        
        Task t = new Task();
        t.Subject='test';
        t.CallType = 'Inbound';
        insert t;
        sObject rec = ConnectorEntityController.getLeadPhoneNumberById(t.Id, 'Task');
        String ut = ConnectorEntityController.updateTask(t.Id, c.Id);
        String ct = ConnectorEntityController.closeTask(t.Id, 'test', 'connected', 'Customer Reached','00110011');
        Task ts = ConnectorEntityController.findTask(c.Id);
        
        Lead l = ConnectorEntityController.createLead('Phone', '123');
        Lead l2 = ConnectorEntityController.createLead('Email', 'test@test.com');
        Lead ld =  TestObjectsFactory.getLeadRecord(1,'Person');
       // insert ld;
        String lid = ld.id;
       Lead l3 = ConnectorEntityController.findLead(lid);
        
        sObject so = ConnectorEntityController.getLeadPhoneNumberById(c.Id, 'Lead');
        sObject so2 = ConnectorEntityController.getLeadPhoneNumberById(c.Id, 'Account');
        sObject so3 = ConnectorEntityController.getLeadPhoneNumberById(c.Id, 'Opportunity');
        sObject so4 = ConnectorEntityController.getLeadPhoneNumberById(c.Id, 'HexaBPM__Service_Request__c');
        ConnectorEntityController.getDropdownvalues();

         Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
        Boolean isAcc = ConnectorEntityController.isPersonalAccount(newAccount.Id);
    }
    
    static testMethod void myUnitTest3() {
        Test.startTest();
        User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca');
        System.runAs(cca) {
            Utilities.userDetail = null;
            LeadTriggerHandler.userDetail = Utilities.getLoggedInUserDetail();

            User userDetail = Utilities.getLoggedInUserDetail();
            Lead leadRec2 = TestObjectsFactory.getLeadRecord(3,'Person');
            leadRec2.LeadSource = '800-Aldar';
            leadRec2.EnquiryCategory__c = 'Aldar Database';
            leadRec2.EnquiryTrigger__c = 'Aldar SMS Campaign';
            insert leadRec2;
            Object o;
            ConnectorAgentController cac = new ConnectorAgentController(o);
            ConnectorAgentController.findLead(leadRec2.Id);
            
        }
        Test.stopTest();
    }

}