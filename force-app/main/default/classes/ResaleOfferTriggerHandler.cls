/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Handler class for Resale Offer Trigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Harsh Rohilla   <hrohilla@aldar.com>
* @modifiedBy     
* @maintainedBy   
* @version        1.0
* @created        2023-06-22
* @modified       2023-06-22
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
 */
public with sharing class ResaleOfferTriggerHandler extends TriggerHandler{
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        ResaleOfferTriggerHelper.manageAcceptedOffer(newList, oldMap);
    } 

    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id,SObject> newmap, List<SObject> oldlist, Map<Id,SObject> oldmap) {
        ResaleOfferTriggerHelper.validateResaleOffers(newList, oldMap);
        // ResaleOfferTriggerHelper.checkForDuplicateAcceptedOffersBeforeUpdate(newList, oldMap);
    }
}