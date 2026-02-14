public with sharing class BookingMemoTriggerHandler extends TriggerHandler{
   //*** After Update Action***//
   public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<OffersPromotions__c> offersPromotionsList = new List<OffersPromotions__c>();

        List<MemoLines__c> memoLinesList = new List<MemoLines__c>();
        Set<String> unitsList = new Set<String>();


        String lastCreatedOffersPromotionsId;
        List<PaymentPlan__c> paymentPlanList = new List<PaymentPlan__c>();

        List<InstallmentLineChanges__c> installmentLineChangesList = new List<InstallmentLineChanges__c>();
        String lastCreatedPaymentPlanId;
        list<ID> rejectedMemoIds = new list<ID>();

        List<BookingMemo__c> approvedBookingMemo =new List<BookingMemo__c>();

        for(BookingMemo__c bookingMemoRec : (List<BookingMemo__c>)newList){
            BookingMemo__c oldMemoRecord = (BookingMemo__c)oldMap.get(bookingMemoRec.id);
            

            if( oldMemoRecord.ApprovalStatus__c != bookingMemoRec.ApprovalStatus__c && bookingMemoRec.ApprovalStatus__c.equals(Constants.STATUS_APPROVED)){
                approvedBookingMemo.add(bookingMemoRec);
            }


            memoLinesList = MemoLinesService.getMemoLinesByBookinMemoId(bookingMemoRec.Id);
            
            if(bookingMemoRec.ApprovalProgress__c != null &&  oldMemoRecord.ApprovalProgress__c != bookingMemoRec.ApprovalProgress__c && bookingMemoRec.ApprovalProgress__c.equals(Constants.APPROVAL_PROGRESS_APPROVED)){
                if(memoLinesList.size() > 0){
                    UnitShareService.unitApprovedByLineManager(memoLinesList,bookingMemoRec.OwnerId);
                }
            }

            /*if( oldMemoRecord.ApprovalStatus__c != bookingMemoRec.ApprovalStatus__c && bookingMemoRec.ApprovalStatus__c.equals(Constants.STATUS_APPROVED)){
                
                
                if(memoLinesList.size() > 0){

                    UnitService.unitBookingMemoApproved(memoLinesList,bookingMemoRec.OwnerId);

                    for (MemoLines__c memoLine : memoLinesList) {
                        OffersPromotions__c offersPromotionsRecord = new OffersPromotions__c();
                        offersPromotionsRecord.BookingMemo__c = bookingMemoRec.Id;
                        offersPromotionsRecord.Name = 'Memo Offer & Promotion - ' + bookingMemoRec.Name;
                        offersPromotionsRecord.OfferName__c = 'Offer Booking Memo Raised by ' + loggedinUser.Name;
                        offersPromotionsRecord.Project__c = memoLine.Unit__r.Project__c;
                        offersPromotionsRecord.Unit__c = memoLine.Unit__c;
                        offersPromotionsRecord.SalesEventCampaignName__c = 'Memo';
                        offersPromotionsRecord.StartDate__c = system.today();
                        offersPromotionsRecord.EndDate__c = system.today().addDays(timerDetails);
                        offersPromotionsList.add(offersPromotionsRecord);
                    }

                    OffersPromotionsService.insertOffersPromotions(offersPromotionsList);
                
               

                    //lastCreatedOffersPromotionsId = OffersPromotionsService.lastCreatedIdOffersPromotions();

                    OfferLinesService.insertOfferLines(memoLinesList, lastCreatedOffersPromotionsId);
                }

                installmentLineChangesList = InstallmentLineChangesService.getInstallmentLineChangesByBookinMemoId(bookingMemoRec.Id);
                if(installmentLineChangesList.size() > 0){
                    
                    for (MemoLines__c memoLine : memoLinesList) {
                        PaymentPlan__c paymentPlanRecord = new PaymentPlan__c();
                        paymentPlanRecord.Name = 'Memo Payment Plan - ' + bookingMemoRec.Name;
                        paymentPlanRecord.Description__c = bookingMemoRec.MemoSubject__c;
                        paymentPlanRecord.Unit__c = memoLine.Unit__c;
                        paymentPlanRecord.PaymentPlanType__c = 'Special';
                        paymentPlanRecord.IsActive__c = 'Yes';
                        paymentPlanRecord.StandardFlag__c = 'No';
                        paymentPlanRecord.Premium__c = 0;
                        paymentPlanRecord.PaymentPlanDiscount__c = 0;
                        paymentPlanRecord.BookingMemo__c = bookingMemoRec.Id;
                        paymentPlanRecord.Classification__c = 'MEMO';
                        paymentPlanList.add(paymentPlanRecord);
                        unitsList.add(memoLine.Unit__c);
                    }
                    PaymentPlanService.insertPaymentPlan(paymentPlanList);
                }
                
            }*/else if(oldMemoRecord.ApprovalStatus__c != bookingMemoRec.ApprovalStatus__c && bookingMemoRec.ApprovalStatus__c.equals(Constants.STATUS_REJECTED)){
                rejectedMemoIds.add(bookingMemoRec.Id);
            }
        }
        /*if(installmentLineChangesList.size() > 0){
            PaymentInstallmentsService.insertPaymentInstallments(installmentLineChangesList);
            BuildingSectionMappingService.insertBuildingSectionMapping(installmentLineChangesList);
            //UnitService.cancelUnitReservation(unitsList);
        }*/
        if(!rejectedMemoIds.isEmpty()){
            releaseUnits(rejectedMemoIds);
        }
        if(!approvedBookingMemo.isEmpty()){
            handleApprovedMemo(approvedBookingMemo);
        }
    }
    public static void handleApprovedMemo(List<BookingMemo__c> approvedBookingMemo){
        User loggedinUser = Utilities.getLoggedInUserDetail();
        Integer timerDetails = Integer.valueOf(Utilities.getTimer('Memo').Timer__c);
        Map<String,OfferLinesService__mdt> OfferLineServiceMap = Utilities.getOfferLineService();
        //get the related Unit and Block it
        map<id,BookingMemo__c> bookingMemoRecordMap = new  map<id,BookingMemo__c>(approvedBookingMemo);
        List<MemoLines__c> memolines = [select Id,Unit__c,Unit__r.Project__c,Unit__r.Status__c,SCWaiverYears__c,PMFeeYears__c,HomeMaintenanceYears__c,VoucherAmount__c,VoucherName__c,
                                    AdditionalDiscountPercentage__c,BrokerCommissionPercentage__c,ADMFeePercentage__c,BookingMemo__c,MembershipAmount__c,MembershipType__c,
                                    IntCommissionPercentage__c,RebatePercentage__c,SubsidyPercentage__c,DiscountPercentage__c from MemoLines__c where BookingMemo__c = :bookingMemoRecordMap.keySet()];
        
        list<Unit__c> unitsToUpdate = new list<Unit__c>();
        map<id,OffersPromotions__c> unitToOffersPromotions = new map<id,OffersPromotions__c>();
        map<id,list<OfferLines__c>> unitToOffersLines = new map<id,list<OfferLines__c>>();
        set<ID> unitsToProcess = new set<ID>();
        map<id,OfferLines__c> voucherAndMembersipRecords = new map<id,OfferLines__c>();
        for(MemoLines__c mlRec : memolines){
            
            if(mlRec.Unit__r.Status__c == Constants.UNIT_STATUS_BLOCKED) {
                unitsToUpdate.add(new Unit__c( Id = mlRec.Unit__c,Status__c = Constants.UNIT_STATUS_AVAILABLE,AllocationGroup__c = null,AssignedToUser__c = bookingMemoRecordMap.get(mlRec.BookingMemo__c).ownerId ));
            }
            //Create offer Header
            OffersPromotions__c offersPromotionsRecord = new OffersPromotions__c();
            offersPromotionsRecord.BookingMemo__c = mlRec.BookingMemo__c;
            offersPromotionsRecord.Name = 'Memo Offer & Promotion - ' + bookingMemoRecordMap.get(mlRec.BookingMemo__c).Name;
            offersPromotionsRecord.OfferName__c = 'Offer Booking Memo Raised by ' + loggedinUser.Name;
            offersPromotionsRecord.Project__c = mlRec.Unit__r.Project__c;
            offersPromotionsRecord.Unit__c = mlRec.Unit__c;
            offersPromotionsRecord.SalesEventCampaignName__c = 'Memo';
            offersPromotionsRecord.StartDate__c = system.today();
            offersPromotionsRecord.EndDate__c = system.today().addDays(timerDetails);
            unitToOffersPromotions.put(mlRec.Unit__c , offersPromotionsRecord);

            if(!unitToOffersLines.containsKey(mlRec.Unit__c)){
                unitToOffersLines.put(mlRec.Unit__c,new list<OfferLines__c>());
            }
            //Creste Offer Lines
            if (mlRec.DiscountPercentage__c > 0) {
                system.debug(OfferLineServiceMap.get('DiscountPercentage__c'));
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'DiscountPercentage__c',null,OfferLineServiceMap ));
            }
            if (mlRec.SCWaiverYears__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'SCWaiverYears__c',null,OfferLineServiceMap ));
              }
              if (mlRec.HomeMaintenanceYears__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'HomeMaintenanceYears__c',null,OfferLineServiceMap ));
              }
              if (mlRec.PMFeeYears__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'PMFeeYears__c',null,OfferLineServiceMap ));
              }
              if (mlRec.BrokerCommissionPercentage__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'BrokerCommissionPercentage__c',null,OfferLineServiceMap ));
              }
              if (mlRec.ADMFeePercentage__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'ADMFeePercentage__c',null,OfferLineServiceMap ));
              }
              if (mlRec.SubsidyPercentage__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'SubsidyPercentage__c',null,OfferLineServiceMap ));
              }
              if (mlRec.RebatePercentage__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'RebatePercentage__c',null,OfferLineServiceMap ));
              }
              if (mlRec.IntCommissionPercentage__c > 0) {
                unitToOffersLines.get(mlRec.Unit__c).add(OfferLinesService.getOfferLinesService(mlRec,'IntCommissionPercentage__c',null,OfferLineServiceMap ));
              }
              if(mlRec.VoucherAmount__c > 0 && mlRec.VoucherName__c!=null){
                voucherAndMembersipRecords.put(mlRec.VoucherName__c,null);
                unitToOffersLines.get(mlRec.Unit__c).add(new OfferLines__c(Unit__c= mlRec.Unit__c, OfferValue__c = mlRec.VoucherAmount__c, OfferName__c = mlRec.VoucherName__c));
              }
              if(mlRec.MembershipAmount__c > 0 && mlRec.MembershipType__c !=null){
                voucherAndMembersipRecords.put(mlRec.MembershipType__c,null);
                unitToOffersLines.get(mlRec.Unit__c).add(new OfferLines__c(Unit__c= mlRec.Unit__c , OfferValue__c = mlRec.MembershipAmount__c, OfferName__c = mlRec.MembershipType__c));
              }
            
            
        }
        for(OfferLines__c tempOff : [select id,Description__c,VoucherName__c,OfferType__c,DiscountType__c,OfferOn__c,OfferValue__c,OfferValueType__c,Unit__c,Nationality__c,BudgetTaskName__c from OfferLines__c where id in :voucherAndMembersipRecords.keySet()]){
            voucherAndMembersipRecords.put(tempOff.Id,tempOff);
        }
        if(!unitsToUpdate.isEmpty()){
            update unitsToUpdate;
        }
        if(!unitToOffersPromotions.isEmpty()){
            insert unitToOffersPromotions.values();
            list<OfferLines__c> offerLinesToCreate = new list<OfferLines__c>();
            for(ID uId : unitToOffersPromotions.keySet()){
                for(OfferLines__c pro : unitToOffersLines.get(uId)){
                        //If value is not set that means its voucher
                        if(pro.OfferType__c==null && pro.BudgetTaskName__c==null && voucherAndMembersipRecords.containskey(pro.OfferName__c)){
                            
                            pro.OfferType__c = voucherAndMembersipRecords.get(pro.OfferName__c).OfferType__c;
                            pro.DiscountType__c = voucherAndMembersipRecords.get(pro.OfferName__c).DiscountType__c;
                            pro.OfferOn__c = voucherAndMembersipRecords.get(pro.OfferName__c).OfferOn__c;
                            pro.VoucherName__c = voucherAndMembersipRecords.get(pro.OfferName__c).VoucherName__c;
                            pro.Description__c = voucherAndMembersipRecords.get(pro.OfferName__c).Description__c;
                            pro.OfferValueType__c = voucherAndMembersipRecords.get(pro.OfferName__c).OfferValueType__c;
                            pro.Nationality__c=null;
                            pro.BudgetTaskName__c = voucherAndMembersipRecords.get(pro.OfferName__c).BudgetTaskName__c;
                            system.debug(pro);
                            system.debug(pro.OfferName__c);
                            system.debug(pro.OfferValueType__c);
                        }
                        pro.OfferName__c = unitToOffersPromotions.get(uId).Id;
                        offerLinesToCreate.add(pro);
                }
                
            }
            if(!offerLinesToCreate.isEmpty()){
                insert offerLinesToCreate;
            }
        }
        
        map<id,PaymentPlan__c> unitToPaymentPlansToCreate = new map<id,PaymentPlan__c>();
        map<id,BuildingSectionMapping__c> unitToBuildingSection = new map<id,BuildingSectionMapping__c>();

        map<id,list<PaymentInstallments__c>> unitToInstallmentLinesToCreate = new map<id,list<PaymentInstallments__c>>();
        for(InstallmentLineChanges__c ilc : [select Id,BrokerPayoutPercentage__c,ProposedInstallmentPercentage__c,PaymentPlan__c,ProposedInstallmentDate__c,Description__c,InstallmentNumber__c,BookingMemo__c,Unit__c,Unit__r.BuildingSectionName__c from InstallmentLineChanges__c where BookingMemo__c = :bookingMemoRecordMap.keySet()]){
            if(!unitToPaymentPlansToCreate.containsKey(ilc.Unit__c)){
                unitToBuildingSection.put(ilc.Unit__c, new BuildingSectionMapping__c( BuildingSectionName__c = ilc.Unit__r.BuildingSectionName__c));
                unitToPaymentPlansToCreate.put(ilc.Unit__c, new PaymentPlan__c( Name = 'Memo Payment Plan - ' + bookingMemoRecordMap.get(ilc.BookingMemo__c).Name,
                                                Description__c =  bookingMemoRecordMap.get(ilc.BookingMemo__c).MemoSubject__c,
                                                Unit__c = ilc.Unit__c,
                                                PaymentPlanType__c = 'Special',
                                                IsActive__c = 'Yes',
                                                StandardFlag__c = 'No',
                                                Premium__c = 0,
                                                PaymentPlanDiscount__c = 0,
                                                BookingMemo__c = ilc.BookingMemo__c,
                                                Classification__c = 'MEMO') );
            }
            if(!unitToInstallmentLinesToCreate.containsKey(ilc.Unit__c)){
                unitToInstallmentLinesToCreate.put(ilc.Unit__c, new list<PaymentInstallments__c>());
            }
            unitToInstallmentLinesToCreate.get(ilc.Unit__c).add(new PaymentInstallments__c( InstallmentNumber__c = ilc.InstallmentNumber__c,
                                                        InstallmentPercentage__c = ilc.ProposedInstallmentPercentage__c,
                                                        InstallmentDate__c = ilc.ProposedInstallmentDate__c,
                                                        Description__c = ilc.Description__c,
                                                        BrokerPayoutPercentage__c = ilc.BrokerPayoutPercentage__c));
        }
        if(!unitToPaymentPlansToCreate.isEmpty()){
            insert unitToPaymentPlansToCreate.values();
            list<PaymentInstallments__c> installmentLinesToCreate = new list<PaymentInstallments__c>();
            for(ID uId : unitToPaymentPlansToCreate.keySet()){
                if(unitToInstallmentLinesToCreate.containsKey(uId) && !unitToInstallmentLinesToCreate.get(uId).isEmpty()){
                    for(PaymentInstallments__c pr : unitToInstallmentLinesToCreate.get(uId)){
                        pr.PaymentPlan__c = unitToPaymentPlansToCreate.get(uId).Id;
                        installmentLinesToCreate.add(pr);
                    }
                }
                unitToBuildingSection.get(uid).PaymentPlan__c=unitToPaymentPlansToCreate.get(uId).Id;
            }
            if(!installmentLinesToCreate.isEmpty()){
                insert installmentLinesToCreate;
            }
            if(!unitToBuildingSection.isEmpty()){
                insert unitToBuildingSection.values();
            }
        }
    
    }


    public static void releaseUnits(list<ID> bookingMemoIds){
        set<id> unitIdsToRelease = new set<id>();
        for(MemoLines__c lineItem : [select id,Unit__c from MemoLines__c where BookingMemo__c in :bookingMemoIds]){
            unitIdsToRelease.add(lineItem.Unit__c);
        }
        //get the units
        list<unit__c> unitsToRelease = new list<unit__c>();
        for(Unit__c unitRec : [select id,Status__c from Unit__c where id in :unitIdsToRelease and Status__c = :Constants.UNIT_STATUS_BLOCKED]){
            unitRec.Status__c = Constants.UNIT_STATUS_AVAILABLE;
            unitsToRelease.add(unitRec);
        }
        if(!unitsToRelease.isEmpty()){
            update unitsToRelease;
        }
        
    }
}