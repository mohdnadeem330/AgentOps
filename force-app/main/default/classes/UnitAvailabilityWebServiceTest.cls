/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for UnitAvailabilityWebService which checks if the unit can be booked or not.
*/
@isTest
public class UnitAvailabilityWebServiceTest {
    
    private static void setupRestRequest(String requestBody){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/booking/unitverification';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
    }
    
    @TestSetup
    public static void testSetupData(){
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.FirstName = 'Test';
        acc.LastName = ' Non-Resident';
        acc.ResidentStatus__pc = 'Non-Resident';
        acc.Nationality__pc = 'India';
        insert acc;
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Mamsha Gardens';
        insert proj;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'In-Progress';
        unit.LockExpiryTime__c = System.now().addDays(2);
        unit.LockedByCustomer__c = acc.Id;
        unit.Project__c = proj.Id;
        unit.DigitalSales__c = true;
        insert unit;
        
        Unit__c un = TestObjectsFactory.unitDataSetup('25083');
        un.Status__c = 'Available';
        un.Project__c = proj.Id;
        un.DigitalSales__c = true;
        insert un;
        
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('25083');
        newUnit.Status__c = 'Available';
        newUnit.Project__c = proj.Id;
        newUnit.DigitalSales__c = false;
        insert newUnit;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Reservation In Progress';
        insert salesOrder;
        
        unit.RelatedSalesOrder__c = salesOrder.Id;
        update unit;
        
        Lead lead = TestObjectsFactory.getLeadRecord(1,'Person');
        lead.FirstName = 'Testing';
        lead.LastName = 'Lead';
        lead.OwnerId = userInfo.getUserId();
        lead.ExistingAccount__c= acc.Id;
        lead.ResidentStatus__c = 'Non-Resident';
        lead.Lead_Type__c = 'New Sale';
        lead.Unit__c = unit.Id;
        lead.EnquiryTrigger__c ='3meed';
        lead.EnquiryCategory__c = 'Affiliates';
        lead.Project__c = 'Mamsha Gardens';
        lead.UnitType__c = 'Apartment';
        lead.BuyRent__c = 'Buy';
        lead.CustomerBudget__c = '700,000 - 999,000';
        lead.NumberOfBedrooms__c = '1 Bed';
        lead.PurposeOfUse__c = 'End User';
        lead.PropertyReadiness__c = 'Ready';
        lead.Financing__c = 'No';
        lead.LeadSource = 'Broker Portal';
        lead.InitiateDigitalBooking__c = true;
        
        insert lead;
        
        Communication_Preference__c cpRecord = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Broker Portal',
            Status__c = 'Fasttrack Completed',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Lead__c = lead.Id,
            FastTrack_Completion_Date_Time__c = System.today().addDays(-10));
        
        insert cpRecord;
        
