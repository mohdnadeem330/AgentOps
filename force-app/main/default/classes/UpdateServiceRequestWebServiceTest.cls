@IsTest
public class UpdateServiceRequestWebServiceTest {
 @isTest
    public static void testCustomerServiceRequestWebServicePropertyTransfer() {

        Account buyerAcc = TestObjectsFactory.getPersonAccountRecord();
        insert buyerAcc;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(buyerAcc.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, buyerAcc.Id);
        so.Unit__c = unit.Id;
        so.IsBookingCompleted__c = true;
        so.NetAmount__c = 100000;
        so.SellingPrice__c = 1000000;
        insert so;
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);
        insert spaTemp;
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');
        insert Submitted;
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');
        insert closed;
        
        Id spaRt = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        HexaBPM__Service_Request__c spaSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaRt, spaTemp.Id);
        spaSR.SalesOrder__c = so.Id;
        spaSR.SPACounterSignedDate__c = Date.today();
        insert spaSR;
        
        HexaBPM__SR_Template__c offPlanTemplate = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_OffPlan);
        offPlanTemplate.Name = 'Property Transfer (Off Plan)';
        insert offPlanTemplate;
        
        Id offPlanRT = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer ( Off Plan )') != null? Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer ( Off Plan )').getRecordTypeId(): Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer (Off Plan)').getRecordTypeId();
        HexaBPM__Service_Request__c offSR = TestObjectsFactory.getServiceRequest(null, unit.Id, Constants.PROPERTY_TRANSFER_OffPlan, offPlanRT, offPlanTemplate.Id);
        offSR.Origin__c = 'Customer Portal';
        //offSR.HexaBPM__Customer__c = sellerAcc.Id;
        //offSR.BuyerName__c = buyerAcc.PersonContactId;
        offSR.HexaBPM__External_SR_Status__c = Submitted.Id;
        insert offSR;
        
        OperatingHours oh = new OperatingHours();
        oh.Name = 'TestOH';
        insert oh;
        ServiceTerritory srvt = New ServiceTerritory();
        srvt.Name = 'Noya';
        srvt.OperatingHoursId = oh.Id;
        insert srvt;
        
        

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        
        Test.startTest();
        try {
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestURI = '/services/apexrest/customer/UpdateServiceRequest';
            
            String bodyIf = '{"requestType":"PropertyTransferOffPlan",'
                + '"requestId":"'+ offSR.Id +'",'
                + '"location":"'+ srvt.Id +'",'
                + '"pdcCollectionLocation": null,'
                + '"pdcCollectionDate": null}';
            
            RestContext.request.requestBody = Blob.valueOf(bodyIf);
            
            UpdateServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestURI = '/services/apexrest/customer/UpdateServiceRequest';
            
            String bodyElse = '{"requestType":"PropertyTransferOffPlan",'
                + '"requestId":"'+ offSR.Id +'",'
                + '"pdcCollectionLocationName":"Dubai",'
                + '"pdcCollectionDate":"'+ Date.today().addDays(2).format() +'"}';
            
            RestContext.request.requestBody = Blob.valueOf(bodyElse);
            
            UpdateServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetData(){
        OperatingHours oh = new OperatingHours(Name = 'TestOH');
        insert oh;

        ServiceTerritory srvt = new ServiceTerritory();
        srvt.Name = 'Dubai';
        srvt.OperatingHoursId = oh.Id;
        srvt.Type__c = 'Property Transfer';
        srvt.Street = 'Street 1';
        srvt.City = 'Abu Dhabi';
        srvt.State = 'Abu Dhabi';
        srvt.Country = 'United Arab Emirates';
        srvt.PostalCode = '00000';
        insert srvt;
        
        ServiceTerritory srvt2 = new ServiceTerritory();
        srvt2.Name = 'Abu Dhabi	';
        srvt2.OperatingHoursId = oh.Id;
        srvt2.Type__c = 'Property Transfer';
        srvt2.Street = 'Aldar Abu dhabi	';
        srvt2.City = 'Abu Dhabi';
        srvt2.State = 'Abu Dhabi';
        srvt2.Country = 'United Arab Emirates';
        srvt2.PostalCode = '00000';
        insert srvt2;
        
       	RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/customer/UpdateServiceRequest';
        req.httpMethod = 'GET';
        
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UpdateServiceRequestWebService.getData();
        Test.stopTest();
        
    }

}