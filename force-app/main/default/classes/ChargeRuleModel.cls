/*
* Purpose: Prepare a Charge Modal to store information about Charge Rule and Service Requests.
*/
public with sharing class ChargeRuleModel {
    
    public Id serviceRequestId {get;set;}
    public Id chargeRuleId {get;set;}
    public Decimal chargeAmountPercentage {get;set;}
    public Decimal vatChanges {get;set;}
    public Boolean isPercentage {get;set;}
}