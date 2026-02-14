@istest
public class UnitQueryWebServiceTest {
    
        static Unit__c unitRec ;
    
        static void init(){
            Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
            insert acc;
            
            Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
            con.Email = 'ali.athamneh@pwc.com';
            update con;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            
            unitRec = TestObjectsFactory.unitDataSetup('25083');
            unitRec.Status__c = 'Sold';
            insert unitRec;
            Project__c p = [SELECT Id FROM Project__c LIMIT 1];
            p.DPGApplicable__c = true;
            Update p;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitRec.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        salesOrder.ADMFeeAmount__c = 20000;
        insert salesOrder;
        }
        
        static testmethod void testAllUnits(){
    
            init();
    
            TestObjectsFactory.initializeRestContext(null, '/query/units');
            OpportunityQueryWebService.doPost();
            TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
            RestContextHandler handler = new RestContextHandler(false);
            //UnitQueryWebService.doPost();
            UnitQueryWebServiceNew.doPost();
        }
    
        static testmethod void testUnitbyId(){
    
            AllocationGroup__c allocationGroup = TestObjectsFactory.getAllocationGroup('Dubai Team','DXB');
        	insert allocationGroup ;
            User userDetail = Utilities.getLoggedInUserDetail();
            
            AllocationGroupUser__c newGroupUser = TestObjectsFactory.getAllocationGroupUser(userDetail,allocationGroup);
        	insert newGroupUser ;
            
            init();
            TestObjectsFactory.initializeRestContext(null, '/query/units');
            
            Map<String, String> searchMap = new Map<String, String>();
            searchMap.put('Id', unitRec.Id);
            searchMap.put('PV_Community_Name', 'Mayan');
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
            //UnitQueryWebService.doPost();
            UnitQueryWebServiceNew.doPost();
        }
      static testmethod void testUnitbyId2(){
    
            AllocationGroup__c allocationGroup = TestObjectsFactory.getAllocationGroup('Dubai Team','DXB');
        	insert allocationGroup ;
            User userDetail = Utilities.getLoggedInUserDetail();
            
            AllocationGroupUser__c newGroupUser = TestObjectsFactory.getAllocationGroupUser(userDetail,allocationGroup);
        	insert newGroupUser ;
            
            init();
            TestObjectsFactory.initializeRestContext(null, '/query/units1');
            
            Map<String, String> searchMap = new Map<String, String>();
            searchMap.put('Id', unitRec.Id);
            searchMap.put('PV_Community_Name', 'Mayan');
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
            UnitQueryWebService.doPost();
            //UnitQueryWebServiceNew.doPost();
        }
     static testmethod void testAllUnits2(){
    
            init();
    
            TestObjectsFactory.initializeRestContext(null, '/query/units');
            OpportunityQueryWebService.doPost();
            TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
            RestContextHandler handler = new RestContextHandler(false);
            UnitQueryWebService.doPost();
           // UnitQueryWebServiceNew.doPost();
        }

/*
        static testmethod void testOpportunitybybrokerLeadException(){
    
            init();
            TestObjectsFactory.initializeRestContext(null, '/query/lead');
            
            Map<String, String> searchMap = new Map<String, String>();
            searchMap.put('brokerLeadNumber', '2134233');
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
            OpportunityQueryWebService.doPost();
        }*/
    }