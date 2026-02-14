/*
 * This Queueable class will be called when the Account's ERP Id is null
 * _copy attributes will receive the values which are same from the place of trigger
 * After this Queueable executed, SalesOrderCalloutHelper.EXECUTE_ACCOUNT_FIRST flag needs to be reset to false
 * so that SalesOrderCalloutHelper.PrepareDataForCallout will execute for salesorder enxt time
 * This Queueable is being invoked from SalesOrderCalloutHelper -> CustomerCalloutHelper -> CalloutToMuleSoft.processMuleResponse 
 * Created Saravanan Sekar ssekar@aldar.com 18/12/2022 - V1
 * LastModified Saravanan Sekar ssekar@aldar.com 19/12/2022 - V2 
 */ 
public with sharing class SalesOrderCalloutQueueable implements Queueable, Database.AllowsCallouts {
	public List<Id> soIds_copy = new List<Id>();
    public Boolean isCalledFromQueueable_copy = false;
    public Map<String, String> customerMap_copy = new Map<String, String>();
    
    public SalesOrderCalloutQueueable(List<Id> soIds, Boolean isCalledFromQueueable, Map<String, String> customerMap) {
        this.soIds_copy = soIds;
        this.isCalledFromQueueable_copy = isCalledFromQueueable;
        this.customerMap_copy = customerMap;
    }
    
    public void execute(QueueableContext context) {
        SalesOrderCalloutHelper.EXECUTE_ACCOUNT_FIRST = FALSE;
        SalesOrderCalloutHelper.PrepareDataForCallout(this.soIds_copy, false, this.customerMap_copy);
    }
}