        Communication_Preference__c newCPRecord = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Broker Portal',
            Status__c = 'Link Sent',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Lead__c = lead.Id,
            FastTrack_Completion_Date_Time__c = System.today()
        );
        insert newCPRecord;
    }
    
    @isTest
    public static void unitAvailabilityPositiveTest(){
        Test.startTest();
        Account acc = [Select Id,ResidentStatus__pc,Nationality__pc,NationalIdExpiryDate__pc,PassportExpiryDate__pc From Account Where Name = 'Test Non-Resident' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = true Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'unitIds' => new List<String>{unit.Id},
                'purpose' => Constants.UNIT_LOCKING,
                'reservationOrBooking' => Constants.RESERVE_PROCESS,
                'digitalSales' => true,
                'CustomerId' => acc.Id
                });
        
        setupRestRequest(requestBody);
        UnitAvailabilityWebService.doPost(new List<Id>{unit.Id},Constants.UNIT_LOCKING,Constants.RESERVE_PROCESS,true,acc.Id,null,null);
        Test.stopTest();
    }
    
    @isTest
    public static void unitAvailabilityNegativeTest(){
        Test.startTest();
        Account acc = [Select Id,ResidentStatus__pc,Nationality__pc,NationalIdExpiryDate__pc,PassportExpiryDate__pc From Account Where Name = 'Test Non-Resident' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = true Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'unitIds' => new List<String>{unit.Id},
                'purpose' => Constants.UNIT_LOCKING,
                'reservationOrBooking' => Constants.BOOKING_PROCESS,
                'digitalSales' => true,
                'CustomerId' => acc.Id
                });
        
        setupRestRequest(requestBody);
        UnitAvailabilityWebService.doPost(new List<Id>{unit.Id},Constants.UNIT_LOCKING,Constants.BOOKING_PROCESS,false,acc.Id,null,null);
        Test.stopTest();
    }
    
    @isTest
    public static void unitAvailabilityWithFalseDigitalSales(){
        Test.startTest();
        Account acc = [Select Id,ResidentStatus__pc,Nationality__pc,NationalIdExpiryDate__pc,PassportExpiryDate__pc From Account Where Name = 'Test Non-Resident' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = false Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'unitIds' => new List<String>{unit.Id},
                'purpose' => Constants.UNIT_LOCKING,
                'reservationOrBooking' => Constants.RESERVE_PROCESS,
                'digitalSales' => true,
                'CustomerId' => acc.Id
                });
        
        setupRestRequest(requestBody);
        UnitAvailabilityWebService.doPost(new List<Id>{unit.Id},Constants.UNIT_LOCKING,Constants.RESERVE_PROCESS,true,acc.Id,null,null);
        Test.stopTest();
    }
    
    @isTest
    public static void unitBookingTest(){
        Test.startTest();
        Account acc = [Select Id,ResidentStatus__pc,Nationality__pc,NationalIdExpiryDate__pc,PassportExpiryDate__pc From Account Where Name = 'Test Non-Resident' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = true Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'unitIds' => new List<String>{unit.Id},
                'purpose' => Constants.UNIT_LOCKING,
                'reservationOrBooking' => Constants.BOOKING_PROCESS,
                'digitalSales' => true,
                'CustomerId' => acc.Id
                });
        
        setupRestRequest(requestBody);
        UnitAvailabilityWebService.doPost(new List<Id>{unit.Id},Constants.UNIT_LOCKING,Constants.BOOKING_PROCESS,true,acc.Id,null,null);
        Test.stopTest();
    }
    
    @isTest
    public static void checkCustomerKYCStatusTest(){
        Test.startTest();
        Account acc = [Select Id,ResidentStatus__pc,Nationality__pc,NationalIdExpiryDate__pc,PassportExpiryDate__pc From Account Where Name = 'Test Non-Resident' Limit 1];
        
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.checkCustomerKYCStatusHelper(acc.Id,response);
        UnitAvailabilityWebService.checkCustomerKYCStatus(acc.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void brokerUnitReservationTest(){
        Test.startTest();
        Lead ld = [SELECT Id,ExistingAccount__c,Unit__c FROM Lead WHERE Name = 'Testing Lead' LIMIT 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,Project__r.Name,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'In-Progress' AND DigitalSales__c = true Limit 1];
        unit.LockType__c = 'Broker Reserve';
        update unit;
        
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.brokerRequestReservation(new List<Unit__c>{unit},Constants.BROKER_UNIT_RESERVATION,response,ld.Id,ld.ExistingAccount__c);
        Test.stopTest();
    }
    
    @isTest
    public static void brokerRequestReservationTest(){
        Test.startTest();
        Lead ld = [SELECT Id,ExistingAccount__c,Unit__c FROM Lead WHERE Name = 'Testing Lead' LIMIT 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,Project__r.Name,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = true Limit 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOwnerId(Userinfo.getuserid());
        lc.setDoNotCreateOpportunity(false);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.UnitdigitalSales = true;
        UnitAvailabilityWebService.UnitCustomerId = ld.ExistingAccount__c;
        UnitAvailabilityWebService.brokerRequestReservation(new List<Unit__c>{unit},Constants.BROKER_UNIT_RESERVATION,response,ld.Id,ld.ExistingAccount__c);
        Test.stopTest();
    }
    
    @isTest
    public static void brokerKYCLockUnitTest(){
        Test.startTest();
        Lead ld = [SELECT Id,ExistingAccount__c FROM Lead WHERE Name = 'Testing Lead' LIMIT 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,Project__r.Name,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' AND DigitalSales__c = true Limit 1];
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.UnitdigitalSales = true;
        UnitAvailabilityWebService.UnitCustomerId = ld.ExistingAccount__c;
        UnitAvailabilityWebService.brokerRequestReservation(new List<Unit__c>{unit},Constants.BROKER_KYC,response,ld.Id,ld.ExistingAccount__c);
        Test.stopTest();
    }
    
    @isTest
    public static void brokerReserveUnitTest(){
        Test.startTest();
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'In-Progress' Limit 1];
        unit.LockType__c = 'Broker KYC';
        update unit;
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.UnitCustomerId = unit.LockedByCustomer__c;
        UnitAvailabilityWebService.verifyUnitStatus(response,new List<Unit__c>{unit},Constants.BROKER_RESERVE_UNIT,Constants.RESERVE_PROCESS);
        Test.stopTest();
    }
    
    @isTest
    public static void cancelBrokerReservationTest(){
        Test.startTest();
        Lead ld = [SELECT Id FROM Lead WHERE Name = 'Testing Lead' LIMIT 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'In-Progress' Limit 1];
        UnitAvailabilityWebService.UnitVerificationResponse response = new UnitAvailabilityWebService.UnitVerificationResponse();
        UnitAvailabilityWebService.UnitCustomerId = unit.LockedByCustomer__c;
        UnitAvailabilityWebService.cancelBrokerReservation(Constants.BROKER_CANCEL_RESERVATION,unit,unit.LockedByCustomer__c,ld.Id);
        Test.stopTest();
    }
}