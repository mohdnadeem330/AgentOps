/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Service Class for Resale Unit.
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
public without sharing class ResaleUnitService {
    /**
   * @description getAvailableResaleUnits Get List of Resale Units under Buildings 
   * ASF-936 Developed by Harsh@Aldar 12/06/23
   * @param  buildingsIds buildingsIds description
   * @return              return description
   */
  public static List<Unit__c> getAvailableResaleUnits(Set<Id> buildingsIds){

    String acceptedStatusListString = System.Label.ResaleUnitAcceptStatusList;
    // Split the values using the comma as a delimiter
    List<String> acceptedStatusList = acceptedStatusListString.split(',');

    return [SELECT Id, Name, NumberOfBedrooms__c, UnitType__c, MultiPurposeAmount__c, MultiPurposeRoomArea__c,
            MeasuredArea__c, PropertyUsage__c, UnitModel__c, FloorNumber__c, UnitView__c, PropertyStatus__c, 
            SaleableArea__c, TotalRooms__c, UnitCategory__c, MeasuredInternalArea__c, TerraceArea__c, TotalArea__c,
            UnitPlotArea__c, SellingPrice__c, OnlineReservationFee__c, AffectionPlan__c, MarketingPlan__c, 
            AnticipatedServiceCharges__c, BuildingSectionName__c, Listing_Price__c,
            BuildingSectionName__r.HomeMaintenanceFee__c, BuildingSectionName__r.PropertyManagementFee__c,
            BuildingSectionName__r.EligibileforMultiPurposeRoom__c, BuildingSectionName__r.EligibleforUnitFinishes__c,
            BuildingSectionName__r.ReservationAmount__c, ProjectBudget__c, ResaleStatus__c 
            FROM Unit__c 
            WHERE BuildingSectionName__c IN :buildingsIds  
            AND ResaleListed__c = true
            AND ResaleStatus__c NOT IN :acceptedStatusList
            ORDER BY Name];
  } 
     
    /**
     * @description Used in the custom lookup component
     * @param  recordId       recordId description
     * @param  sObjectApiName sObjectApiName description
     * @return                return description
     */
    @AuraEnabled
    public static sObject searchDefaultRecord(string recordId , string sObjectApiName) {
        string sRecId = recordId;    
        string sQuery = 'SELECT Id,Name FROM ' + sObjectApiName + ' WHERE Id = : sRecId LIMIT 1';
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }

    /**
     * @description createResaleCharges ASF-869 Harsh@Aldar 
     * @param  thisOpp thisOpp description
     */
    public static void createResaleCharges(List<Opportunity> oppList){

        List<SalesOrderOtherCharges__c> chargeList = new List<SalesOrderOtherCharges__c>();
        Map<String, Opportunity> chargeToOppMap = new Map<String, Opportunity>(); 
        Map<Id, Id> oppIdSalesOrderIdMap = new Map<Id, Id>(); 

        Set<String> resaleChargeTypes = new Set<String>{ResaleConstants.CHARGETYPE_LISTING, ResaleConstants.CHARGETYPE_SC_BUYER, ResaleConstants.CHARGETYPE_SC_SELLER};
        Map<String, SalesOrderOtherCharges__c> existingChargesMap = new Map<String, SalesOrderOtherCharges__c>(); 
        //check existing charges, do not create duplicate charges
        for(SalesOrderOtherCharges__c thisChargeRec: [SELECT Id, TypeOfCharge__c, Opportunity__c FROM SalesOrderOtherCharges__c WHERE Opportunity__c IN: oppList]){
            existingChargesMap.put(thisChargeRec.Opportunity__c+'-'+thisChargeRec.TypeOfCharge__c, thisChargeRec);
        }

        for (Opportunity thisOpp : [SELECT Id, SalesOrder__r.Account__c, OwnerId, Amount, Opportunity.AccountId,
                                    SalesOrder__c, LeadSource // BuyerPaymentMethodPreference__c, SellerPaymentMethodPreference__c, 
                                    FROM Opportunity 
                                    WHERE Id IN: oppList]) {
            oppIdSalesOrderIdMap.put(thisOpp.Id, thisOpp.SalesOrder__c);

            //keeping this nested for loop because resaleChargeTypes will always have size of 3
            for(String thisChargeType: resaleChargeTypes){
                
                //Harsh@Aldar -- 28/08/23 -- Dont create Buyer Charge if Lead Source is Broker / Broker Portal
                if(String.valueOf(thisOpp.LeadSource).toLowerCase().contains('broker') && thisChargeType == ResaleConstants.CHARGETYPE_SC_BUYER){
                    continue;
                }
                //check if already exists
                if(existingChargesMap != null && existingChargesMap.get(thisOpp.Id+'-'+thisChargeType) != null){
                    //charge exists
                    System.debug('#### ----- > '+existingChargesMap.get(thisOpp.Id+'-'+thisChargeType));
                    continue;
                }else{
                    //charge doesnt exist
                    SalesOrderOtherCharges__c thisSOOC = new SalesOrderOtherCharges__c();
                    thisSOOC.Opportunity__c = thisOpp.Id;
                    thisSOOC.ChargedFromResaleOpp__c = true;
                    thisSOOC.Approval_Status__c = ResaleConstants.STATUS_IN_PROGRESS;
                    thisSOOC.SalesOrder__c = thisOpp.SalesOrder__c;
                    thisSOOC.ERPID__c = '';

                    if (thisChargeType == ResaleConstants.CHARGETYPE_LISTING) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_LISTING;
                        thisSOOC.Amount__c = ResaleConstants.LISTING_PRICE;
                        thisSOOC.Account__c = thisOpp.SalesOrder__r.Account__c;
                    }
                    if (thisChargeType == ResaleConstants.CHARGETYPE_SC_BUYER ) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_SC_BUYER;
                        thisSOOC.Amount__c = thisOpp.Amount > 0 ? 0.02*thisOpp.Amount : 0;
                        thisSOOC.Account__c = thisOpp.AccountId;
                    }
                    if (thisChargeType == ResaleConstants.CHARGETYPE_SC_SELLER) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_SC_SELLER;
                        thisSOOC.Amount__c = thisOpp.Amount > 0 ? 0.02*thisOpp.Amount : 0;
                        thisSOOC.Account__c = thisOpp.SalesOrder__r.Account__c;
                    }

                    chargeToOppMap.put(thisSOOC.Account__c+thisSOOC.TypeOfCharge__c, thisOpp);
                    chargeList.add(thisSOOC);
                }
            }
        }
        
        if (chargeList.size() > 0) {
            Database.insert(chargeList, true);
            if(chargeList.size() > 0){
                //Create Charge Receipt Ack and Receipt Allocation
                //Commented the Receipt Automations 12 June 2023, Harsh@Aldar
                // createReceipt(chargeList, chargeToOppMap, oppIdSalesOrderIdMap);

                //sync the created Charges in ALDOC
                createReceiptInALDOC(chargeList);
            }
        }
    }

    /**
    * Sync the newly created charges to ALDOC
    */
    private static void createReceiptInALDOC(List<SalesOrderOtherCharges__c> chargeList){

        List<Id> chargeIdList = new List<Id>(); 

        for(SalesOrderOtherCharges__c thisCharge: chargeList){
            if(thisCharge.ERPID__c == ''){
                chargeIdList.add(thisCharge.Id);
            }
        }
        if(chargeIdList.size() > 0){
            ALDOC_OtherChargesHelper.doOtherChargeCallout(chargeIdList, null);
        }
    }

    //Commented the Receipt Automations 12 June 2023, Harsh@Aldar
    /**
     * @description Create Receipt Acknowledgement after SOOC are created
     * @param  chargeList           List of SOOC records
     * @param  chargeToOppMap       Map used to identifu the Opportunity related to corresponding SOOC record, thisSOOC.Account__c+thisSOOC.TypeOfCharge__c is the key
     * @param  oppIdSalesOrderIdMap Map of Opportunity Id to corresponding Sales Order Id
     */
    // private static void createReceipt(List<SalesOrderOtherCharges__c> chargeList, Map<String, Opportunity> chargeToOppMap, Map<Id, Id> oppIdSalesOrderIdMap){
    //     List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
    //     Map<String, SalesOrderOtherCharges__c> receiptToChargeMap = new Map<String, SalesOrderOtherCharges__c>();

    //     for(SalesOrderOtherCharges__c thisSOOC : chargeList){
    //         String key = thisSOOC.Account__c+thisSOOC.TypeOfCharge__c;  

    //         System.debug('####chargeToOppMap.get(thisSOOC): '+chargeToOppMap.get(key));

    //         ReceiptAcknowledgement__c thisReceipt = new ReceiptAcknowledgement__c();
    //         thisReceipt.Account__c = thisSOOC.Account__c;
    //         thisReceipt.Amount__c = thisSOOC.Amount__c;
    //         thisReceipt.Opportunity__c = thisSOOC.Opportunity__c;
    //         thisReceipt.SalesOrder__c = oppIdSalesOrderIdMap.get(thisSOOC.Opportunity__c);

    //         if (thisSOOC.TypeOfCharge__c == ResaleConstants.CHARGETYPE_LISTING) {
    //             thisReceipt.PaymentType__c = chargeToOppMap.get(key).SellerPaymentMethodPreference__c;
    //         }
    //         if (thisSOOC.TypeOfCharge__c == ResaleConstants.CHARGETYPE_SC_BUYER) {
    //             thisReceipt.PaymentType__c = chargeToOppMap.get(key).BuyerPaymentMethodPreference__c;
    //         }
    //         if (thisSOOC.TypeOfCharge__c == ResaleConstants.CHARGETYPE_SC_SELLER) {
    //             thisReceipt.PaymentType__c = chargeToOppMap.get(key).SellerPaymentMethodPreference__c;
    //         }

    //         receiptToChargeMap.put(thisReceipt.Account__c+'-'+thisReceipt.Amount__c, thisSOOC);
    //         receiptList.add(thisReceipt);
    //     }
    //     Database.insert(receiptList, true);
    //     if(receiptList.size() > 0){
    //         createAllocation(receiptList, receiptToChargeMap, oppIdSalesOrderIdMap);
    //     }
    // }


    //Commented the Receipt Automations 12 June 2023, Harsh@Aldar
    /**
     * @description Once Receipts are created for SOOC records, create allocations
     * @param  receiptList          List of newly created receipts
     * @param  receiptToChargeMap   Map to get SOOC record corresponding to the Receipt, thisReceipt.Account__c+'-'+thisReceipt.Amount__c is used as key
     * @param  oppIdSalesOrderIdMap Map of Opportunity Id to corresponding Sales Order Id
     */
    // private static void createAllocation(List<ReceiptAcknowledgement__c> receiptList, Map<String, SalesOrderOtherCharges__c> receiptToChargeMap, Map<Id, Id> oppIdSalesOrderIdMap){
        
    //     List<ReceiptAllocation__c> ackList = new List<ReceiptAllocation__c>();

    //     for (ReceiptAcknowledgement__c thisReceipt : receiptList) {
    //         ReceiptAllocation__c thisAck = new ReceiptAllocation__c();
    //         thisAck.Account__c = thisReceipt.Account__c;
    //         thisAck.ReceiptAcknowledgement__c = thisReceipt.Id;
    //         thisAck.AmountApplied__c = thisReceipt.Amount__c;
    //         thisAck.SalesOrderOtherCharges__c = receiptToChargeMap.get(thisReceipt.Account__c+'-'+thisReceipt.Amount__c).Id;
    //         System.debug('####receiptToChargeMap -- '+thisReceipt.Amount__c+' -- '+receiptToChargeMap.get(thisReceipt.Account__c+'-'+thisReceipt.Amount__c).Id);
    //         thisAck.SalesOrder__c = oppIdSalesOrderIdMap.get(thisReceipt.Opportunity__c);
    //         thisAck.InstallmentLine__c = null;
    //         ackList.add(thisAck);
    //     }
    //     Database.insert(ackList, true);
    // }

    /**
     * @description handleCompletedResaleMOUDocAction description, update the MOU Signed Flag on Unit
     * @param  oppIdList oppIdList description
     */
    public static void handleUploadedResaleMOUDocAction(Set<Id> oppIdList){
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        List<Unit__c> unitUpdateList = new List<Unit__c>();
        List<Case> caseUpdateList = new List<Case>();

        Map<Id, Boolean> mapOppId_Flag_CheckDocument = checkUploadedDoc(oppIdList);
        System.debug('####mapOppId_Flag_CheckDocument: '+mapOppId_Flag_CheckDocument);
        for (Id thisOppId : oppIdList) {
            if(mapOppId_Flag_CheckDocument.size() > 0 && mapOppId_Flag_CheckDocument.keySet().contains(thisOppId) && mapOppId_Flag_CheckDocument.get(thisOppId) == true){
                Opportunity thisOpp = new Opportunity();
                thisOpp.Id = thisOppId;
                thisOpp.StageName = ResaleConstants.OPP_STATUS_CLOSED_WON;
                thisOpp.MOUSignedDate__c = System.today();
                thisOpp.TransferRequestInitiationDate__c = System.today();
                thisOpp.ResaleOpportunityStageFlag__c = String.valueOf(System.now());
                thisOpp.WinReason__c = 'Won - Price';
                oppUpdateList.add(thisOpp);
            }
        }

        if(oppUpdateList.size() > 0){
            update oppUpdateList;
        }

        //update the MOU siged flag on Unit
        for(Opportunity thisOpp: [SELECT Id, Unit__c, Unit__r.ListedCase__c FROM Opportunity WHERE Id IN: oppUpdateList]){
            Unit__c thisUnit = new Unit__c();
            thisUnit.Id = thisOpp.Unit__c;
            thisUnit.MOU_Signed__c = true;
            thisUnit.ResaleStatus__c = ResaleConstants.UNIT_RESALESTATUS_TRANSFER_PROGRESS;
            thisUnit.ResaleListed__c = false;
            thisUnit.Delisted_Date__c = System.today();
            thisUnit.Listing_Price__c = null;
            unitUpdateList.add(thisUnit);
            if(thisOpp.Unit__r.ListedCase__c != null){
                caseUpdateList.add(
                    new Case(
                        Id = thisOpp.Unit__r.ListedCase__c,
                        Status = Constants.CLOSED_CASE
                    )
                );
            }
        }

        if(unitUpdateList.size() > 0){
            update unitUpdateList;
        }
        if(caseUpdateList.size() > 0){
            update caseUpdateList;
        }
    }

    private static Map<Id, Boolean> checkUploadedDoc (Set<Id> oppIdlist){
        Map<Id, Boolean> returnMap = new Map<Id, Boolean>();

        if(!oppIdlist.isEmpty()){
            for(Document__c doc : [ SELECT Id,
                                        Opportunity__c,
                                        DocumentType__c,
                                        (SELECT Id FROM ContentDocumentLinks)
                                    FROM Document__c
                                    WHERE Opportunity__c IN: oppIdlist
                                    AND DocumentType__c = 'Signed Listing MOU']){
                if(!doc.ContentDocumentLinks.isEmpty()){
                    returnMap.put(doc.Opportunity__c, true);
                }
            }
        }

        return returnMap;
    }

    /**
     * @description createResaleMOUDocuments description ASF-936
     * @param  oppList oppList description
     */ 
    public static void createResaleMOUDocuments(List<Opportunity> oppList){

        List<Document__c> documentListToInsert = new List<Document__c>();

        Map<String, Id> documentRecordTypeMap = new Map<String,Id>();

        Map<Id, Opportunity> oppIdToRecMap = new  Map<Id, Opportunity>(oppList);

        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{ResaleConstants.CATEGORY_RESALE_OPP});
        System.debug('#### documentMap: '+documentMap);
        if(!documentMap.isEmpty()){
            //get Existing Documents
            Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Opportunity__c 
                                        FROM Document__c 
                                        WHERE Opportunity__c IN :oppIdToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Opportunity__c+tempDoc.DocumentType__c, tempDoc);
            }

            for(Opportunity actRec : oppList){
                String documentTypeToProcess = ResaleConstants.CATEGORY_RESALE_OPP; 
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    String recordTypeID = null;
                    if(tempMetaRec.RecordTypeDeveloperName__c != null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //existing check
                    if(!existingDocMap.containsKey(actRec.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                                    Opportunity__c = actRec.Id,
                                                                    OwnerId = actRec.OwnerId,
                                                                    RecordtypeId = recordTypeID,
                                                                    AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c,
                                                                    GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true) );
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(actRec.Id + tempMetaRec.DocumentType__c, documentRecord); 
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }

    /**
     * @description On Unit Update, update the Sales Order too
     * @param  oppList List of Opportunity from Trigger
     */
    public static void handleResaleUnitChange(List<Opportunity> oppList){
        try{
            List<Opportunity> oppUpdateList = new List<Opportunity>();
            for (Opportunity thisOpp : [SELECT Id, Unit__c, Unit__r.ListedCase__r.SalesOrder__c FROM Opportunity WHERE Id IN: oppList]) {
                if (thisOpp.Unit__r.ListedCase__r.SalesOrder__c != null) {
                    thisOpp.SalesOrder__c = thisOpp.Unit__r.ListedCase__r.SalesOrder__c;
                    oppUpdateList.add(thisOpp);
                }
            }

            if(oppUpdateList.size() > 0){
                Database.update(oppUpdateList);
            }
        }catch(Exception e){
            system.debug('## ERROR OCCURRED '+e.getMessage());
        }
        

    }

    /**
    * When Lead is populate with Resale Case, update the Unit and Account on Case into Lead
    *
    */
    /*public static void handleCasePopulationOnResaleLead(List<Lead> leadsList){

        List<Lead> leadUpdateList = new List<Lead>();

        for(Lead thisLead: [SELECT Id, Resale_Unit_Case__r.Id, Resale_Unit_Case__r.AccountId, Resale_Unit_Case__r.Unit__c, Resale_Unit_Case__r.SalesOrder__c
                            FROM Lead WHERE Id IN: leadsList]){

            Lead leadToUpdate = new Lead();
            leadToUpdate.Id = thisLead.Id;
            leadToUpdate.Account__c = thisLead.Resale_Unit_Case__r.AccountId;
            leadToUpdate.Unit__c = thisLead.Resale_Unit_Case__r.Unit__c;
            leadToUpdate.Sales_Order__c = thisLead.Resale_Unit_Case__r.SalesOrder__c;
            leadUpdateList.add(leadToUpdate);
        }

        if(leadUpdateList.size() > 0){
            update leadUpdateList;
        }
    }*/
    /**
    * called from JointOwnersOppController, get all related accounts from opportunity
    */
    public static Set<Id> getOpportunityAccountId(Id oppId){
        Set<Id> accountIds = new Set<Id> ();
        for(Opportunity thisOpp : [SELECT Name, AccountId from Opportunity WHERE Id =: oppId]){
            accountIds.add(thisOpp.AccountId);
        }
        return accountIds;
    }

    /*
    *updateOpportunity : method to update document status on Opportunity when signed.   
    *Created By : Himanshu@aldar.com
    *Return : null
    */
    public static void updateOpportunity(List<dfsle__RecipientStatus__c> newList, Map<Id,SObject> oldMap){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        if(oldMap == null) oldMap = new Map<Id, SObject>();
        // System.debug('newList>>'+JSON.serializepretty(newList));
        
        Map<Id, Decimal> sourceIdToMaxCompletedROrderMap = new Map<Id, Decimal>();
        
        for(dfsle__RecipientStatus__c newRS : newList ){
            dfsle__RecipientStatus__c oldRS = (dfsle__RecipientStatus__c) oldMap.get(newRS.Id);
            if( newRS.dfsle__Status__c == 'Completed' 
                && (oldRS != null || newRS.dfsle__Status__c != newRS.dfsle__Status__c) 
                && newRS.dfsle__RoutingOrder__c != null 
            ){
                if( !sourceIdToMaxCompletedROrderMap.containsKey(newRS.dfsle__SourceId__c) 
                    || sourceIdToMaxCompletedROrderMap.get(newRS.dfsle__SourceId__c) < newRS.dfsle__RoutingOrder__c 
                ){
                    sourceIdToMaxCompletedROrderMap.put(newRS.dfsle__SourceId__c, newRS.dfsle__RoutingOrder__c);
                }
            }
        }

        if(!sourceIdToMaxCompletedROrderMap.isEmpty()){
            Map<Id, Document__c> docMap = new Map<Id, Document__c>();
            Map<Id, Decimal> recIdToSignersCount = new Map<Id, Decimal>();
            for(Document__c doc: [  SELECT Id, DocumentType__c, 
                                        Opportunity__c, Opportunity__r.SalesOrder__c, 
                                        Opportunity__r.Document_Status__c
                                    FROM Document__c 
                                    WHERE Id IN:sourceIdToMaxCompletedROrderMap.keySet()
                                        AND DocumentType__c = 'Listing MOU' 
                                        AND Opportunity__c != null
                                    ORDER BY LastModifiedDate ASC]
            ){
                docMap.put(doc.Id, doc);
                recIdToSignersCount.put(doc.Opportunity__c, 1);
                if(doc.Opportunity__r.SalesOrder__c != null){
                    recIdToSignersCount.put(doc.Opportunity__r.SalesOrder__c, 1);
                }
            }
            if(!recIdToSignersCount.isEmpty()){
                for(AggregateResult ar : [  SELECT count(Id) jos, 
                                                Opportunity__c oppId, SalesOrder__c soId 
                                            FROM JointOwner__c 
                                            WHERE Opportunity__c IN: recIdToSignersCount.keySet()
                                                OR SalesOrder__c IN: recIdToSignersCount.keySet()
                                            GROUP BY Opportunity__c, SalesOrder__c]
                ){
                    Id oppId = (Id)ar.get('oppId');
                    Id soId = (Id)ar.get('soId');
                    Decimal jos = (Decimal)ar.get('jos');
                    if(recIdToSignersCount.containsKey( oppId )){
                        recIdToSignersCount.put( oppId, recIdToSignersCount.get(oppId) + jos );
                    }else if(recIdToSignersCount.containsKey( soId )){
                        recIdToSignersCount.put( soId, recIdToSignersCount.get(soId) + jos );
                    }
                }
            }
            // System.debug(sourceIdToMaxCompletedROrderMap);
            // System.debug(recIdToSignersCount);
            for(Id sourceId : docMap.keySet()){
                Document__c sourceDoc = docMap.get(sourceId);
                Decimal lastSignOrder = sourceIdToMaxCompletedROrderMap.get(sourceId);
                String newDocStatus;
                if(lastSignOrder == recIdToSignersCount.get(sourceDoc.Opportunity__c)){
                    newDocStatus = 'Buyer completed';
                }else if(lastSignOrder == (recIdToSignersCount.get(sourceDoc.Opportunity__c) + recIdToSignersCount.get(sourceDoc?.Opportunity__r?.SalesOrder__c)) ){
                    newDocStatus = 'Seller completed';
                }
                if(newDocStatus != null){
                    oppsToUpdate.add(
                        new Opportunity(
                            Id = sourceDoc.Opportunity__c,
                            Document_Status__c = newDocStatus
                        )
                    );
                }
            }
            if(!oppsToUpdate.isEmpty()){
                System.debug(oppsToUpdate);
                Database.update(oppsToUpdate, false);
            }
        }
    }
    
    public static void handleManagerChequeReceipt(List<ReceiptAcknowledgement__c> managerChequeReceiptAckList){

    }

    public static void disqualifyOtherOffers(List<Opportunity> oppList){

        Set<String> unitSet = new Set<String>();
        for (Opportunity opp : [SELECT Unit__c FROM Opportunity WHERE Id IN :oppList]) {
            unitSet.add(opp.Unit__c);
        }

        List<Resale_Offers__c> disqualifiedOffers = [
                                                        SELECT Id, Status__c 
                                                        FROM Resale_Offers__c 
                                                        WHERE (Unit__c IN :unitSet OR Opportunity__c IN :oppList)
                                                        AND Status__c != :ResaleConstants.RO_STATUS_DISQUALIFIED
                                                        AND Status__c != :ResaleConstants.RO_STATUS_ACCEPTED
                                                    ];

        // List<Resale_Offers__c> disqualifiedOffers = [SELECT Id, Status__c 
        //                                                 FROM Resale_Offers__c 
        //                                                 WHERE (( Unit__c IN (SELECT Unit__c FROM Opportunity WHERE Id IN :oppList)
        //                                                 OR Opportunity__c IN :oppList)
        //                                                 AND Status__c !=: ResaleConstants.RO_STATUS_DISQUALIFIED
        //                                                 AND Status__c !=: ResaleConstants.OPP_STATUS_OFFER_ACCEPTED)
        //                                             ];

        for (Resale_Offers__c offer : disqualifiedOffers) {
            offer.Status__c = ResaleConstants.RO_STATUS_DISQUALIFIED;
        }

        if (disqualifiedOffers.size() > 0) {
            update disqualifiedOffers;
        }
    }

    /**
    * Harsh@Aldar 12/07 Manage the Joint owners created under Opportuniy and not Sales Order
    */
    public static void manageOpportunityJointOwners(List<JointOwner__c> jointOwnerOpportunityList){

        if(jointOwnerOpportunityList.size() > 0){

            Set<Id> oppIdSet = new Set<Id>();
            List<Opportunity> oppUpdateList = new List<Opportunity>(); 

            Map<String, Decimal> oppIdToSharePercentageMap = getOppToSharePercantageMap(jointOwnerOpportunityList);

            for(JointOwner__c thisJo : jointOwnerOpportunityList){

                Decimal sharePercentage = oppIdToSharePercentageMap?.containsKey(thisJo.Opportunity__c) ? oppIdToSharePercentageMap.get(thisJo.Opportunity__c) + (thisJo.SharePercentage__c) : thisJo.SharePercentage__c;
                if (sharePercentage > 99) {
                    thisJo.addError('Total Joint Owner Share Percentage cannot exceed 99%');
                }else{
                    if (oppIdSet.contains(thisJo.Opportunity__c)) {
                        continue;
                    }
                    Opportunity thisOpp = new Opportunity();
                    thisOpp.Id = thisJo.Opportunity__c;
                    thisOpp.SharePercentage__c = 100 - sharePercentage;
                    oppUpdateList.add(thisOpp);
                    oppIdSet.add(thisJo.Opportunity__c);

                }

            }

            if(oppUpdateList.size() > 0){
                update oppUpdateList;
            }

        }

    }

    private static Map<String, Decimal> getOppToSharePercantageMap(List<JointOwner__c> jointOwnerList){
        List<Id> oppIdList = new List<Id>();
        Map<String, Decimal> oppIdToSharePercentageMap = new Map<String, Decimal>();
        for(JointOwner__c thisJO: jointOwnerList){
            if (thisJO.Opportunity__c != null){
                oppIdList.add(thisJO.Opportunity__c);
            }
        }

        for(Opportunity thisOpp: [SELECT Id, SharePercentage__c, 
                                    (SELECT Id, SharePercentage__c 
                                    FROM JointOwnersOpportunity__r 
                                    WHERE IsDeleted__c = false) 
                                    FROM Opportunity 
                                  WHERE Id IN:oppIdList]){
            Decimal sharePercentage = 0;
            if (!thisOpp.JointOwnersOpportunity__r.isEmpty()) {
                for (JointOwner__c jointOwner: thisOpp.JointOwnersOpportunity__r) {
                    // sharePercentage += jointOwnerPercentageMap.containsKey(jointOwner.Id) ? jointOwnerPercentageMap.get(jointOwner.Id) : jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
                    sharePercentage += jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
                }
                oppIdToSharePercentageMap.put(thisOpp.Id, sharePercentage);
            }

        }

        return oppIdToSharePercentageMap;
    }

    public static void createPTCaseForResaleOpps(List<Opportunity> oppList) {
        if(!oppList.isEmpty()){
            List<Case> newPTCases = new List<Case>();
            Id standardRecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
            for(Opportunity opp: oppList){
                newPTCases.add(
                    new Case(
                        RecordTypeId = standardRecordTypeId,
                        Opportunity__c = opp.Id,
                        Initial_Condition__c = 'Re Sale',
                        CustomerType__c = 'Owner',
                        Origin = opp.LeadSource,
                        Status = 'New',
                        SubVertical__c = 'Customer Care',
                        CaseCategory__c = 'Property Transfer',
                        Unit__c = opp.Unit__c,
                        Subject = 'Resale Porperty Transfer',
                        BuyerComplianceStatus__c = opp.BuyerComplianceStatus__c
                    )
                );
            }
            if(!newPTCases.isEmpty()){
                insert newPTCases;
            }
        }
    }

    //Added By harsh@Aldar 20/09
    @AuraEnabled(cacheable=false)
    public static String getVFDomainURL(){
        String currentDomainURL = URL.getSalesforceBaseUrl().toExternalForm();
        return currentDomainURL ;     
    }
}