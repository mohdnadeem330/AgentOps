/**
* LeadFirstMethodOfContactUpdateBatchTest
*
* Test class for LeadFirstMethodOfContactUpdateBatch
*/
@isTest
public class LeadFirstMethodOfContactUpdateBatchTest {
	@isTest
    Public static void LeadFirstMethodOfContactUpdate(){
        
        
        
        Test.startTest();
        Lead leadRec2 = TestObjectsFactory.getLeadRecord(45,'Person');
        leadRec2.LeadSource = '800-Aldar';
        leadRec2.OwnerId = userInfo.getUserId();
        insert leadRec2;
        
        Lead leadRec3 = TestObjectsFactory.getLeadRecord(45,'Person');
        leadRec3.createdDate = system.now().addDays(-4);
        leadRec3.OwnerId = userInfo.getUserId();
        leadRec3.LeadSource = 'Direct Email';
        leadRec3.EnquiryCategory__c = 'Aldar Employees';
        leadRec3.EnquiryTrigger__c = 'Khidmah';
        insert leadRec3;
        Lead ld = [Select Id, LeadNumber__c, EnquiryCategory__c, EnquiryTrigger__c, LeadSource, FirstMethodOfContact__c, FirstEnquiryCategory__c,FirstEnquiryTrigger__c, CreatedDate, Email, MobilePhone from Lead where Id =: leadRec3.id];
        system.debug('ld::'+ld);
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.LeadNumber__c = ld.LeadNumber__c;
        insert opp;
        system.debug('opp::'+opp);
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        List<Lead> lstLeads = new List<Lead>();
       
        lstLeads.add(ld);
        Date createdDate = date.newInstance(system.now().year(), system.now().month(), system.now().day());
        Date endDate = createdDate.addDays(2);
		time createdtime = time.newInstance(0, 0, 0, 0);
		DateTime dtFinalCreatedDate = dateTime.newInstance(createdDate, createdtime);
		database.executeBatch(new LeadFirstMethodOfContactUpdateBatch(dtFinalCreatedDate-6,endDate+4,false),100);
        LeadFirstMethodOfContactService.updateLeadFirstMethodofContact(lstLeads, new Map<String,Lead>());
        LeadFirstMethodOfContactService.updateSalesOrderFirstMethodofContactRelatedLeads(new Map<String, Lead>{leadRec3.id=>leadRec3});
        Test.stopTest(); 
	}
}