/**********************************************************************************************************************
* Name               : UpdateSalesOrderStatusQueueable                                                        
* Description        : Class to Update SalesOrder Status to Pending only for Dubai Digital Sales Projects
* Usage              : ReceiptAcknowledgementTriggerHelper
* Created By         : Live Aldar Salesforce Team                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           tdevar@aldar.com     13/09/2025      Initial Draft       
******************************************************************************************************************/
public class UpdateSalesOrderStatusQueueable implements Queueable {
    
    public Set<Id> salesOrderIds;
    
    public UpdateSalesOrderStatusQueueable(Set<Id> salesOrderIds){
        this.salesOrderIds = salesOrderIds;
    }
    
    public void execute(QueueableContext qc){
        
        List<SalesOrder__c> salesOrderList = [SELECT Id,Status__c,SubStatus__c,BookingDate__c,Opportunity__c,Unit__c FROM SalesOrder__c WHERE Id IN : salesOrderIds];
        List<Opportunity> OpportunityList = new List<Opportunity>();
        List<Unit__c> unitList = new List<Unit__c>();
        
        for(SalesOrder__c so : salesOrderList){
            
            so.Status__c = constants.OPPO_UNIT_STATUS_PENDING; 
            so.SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM; 
            so.BookingDate__c = System.Today();
            
            if(so.Opportunity__c != null){
                OpportunityList.add(new Opportunity(
                    Id = so.Opportunity__c,
                    StageName = Constants.STAGE_CLOSEDWON,
                    CloseDate = System.Today(),
                    WinReason__c = 'Won - Aldar Brand Value'
                ));
            }
            
            if(so.Unit__c != null){
                unitList.add(new Unit__c(
                    Id = so.Unit__c,
                    Status__c = Constants.UNIT_STATUS_BOOKED,
                    AllocationGroup__c = null,
                    AssignedToUser__c = UserInfo.getUserId()
                ));
            }
        }
        
        if(!salesOrderList.isEmpty()){
            try{
                update salesOrderList;
            } 
            catch(Exception ex){
                LoggerService.save(LoggerService.addApexLog(ex,'SalesOrderUpdate','UpdateSalesOrderStatusQueueable','Execute'));
            }
        }
        
        if(!OpportunityList.isEmpty()){
            try{
                update OpportunityList;
            } 
            catch(Exception ex){
                LoggerService.save(LoggerService.addApexLog(ex,'OpportunityUpdate','UpdateSalesOrderStatusQueueable','Execute'));
            }
        }
        
        if(!unitList.isEmpty()){
            try{
                update unitList;
            } 
            catch(Exception ex){
                LoggerService.save(LoggerService.addApexLog(ex,'UnitUpdate','UpdateSalesOrderStatusQueueable','Execute'));
            }
        }
    }
}