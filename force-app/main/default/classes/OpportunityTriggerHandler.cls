public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    Id oppPIRecId = PI_Services.oppPIRecId;

    //*** Before Insert Action***//
    public override void beforeInsertMethod(list<SObject> newList,map<ID,SObject> newMap){

        Set<Id> accountsIds = new Set<Id>();
        Id oppNewSaleRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NewSale').getRecordTypeId();
        
        for(Opportunity opportunityRecord : (list<Opportunity>)newList){
            accountsIds.add(opportunityRecord.AccountId);
            String closeDateDays = Label.OpportunityCloseDateDays;
            date todayDate = date.today();
            opportunityRecord.CloseDate = todayDate.addDays(integer.valueof(closeDateDays));
            
            //----- Changeing Opportunity Stage
            if(opportunityRecord.LeadSource == Constants.WALK_IN || opportunityRecord.LeadSource == Constants.BROKER_PORTAL){
                opportunityRecord.StageName = Constants.MEETING;
            } else{
                if(opportunityRecord.CustomerContactedBySM__c){
                    opportunityRecord.StageName = Constants.STAGE_IN_PROGRESS;
                } else{
                    opportunityRecord.StageName = Constants.STAGE_NEW;
                }
            }

            //Added by Arvind
            if(opportunityRecord.Lead_Type__c == 'Resale'){
                opportunityRecord.SaleType__c = 'Resale';  
                opportunityRecord.StageName = ResaleConstants.OPP_STATUS_DISCUSSION_IN_PROGRESS;        
            }
            
            //AM SaleType for Lead Type AM Sale - added by Karunakar
            if(opportunityRecord.Lead_Type__c == 'AM Sale'){
                opportunityRecord.SaleType__c = 'AM Sale';  
                opportunityRecord.RecordTypeId = oppNewSaleRecordTypeId;
            }
        }

        //---- to share Account record with Opportunity Owner.
        ShareHelper.shareAccountRelatedToOpportunity(newList, Constants.EDIT_ACCESS);

        Map<String,Contact> contactRecords = ContactService.getContactsByAccountId(accountsIds);
        
        for(Opportunity opportunityRecord : (list<Opportunity>)newList){
            if(opportunityRecord.recordtypeId != oppPIRecId){//Added this check For PI to exclude the name update by Himanshu@aldar.com
                if(contactRecords.get(opportunityRecord.AccountId) != null){
                    opportunityRecord.Contact__c = contactRecords.get(opportunityRecord.AccountId).Id;
                    opportunityRecord.Name = contactRecords.get(opportunityRecord.AccountId).Name + ' - ' + DateTime.now().format('yyyy-MM-dd h:mm:ss a');
                }
            }
        }

        //----- Check for duplicate Opportuity
        duplicateOpportuity(newList, accountsIds);
    }

     //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList,map<Id,SObject> newmap,list<SObject> oldlist,map<Id,SObject> oldmap) {
    List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
    Map<Id,List<SalesOrder__c>> salesOrderMap = new Map<Id,List<SalesOrder__c>>();
  //Get Resale RecordType Id
    Id resaleRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
  Set<Id> PIOpportunityIds = new Set<Id>();//PIOpportunityIds added by Himanshu@Aldar
        //List<ReceiptAcknowledgement__c> receiptAcknowledgementList = new List<ReceiptAcknowledgement__c>();
        set<String> retiredReasons = new set<String>{constants.OPPORTUNITY_LOST_INTEREST,
                                                    constants.OPPORTUNITY_LOST_COMPLETION_DATE,
                                                    constants.OPPORTUNITY_LOST_PROJECT_LOCATIONS,
                                                    constants.OPPORTUNITY_LOST_AVAILABILITY,
                                                    //constants.OPPORTUNITY_LOST_UNCONTACTABLE,
                                                    constants.OPPORTUNITY_LOST_FUTURE_POTENTIAL,
                                                    constants.OPPORTUNITY_LOST_UNIT_VIEW,
                                                    constants.OPPORTUNITY_LOST_PAYMENT_PLAN,
                                                    constants.OPPORTUNITY_LOST_PRICE
        };
        //Map<Opportunity,SalesOrder__c>
        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity opportunityRecord : (list<Opportunity>)newList){
            Opportunity opportunityOldRec = (Opportunity)oldmap.get(opportunityRecord.Id);
            opportunityIds.add(opportunityRecord.Id);
            //PIOpportunityIds added by Himanshu@Aldar 
            if (opportunityRecord.recordtypeId == oppPIRecId) {
                PIOpportunityIds.add(opportunityRecord.Id);
            }
            //ASF-3341 changes start here 
            if(resaleRecordTypeId == opportunityRecord.RecordTypeId && opportunityRecord.StageName == 'MOU Signature in progress' && opportunityOldRec.StageName != opportunityRecord.StageName){
                    opportunityRecord.BuyerComplianceStatus__c = 'Under Review';
            }
            //ASF-3341 changes end here 
        }
        salesOrderMap = SalesOrderService.getOpportunitySalesOrderMap(opportunityIds);
        System.debug('fab salesordermap:'+salesOrderMap);

        for(Opportunity opportunityRec : (List<Opportunity>)newList){
            Opportunity opportunityOldRec = (Opportunity)oldmap.get(opportunityRec.Id);
            if(opportunityRec.ReservationApprovalStatus__c != null &&  opportunityRec.ReservationApprovalStatus__c !=opportunityOldRec.ReservationApprovalStatus__c && opportunityRec.ReservationApprovalStatus__c.equals(Constants.STATUS_APPROVED)){
                //salesOrderList = salesOrderMap.get(opportunityRec.Id);//SalesOrderService.getSalesOrderByOpportunityId(opportunityRec.Id);
                System.debug('FAB Approval before if:'+opportunityRec+' '+salesOrderMap);
                if(salesOrderMap.ContainsKey(opportunityRec.Id)){
                    salesOrderList.addAll(salesOrderMap.get(opportunityRec.Id));
                    
                }
                System.debug('FAB Approval after if:'+salesOrderList);
            }/* Moving it to After trigger
else if(opportunityRec.ReservationApprovalStatus__c != null && opportunityRec.ReservationApprovalStatus__c !=opportunityOldRec.ReservationApprovalStatus__c && opportunityRec.ReservationApprovalStatus__c.equals(Constants.STATUS_REJECTED)){
salesOrderList = SalesOrderService.getSalesOrderByOpportunityId(opportunityRec.Id);
if(salesOrderList.size() > 0){
OpportunityUnitSearchController.expiredReservation(salesOrderList);
}
}*/
             //If Lead Status is Retired and matched one of the reasons then update the QualtricsIntegrationStatus__c
             if( opportunityRec.StageName!= opportunityOldRec.StageName && opportunityRec.StageName == Constants.STAGE_CLOSED_LOST &&  opportunityRec.LossReason__c!=null && retiredReasons.contains(opportunityRec.LossReason__c)){
                opportunityRec.QualtricsIntegrationStatus__c=Constants.QUALTRICS_IN_PROGRESS;
             }
            if(opportunityRec.Transferred__c &&  !opportunityOldRec.Transferred__c){
                opportunityRec.TransferredDate__c = system.today();
            }
            //Harsh@Aldar 25/08/2023 Adding Stage Timestamps -- Resale -- Offer Accepted Date
            if( opportunityRec.RecordTypeId == resaleRecordTypeId && 
               opportunityOldRec.StageName != ResaleConstants.OPP_STATUS_OFFER_ACCEPTED && 
               opportunityRec.StageName == ResaleConstants.OPP_STATUS_OFFER_ACCEPTED ){
                   
                   opportunityRec.OfferAcceptedDate__c = System.today();
               }
            //Harsh@Aldar 25/08/2023 Adding Stage Timestamps -- Resale -- MOU Signed Date
            // if( opportunityRec.RecordTypeId == resaleRecordTypeId && 
            //    opportunityOldRec.StageName == ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS && 
            //    opportunityRec.StageName == ResaleConstants.OPP_STATUS_PAY_PROGRESS ){
                   
            //        opportunityRec.MOUSignedDate__c = System.today();
            //    }
            //Harsh@Aldar 25/08/2023 Adding Stage Timestamps -- Resale -- Payment Cleared Date
            if( opportunityRec.RecordTypeId == resaleRecordTypeId && 
               opportunityOldRec.StageName != ResaleConstants.OPP_STATUS_PAYMENT_CLEARED && 
               opportunityRec.StageName == ResaleConstants.OPP_STATUS_PAYMENT_CLEARED ){
                   
                   opportunityRec.PaymentClearedDate__c = System.today();
            }
            if(opportunityRec.RecordTypeId == resaleRecordTypeId 
                && opportunityOldRec.StageName != ResaleConstants.OPP_STATUS_CLOSED_WON 
                && opportunityRec.StageName == ResaleConstants.OPP_STATUS_CLOSED_WON) {
                opportunityRec.MOUSignedDate__c = System.today();
            }
        }
        if(!salesOrderList.isEmpty()){
            for (SalesOrder__c salesOrder : salesOrderList) {
                if(salesOrder.Status__c!=null && salesOrder.Status__c.equals(Constants.STATUS_RESERVATION_IN_PROGRESS)){
                    salesOrder.SubStatus__c = Constants.STATUS_APPROVED;
                }
            }
            update salesOrderList;
        }
        //PaymentService.insertReceiptAcknowledgementRecords(receiptAcknowledgementList);
        
        //This is added by himanshu@aldar.com for P & I Opportunity
        System.debug('PIOpportunityIds'+JSON.serializePretty(PIOpportunityIds));
        if(!PIOpportunityIds.isEmpty()){
            for(Opportunity tempOpp : [SELECT Id,RecordTypeId,Approval_Status__c,
                                            (SELECT  Id, Status__c 
                                                FROM Opporutnity_actions_Reviews__r 
                                                WHERE Status__c =: PI_Services.OPPActionReviewStatus LIMIT 1 )  
                                        FROM Opportunity 
                                        WHERE Id IN :   PIOpportunityIds 
                                        AND RecordTypeId =: oppPIRecId ]){
                Opportunity newRec = (Opportunity)newmap.get(tempOpp.Id);
                Opportunity OldRec = (Opportunity)oldmap.get(tempOpp.Id);
                System.debug('tempOpp.RecordTypeId'+newRec.RecordTypeId);
                System.debug('tempOpp.Approval_Status__c'+newRec.Approval_Status__c);
                System.debug('OldRec.Approval_Status__c'+OldRec.Approval_Status__c);
                
                if(OldRec.Approval_Status__c == 'Validation in review'
                    && newRec.Approval_Status__c  == 'Validation approval in progress'){
                    
                    if (!tempOpp.Opporutnity_actions_Reviews__r.isEMpty()) {
                        System.debug('in check for hourykgnsmhknjygb'+OldRec.Approval_Status__c);
                        newRec.addError(Label.PI_OPP_ActionReview_PendingError);
                    } 
                }else if(OldRec.Approval_Status__c == 'Execution in review'
                        && newRec.Approval_Status__c  == 'Execution approval in progress'){
                
                    if (!tempOpp.Opporutnity_actions_Reviews__r.isEMpty()) {
                        System.debug('in check for hourykgnsmhknjygb'+OldRec.Approval_Status__c);
                        newRec.addError(Label.PI_OPP_ActionReview_PendingError);
                    } 
                }else if(OldRec.Approval_Status__c == 'Investment Monitoring in review'
                            && newRec.Approval_Status__c  == 'Investment Monitoring approval in progress'){
                    if (!tempOpp.Opporutnity_actions_Reviews__r.isEMpty()) {
                        System.debug('in check for hourykgnsmhknjygb'+OldRec.Approval_Status__c);
                        newRec.addError(Label.PI_OPP_ActionReview_PendingError);
                    } 
                }else if(OldRec.Approval_Status__c == 'Exit in review'
                        && newRec.Approval_Status__c  == 'Exit approval in progress'){
                    if (!tempOpp.Opporutnity_actions_Reviews__r.isEMpty()) {
                        System.debug('in check for hourykgnsmhknjygb'+OldRec.Approval_Status__c);
                        newRec.addError(Label.PI_OPP_ActionReview_PendingError);
                    } 
                }
            }
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
       //---- to share Opportunity record with Broker Manager.
       ShareHelper.shareOpportunityRecord(newList, Constants.READ_ACCESS);
        /* Added by Cloudzlab*/
        ECSS_OpportunityTriggerHelper.getNonLeasingCreatedOpportunityIds(newList);
        
           // ------------------- Leasing Opportunity Document Generation -------------------
       Id leasingRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ECSS_Leasing').getRecordTypeId();
        list<opportunity> opplist = (list<opportunity>) newList;
        for(Opportunity opp : opplist){
            if(leasingRecordTypeId != null && opp.recordTypeId == leasingRecordTypeId){
       createLeasingDocuments(newList);
            }
           
        }
      

    }
   
    
    // ------------------- Leasing Opportunity Document Generation -------------------
    // 
     //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //** Added by CloudzLab **//
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        for (SObject obj : oldMap.values()) {
            Opportunity opp = (Opportunity) obj;
            oppMap.put(opp.Id,opp);
        }
        ECSS_OpportunityTriggerHelper.UpdateLeasingAssetinSplit(newList,oppMap);
        ECSS_OpportunityTriggerHelper.publishOfferEvents(newList,oppMap);
        //---- to share Opportunity record with Broker Manager.
       // ShareHelper.shareOpportunityRecord(newList, Constants.READ_ACCESS);
        set<ID> qualtircsIDsToProcess = new set<ID>();
        set<ID> rejectedOptyIds = new set<ID>();
        // Harsh@Aldar / ASF-869
        //List<Opportunity> oppSOOCList = new List<Opportunity>();
        //ASF - 937
        
        List<Opportunity> validOppDocGenList = new List<Opportunity>();
        List<Account> accountList = new List<Account>();
        /* Added by Cloudzlab */
        List<Opportunity> ecssRoundRobinLease = new List<Opportunity>();
        String ECSSLabelRecordType = System.Label.ECSS_OpportunityRecordType;
        Id ecssLeaseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(ECSSLabelRecordType)
            .getRecordTypeId();
        /* End by Cloudzlab */
        
        //Get Resale RecordType Id
        Id resaleRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
        // ASF-1017
        List<Opportunity> resaleOppList_UnitChanged = new List<Opportunity>();
        List<Opportunity> oppListForcommissionsTobeCreated = new List<Opportunity>();
        //Payment Cleared Resale Opportunities
        List<Opportunity> oppList_PaymentCleared = new List<Opportunity>();
        //Unit Update List
        List<Unit__c> unitUpdateList = new List<Unit__c>();
        // Closed Won Resale Opportunities
        List<Opportunity> closedWonResaleOpps = new List<Opportunity>();
           //PI PoortunityList to create doc placeholders Added by Himanshu@aldar.com for P & I Opportunity
        List<Opportunity> oppList_PandI = new List<Opportunity>();
        for(Opportunity tempOpp : (list<Opportunity>) newList){
            Opportunity OldRec = (Opportunity)oldmap.get(tempOpp.Id);
            
            
            /*Added by cloudzlab */
           if(OldRec.RecordTypeId != tempOpp.RecordTypeId &&  tempOpp.RecordTypeId == ecssLeaseRecordTypeId){
                ecssRoundRobinLease.add(tempOpp);
            }
            
            if (tempOpp.RecordTypeId == oppPIRecId) {
                
                oppList_PandI = evaluatePIApprovalStatus(tempOpp,oldRec,oppPIRecId);
                
                continue;
            }
            /* End by Cloudzlab */            
            //This is added by himanshu@aldar.com for P & I Opportunity
            /*  if (tempOpp.RecordTypeId == oppPIRecId ) {
System.debug('tempOpp.RecordTypeId'+tempOpp.RecordTypeId);
System.debug('tempOpp.Approval_Status__c'+tempOpp.Approval_Status__c);
System.debug('OldRec.Approval_Status__c'+OldRec.Approval_Status__c);
if(OldRec.Approval_Status__c == 'Validation approval in progress'
&& tempOpp.Approval_Status__c  == 'Validation approved'){
oppList_PandI.add(tempOpp);
}else if(OldRec.Approval_Status__c == 'Execution approval in progress'
&& tempOpp.Approval_Status__c  == 'Execution Approved'){
oppList_PandI.add(tempOpp);
}else if(OldRec.Approval_Status__c == 'Investment Monitoring approval in progress'
&& tempOpp.Approval_Status__c  == 'Investment Monitoring Approved'){
oppList_PandI.add(tempOpp);
}
continue;
}*/
            //Harsh@Aldar 25/08 Updating Unit Resale Status values on Opp stage change
           // Unit__c thisUnit = new Unit__c();

            //When Stage is updated to Offer Accepted
            if(tempOpp.RecordTypeId == resaleRecordTypeId && OldRec.StageName != ResaleConstants.OPP_STATUS_OFFER_ACCEPTED && tempOpp.StageName == ResaleConstants.OPP_STATUS_OFFER_ACCEPTED && tempOpp.Unit__c != null){
                // thisUnit.ResaleStatus__c = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED;
                Unit__c thisUnit = new Unit__c(
                    Id = tempOpp.Unit__c,
                    ResaleStatus__c = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED
                );
                unitUpdateList.add(thisUnit);
            }
            
            //ASF-937 Harsh@Aldar -- Generate Document Placeholders once LM Approves
            if(tempOpp.RecordTypeId == resaleRecordTypeId && OldRec.StageName != ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS && tempOpp.StageName == ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS ){
                //oppSOOCList.add(tempOpp);
                validOppDocGenList.add(tempOpp);
            }
            // if( tempOpp.RecordTypeId == resaleRecordTypeId && 
            //     OldRec.StageName == ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS && 
            //     tempOpp.StageName == ResaleConstants.OPP_STATUS_PAY_PROGRESS ){
            //     thisUnit.ResaleStatus__c = ResaleConstants.UNIT_RESALESTATUS_MOU_SIGNED;
            //     thisUnit.MOU_Signed__c = true;
            // }
            //ASF-1017 Harsh@Aldar -- If Unit on Resale Opp is updated, Update the corresponding Sales Order too 
            if(tempOpp.RecordTypeId == resaleRecordTypeId && tempOpp.Unit__c != null && tempOpp.Unit__c != OldRec.Unit__c){
                resaleOppList_UnitChanged.add(tempOpp);
            }
            //harsh@aldar 17/08 -- Once Payment is Cleared, Disqualify other offers under this Opportunity
            // if(tempOpp.RecordTypeId == resaleRecordTypeId && OldRec.StageName != ResaleConstants.OPP_STATUS_PAYMENT_CLEARED && tempOpp.StageName == ResaleConstants.OPP_STATUS_PAYMENT_CLEARED ){
            //     oppList_PaymentCleared.add(tempOpp);
            //     thisUnit.ResaleStatus__c = ResaleConstants.OPP_STATUS_PAYMENT_CLEARED;
            // }
            // yenshul@aldar
            if(tempOpp.RecordTypeId == resaleRecordTypeId 
                && OldRec.StageName != ResaleConstants.OPP_STATUS_CLOSED_WON 
                && tempOpp.StageName == ResaleConstants.OPP_STATUS_CLOSED_WON){
                closedWonResaleOpps.add(tempOpp);
            }
            if(tempOpp.QualtricsIntegrationStatus__c==Constants.QUALTRICS_IN_PROGRESS){
              //  qualtircsIDsToProcess.add(tempOpp.Id);
            }
            if(tempOpp.ReservationApprovalStatus__c != null && tempOpp.ReservationApprovalStatus__c !=OldRec.ReservationApprovalStatus__c && tempOpp.ReservationApprovalStatus__c.equals(Constants.STATUS_REJECTED)){
                rejectedOptyIds.add(tempOpp.Id);
            }
            
            if(tempOpp.StageName == constants.STAGE_CLOSEDWON  && tempOpp.BrokerAgencyAccount__c != null)
            {
                Account accountRec = new Account();
                accountRec.Id = tempOpp.BrokerAgencyAccount__c;
                accountRec.LastSalesOrderClosureDate__c = Date.today();
                accountList.add(accountRec);
            }
            if(tempOpp.Transferred__c != OldRec.Transferred__c && tempOpp.Transferred__c ){
                oppListForcommissionsTobeCreated.add(tempOpp);
            }
            
            /*if(tempOpp.Unit__c != null){
                thisUnit.Id = tempOpp.Unit__c;
                unitUpdateList.add(thisUnit);
            }*/
        }
        //Added by Himanshu@aldar.com for P & I Opportunity
        System.debug('oppList_PandI>>'+JSON.serializePretty(oppList_PandI));
        if (!oppList_PandI.isEmpty()) {
            PI_Services.createDocumentForOpportunity(oppList_PandI);   
        }
        if(!oppListForcommissionsTobeCreated.isEmpty()){
           createCommissionLineItemsOnTransfer(oppListForcommissionsTobeCreated);
        }
        //RESALE ITEMS ROLLBACK STARTS
        Savepoint savepoint = Database.setSavepoint();
        
        //// ASF-943/975 Harsh@Aldar -- Create Sales Order Other Charges and related records
        try{
            //if(oppSOOCList.size() > 0){
                 //ResaleUnitService.createResaleCharges(oppSOOCList);
            //}
            //ASF-937 Harsh@Aldar -- Generate Document Placeholders once LM Approves
            if(validOppDocGenList.size() > 0){
                ResaleUnitService.createResaleMOUDocuments(validOppDocGenList);
            }
            //ASF-1017 Harsh@Aldar -- If Unit on Resale Opp is updated, Update the corresponding Sales Order too
            if(resaleOppList_UnitChanged.size() > 0){                ResaleUnitService.handleResaleUnitChange(resaleOppList_UnitChanged);
            }
            //Disqualify other offers once payment is cleared
            if(oppList_PaymentCleared.size() > 0){                ResaleUnitService.disqualifyOtherOffers(oppList_PaymentCleared);
            }
            
            if(unitUpdateList.size() > 0){                ResaleComponentService.updateUnitWithoutSharing(unitUpdateList);
            }
            if(closedWonResaleOpps.size() > 0){
                ResaleUnitService.createPTCaseForResaleOpps(closedWonResaleOpps);
                ResaleUnitService.disqualifyOtherOffers(closedWonResaleOpps);
            }
        } catch (Exception e) {
            // Rollback the transaction
            System.debug('####error : '+e.getMessage());
            Database.rollback(savepoint);
        }
        //RESALE ITEMS ROLLBACK ENDS
        if(!rejectedOptyIds.isEmpty()){
            list<SalesOrder__c>salesOrderList = SalesOrderService.getSalesOrderByOpportunityIdSet(rejectedOptyIds);
            if(!salesOrderList.isEmpty()){
                OpportunityUnitSearchController.expiredReservation(salesOrderList);
            }
        }
        
        if(!qualtircsIDsToProcess.isEmpty()){
            //            System.enqueueJob(new Qualtrics.QualtricsIntegration(qualtircsIDsToProcess));
        }
        
        if(accountList.size() > 0)
            UtilitiesWithoutSharing.updateLastsalesOrderDate(accountList);
        /* Added by Cloudzlab */
        ECSS_OpportunityTriggerHelper.getNonLeasingCreatedOpportunityIds(ecssRoundRobinLease);
        /* End by Cloudzlab */
    }
    public static void duplicateOpportuity(List<SObject> newList, Set<Id> accountsIds){

        //----- get all Opportunity related to the accountIds
        Map<Id,Opportunity> opportunityRelatedToAccountsIds = UtilitiesWithoutSharing.getAllOpportunitysByAccountsIds(accountsIds);

        //---- Check for Duplicate Opportunity
        for(Opportunity oppRec : (list<Opportunity>)newList){
            if(opportunityRelatedToAccountsIds !=null && opportunityRelatedToAccountsIds.containsKey(oppRec.AccountId)){
                //---- Get the existing Opportunity and populate Existing Opportunity Field
                Opportunity existingOpportunity = opportunityRelatedToAccountsIds.get(oppRec.AccountId);
                
                //Added By Cloudzlab
                //Start of Changes
                 //if(existingOpportunity.Project__c == oppRec.Project__c && existingOpportunity.Offer__c == oppRec.Offer__c){
                if(!oppRec.ECSS_RecordType_DevName__c.contains('ECSS')){
                    oppRec.ExistingOpportunity__c = existingOpportunity.Id;
                    oppRec.ExistingOpportunityOwnerId__c = existingOpportunity.OwnerId;
                }
                //}
                //End of Changes
            }
        }
    }
    
    public static void createCommissionLineItemsOnTransfer(List<Opportunity> commissionsTobeCreated){
        Integer buyerCommissionPot = Integer.valueOf(System.label.BuyerCommissionPot); 
        Integer SellerCommissionPot = Integer.valueOf(System.label.SellerCommissionPot);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(commissionsTobeCreated);
        Map<Id, Opportunity> unitOppMap = new Map<Id, Opportunity>();
        Map<Id, Map<String, Id>> unitUserMap = new Map<Id, Map<String, Id>>();
        Id caseResaleRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Resale Case').getRecordTypeId();
        List<CommissionLineItem__c> commissionLineItemList = new List<CommissionLineItem__c>();
        
        for(Opportunity opportunity: commissionsTobeCreated){
            unitOppMap.put(opportunity.Unit__c, opportunity);
        }
        List<Case> caseList = [SELECT
                               Id,
                               OwnerId,
                               ReferredBy__c,
                               Unit__c
                               FROM Case
                               WHERE Unit__c in: unitOppMap.keySet()
                               AND RecordTypeId =: caseResaleRecordTypeId 
                               ORDER BY createddate DESC];
        
        for(Case cs: caseList){
            Map<String, Id> usertypeMap = new Map<String, Id>();
            if(cs.OwnerId != null){
                usertypeMap.put('Seller RM', cs.OwnerId);
            }
            if(cs.ReferredBy__c != null){                usertypeMap.put('Seller Referreal RM', cs.ReferredBy__c);
            }
            unitUserMap.put(cs.Unit__c,  usertypeMap);
        }
        system.debug('unitUserMap::'+unitUserMap);
        for(Opportunity opportunity: commissionsTobeCreated){
            system.debug('=== AA '+opportunity.Buyer_Service_Charge_fx__c);
            system.debug('=== AA '+opportunity.stagename);
            system.debug('=== AA '+buyerCommissionPot);
            system.debug('=== AA '+buyerCommissionPot);
     
            Decimal buyerPayableCommission = ((opportunity.Buyer_Service_Charge_fx__c * buyerCommissionPot)/100);
            Decimal sellerPayableCommission = ((opportunity.Seller_Service_Charge_fx__c * SellerCommissionPot)/100);
            Decimal buyerPayableCommissionPot = ((buyerPayableCommission * Integer.valueOf(System.label.BuyerRMCommissionPot))/100) ;
            Decimal sellerPayableCommissionPot = ((sellerPayableCommission * Integer.valueOf(System.label.SellerRMCommissionPot))/100);
            if(opportunity.ReferredBy__c != null){
                Decimal commissionAmount = ((buyerPayableCommissionPot* Integer.valueOf(System.label.BuyerRMReferralCommissionPot))/100);
                commissionLineItemList.add(createCommissionLineItems(opportunity.ReferredBy__c, commissionAmount, opportunity.SalesOrder__c, 'Buyer referral'));
            }
            if(opportunity.OwnerId != null){
                system.debug('opportunity.OwnerId::'+opportunity.OwnerId);
                system.debug('opportunity.Project__c::'+opportunity.Project__c);
                system.debug('opportunity.SalesOrder__c::'+opportunity.SalesOrder__c);
                Decimal commissionAmount = opportunity.ReferredBy__c != null ? ((buyerPayableCommissionPot*Integer.valueOf(System.label.BuyerRMReferralCommissionPot))/100) : (buyerPayableCommissionPot);
                    commissionLineItemList.add(createCommissionLineItems(opportunity.OwnerId, commissionAmount, opportunity.SalesOrder__c, 'Buyer'));
            }
            if(unitUserMap.containsKey(opportunity.Unit__c)){
                Map<String, Id> usertypeMap = unitUserMap.get(opportunity.Unit__c);
                system.debug('usertypeMap::'+usertypeMap);
                Integer SellerRMReferralCommissionPotForRM = (100 - Integer.valueOf(System.label.SellerRMReferralCommissionPot));
                if (usertypeMap.get('Seller Referreal RM') != null){
                    Decimal commissionAmount = ((sellerPayableCommissionPot* Integer.valueOf(System.label.SellerRMReferralCommissionPot))/100); 
                    commissionLineItemList.add(createCommissionLineItems(usertypeMap.get('Seller Referreal RM'),  commissionAmount, opportunity.SalesOrder__c, 'Seller referral'));
                }
                if(!Test.isRunningTest()){
                    if(usertypeMap.get('Seller RM') != null){
                        Decimal commissionAmount = usertypeMap.get('Seller Referreal RM') != null ? ((sellerPayableCommissionPot*SellerRMReferralCommissionPotForRM)/100) : sellerPayableCommissionPot; 
                        commissionLineItemList.add(createCommissionLineItems(usertypeMap.get('Seller RM'), commissionAmount, opportunity.SalesOrder__c, 'Seller'));
                    }
                }
            }
            
        }
        if(!commissionLineItemList.isEmpty()){
            insert commissionLineItemList;
        }
        
    }    
    
    public static void createLeasingDocuments(List<Opportunity> oppList){
        
        List<Document__c> documentListToInsert = new List<Document__c>();
        
        Map<String, Id> documentRecordTypeMap = new Map<String,Id>();
        
        Map<Id, Opportunity> oppIdToRecMap = new  Map<Id, Opportunity>(oppList);
        
        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{'Leasing Opportunity'});
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
                String documentTypeToProcess = 'Leasing Opportunity'; 
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    /* String recordTypeID = null;
if(tempMetaRec.RecordTypeDeveloperName__c != null ){
if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
}
recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
} */
                    
                    //existing check
                    if(!existingDocMap.containsKey(actRec.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                                    Opportunity__c = actRec.Id,
                                                                    OwnerId = actRec.OwnerId,
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

    
    public static CommissionLineItem__c createCommissionLineItems(Id SalesManager, Decimal commissionAmount, Id SalesOrderId, String resaleJourneyType){
        CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
        commissionLineItem.SalesManager__c = SalesManager;
        commissionLineItem.CommissionType__c = 'Internal';
        commissionLineItem.CommissionAmount__c = commissionAmount;
        commissionLineItem.SalesOrder__c = SalesOrderId;
        commissionLineItem.CommissionPercentage__c = 0;
        commissionLineItem.ReSaleJourneyType__c = resaleJourneyType;
        return commissionLineItem;
    }
    public static List<Opportunity> evaluatePIApprovalStatus(
    Opportunity newRec,
    Opportunity oldRec,
    Id oppPIRecId
        
    ) {
        List<Opportunity> result = new List<Opportunity>();
        if (newRec == null || oldRec == null) return result;
        if (newRec.RecordTypeId != oppPIRecId) return result;
        
        if (oldRec.Approval_Status__c == 'Validation approval in progress'
            && newRec.Approval_Status__c == 'Validation approved') {
                
                result.add(newRec);
                
            } else if (oldRec.Approval_Status__c == 'Execution approval in progress'
                       && newRec.Approval_Status__c == 'Execution Approved') {
                           
                           result.add(newRec);
                           
                       } else if (oldRec.Approval_Status__c == 'Investment Monitoring approval in progress'
                                  && newRec.Approval_Status__c == 'Investment Monitoring Approved') {
                                      
                                      result.add(newRec);
                                  }
        return result;
}
    
}