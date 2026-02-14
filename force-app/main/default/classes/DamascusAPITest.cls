@isTest
public class DamascusAPITest {
    
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        paymentPlanRecord.OnlineFlag__c = true;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
    }
    
    @isTest public static void testGetAPIs2() {
        TestObjectsFactory.initializeRestContext(null, '/getModifiedIds?startDate=2023-01-01&endDate=2023-12-12');
        Damascus_GetModifiedIds.getModifiedIds();
        TestObjectsFactory.initializeRestContext(null, '/getModifiedProjects');
        Damascus_GetModifiedProjects.getModifiedProjects();
        TestObjectsFactory.initializeRestContext(null, '/getModifiedUnits');
        PaymentPlan__c paymentPlanRecord = [SELECT Id FROM PaymentPlan__c LIMIT 1];
        Damascus_RestApiHandler.getModifiedPaymentPlans(new List<String>{paymentPlanRecord.Id});
        TestObjectsFactory.initializeRestContext(null, '/getModifiedPaymentPlan');
        
        Damascus_GetModifiedUnits.getModifiedUnits();
    }
    
    @isTest public static void testGetAPIs() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/getModifiedIds'; 
        req.params.put('startDate', '2023-01-01');
        req.params.put('endDate', '2023-12-12');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Damascus_GetModifiedIds.getModifiedIds();
        
        List<Project__c> projList = new List<Project__c>([SELECT Id FROM Project__c LIMIT 1]);
         RestRequest req2 = new RestRequest(); 
        RestResponse res2 = new RestResponse();
        req2.requestURI = '/getModifiedProjects'; 
        req2.params.put('projectIds',projList[0].Id );
        req2.httpMethod = 'GET';
        req2.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req2;
        RestContext.response = res2;
        Damascus_GetModifiedProjects.getModifiedProjects();
        
        List<Unit__c> unitList = new List<Unit__c>([SELECT Id FROM Unit__c LIMIT 1]);
        RestRequest req3 = new RestRequest(); 
        RestResponse res3 = new RestResponse();
        req3.requestURI = '/getModifiedUnits'; 
        req3.params.put('unitIds',unitList[0].Id );
        req3.httpMethod = 'GET';
        req3.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req3;
        Damascus_GetModifiedUnits.getModifiedUnits();
        
         List<PaymentPlan__c> ppList = new List<PaymentPlan__c>([SELECT Id FROM PaymentPlan__c LIMIT 1]);
        RestRequest req4 = new RestRequest(); 
        RestResponse res4 = new RestResponse();
        req4.requestURI = '/getModifiedPaymentPlan'; 
        req4.params.put('paymentPlanIds',ppList[0].Id );
        req4.httpMethod = 'GET';
        req4.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req4;
        Damascus_GetModifiedPaymentPlan.getModifiedPaymentPlans();
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567811';
        projectRecord.Split_inventory_on_Damascus__c = true;
        insert projectRecord;
         RestRequest req5 = new RestRequest(); 
        RestResponse res5 = new RestResponse();
        req5.requestURI = '/getModifiedProjects'; 
        req5.params.put('projectIds',projectRecord.Id );
        req5.httpMethod = 'GET';
        req5.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req5;
        RestContext.response = res5;
        Damascus_GetModifiedProjects.getModifiedProjects();

//        User usr1 = UserClaimApi.getClaimUser();
//        System.debug(usr1);
//        TestObjectsFactory.initializeRestContext(null, '/getModifiedIds?startDate=2023-01-01&endDate=2023-12-12');
//        Damascus_GetModifiedIds.getModifiedIds();
        /*CancelDirectDebitWebService.doPost(ddr2.Id, 'test remarks cancellation');
        CancelDirectDebitWebService.doPost('asdfghj', 'test remarks cancellation');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');*/
