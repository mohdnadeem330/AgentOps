/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Helper class for Resale Offer Trigger Handler
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
public without sharing class ResaleOfferTriggerHelper {
    
    /*
     * If Offer is Accepted -> Mark related unit as Offer Accepted 
     *                      -> Disqualify all other offers present for the same 
     *                      -> Disqualify all other offers present in the opportunity
     *                      -> Update Opp Stage to Offer Accepted
     * 16/08/2023 harsh@aldar -> On Offer Accept, If Offer Price is +-5% of the Listing Price, skip approval and set Stage as Sign in Progress
     *                             
    */
    public static void manageAcceptedOffer(List<SObject> newList, Map<Id,SObject> oldMap){

        Set<Id> acceptedUnitList = new Set<Id>();
        Set<Id> acceptedOfferIds = new Set<Id>();
        Set<Id> validOppIds = new Set<Id>();
        Map<Id, Decimal> oppIdToOfferPriceMap = new Map<Id, Decimal>();
        Map<Id, Id> oppToAccepetdUnitIdMap = new Map<Id, Id>();
        Map<Id, Decimal> unitIdToListingPriceMap = new Map<Id, Decimal>();

        Map<Id, Resale_Offers__c> oppIdToResaleOfferMap = new Map<Id, Resale_Offers__c>();

        Map<Id, Id> oppIdToSalesOrderIdMap = new Map<Id, Id>();
        Map<Id, SalesOrder__c> salesOrderRecMap;
        //Harsh@Aldar 17/08 Disqualify other offers when Payment is cleared not when one Offer is Accepted
        // List<Resale_Offers__c> disqualifiedOffers = new List<Resale_Offers__c>();
        //mark accepted units as offer accepted
        List<Unit__c> acceptedUnitListToUpdate = new List<Unit__c>();

        for(Resale_Offers__c newRecord : (List<Resale_Offers__c>) newList){
            Resale_Offers__c oldRecord = (Resale_Offers__c) oldMap.get(newRecord.Id);

            if(oldRecord.Status__c != ResaleConstants.RO_STATUS_ACCEPTED && newRecord.Status__c == ResaleConstants.RO_STATUS_ACCEPTED){
                acceptedUnitList.add(newRecord.Unit__c);
                acceptedOfferIds.add(newRecord.Id);
                validOppIds.add(newRecord.Opportunity__c);
                oppIdToResaleOfferMap.put(newRecord.Opportunity__c, newRecord);
                oppIdToOfferPriceMap.put(newRecord.Opportunity__c, newRecord.Offer_Price__c);
                oppToAccepetdUnitIdMap.put(newRecord.Opportunity__c, newRecord.Unit__c);

                oppIdToSalesOrderIdMap.put(newRecord.Opportunity__c, newRecord.Sales_Order__c);
            }
        }

        salesOrderRecMap = new Map<Id, SalesOrder__c>([SELECT Id, NetAmount__c FROM SalesOrder__c WHERE Id IN: oppIdToSalesOrderIdMap.values()]);

        //Harsh@Aldar 16/08
        // Query Unit records to get the Listing Price for accepted units
        Map<Id, Unit__c> unitIdToUnitMap = new Map<Id, Unit__c>([ SELECT Id, Listing_Price__c
                                                                   FROM Unit__c
                                                                   WHERE Id IN :acceptedUnitList]);

        for (Id unitId : acceptedUnitList) {
            unitIdToListingPriceMap.put(unitId, unitIdToUnitMap.get(unitId).Listing_Price__c);
        }

        if (acceptedUnitList.size() > 0) {
            for(Id thisUnitId: acceptedUnitList){
                Unit__c thisUnit = new Unit__c();
                thisUnit.Id = thisUnitId;
                // thisUnit.Offer_Accepted__c = true;
                thisUnit.ResaleStatus__c = 'Offer Accepted';
                // <!-- Harsh@Aldar -- 01/09/23 -- commented the disable logic -->
                // thisUnit.ResaleListed__c = false;
                acceptedUnitListToUpdate.add(thisUnit);
            }
            //Harsh@Aldar 17/08 Disqualify other offers when Payment is cleared not when one Offer is Accepted
            // disqualifiedOffers = [  SELECT Id, Status__c 
            //                         FROM Resale_Offers__c 
            //                         WHERE (Unit__c IN :acceptedUnitList OR Opportunity__c IN:validOppIds) 
            //                         AND Status__c !=: ResaleConstants.RO_STATUS_DISQUALIFIED
            //                         AND Id NOT IN: acceptedOfferIds];
    
            // for (Resale_Offers__c offer : disqualifiedOffers) {
            //     offer.Status__c = ResaleConstants.RO_STATUS_DISQUALIFIED;
            // }
        }

        if(validOppIds.size() > 0){
            List<Opportunity> oppUpdateList = new List<Opportunity>();
            for (Opportunity thisOpp : [SELECT Id, StageName, Amount, 
                                                Unit__c, Seller__c, SalesOrder__c, 
                                                OfferAcceptedDate__c, ResaleOpportunityStageFlag__c, SharePercentage__c 
                                        FROM Opportunity 
                                        WHERE Id IN: validOppIds]) {
                //Harsh@Aldar 28/08/23 -- By default all Opp will move on to MOU Sign In Progress, unless if Net Amount - Offer Price > 0 then it will go to approval
                //this approval bypass logic is configured using Label.ResaleApprovalBypassThreshold5
                /* commented this code as bypassing approval has moved to "Verify Details" Action on Opportunity - yenshul@aldar
                Boolean config = Label.ResaleApprovalBypassThreshold5.toLowerCase() == 'true' ? true : false;
                if(!config){
                    thisOpp.StageName = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED;
                }else{
                    if(oppIdToSalesOrderIdMap != null && oppIdToSalesOrderIdMap.containsKey(thisOpp.Id) && salesOrderRecMap != null && salesOrderRecMap.containsKey(oppIdToSalesOrderIdMap.get(thisOpp.Id))){
                        SalesOrder__c thisSalesOrderRecord = salesOrderRecMap.get(oppIdToSalesOrderIdMap.get(thisOpp.Id));
                        if(oppIdToOfferPriceMap.containsKey(thisOpp.Id) && (thisSalesOrderRecord.NetAmount__c - oppIdToOfferPriceMap.get(thisOpp.Id)) > 0){
                            thisOpp.StageName = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED;
                        }else {
                            thisOpp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
                        }
                    }else{
                        thisOpp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
                    }
                }*/
                thisOpp.StageName = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED;
                thisOpp.OfferAcceptedDate__c = System.today();
                thisOpp.Unit__c = oppToAccepetdUnitIdMap != null && oppToAccepetdUnitIdMap.get(thisOpp.Id) != null ? oppToAccepetdUnitIdMap.get(thisOpp.Id) : thisOpp.Unit__c; 
                
                //Harsh@Aldar 28/08/2023 -- Commenting the below +-5% rule
                // Check if Offer Price is within +-5% (configurable using label) of Listing Price
                //harsh@aldar 16/08/2023
                // Decimal configuredPercentage = Decimal.valueOf(Label.ResaleApprovalBypassThreshold5) / 100;
                // //If this value is 0, BYPASS
                // if (configuredPercentage > 0 && unitIdToListingPriceMap.containsKey(thisOpp.Unit__c) && oppIdToOfferPriceMap.containsKey(thisOpp.Id)) {
                //     Decimal listingPrice = unitIdToListingPriceMap.get(thisOpp.Unit__c);
                //     Decimal offerPrice = oppIdToOfferPriceMap.get(thisOpp.Id);
                //     Decimal minPrice = listingPrice * (1 - configuredPercentage);//listingPrice * 0.95;
                //     Decimal maxPrice = listingPrice * (1 + configuredPercentage); //listingPrice * 1.05;

                //     System.debug('#### listingPrice: '+listingPrice);
                //     System.debug('#### offerPrice: '+offerPrice);
                //     System.debug('#### minPrice: '+minPrice);
                //     System.debug('#### maxPrice: '+maxPrice);

                //     if (offerPrice >= minPrice && offerPrice <= maxPrice) {
                //         thisOpp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
                //     }
                // }

                //flag to update Stage
                thisOpp.ResaleOpportunityStageFlag__c = String.valueOf(System.now());
                if (oppIdToOfferPriceMap != null) {
                    Decimal amountDec = oppIdToOfferPriceMap.get(thisOpp.Id) != null ? oppIdToOfferPriceMap.get(thisOpp.Id) : thisOpp.Amount;
                    thisOpp.Amount = amountDec;
                    thisOpp.SecurityDepositAmount__c = amountDec != null ? amountDec * 0.1 : null;
                    thisOpp.SecurityDepositAmountBuyer__c = amountDec != null ? amountDec * 0.1 : null;
                }
                //added from the email service class Harsh 10/08/23
                thisOpp.Seller__c = oppIdToResaleOfferMap != null && oppIdToResaleOfferMap.get(thisOpp.Id) != null ? oppIdToResaleOfferMap.get(thisOpp.Id).Seller_Account__c : null;
                thisOpp.SalesOrder__c = oppIdToResaleOfferMap != null && oppIdToResaleOfferMap.get(thisOpp.Id) != null ? oppIdToResaleOfferMap.get(thisOpp.Id).Sales_Order__c : null;
                thisOpp.SharePercentage__c = 100.00;
                oppUpdateList.add(thisOpp);
            }
            Savepoint savepoint = Database.setSavepoint();
            try{
                update oppUpdateList;
                //Harsh@Aldar 17/08 Disqualify other offers when Payment is cleared not when one Offer is Accepted
                // if (disqualifiedOffers.size() > 0) {
                //     update disqualifiedOffers;
                // }

                if(acceptedUnitListToUpdate.size() > 0){
                    update acceptedUnitListToUpdate;
                }
            }catch (Exception e) {
                // Rollback the transaction
                Database.rollback(savepoint);
            }
            
        }
    }

    public static void validateResaleOffers(List<SObject> newList, Map<Id, SObject> oldMap) {
        if(oldMap == null){
            oldMap = new Map<Id, SObject>();
        }

        List<Resale_Offers__c> newAcceptedResaleOffers = new List<Resale_Offers__c>();
        Map<Id, Set<Id>> unitIdToAcceptedOfferIdsMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> oppIdToAcceptedOfferIdsMap = new Map<Id, Set<Id>>();
        Map<Id, Resale_Offers__c> noMoreAcceptedResaleOffersIdMap = new Map<Id, Resale_Offers__c>();
        for(Resale_Offers__c newOffer: (List<Resale_Offers__c>)newList){
            Resale_Offers__c oldOffer = oldMap.containsKey(newOffer.Id) ? (Resale_Offers__c)oldMap.get(newOffer.Id) : null; 
            if(oldOffer == null || newOffer.Status__c != oldOffer.Status__c){
                if(newOffer.Status__c == ResaleConstants.RO_STATUS_ACCEPTED){
                    newAcceptedResaleOffers.add(newOffer);
                    // group by units
                    if(newOffer.Unit__c != null){
                        if(unitIdToAcceptedOfferIdsMap.containsKey(newOffer.Unit__c)){
                            unitIdToAcceptedOfferIdsMap.get(newOffer.Unit__c).add(newOffer.Id);
                        }else{
                            unitIdToAcceptedOfferIdsMap.put(newOffer.Unit__c, new Set<Id>{newOffer.Id});
                        }
                    }
                    // group by opps
                    if(newOffer.Opportunity__c != null){
                        if(oppIdToAcceptedOfferIdsMap.containsKey(newOffer.Opportunity__c)){
                            oppIdToAcceptedOfferIdsMap.get(newOffer.Opportunity__c).add(newOffer.Id);
                        }else{
                            oppIdToAcceptedOfferIdsMap.put(newOffer.Opportunity__c, new Set<Id>{newOffer.Id});
                        }
                    }
                }else if(newOffer.Status__c != ResaleConstants.RO_STATUS_ACCEPTED 
                            && oldOffer != null && oldOffer.Status__c == ResaleConstants.RO_STATUS_ACCEPTED){
                    noMoreAcceptedResaleOffersIdMap.put(newOffer.Id, newOffer);
                }
            }
        }

        Set<Id> unitIdWithExAcceptedOffers = new Set<Id>();
        Set<Id> oppIdWithExAcceptedOffers = new Set<Id>();
        if( !newAcceptedResaleOffers.isEmpty() && ( !unitIdToAcceptedOfferIdsMap.isEmpty() || !oppIdToAcceptedOfferIdsMap.isEmpty() ) ){
            for(Resale_Offers__c ro: [SELECT Id, Status__c, 
                                            Unit__c, Opportunity__c 
                                      FROM Resale_Offers__c 
                                      WHERE Status__c =: ResaleConstants.RO_STATUS_ACCEPTED
                                            AND ( Unit__c IN: unitIdToAcceptedOfferIdsMap.keySet()
                                                    OR Opportunity__c IN: oppIdToAcceptedOfferIdsMap.keySet()
                                                )]){
                if(!noMoreAcceptedResaleOffersIdMap.containsKey(ro.Id)
                    || noMoreAcceptedResaleOffersIdMap.get(ro.Id).hasErrors()){
                    if(ro.Unit__c != null){
                        unitIdWithExAcceptedOffers.add(ro.Unit__c);
                    }
                    if(ro.Opportunity__c != null){
                        oppIdWithExAcceptedOffers.add(ro.Opportunity__c);
                    }
                }
            }

            System.debug('#### EXISTING RECORD DATA CAUING ERROR unitIdWithExAcceptedOffers ####'+ JSON.serializePretty(unitIdWithExAcceptedOffers));
            System.debug('#### EXISTING RECORD DATA CAUING ERROR oppIdWithExAcceptedOffers ####'+ JSON.serializePretty(oppIdWithExAcceptedOffers));

            for(Resale_Offers__c ro: newAcceptedResaleOffers){
                Id unitId = ro.Unit__c;
                Id oppId = ro.Opportunity__c;
                String validationError;
                if( unitIdWithExAcceptedOffers.contains(unitId) ){
                    validationError = System.Label.ResaleOfferValidationPerUnit1; // 'Cannot accept this offer. Seller has already accepted another offer for this Unit.';
                }else if( unitIdToAcceptedOfferIdsMap.get(unitId).size() > 1 ){
                    validationError = System.Label.ResaleOfferValidationPerUnit2; // 'Cannot accept multiple offers for the same unit.';
                }else if( oppIdWithExAcceptedOffers.contains(oppId) 
                            || oppIdToAcceptedOfferIdsMap.get(oppId).size() > 1 ){
                    validationError = System.Label.ResaleOfferValidationPerOpportunity; // 'Cannot accept mulitple offers on the same opportunity.';
                }
                if(validationError != null){
                    ro.addError(validationError);
                }
            }
        }
    }

    // public static void checkForDuplicateAcceptedOffersBeforeUpdate(List<SObject> newOffers, Map<Id,SObject> oldMap) {

    //     System.debug('#### checkForDuplicateAcceptedOffersBeforeUpdate ####');

    //     Map<Id, Id> oppIdToAcceptedOfferMap = new Map<Id, Id>();

    //     for (Resale_Offers__c newOffer : (List<Resale_Offers__c>)newOffers) {
    //         Resale_Offers__c oldOffer = (Resale_Offers__c)oldMap.get(newOffer.Id);

    //         if (newOffer.Status__c == ResaleConstants.RO_STATUS_ACCEPTED && 
    //             (oldOffer == null || oldOffer.Status__c != ResaleConstants.RO_STATUS_ACCEPTED)) {
    //                 System.debug('#### newOffer.Opportunity__c: '+newOffer.Opportunity__c);
    //                 System.debug('#### newOffer.Id: '+newOffer.Id);
    //             // oppIdToAcceptedOfferMap.put(newOffer.Opportunity__c, newOffer.Id);
    //             oppIdToAcceptedOfferMap.put(newOffer.Id, newOffer.Opportunity__c);
    //         }
    //     }

    //     System.debug('#### oppIdToAcceptedOfferMap #### : '+oppIdToAcceptedOfferMap);

    //     if (!oppIdToAcceptedOfferMap.isEmpty()) {
    //         Map<Id, Opportunity> oppIdToExistingAcceptedOfferMap =
            
    //         new Map<Id, Opportunity>([
    //                                     SELECT Id, (SELECT Id FROM Resale_Offers__r WHERE Status__c = :ResaleConstants.RO_STATUS_ACCEPTED)
    //                                     FROM Opportunity
    //                                     WHERE Id IN :oppIdToAcceptedOfferMap.values()
    //                                 ]);
    //         System.debug('#### oppIdToExistingAcceptedOfferMap #### : '+oppIdToExistingAcceptedOfferMap.values()[0].Resale_Offers__r);

    //         for (Resale_Offers__c newOffer : (List<Resale_Offers__c>)newOffers) {
    //             if (oppIdToAcceptedOfferMap.containsKey(newOffer.Id)) {
    //                 Opportunity opp = oppIdToExistingAcceptedOfferMap.get(newOffer.Opportunity__c);
    //                 System.debug('#### newOffer #### '+newOffer);
    //                 if (opp != null && opp.Resale_Offers__r.size() > 0) {
    //                     newOffer.addError('There is already an accepted offer under this Opportunity.');
    //                 }
    //             }
    //         }
    //     }
    // }

    // //update the unit to offer accepted when status changed manually
    // private static Unit__c updateUnit(List<Id> ){
    //     thisOffer = [SELECT Id, Unit__c, Opportunity__c, Seller_Account__c FROM Resale_Offers__c WHERE Id =: thisOffer.Id LIMIT 1];
    //     Unit__c thisUnit = new Unit__c();
    //     thisUnit.Id = thisOffer.Unit__c;
    //     thisUnit.Offer_Accepted__c = true;
    //     return thisUnit;
    // }

    // private static Opportunity updateOpportunity(Resale_Offers__c thisOffer){
    //     Opportunity thisOpp = new Opportunity();
    //     thisOpp.Id = thisOffer.Opportunity__c;
    //     thisOpp.Seller__c = thisOffer.Seller_Account__c;
    //     thisOpp.SharePercentage__c = 100.00;
    //     return  thisOpp;
    // }
}