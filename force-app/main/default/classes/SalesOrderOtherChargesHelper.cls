/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Helper class for Sales Order Other Charges Trigger.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Harsh Rohilla   <hrohilla@aldar.com>
* @modifiedBy     
* @maintainedBy   
* @version        1.0
* @created        2023-06-28
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
 */
public with sharing class SalesOrderOtherChargesHelper {
    
    /**
     * @description If all payments are cleared on a resale opportunity, check the payments cleared flag on opportunity
     * @param  resaleCompleteChargesOppIdSet set of Opp from trigger
     */
    public static void handleResaleOpp_PaymentCleared(Set<Id> resaleCompleteChargesOppIdSet){

        Set<Id> soocIdWithManagerChequeSet = getSalesOrderToReceiptAckMap(resaleCompleteChargesOppIdSet);

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        // Query all related SalesOrderOtherCharges__c under the parent Opportunity
        Map<Id, List<SalesOrderOtherCharges__c>> opportunityToSocsMap = new Map<Id, List<SalesOrderOtherCharges__c>>();

        for (SalesOrderOtherCharges__c soc : [SELECT Id, OutstandingAmount__c, Opportunity__c 
                                              FROM SalesOrderOtherCharges__c 
                                              WHERE Opportunity__c IN :resaleCompleteChargesOppIdSet]) {

            if (!opportunityToSocsMap.containsKey(soc.Opportunity__c)) {
                opportunityToSocsMap.put(soc.Opportunity__c, new List<SalesOrderOtherCharges__c>());
            }
            opportunityToSocsMap.get(soc.Opportunity__c).add(soc);
        }

        System.debug('####opportunityToSocsMap: '+opportunityToSocsMap);

        // Check if all SalesOrderOtherCharges__c records have OutstandingAmount__c as 0 and update Opportunity Payment Cleared Flag
        for (Id opportunityId : resaleCompleteChargesOppIdSet) {
            if (opportunityToSocsMap.containsKey(opportunityId)) {
                boolean allZeroOutstandingAmount = true;
                for (SalesOrderOtherCharges__c soc : opportunityToSocsMap.get(opportunityId)) {
                    if (soc.OutstandingAmount__c != 0 && !soocIdWithManagerChequeSet.contains(soc.Id)) {
                        allZeroOutstandingAmount = false;
                        break;
                    }
                }

                if (allZeroOutstandingAmount) {
                    opportunitiesToUpdate.add(new Opportunity(Id = opportunityId, Payment_Cleared__c = true, StageName = 'Payment Cleared'));
                }
            }
        }
        System.debug('####opportunitiesToUpdate: '+opportunitiesToUpdate);
        // Update Opportunity records
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }

    }

    private static Set<Id> getSalesOrderToReceiptAckMap (Set<Id> resaleCompleteChargesOppIdSet){

        Set<Id> soocIdWithManagerChequeSet = new Set<Id>();
        List<ReceiptAllocation__c> junctionRecords = [  SELECT SalesOrderOtherCharges__c, 
                                                         ReceiptAcknowledgement__r.Id, 
                                                         ReceiptAcknowledgement__r.Name
                                                        FROM ReceiptAllocation__c
                                                        WHERE ReceiptAcknowledgement__r.ManagersCheque__c = true
                                                        AND SalesOrderOtherCharges__r.Opportunity__c IN :resaleCompleteChargesOppIdSet];

        if(junctionRecords.size() > 0){
            for (ReceiptAllocation__c junctionRecord : junctionRecords) {
                soocIdWithManagerChequeSet.add(junctionRecord.SalesOrderOtherCharges__c);
            }
        }
        
        return soocIdWithManagerChequeSet;                           
    }
     public static void customerPaymentStepClosure(List<sObject> otherChargesList,Map<Id,sObject> oldMap){
        Set<Id> srIdset = new Set<Id>();
        for(SalesOrderOtherCharges__c soCharges: (List<SalesOrderOtherCharges__c>)otherChargesList){     
            SalesOrderOtherCharges__c oldRecord =(SalesOrderOtherCharges__c)oldmap.get(soCharges.Id);
            if(soCharges.TypeOfCharge__c == 'Title Deed Registration Fee' && soCharges.ServiceRequest__c <> null && soCharges.AmountReceived__c <> null && (soCharges.AmountReceived__c + 10) >= soCharges.Amount__c && soCharges.AmountReceived__c !=oldRecord.AmountReceived__c){
                srIdset.add(soCharges.ServiceRequest__c);
            }
        }
        if(!srIdset.isEmpty()){
            System.debug('srIdset:'+srIdset);
            Id completedSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name = 'Completed' LIMIT 1]?.Id; 
            List<HexaBPM__Step__c> stepUpdList = new List<HexaBPM__Step__c>();
            for(HexaBPM__Step__c srStep:[SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN: srIdset AND SRTemplateName__c = 'Title Deed Registration' AND HexaBPM__Summary__c = 'Customer Payment' AND HexaBPM__Step_Status__c = 'Pending']){
                HexaBPM__Step__c srStepObj = new HexaBPM__Step__c();
                srStepObj.Id = srStep.Id;
                srStepObj.HexaBPM__Status__c = completedSts;
                stepUpdList.add(srStepObj);
            }
            System.debug('stepUpdList:'+stepUpdList);
            if(!stepUpdList.isEmpty()){
                update stepUpdList;
            }
        }
    }

}