//        RestContextHandler handler = new RestContextHandler(false);
    }
    
    @isTest public static void testData () {
        List<Project__c> projList = new List<Project__c>([SELECT Id FROM Project__c LIMIT 1]);  
        
        Project__c projectRecord1 = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord1.IBANNoCorporate__c = '1234567822';
        projectRecord1.Parent_Project__c = projList[0].Id;
        insert projectRecord1;
        Project__c proj = [SELECT Id, Name, CommunityName__c, ProjectLocation__c, Amenities__c, City__c,Parent_Project__r.Description__c,Parent_Project__r.Amenities__c,Parent_Project__r.City__c,Parent_Project__r.FeaturedProject__c,Parent_Project__r.CurrencyIsoCode,Parent_Project__r.VirtualTour__c, CurrencyIsoCode, VirtualTour__c, Description__c,VideoLink__c, Parent_Project__c,Parent_Project__r.Damascus_Community_Name__c,Parent_Project__r.CommunityName__c,LastModifiedDate,FeaturedProject__c,Split_inventory_on_Damascus__c,Damascus_Community_Name__c,Parent_Project__r.Name, Parent_Project__r.VideoLink__c,( SELECT Id,Split_Project_Name__c,Split_Project_Id__c,Damascus_Splitted_Project_Description__c FROM BuildingsSectionsProject__r),(SELECT Id,ProjectLocation__c,Split_inventory_on_Damascus__c,Parent_Project__c,Name,CommunityName__c,Description__c,Amenities__c,City__c,FeaturedProject__c,CurrencyIsoCode,VideoLink__c,VirtualTour__c FROM Projects__r), Parent_Project__r.ProjectLocation__c FROM Project__c WHERE Id =:projList[0].Id LIMIT 1];
        RestRequest req6 = new RestRequest();
        RestResponse res6 = new RestResponse();
        req6.requestURI = '/getModifiedProjects'; 
        req6.params.put('projectIds',projList[0].Id );
        req6.httpMethod = 'GET';
        req6.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req6;
        RestContext.response = res6;
        Damascus_GetModifiedProjects.getModifiedProjects();      
    }
    
    @isTest public static void testGetRecordsBulk() {
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c bld = [SELECT Id FROM BuildingSection__c LIMIT 1];
        
        List<Unit__c> unitRecord = new List<Unit__c>();
        for(Integer i = 0;i<=30;i++){
            Unit__c u = TestObjectsFactory.getUnitDetail(pro.id,bld.id);
            u.Name = u.Name + '' + String.valueOf(i);
            unitRecord.add(u);
        }
        Insert unitRecord;
        List<Project__c> projRecord = new List<Project__c>();
        for(Integer i = 0;i<=30;i++){
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan'+String.valueOf(i) );
            projectRecord.IBANNoCorporate__c = '1234567890';
            projRecord.add(projectRecord);
        }
        Insert projRecord;
        Map<Id,Unit__c> unitMap = new Map<Id,Unit__c>([SELECT Id FROM Unit__c]);
        String idString = string.join(unitMap.keySet(),',');
        Map<Id,Project__c> projMap = new Map<Id,Project__c>([SELECT Id FROM Project__c]);
        String idStringProj = string.join(projMap.keySet(),',');

        
        List<Project__c> projList = new List<Project__c>([SELECT Id FROM Project__c LIMIT 1]);
        RestRequest req2 = new RestRequest(); 
        RestResponse res2 = new RestResponse();
        req2.requestURI = '/getModifiedProjects'; 
        req2.params.put('projectIds',idStringProj );
        req2.httpMethod = 'GET';
        req2.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req2;
        RestContext.response = res2;
        Damascus_GetModifiedProjects.getModifiedProjects();
        
        RestRequest req3 = new RestRequest(); 
        RestResponse res3 = new RestResponse();
        req3.requestURI = '/getModifiedUnits'; 
        req3.params.put('unitIds',idString );
        req3.httpMethod = 'GET';
        req3.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req3;
        RestContext.response = res3;

        try{
        Damascus_GetModifiedUnits.getModifiedUnits();
            
        }catch(Exception e){
            
        }
        
    }

}