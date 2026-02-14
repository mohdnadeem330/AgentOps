global  without sharing class CC_SRTransferFeeCharegeProcessing implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        List<Id> recordIds =new List<Id>();
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        //Id recordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('PropertyTransfer').getRecordTypeId();
        List<SalesOrderOtherCharges__c> chargeList = new List<SalesOrderOtherCharges__c>();
        
        if (serviceRequest.SRType__c == 'Property Transfer NOC' && stp.HexaBPM__Summary__c == 'Signing of the Transfer Documents & Collecting the Transfer Charges') { 
            // Check if either of the conditions is met
            Boolean isSellingPriceBlank = (serviceRequest.MOUSigned__c == 'Yes' && serviceRequest.TransferSellingPrice__c ==null);
            Boolean isChargeTypeBlank = (serviceRequest.ChargeWaivedOff__c == false && String.isBlank(serviceRequest.ChargeType__c));
            // If either condition is true, add a single error message
            if (isSellingPriceBlank || isChargeTypeBlank) {
                return 'Please provide the Transfer Selling Price and Charge Type to proceed with the NOC process.';
            }
        }
		
        if(serviceRequest.ResaleOpportunity__r.SaleType__c == 'Resale') { //Added by Anil Kumar for Resale issue.
            Opportunity opp = new Opportunity(Id=serviceRequest.ResaleOpportunity__c);
            chargeList = createResaleCharges(new List<Opportunity>{opp}, true);
        } else if(serviceRequest.ResaleOpportunity__c != null && serviceRequest.Unit__r.ResaleListingExclusiveness__c == 'Exclusive' && serviceRequest.Unit__r.CancellationChargesExpiryDate__c != null && serviceRequest.Unit__r.CancellationChargesExpiryDate__c > System.today()){
            Opportunity opp = new Opportunity(Id=serviceRequest.ResaleOpportunity__c);
            chargeList = createResaleCharges(new List<Opportunity>{opp}, false);
        }
        
        if(!chargeList.isEmpty()) {
            for(SalesOrderOtherCharges__c charge : chargeList) {
                charge.ServiceRequest__c = serviceRequest.Id;
            }
        }

        /*
        * Logic: If Charge to be Collected in not zero then Create a Trasfer Fee in Other Charges and allocate those to Receipt
        */
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
        if (serviceRequest.ChargeCollected__c != null && serviceRequest.ChargeCollected__c != 0 && serviceRequest.ChargeWaivedOff__c == false) {
            otherCharge.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE;
            
            if(serviceRequest.BuyerName__c != null) {
                otherCharge.Account__c = serviceRequest.BuyerName__c;
            } else if(serviceRequest.HexaBPM__Customer__c != null) {
                otherCharge.Account__c = serviceRequest.HexaBPM__Customer__c;
            }
            otherCharge.Amount__c = serviceRequest.ChargeCollected__c;
            otherCharge.SalesOrder__c = serviceRequest.SalesOrder__c;
            otherCharge.AmountWithoutVAT__c = serviceRequest.AmountWithoutVAT__c;
            otherCharge.ServiceRequest__c=serviceRequest.Id;
            otherCharge.VATAmount__c = serviceRequest.AmountWithoutVAT__c != null && serviceRequest.AmountWithoutVAT__c != 0 ? serviceRequest.ChargeCollected__c - serviceRequest.AmountWithoutVAT__c : 0;
            otherCharge.SyncStatus__c='In Progress';
            chargeList.add(otherCharge);
        }
        
        if (chargeList.size() > 0) {
            Database.insert(chargeList, true);

            if (!serviceRequest.Receipt_Acknowledgements__r.isEmpty()) {
                ReceiptAllocation__c receiprAllocation = SRUtility.createReceiptAllocation(otherCharge, serviceRequest);
            }

            Set<Id> chargeIdList = new Set<Id>(); 
            chargeIdList.add(otherCharge.Id);

            for(SalesOrderOtherCharges__c thisCharge: chargeList){
                if(thisCharge.ERPID__c == ''){
                    chargeIdList.add(thisCharge.Id);
                }
            }

            if(chargeIdList.size() > 0) {
                Map<String, String> cdLinkEntityId = new Map<String, String>();
                ALDOC_OtherChargesHelper.doOtherChargeCallout(new List<Id>(chargeIdList), cdLinkEntityId);
            }
        }


         /*if(SR.RecordTypeId != recordTypeId) {
            
            if (serviceRequest.ChargeCollected__c != null && serviceRequest.ChargeCollected__c != 0 && serviceRequest.ChargeWaivedOff__c == false) {
                SalesOrderOtherCharges__c otherCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE);
                otherCharge.SyncStatus__c='In Progress';
                update otherCharge;
                recordIds.add(otherCharge.Id);
                if (!serviceRequest.Receipt_Acknowledgements__r.isEmpty()) {
                    ReceiptAllocation__c receiprAllocation = SRUtility.createReceiptAllocation(otherCharge, serviceRequest);
                }
            }
            if(recordIds.size()>0){
                Map<String, String> cdLinkEntityId = new Map<String, String>();
                ALDOC_OtherChargesHelper.doOtherChargeCallout(recordIds,cdLinkEntityId);
            }
            
         } else {
             Opportunity opp = new Opportunity(Id=serviceRequest.ResaleOpportunity__c);
             createResaleCharges(new List<Opportunity>{opp});
         }*/

        return null;
    }

    public static List<SalesOrderOtherCharges__c> createResaleCharges(List<Opportunity> oppList, Boolean isAllCharged){

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
                } else if(thisChargeType == ResaleConstants.CHARGETYPE_SC_BUYER && !isAllCharged){
                    continue;
                } else{
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
                        thisSOOC.AmountWithoutVAT__c = thisSOOC.Amount__c / (1+ (Decimal.valueOf(System.label.ResaleVATPerc)/100));
                        thisSOOC.VATAmount__c = thisSOOC.Amount__c - (thisSOOC.AmountWithoutVAT__c).setScale(2);
                        thisSOOC.Account__c = thisOpp.SalesOrder__r.Account__c;
                    }
                    if (thisChargeType == ResaleConstants.CHARGETYPE_SC_BUYER) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_SC_BUYER;
                        thisSOOC.Amount__c = thisOpp.Amount > 0 ? 0.02*thisOpp.Amount : 0;
                        thisSOOC.AmountWithoutVAT__c = thisSOOC.Amount__c / (1+ (Decimal.valueOf(System.label.ResaleVATPerc)/100).setScale(2));
                        thisSOOC.VATAmount__c = thisSOOC.Amount__c - thisSOOC.AmountWithoutVAT__c;
                        thisSOOC.Account__c = thisOpp.AccountId;
                    }
                    if (thisChargeType == ResaleConstants.CHARGETYPE_SC_SELLER) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_SC_SELLER;
                        thisSOOC.Amount__c = thisOpp.Amount > 0 ? 0.02*thisOpp.Amount : 0;
                        thisSOOC.AmountWithoutVAT__c = thisSOOC.Amount__c / (1+ (Decimal.valueOf(System.label.ResaleVATPerc)/100).setScale(2));
                        thisSOOC.VATAmount__c = thisSOOC.Amount__c - thisSOOC.AmountWithoutVAT__c;
                        thisSOOC.Account__c = thisOpp.SalesOrder__r.Account__c;
                    }

                    chargeToOppMap.put(thisSOOC.Account__c+thisSOOC.TypeOfCharge__c, thisOpp);
                    chargeList.add(thisSOOC);
                }
            }
        }

        return chargeList;
        
        /*if (chargeList.size() > 0) {
            Database.insert(chargeList, true);
            if(chargeList.size() > 0){
                //Create Charge Receipt Ack and Receipt Allocation
                //Commented the Receipt Automations 12 June 2023, Harsh@Aldar
                // createReceipt(chargeList, chargeToOppMap, oppIdSalesOrderIdMap);

                //sync the created Charges in ALDOC
                createReceiptInALDOC(chargeList);
            }
        }*/
    }

    /**
    * Sync the newly created charges to ALDOC
    */
    /*private static void createReceiptInALDOC(List<SalesOrderOtherCharges__c> chargeList){
        List<Id> chargeIdList = new List<Id>(); 

        for(SalesOrderOtherCharges__c thisCharge: chargeList){
            if(thisCharge.ERPID__c == ''){
                chargeIdList.add(thisCharge.Id);
            }
        }
        if(chargeIdList.size() > 0){
            ALDOC_OtherChargesHelper.doOtherChargeCallout(chargeIdList, null);
        }
    }*/
}