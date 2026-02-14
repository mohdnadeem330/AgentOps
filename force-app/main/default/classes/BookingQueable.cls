/**
* File Name : BookingQueable.cls
* Description : DML Logics seperated from OpportunityUnitSearchController.cls
* Author : Akash Kumar
* Created On : 16/01/2025
==============================================================================
Version |    Date    |    Author    | Modification
==============================================================================
* 1.0    | 16/01/2025 | Akash Kumar  | Initial Version
**/
public class BookingQueable implements Queueable{
    List<SalesOrder__c> salesOrders;
    Opportunity opportunityDetail;
    List<ReceiptAcknowledgement__c> eoiRAtoReparent;
    
    public BookingQueable(Opportunity opportunityDetail, List<SalesOrder__c> salesOrders, List<ReceiptAcknowledgement__c> eoiRAtoReparent){ //Set<Id> qualtircsIDsToProcess) {
        this.opportunityDetail = opportunityDetail;
        this.salesOrders = salesOrders;
        this.eoiRAtoReparent = eoiRAtoReparent;
    }
    
    public void execute(QueueableContext context){
        
        try{
            // Service request Updation
            if(opportunityDetail != NULL){
                if (opportunityDetail.ServiceRequest__c != null){
                    HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c(
                        Id = opportunityDetail.ServiceRequest__c,
                        SwappedOrder__c = salesOrders[0].id
                    );
                    update serviceRequest;
                }
            }
        } catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'Service request Updation','BookingQueable','execute'));
        }
        
        try{
            //Reparent EOI records
            if(!eoiRAtoReparent.isEmpty()){
                for(ReceiptAcknowledgement__c ra : eoiRAtoReparent){
                    ra.SalesOrder__c = salesOrders[0].id;
                }
                update eoiRAtoReparent;
            }
        } catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'Reparent EOI records','BookingQueable','execute'));
        }
        
        try{
            // Update Sales Order to call Sales Order API
            List<Id> soIds = new List<Id>();
            if(!salesOrders.isEmpty()){
                for(SalesOrder__c salesOrder : salesOrders){
                    soIds.add(salesOrder.Id);
                    //salesOrder.IsBookingCompleted__c = true;
                }
                //                update salesOrders;
                TriggerHandler.processedIds = new Set<Id>();
                if (!soIds.isEmpty()) {
                    SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
                }
            }
        } catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'Update Sales Order','BookingQueable','execute'));
        } 
        
        
        try{
            Set<Id> unitIds = new Set<Id>();
            List<Unit__c> lstUnitToUpdate = new List<Unit__c>();
            // Query the units associated with related opportunites and status should be available

            List<Unit_Assignment__c> unitAssignmentListUpdate = new List<Unit_Assignment__c>();
            for(Unit_Assignment__c unitAssignment : [SELECT Status__c,Id,Unit__r.Status__c ,ExistingAllocationGroup__c,Unit__c  FROM Unit_Assignment__c
                                        WHERE Opportunity__c =: opportunityDetail.id]){
                    
                    if(unitAssignment.Status__c == 'Pending approval'){
                        unitAssignment.Status__c = 'Rejected';
                        unitAssignmentListUpdate.add(unitAssignment);
                    }  

                    if(unitAssignment.Unit__r.Status__c == Constants.UNIT_STATUS_AVAILABLE || unitAssignment.Unit__r.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS){
                   // Remove the related opportunity, make assigned to user and locked by to null and assign the existing allocation group to unit
                    Unit__c unitObj= new Unit__c();
                    unitObj.Id = unitAssignment.Unit__c;
                    unitObj.AssignedToUser__c = null;
                    unitObj.LockedBy__c = null;
                    unitObj.Status__c = unitAssignment.Unit__r.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS ? Constants.UNIT_STATUS_AVAILABLE : unitAssignment.Unit__r.Status__c ;
                    unitObj.RelatedOpportunity__c = null;
                    unitObj.AllocationGroup__c = unitAssignment.ExistingAllocationGroup__c;
                        if(!unitIds.contains(unitAssignment.Unit__c)){
                            unitIds.add(unitAssignment.Unit__c);
                            lstUnitToUpdate.add(unitObj);    
                        }
            }
            if(!lstUnitToUpdate.isEmpty()){
                update lstUnitToUpdate;
            }
            if(!unitAssignmentListUpdate.isEmpty()){
                update unitAssignmentListUpdate;
            }
        }            
        } catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'Release Units After Opportunity Close Won','BookingQueable','execute'));
        } 
    }
}