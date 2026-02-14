/**
 * @description       : This class used for handle trigger logic for Sales Order object.
 * @coverage          : SalesOrderTriggerHandlerTest.cls | @CC100%
 * @author            : rrangrej@aldar.com
 * @group             : Aldar
 * @last modified on  : 06/03/2025
 * @last modified by  : rrangrej@aldar.com
 * Modifications Log
 * Ver   Date         Author                                    Modification
 * 1.0   06/03/2025   rrangrej@aldar.com             Initial Version | Story Number | @CC100%
 **/
public without sharing class SalesOrderTriggerHelper {
	
    /**
     * @description Method to used Sales Order Document validation
     * @author rrangrej@aldar.com | 06/03/2025 | Story Number
     * @param List<SalesOrder__c> newList
     * @param Set<Id> salesOrderSoldStatusIds
     **/
    public static void checkSalesOrderSoldValidation(List<SalesOrder__c> newList, Set<Id> salesOrderSoldStatusIds) {
        if (LSQ_UserValidation.isLsqUser()) {//Added for LSQ
            return;
        }
        
        Map<Id, SalesOrder__c> salesOrderMap =  new Map<Id, SalesOrder__c>([SELECT Id FROM SalesOrder__c WHERE Id IN (SELECT SalesOrder__c FROM Document__c WHERE Status__c = :Constants.DOCUMENT_STATUS_UPLOADED AND DocumentType__c = :Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA AND SalesOrder__c IN :salesOrderSoldStatusIds)]);
        
        for(SalesOrder__c so : newList) {
            if(!salesOrderMap.containsKey(so.Id)) {
                so.addError(Label.Aldar_Signed_SPA_Required_Validation); 
            }
        }
    }

    // SSC-385: Added Byt Suryapratap : Check if the SO Cancel have Name Change or Upgrage Reason, then Update the Unit to Available in
    public static void checkSalesOrderCancellationReason(Map<Id, Id> salesOrderAndUnitIdsMap,  Map<Id, Id> salesOrderAndOfferIdMap, Map<Id, SObject> soMap) {
        // Valid cancellation reasons
        String NAME_CHANGE = 'Changing customer name or switching between the joint owners.';
        String UPGRADE = 'Upgrade or Swap requests while the unit still at pending/approve pending stages';
        Set<String> cancellationReason = new Set<String> {NAME_CHANGE};
        // Query cancellations
        List<SalesOrderCancellation__c> cancellations = [
                                                            SELECT Id, Name, SalesOrder__c, New_Buyer_Opportunity__c, New_Buyer_Opportunity__r.SaleType__c, 
                                                            New_Buyer_Opportunity__r.CustomerResidentStatus__c, ReasonforCancellation__c, Unit__c,
                                                            SalesOrder__r.SalesManager__c
                                                            FROM SalesOrderCancellation__c
                                                            WHERE SalesOrder__c IN :salesOrderAndUnitIdsMap.keySet()
                                                            AND ReasonforCancellation__c IN :cancellationReason
                                                        ];

        if (cancellations.isEmpty()) {
            return;
        }

         //  Prepare unit updates
        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        Set<Id> unitIds = new Set<Id>();
        Map<Id, Id> soToOfferId = new Map<Id, Id>();
        Map<Id, SalesOrderCancellation__c> offerIdToCancellationMap = new Map<Id, SalesOrderCancellation__c>();
        Map<Id, Id> unitIdToSalesManagerId = new Map<Id, Id>(); // New map

        for (SalesOrderCancellation__c cancel : cancellations) {
            Id unitId = salesOrderAndUnitIdsMap.get(cancel.SalesOrder__c);
            if (cancel.ReasonforCancellation__c == NAME_CHANGE && unitId != null && cancel.New_Buyer_Opportunity__c != null) {
                unitsToUpdate.add(
                    new Unit__c(
                        Id = unitId,
                        Status__c = 'Blocked',
                        RelatedOpportunity__c = cancel.New_Buyer_Opportunity__c,
                        BlockedBy__c = UserInfo.getUserId(),
                        BlockedReason__c = 'Sales Cancellation',
                        BlockedComments__c = 'Sales Order Cancellation Name Change'
                    )
                );
                unitIds.add(unitId);
            } /* else if (cancel.ReasonforCancellation__c == UPGRADE && unitId != null ) {
                unitsToUpdate.add(
                    new Unit__c(
                        Id = unitId,
                        Status__c = 'Blocked'
                    )
                );
            } */

            if (cancel.SalesOrder__r.SalesManager__c != null) {
                unitIdToSalesManagerId.put(unitId, cancel.SalesOrder__r.SalesManager__c);
            }

            if (salesOrderAndOfferIdMap.containsKey(cancel.SalesOrder__c)) {
                soToOfferId.put(cancel.SalesOrder__c, salesOrderAndOfferIdMap.get(cancel.SalesOrder__c));
                offerIdToCancellationMap.put(salesOrderAndOfferIdMap.get(cancel.SalesOrder__c), cancel);
            }

        }
        // Update units
        if (!unitsToUpdate.isEmpty()) {
            update unitsToUpdate;
            markUnitsAvailable(new List<Id>(unitIds), unitIdToSalesManagerId);
        }

        // clone Offer, OfferLines and Mapping
        if (!soToOfferId.isEmpty()) {
            cloneOfferAndOfferLineAndMapping(soToOfferId, offerIdToCancellationMap, soMap);
        }

    }

    @future
    public static void markUnitsAvailable(List<Id> unitIds, Map<Id, Id> unitIdToSalesManagerId) {
        List<Unit__c> unitsToUpdateAvailable = new List<Unit__c>();
        for (Id unitId : unitIds) {
            unitsToUpdateAvailable.add(
                new Unit__c(
                    Id = unitId,
                    Status__c = 'Available',
                    AssignedToUser__c = unitIdToSalesManagerId.containsKey(unitId) ? unitIdToSalesManagerId.get(unitId) : null,
                    LockedBy__c = unitIdToSalesManagerId.containsKey(unitId) ? unitIdToSalesManagerId.get(unitId) : null
                )
            );
        }
        update unitsToUpdateAvailable;
    }

    public static void cloneOfferAndOfferLineAndMapping(Map<Id, Id> soToOfferId, Map<Id, SalesOrderCancellation__c> offerIdToCancellationMap, Map<Id, SObject> soMap) {
        if (soToOfferId.isEmpty()) return;

        Set<Id> offerIds = new Set<Id>(soToOfferId.values());

        // Query offers with children in one SOQL
        List<OffersPromotions__c> offers = [
            SELECT Id, Name, AllocationGroup__c, BookingMemo__c, BookingMemoOwner__c, BrokerPortalFlag__c, BuildingSectionName__c, CurrencyIsoCode,
                DigitalSales__c, EndDate__c, ExtendOffer__c, OfferDescription__c, OfferName__c, OriginalCreationDate__c, OwnerId,
                Project__c, SalesEventCampaignName__c, StartDate__c, Unit__c, 
                
                (SELECT Id, Agent_Type__c, AgentType__c, BudgetControl__c, BudgetTaskName__c, Bulk__c, CurrencyIsoCode, CustomerType__c,
                Description__c, DiscountType__c, Enquiry_Category__c, Enquiry_Trigger__c, LeadSource__c, LowerBound__c, Nationality__c,
                NumberOfBedrooms__c, OfferName__c, OfferOn__c, OfferType__c, OfferValue__c, OfferValueType__c, OriginalCreationDate__c,
                PromoType__c, PromoValue__c, Range__c, RangeOnField__c, ResidentStatus__c, Unit__c, UnitFeatures__c, UnitModel__c,
                UnitType__c, UpperBound__c, VoucherName__c FROM Offers_Lines__r),

                (SELECT Id, BuildingSection__c, CurrencyIsoCode, OfferPromotion__c FROM BuldingOfferBOJs__r)
            FROM OffersPromotions__c
            WHERE Id IN :offerIds
        ];

        if (offers.isEmpty()) return;

        // Clone parent offers
        List<OffersPromotions__c> newOffers = new List<OffersPromotions__c>();
        Map<Id, Id> oldToNewOfferMap = new Map<Id, Id>();

        for (OffersPromotions__c oldOffer : offers) {
            SalesOrderCancellation__c cancel = offerIdToCancellationMap.get(oldOffer.Id);
            OffersPromotions__c newOffer = oldOffer.clone(false, false, false, false);

            newOffer.Name = 'Offer & Promotion - ' +cancel.Name;
            newOffer.OfferName__c = 'Offer & Promotion - '+cancel.Name;
            newOffer.StartDate__c = Date.today().addDays(-1);
            newOffer.EndDate__c = Date.today().addDays(1);
            newOffer.Unit__c = cancel.Unit__c;
            newOffer.ExtendOffer__c = false;
            newOffer.New_Buyer_Opportunity__c = cancel.New_Buyer_Opportunity__c;
            newOffers.add(newOffer);
            oldToNewOfferMap.put(oldOffer.Id, null); // fill later after insert
        }

        if (!newOffers.isEmpty()) {
            insert newOffers;

            // Map back old → new offer Ids
            for (Integer i = 0; i < offers.size(); i++) {
                oldToNewOfferMap.put(offers[i].Id, newOffers[i].Id);
            }
        }

        // Clone children
        List<SObject> childrenToInsert = new List<SObject>();

        for (OffersPromotions__c oldOffer : offers) {
            Id newOfferId = oldToNewOfferMap.get(oldOffer.Id);

            // Clone Offer Lines
            for (OfferLines__c line : oldOffer.Offers_Lines__r) {
                OfferLines__c newLine = line.clone(false, false, false, false);
                newLine.OfferName__c = newOfferId;
                childrenToInsert.add(newLine);
            }

            // Clone Building Offer BOJs
            for (BuildingOfferBOJ__c boj : oldOffer.BuldingOfferBOJs__r) {
                BuildingOfferBOJ__c newBoj = boj.clone(false, false, false, false);
                newBoj.OfferPromotion__c = newOfferId;
                childrenToInsert.add(newBoj);
            }
        }

        if (!childrenToInsert.isEmpty()) {
            insert childrenToInsert;
        }
        createInternalCommissions(soToOfferId, offerIdToCancellationMap, oldToNewOfferMap, soMap);
    }

    private static void createInternalCommissions(
        Map<Id, Id> soToOfferId,
        Map<Id, SalesOrderCancellation__c> offerIdToCancellationMap,
        Map<Id, Id> oldToNewOfferMap,
        Map<Id, SObject> soMap
    ) {
        List<InternalCommission__c> internalCommissionsToInsert = new List<InternalCommission__c>();
        List<BrokerCommission__c> brokerCommissionsToInsert = new List<BrokerCommission__c>();

        for (SalesOrderCancellation__c cancel : offerIdToCancellationMap.values()) {
            Id soId = cancel.SalesOrder__c;
            Id oldOfferId = soToOfferId.get(soId);
            Id newOfferId = oldToNewOfferMap.get(oldOfferId);

            if (soId == null || newOfferId == null) continue;

            SalesOrder__c so = (SalesOrder__c) soMap.get(soId);
            if (so == null) continue;

            Decimal netAmount   = (so.NetAmount__c == null || so.NetAmount__c == 0) ? 0 : so.NetAmount__c;
            Decimal internalAmt = so.InternalCommissionAmount__c == null ? 0 : so.InternalCommissionAmount__c;
            Decimal externalAmt = so.ExternalCommissionAmount__c == null ? 0 : so.ExternalCommissionAmount__c;

            Decimal internalPct = netAmount == 0 ? 0 : ((internalAmt / netAmount) * 100).setScale(4);
            Decimal externalPct = netAmount == 0 ? 0 : ((externalAmt / netAmount) * 100).setScale(4);

            // === Internal Commission record ===
            InternalCommission__c internalCommission = new InternalCommission__c(
                OfferPromotion__c    = newOfferId,
                Project__c           = so.Project_Id__c,
                DirectCommission__c  = internalPct,
                VIPDirectCommission__c = internalPct,
                LandDirectCommission__c = internalPct,
                IndirectCommission__c   = internalPct,
                VIPIndirectCommission__c = internalPct,
                LandInDirectCommission__c = internalPct,
                SalesValueFrom__c    = 0,
                SaleValueTo__c       = 999999999,
                StartDate__c         = Date.today().addDays(-1),
                EndDate__c           = Date.today().addDays(1),
                SaleType__c          = cancel.New_Buyer_Opportunity__r.SaleType__c,
                ResidentStatus__c    = cancel.New_Buyer_Opportunity__r.CustomerResidentStatus__c
            );
            internalCommissionsToInsert.add(internalCommission);

            // === External (Broker) Commission record ===
            BrokerCommission__c brokerCommission = new BrokerCommission__c(
                OfferPromotion__c      = newOfferId,
                Project__c             = so.Project_Id__c,
                CommissionPercentage__c = externalPct,
                StartDate__c           = Date.today().addDays(-1),
                EndDate__c             = Date.today().addDays(1),
                SaleType__c            = cancel.New_Buyer_Opportunity__r.SaleType__c
            );
            brokerCommissionsToInsert.add(brokerCommission);
        }

        if (!internalCommissionsToInsert.isEmpty()) {
            insert internalCommissionsToInsert;
        }
        if (!brokerCommissionsToInsert.isEmpty()) {
            insert brokerCommissionsToInsert;
        }
    }
}