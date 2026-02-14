@isTest(SeeAllData=false)
public class ReservationEmailControllerTest {
    @isTest static void setupData() {

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opportunityRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAcc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        insert salesOrder;


        ReservationEmailController reservationEmailController = new ReservationEmailController();
        reservationEmailController.opportunityId = opportunityRecord.Id;

        List<SalesOrder__c> salesOrderList = ReservationEmailController.reqList;
        String newLine = ReservationEmailController.NewLine;

    }
}