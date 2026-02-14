@isTest(SeeAllData=false)
public class SalesReportConrollerTest {

    @IsTest
    public static void testgetSalesReport() {

        Project__c p= TestObjectsFactory.getProjectRecord('45223452');
        insert p;
        BuildingSection__c b= TestObjectsFactory.getBuildingDetailRecord(p.id);
        insert b;
        Unit__c u = TestObjectsFactory.getUnitDetail(p.id,b.id);
        insert u;

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Organisation Account', 'TestRegistrationNo');
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Opportunity op = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert op;
        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(op.Id,acc.Id);
        sa.Unit__c = u.id;
        insert sa;

        List<SalesOrder__c> testWithOutParams= SalesReportConroller.getSalesReport(acc.Id,null,system.today().addDays(-10),system.today().addDays(10));
        List<SalesOrder__c> testWithParams= SalesReportConroller.getSalesReport(acc.Id,'Mr', system.today().addDays(-10),system.today().addDays(10));
        System.assertNotEquals(null,testWithOutParams); 
        System.assertNotEquals(null,testWithParams); 

    }

    
   
}