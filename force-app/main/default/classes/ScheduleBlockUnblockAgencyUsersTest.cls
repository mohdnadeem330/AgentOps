@isTest
public class ScheduleBlockUnblockAgencyUsersTest {

    @IsTest public static void testExecute() {
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('agencyName', 'registrationNo');
        acc.RegistrationExpiryDate__c = Date.today().addYears(-1);
        acc.AgencyStatus__c = 'Active';
		insert acc;
        
        Test.startTest();
        ScheduleBlockUnblockAgencyUsers objSchedule = new ScheduleBlockUnblockAgencyUsers();
		Datetime dt = system.now().addMinutes(1);
		string sCornExp = '0 '+dt.minute()+' '+dt.hour()+' '+dt.day()+' '+dt.month()+' ? '+dt.year();

		for(CronTrigger obj : [select Id from CronTrigger where CronJobDetailId IN (SELECT Id FROM CronJobDetail where Name = 'Unit Unlock Batch Process')])
			system.abortJob(obj.Id);
        
		system.schedule('Unit Unlock Batch Process', sCornExp, objSchedule);
        Test.stopTest();
    }
}