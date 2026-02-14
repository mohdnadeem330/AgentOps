@RestResource (urlMapping = '/query/paymentplansofferdetail')
global with sharing class PaymentPlansOffersDetailWebService {
    // swimming pool related changes for yas riva, added swimming pool selection paramater
    @HttpPost
    global static void doPost(Id opportunityId, Id selectedUnit, Id paymentPlanId, Id offerId,String PODSelection,String SwimmingPoolSelection,Boolean multipurposeRoom, List<Id> allUnitIds,List<Id> paymentPlanIds,Id designTypeId,Boolean digitalSales) {  //DIGITAL SALES CHIRAG 
        
        RestContextHandler handler = new RestContextHandler(false);
         
        //try {  
            UnitPaymentOfferModel response = new UnitPaymentOfferModel();

            Map<Id,Id> unitIdToOffer = new Map<Id,Id>();
            Map<Id,Boolean> unitToMultiPurposeAmountApplicableMap = new Map<Id,Boolean>();
            Map<Id,Id> unitToDesignTypeMap = new Map<Id,Id>();
            Map<Id,set<Id>> unitToSelectedPaymentPlanMap = new Map<Id,set<Id>>();
            map<Id,string> unitToPodiumSelectedMap = new map<id,string>();
            Set<Id> paymentPlanIdSet = new Set<Id>();
            // swimming pool related changes for yas riva
            map<Id,string> unitToSwimmingPoolSelectedMap = new map<Id,string>();
            map<Id, String> unitSignaturetypemap = new map<Id, String>();
            
            for(Id unitId : allUnitIds){
                unitIdToOffer.put(unitId,null);
                unitToSelectedPaymentPlanMap.put(unitId,new set<Id>());
                unitToMultiPurposeAmountApplicableMap.put(unitId,false);
                unitToPodiumSelectedMap.put(unitId,'none');
                unitToSwimmingPoolSelectedMap.put(unitId,'none');
                unitSignaturetypemap.put(unitId, null);
            }
            system.debug('unitToPodiumSelectedMap' + unitToPodiumSelectedMap);
            if(offerId!=null){
                unitIdToOffer.put(selectedUnit,offerId);
            }

            if(paymentPlanIds!=null && paymentPlanIds.size()>0){
                unitToSelectedPaymentPlanMap.get(selectedUnit).addAll(paymentPlanIds);
                paymentPlanIdSet.addAll(paymentPlanIds);
            }
            else{
                unitToSelectedPaymentPlanMap.get(selectedUnit).add(paymentPlanId);
            }

            //if(PODselection != null){
                unitToPodiumSelectedMap.put(selectedUnit,PODSelection);//PODselection);
            //}
            // swimming pool related changes for yas riva
            unitToSwimmingPoolSelectedMap.put(selectedUnit,SwimmingPoolSelection);
            if(multipurposeRoom !=null)
                unitToMultiPurposeAmountApplicableMap.put(selectedUnit,multipurposeRoom);

            if(designTypeId!=null){
                unitToDesignTypeMap.put(selectedUnit,designTypeId);
            }
            // swimming pool related changes for yas riva
            Map<id,SalesOfferUtility.SalesOfferDetails> unitDetailWrapper = SalesOfferUtility.generateSalesOfferMap(unitIdToOffer,unitToMultiPurposeAmountApplicableMap,unitToPodiumSelectedMap,unitToSwimmingPoolSelectedMap,unitToSelectedPaymentPlanMap,unitToDesignTypeMap,opportunityId, unitSignaturetypemap);
            
            SalesOfferUtility.SalesOfferDetails unitBookingDetailtemp = unitDetailWrapper.get(selectedUnit);
            //DIGITAL SALES CHIRAG
            SalesOfferUtility.SalesOfferDetails unitBookingDetail = new SalesOfferUtility.SalesOfferDetails();
            
            if(digitalSales == true ){
                if(unitBookingDetailtemp.unitRecord.DigitalSales__c == true){
                    unitBookingDetail = unitBookingDetailtemp;
                }
            }else{
                unitBookingDetail= unitBookingDetailtemp;
            }


            List<OfferLines__c> applicableOfferLinesCalculated = new List<OfferLines__c>();
            System.debug('Chirag'+unitBookingDetail);
            //DIGITAL SALES CHIRAG
            List<OfferLines__c> applicableOfferLinesCalculatedtemp = unitBookingDetail.applicableOfferLinesCalculated != null ? unitBookingDetail.applicableOfferLinesCalculated:new List<OfferLines__c>() ;
            for(OfferLines__c ooff : applicableOfferLinesCalculatedtemp){
                //DIGITAL SALES CHIRAG
                if(digitalSales == true){
                    if(unitBookingDetail.offerRecord.DigitalSales__c == true){
                    applicableOfferLinesCalculated.add(ooff);
                    }
                }else{
                    applicableOfferLinesCalculated.add(ooff);
                }
                
            }
            List<SalesOfferUtility.PaymentPlanWrapper> applicablePaymentPlansCalculatedtemp =  unitBookingDetail.applicablePaymentPlansCalculated != null ?  unitBookingDetail.applicablePaymentPlansCalculated: new List<SalesOfferUtility.PaymentPlanWrapper>();
            List<SalesOfferUtility.PaymentPlanWrapper> applicablePaymentPlansCalculated = new List<SalesOfferUtility.PaymentPlanWrapper>();
            for(SalesOfferUtility.PaymentPlanWrapper ppl :applicablePaymentPlansCalculatedtemp){
                //DIGITAL SALES CHIRAG
                if(digitalSales == true){
                    if(ppl.paymentPlanDetails.DigitalSales__c == true){
                        applicablePaymentPlansCalculated.add(ppl);
                    }
                }else{
                    applicablePaymentPlansCalculated.add(ppl);
                }
            }


            System.debug(applicablePaymentPlansCalculated.size()+'**applicablePaymentPlansCalculated**'+applicablePaymentPlansCalculated);

            SalesOfferUtility.PaymentPlanWrapper paymentPlanDetail = new SalesOfferUtility.PaymentPlanWrapper(); 

            for(SalesOfferUtility.PaymentPlanWrapper paymentPlan :applicablePaymentPlansCalculated){//Updated By Chirag // unitBookingDetail.applicablePaymentPlansCalculated
                System.debug(paymentPlan.paymentPlanDetails.Id+'**payment plan Id**'+paymentPlan.installmentDetails);
                List<PaymentPlanModel> paymentModel = new List<PaymentPlanModel>();
                for(SalesOfferUtility.PaymentInstallmentWrapper installmentLine : paymentPlan.installmentDetails){
                    if(paymentPlanId!=null && paymentPlan.paymentPlanDetails.Id == paymentPlanId){
                        response.paymentInstallmentsPlans.add(new PaymentPlanModel(installmentLine.installmentRecord.InstallmentNumber__c,installmentLine.installmentRecord.Description__c,installmentLine.installmentRecord.InstallmentPercentage__c,installmentLine.installmentRecord.InstallmentDate__c,installmentLine.totalValue));
                        paymentPlanDetail = paymentPlan ;
                    }
                    else if(paymentPlanIdSet!=null && paymentPlanIdSet.contains(paymentPlan.paymentPlanDetails.Id)){
                        paymentModel.add(new PaymentPlanModel(installmentLine.installmentRecord.InstallmentNumber__c,installmentLine.installmentRecord.Description__c,installmentLine.installmentRecord.InstallmentPercentage__c,installmentLine.installmentRecord.InstallmentDate__c,installmentLine.totalValue));
                    }     
                }
                if(paymentModel != null && paymentModel.size()>0){
                    //response.paymentInstallmentsPlanMap.put(paymentPlan.paymentPlanDetails.Id,paymentModel);
                    PaymentPlanInstallments paymentInstallment = new PaymentPlanInstallments(paymentPlan.paymentPlanDetails.Id,paymentPlan.paymentPlanDetails.Name,paymentModel);
                    paymentInstallment.totalDiscount = paymentPlan.discountAmount ;
                    paymentInstallment.rebateAmount = paymentPlan.rebateAmount ;
                    paymentInstallment.payablePrice = paymentPlan.netSalesPrice ;
                    paymentInstallment.sellingPrice = unitBookingDetail.unitRecord.SellingPrice__c ;
                    response.paymentPlanInstallments.add(paymentInstallment);
                }   
               
            } 

            for(OfferLines__c offerLine : applicableOfferLinesCalculated){//Updated By Chirag unitBookingDetail.applicableOfferLinesCalculated
                response.offerAndPromotions.add(new OfferAndPromotionsModel(offerLine.PromoType__c,offerLine.PromoValue__c));
            }

            response.opportunityId = opportunityId ;
            response.unitDetail = unitBookingDetail.unitRecord ;
            response.sellingPrice = unitBookingDetail.unitRecord.SellingPrice__c ;
            response.totalDiscount = paymentPlanDetail.discountAmount ;
            response.rebateAmount = paymentPlanDetail.rebateAmount ;
            response.payablePrice = paymentPlanDetail.netSalesPrice ;
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
      /*  }
        catch (Exception exc) {
        
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        } */
    } 


    global class UnitPaymentOfferModel{
        public Id unitId ;
        public Id opportunityId ;
        public Unit__c unitDetail ;
        public List<PaymentPlanModel> paymentInstallmentsPlans ;
        // Map<Id,List<PaymentPlanModel>> paymentInstallmentsPlanMap ;
        public List<PaymentPlanInstallments> paymentPlanInstallments ;
        public List<OfferAndPromotionsModel> offerAndPromotions ;
        public Decimal sellingPrice ;
        public Decimal totalDiscount ;
        public Decimal payablePrice ;
        public Decimal rebateAmount ;
        public String currencyISOCode ;
                                             

        public UnitPaymentOfferModel(){
            this.unitId = null ;
            this.opportunityId = null ;
            this.unitDetail = new Unit__c();
            this.paymentInstallmentsPlans = new List<PaymentPlanModel>() ;
            //this.paymentInstallmentsPlanMap = new Map<Id,List<PaymentPlanModel>>();
            this.paymentPlanInstallments = new List<PaymentPlanInstallments>();
            this.offerAndPromotions = new List<OfferAndPromotionsModel>() ;
            this.sellingPrice = 0 ;
            this.totalDiscount = 0 ;
            this.payablePrice = 0 ;
            this.rebateAmount = 0 ;
            this.currencyISOCode = null;
        }
    }

    global class PaymentPlanModel{
        public Decimal installmentNo ;
        public String description ;
        public Decimal installmentPercentage ;
        public Date installmentDate ;
        public Decimal installmentAmount ;

        public PaymentPlanModel(Decimal installmentNo,String description,Decimal installmentPercentage,Date installmentDate,Decimal installmentAmount ){
            this.installmentNo = installmentNo;
            this.description = description ;
            this.installmentPercentage = installmentPercentage;
            this.installmentDate = installmentDate ;
            this.installmentAmount = installmentAmount ;

        }
    }

    global class OfferAndPromotionsModel{
        public String offerType ;
        public String offerValue ;

        public OfferAndPromotionsModel(String offerType ,String offerValue){
            this.offerType = offerType;
            this.offerValue = offerValue;
        }
    }

    global class PaymentPlanInstallments{
		public Id paymentPlanId;	//a0A26000006hHKBEA2
		public String paymentPlanName;	//Plan Name
		public List<PaymentPlanModel> installments;
        public Decimal sellingPrice ;
        public Decimal totalDiscount ;
        public Decimal payablePrice ;
        public Decimal rebateAmount ;
        public String currencyISOCode ;

        public PaymentPlanInstallments(Id paymentPlanId,String paymentPlanName,List<PaymentPlanModel> installments){
            this.paymentPlanId = paymentPlanId ;
            this.paymentPlanName = paymentPlanName ;
            this.installments = installments;
            this.sellingPrice = 0 ;
            this.totalDiscount = 0 ;
            this.payablePrice = 0 ;
            this.rebateAmount = 0 ;
            this.currencyISOCode = null;
        }
	}
}