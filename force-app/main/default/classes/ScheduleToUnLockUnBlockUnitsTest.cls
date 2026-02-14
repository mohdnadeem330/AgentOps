@isTest
public class ScheduleToUnLockUnBlockUnitsTest {

    static void init(){

        Unit__c unit = TestObjectsFactory.unitDataSetup('10101');
        insert unit;
        unit_assignment__c uniAss = new unit_assignment__c();
        uniAss.Unit__c = unit.Id;
        uniAss.Approver__c = userInfo.getUserId();
        uniAss.RequestedBy__c = userInfo.getUserId();
        uniAss.AutoApprove__c = true;
		insert uniAss;
        unit.LockTime__c = system.now();
        unit.LockedBy__c = UserInfo.getUserId();         
        unit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS; 
        unit.LockExpiryTime__c = system.now().addMinutes(-24);
        update unit;
    }

    @IsTest(SeeAllData=true) public static void testExecute() {

        Test.startTest();
        init();
        ScheduleToUnLockUnBlockUnits objSchedule = new ScheduleToUnLockUnBlockUnits();
		Datetime dt = system.now().addMinutes(1);
		string sCornExp = '0 '+dt.minute()+' '+dt.hour()+' '+dt.day()+' '+dt.month()+' ? '+dt.year();
		for(CronTrigger obj : [select Id from CronTrigger where CronJobDetailId IN (SELECT Id FROM CronJobDetail where Name = 'Unit Unlock Batch Process')])
			system.abortJob(obj.Id);
		system.schedule('Unit Unlock Batch Process', sCornExp, objSchedule);
        Test.stopTest();
        
    }
    
    @isTest
    public static void deactivateCPRecordsOnUnitReleaseTest() {
        
        Map<Id,Id> unitToAccountMap = new Map<Id,Id>();
        Set<Id> unitIds = new Set<Id>();
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Mamsha Gardens';
        insert proj;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.FirstName = 'Test';
        acc.LastName = ' Non-Resident';
        acc.ResidentStatus__pc = 'Non-Resident';
        acc.Nationality__pc = 'India';
        insert acc;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Available';
        unit.Project__c = proj.Id;
        unit.LockedByCustomer__c = acc.Id;
        unit.LockExpiryTime__c = System.now().addMinutes(-2);
        unit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;
        unit.DigitalSales__c = true;
        
        insert unit;
        
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
        
        Communication_Preference__c newCPRecord = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Broker Portal',
            Status__c = 'Link Sent',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Lead__c = lead.Id
        );
        insert newCPRecord;
        
        unitIds.add(unit.Id);
        unitToAccountMap.put(unit.Id,unit.LockedByCustomer__c);
        
        ScheduleToUnLockUnBlockUnits.UnitsWithRelatedAccount inputs = new ScheduleToUnLockUnBlockUnits.UnitsWithRelatedAccount();
        inputs.accountId = acc.Id;
        inputs.unitId = unit.Id;
        
        List<ScheduleToUnLockUnBlockUnits.UnitsWithRelatedAccount> inputsList = new List<ScheduleToUnLockUnBlockUnits.UnitsWithRelatedAccount>{inputs};
        
        Test.startTest();
        ScheduleToUnLockUnBlockUnits.deactivateCPRecordsOnUnitRelease(new List<Unit__c>{unit});
        ScheduleToUnLockUnBlockUnits.updateBrokerLeadOnUnitRelease(unitIds,unitToAccountMap);
        ScheduleToUnLockUnBlockUnits.processUnitRelease(inputsList);
        Test.stopTest();
    }
}