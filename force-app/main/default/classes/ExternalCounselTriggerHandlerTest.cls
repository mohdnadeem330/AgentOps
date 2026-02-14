@isTest	
public class ExternalCounselTriggerHandlerTest {
	@isTest
    public static void test(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        Id AccrecordTypeId=Schema.SobjectType.Account.getRecordTypeInfosByName().get('Legal Firm').getRecordTypeID();
        Account Acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = AccrecordTypeId;
        insert acc;
        Contact con = new Contact();
        con.FirstName = 'Test Contact';
        con.LastName = 'Test';
        con.AccountId = acc.Id;
        insert con;
        Id feedbackRecordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case newStandardCase2 = TestObjectsFactory.getCaseRecord(feedbackRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
        newStandardCase2.SubVertical__c = Constants.DLP_SUB_VERTICAL;
        newStandardCase2.CaseCategory__c = 'Civil';
        newStandardCase2.SubCategory__c = 'Aluminium';
        newStandardCase2.ProblemCode__c = 'CM-PQA- Window frame';
        newStandardCase2.IncidentDescription__c = 'Scratched';
        newStandardCase2.ResolutionType__c = 'Repair';
        newStandardCase2.OwnerId = UserInfo.getUserId();
        newStandardCase2.Subject='Test2';
        newStandardCase2.Law_Firm__c = acc.Id;
        Test.startTest();
        insert newStandardCase2;
        Test.stopTest();
        
        External_Counsel__c ex = new External_Counsel__c();
        ex.Case__c = newStandardCase2.Id;
        ex.Contact__c = con.Id;
        insert ex;
        update ex;
        
    }
}