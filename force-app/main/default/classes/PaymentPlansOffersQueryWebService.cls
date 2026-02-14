@RestResource (urlMapping = '/query/paymentplansoffers')
global with sharing class PaymentPlansOffersQueryWebService {
    
    @HttpPost
    global static void doPost(String opportunityId, List<Id> unitIds,Boolean digitalSales) {   
        
        RestContextHandler handler = new RestContextHandler(false);
        
        try {
            
            PaymentPlanOfferResponse response = new PaymentPlanOfferResponse();

            User loggedInUser = Utilities.getLoggedInUserDetail();
            Set<Id> unitSet = new Set<Id>();
            unitSet.addAll(unitIds);
            List<Unit__c> unitDetails = UnitService.getAllUnitsById(unitSet);
             //DIGITAL SALES CHIRAG
             if(digitalSales == true){
                unitDetails = UnitService.getAllOnlineUnitsById(unitSet);
            }else{
                unitDetails = UnitService.getAllUnitsById(unitSet);
            }
            Map<Id,Unit__c> unitDetailMap = new Map<Id,Unit__c>(unitDetails);
            Map<Id,Opportunity> opportunityMap = OpportunityService.getOpportunityDetailsMapbyId(opportunityId);
            
            Map<Id,List<PaymentPlan__c>> unitPaymentPlanMapDigital = new Map<Id,List<PaymentPlan__c>>(); //DIGITAL SALES CHIRAG
            Map<Id,List<OffersPromotions__c>> unitOfferMapDigital  = new Map<Id,List<OffersPromotions__c>>(); //DIGITAL SALES CHIRAG
            
            Map<Id,List<PaymentPlan__c>> unitPaymentPlanMap = new Map<Id,List<PaymentPlan__c>>();
            
            //Map<Id,List<OffersPromotions__c>> unitOfferMap = OffersPromotionsService.getActiveOffersPromotions(opportunityMap.get(opportunityId),unitDetails,loggedInUser);
            Map<String, List<String>> projectUnitFinishingMap = SalesOfferUtility.getUnitFurnishingBasedOnProject();
            response.opportunityId = opportunityId ;
            response.unitPaymentPlanOffer = new List<UnitPlanOffer>();
            response.unitFinishes = new List<String>();
            response.unitFurnishing = new List<String>();
            response.PODTypes = new list<string>();
			// swimming pool related changes for yas riva
            response.SwimmingPoolOptions = new list<string>();
            map<id,UnitDesign__c> unitDesignMap = new map<id,UnitDesign__c>();

            List<UnitDesign__c> unitDesignList = UnitServiceWithoutSharing.getAllUnitDesign(unitSet);
            Map<Id,List<DesignType>> unitDesignTypeMap = new Map<Id,List<DesignType>>();
            if(unitDetails.size() >0 && unitDetails != null){
            Map<Id,List<OffersPromotions__c>> unitOfferMap = new Map<Id,List<OffersPromotions__c>>();
             //DIGITAL SALES CHIRAG CHANGES START
             if(digitalSales ==false){
                unitPaymentPlanMap = PaymentPlanService.getListOfPaymentPlans(opportunityMap.get(opportunityId),unitDetails,loggedInUser);
                unitOfferMap = OffersPromotionsService.getActiveOffersPromotions(opportunityMap.get(opportunityId),unitDetails,loggedInUser);
               }else{
                unitPaymentPlanMap = PaymentPlanService.getListOfPaymentPlans(opportunityMap.get(opportunityId),unitDetails,loggedInUser);
                System.debug('unitPaymentPlanMap' +unitPaymentPlanMap);
                unitOfferMap = OffersPromotionsService.getActiveOffersPromotions(opportunityMap.get(opportunityId),unitDetails,loggedInUser);
                    for(Id uniId :unitPaymentPlanMap.keySet()){
                        for(PaymentPlan__c pl :unitPaymentPlanMap.get(uniId)){
                            if(pl.DigitalSales__c==true){
                                if(unitPaymentPlanMapDigital.containsKey(uniId)){
                                    List<PaymentPlan__c> plList = unitPaymentPlanMapDigital.get(uniId);
                                    plList.add(pl);
                                    unitPaymentPlanMapDigital.put(uniId,plList);
                                }else{
                                    List<PaymentPlan__c> plList = new List<PaymentPlan__c>();
                                    plList.add(pl);
                                    unitPaymentPlanMapDigital.put(uniId,plList);
                                }
                            }
                        }
                    }
                    for(Id uniId :unitOfferMap.keySet()){
                        for(OffersPromotions__c pl :unitOfferMap.get(uniId)){
                            if(pl.DigitalSales__c==true){
                                if(unitOfferMapDigital.containsKey(pl.Unit__c)){
                                    List<OffersPromotions__c> plList = unitOfferMapDigital.get(pl.Unit__c);
                                    plList.add(pl);
                                    unitOfferMapDigital.put(pl.Unit__c,plList);
                                }else{
                                    List<OffersPromotions__c> plList = new List<OffersPromotions__c>();
                                    plList.add(pl);
                                    unitOfferMapDigital.put(pl.Unit__c,plList);
                                }
                            }
                        }
                    }
                }
          //DIGITAL SALES CHIRAG CHANGES END
            
            for(UnitDesign__c unitDesignRec : unitDesignList){
                List<DesignType> designTypeList = new List<DesignType>{new DesignType(unitDesignRec.DesignType__c,unitDesignRec.Id)};
                String MedLabel;

                if(unitDesignTypeMap.containsKey(unitDesignRec.Unit__c)){
                    designTypeList.addAll(unitDesignTypeMap.get(unitDesignRec.Unit__c));
                }
                else{
                    MedLabel = (unitDesignRec.Unit__r.ProjectName__c == 'Fay Alreeman')? Constants.DESIGNTYPE_MEDITERRANEAN : 'Modern'; 
                    designTypeList.add(new DesignType(MedLabel,null));
                }
                unitDesignTypeMap.put(unitDesignRec.Unit__c,designTypeList); 
            }
            for(Id unitId : unitIds){
                Unit__c unitDetail = unitDetailMap.get(unitId);
                 
              response.unitFinishes = projectUnitFinishingMap.get(unitDetail.Project__r.Name);
            }

            

            for(Id unitId : unitIds){
                Unit__c unitDetail = unitDetailMap.get(unitId);
                if(unitDetail.BuildingSectionName__r.EligibleforPodium__c){
                    //list<PODtype> PODTypes = new list<PODType>();
                    //PODtype PODTypesitem = new PODtype();

                    if(!unitdetail.Mandatory_POD__c){
                        response.PODTypes.add('None');
                    }
                    if(unitdetail.PODMultiPurposeRoomPrice__c>0){
                        response.PODTypes.add('Multi Purpose Room');
                    }
                    if(unitdetail.PODkitchenPrice__c>0){
                        response.PODTypes.add('Kitchen');
                    }

               //     if(PODTypes.size()>0) {
               //         unitPODMap.put(unitDetail.Id,PODTypes);
              //      }
              		// swimming pool related changes for yas riva
                    if(unitDetail.Swimming_Pool_Price__c > 0){
                        if(!unitdetail.Mandatory_Swimming_Pool__c){
                            response.SwimmingPoolOptions.add('No');
                        }
                        response.SwimmingPoolOptions.add('Yes');
                    }
                }
            }

            List<Unit_Add_on__c> unitList = [SELECT Id,Name_of_Add_on__c,SubName_of_AddOns__c, Unit__c FROM Unit_Add_on__c WHERE Unit__c =:unitIds and IsActive__c = TRUE];
            Map<Id,List<Unit_Add_on__c>> unitMap = new Map<Id,List<Unit_Add_on__c>>();

            if(!unitList.isEmpty())  {
                for(Unit_Add_on__c un : unitList){
                     if(unitMap.containsKey(un.Unit__c)){
                        List<Unit_Add_on__c> unitaddonList = unitMap.get(un.Unit__c);
                        unitaddonList.add(un);
                        unitMap.put(un.Unit__c,unitaddonList);
                    }else{
                        List<Unit_Add_on__c> unitaddonList = new List<Unit_Add_on__c>();
                        unitaddonList.add(un);
                        unitMap.put(un.Unit__c,unitaddonList);
                    }
                }      
            }
            
            for(Id unitId : unitIds){
                UnitPlanOffer newUnit = new UnitPlanOffer();
                Unit__c unitDetail = unitDetailMap.get(unitId);
                newUnit.unitId = unitId ;
                newUnit.unitDetail = unitDetail ; 
                newUnit.paymentPlans = digitalSales == true  ?  unitPaymentPlanMapDigital.get(unitId) :unitPaymentPlanMap.get(unitId) ;//DIGITAL SALES CHIRAG
                newUnit.offerAndPromotions = digitalSales == true  ?  unitOfferMapDigital.get(unitId): unitOfferMap.get(unitId);//DIGITAL SALES CHIRAG
                newUnit.eligibleForMultiPurpose = unitDetail.BuildingSectionName__r.EligibileforMultiPurposeRoom__c ;
                newUnit.eligibleForPOD = unitDetail.BuildingSectionName__r.EligibleforPodium__c ; //added by sujesh on 26th oct
                newUnit.eligibleForSwimmingPool = unitDetail.Swimming_Pool_Price__c > 0?true:false;
                newUnit.eligibleForUnitFinishing = unitDetail.BuildingSectionName__r.EligibleforUnitFinishes__c ;
                newUnit.eligibleForUnitFurnishing = unitDetail.EligibleforUnitFurnishing__c ;
                newUnit.designTypes = (unitDesignTypeMap.containsKey(unitId) ? unitDesignTypeMap.get(unitId) : null);
                newUnit.mandatorypremium = unitDetail.Mandatory_Premium__c; //added by sujesh on 26th oct
                Map<String,List<SalesOfferUtility.UnitSubAddonWrapper>> UnitAddonMap = new Map<String,List<SalesOfferUtility.UnitSubAddonWrapper>>();
                if(!unitMap.isEmpty()){
                  for(Unit_Add_on__c un : unitMap.get(unitId)){
                        if(UnitAddonMap.containsKey(un.Name_of_Add_on__c)){
                            List<SalesOfferUtility.UnitSubAddonWrapper> subAddonList = UnitAddonMap.get(un.Name_of_Add_on__c);
                            SalesOfferUtility.UnitSubAddonWrapper us = new SalesOfferUtility.UnitSubAddonWrapper();
                            us.label = un.SubName_of_AddOns__c;
                            us.value=un.Id;
                            subaddonList.add(us);
                            UnitAddonMap.put(un.Name_of_Add_on__c,subAddonList);
                        }else{
                            List<SalesOfferUtility.UnitSubAddonWrapper> subAddonList = new List<SalesOfferUtility.UnitSubAddonWrapper>();
                            SalesOfferUtility.UnitSubAddonWrapper us = new SalesOfferUtility.UnitSubAddonWrapper();
                            us.label = un.SubName_of_AddOns__c;
                            us.value=un.Id;
                            subaddonList.add(us);
                            UnitAddonMap.put(un.Name_of_Add_on__c,subAddonList);
                        }
                	}
                }

                system.debug('UnitAddonMap' + UnitAddonMap);
                newUnit.unitAddons = UnitAddonMap;
                
                response.unitPaymentPlanOffer.add(newUnit);
            }

            Schema.DescribeFieldResult unitFurnishingFieldResult = SalesOrder__c.UnitFurnishing__c.getDescribe();
            for(Schema.PicklistEntry picklist: unitFurnishingFieldResult.getPicklistValues()){
                response.unitFurnishing.add(picklist.getValue());
            }
        }
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
        
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    } 

    global class PaymentPlanOfferResponse{
        public String opportunityId ;
        public List<UnitPlanOffer> unitPaymentPlanOffer ;
        public List<String> unitFinishes ; 
        public List<String> PODTypes ; 
        // swimming pool related changes for yas riva
        public List<String> SwimmingPoolOptions;
        public List<String> unitFurnishing ; 
    }

    global class UnitPlanOffer{
        public Id unitId ;
        public Unit__c unitDetail ;
        public List<PaymentPlan__c> paymentPlans ;
        public List<OffersPromotions__c> offerAndPromotions ;
        public Boolean eligibleForMultiPurpose ;
        public Boolean eligibleForUnitFinishing ;
        public Boolean eligibleForUnitFurnishing ;
        public boolean eligibleForPOD;
        // swimming pool related changes for yas riva
        public boolean eligibleForSwimmingPool;
        public boolean mandatorypremium;
        public List<DesignType> designTypes ;
		public map<string,list<SalesOfferUtility.UnitSubAddonWrapper>> unitAddons;


        public UnitPlanOffer(){
            this.UnitId = null ;
            this.unitDetail = new Unit__c();
            this.paymentPlans = new List<PaymentPlan__c>() ;
            this.offerAndPromotions = new List<OffersPromotions__c>() ;
            this.eligibleForMultiPurpose = false ;
            this.eligibleForUnitFinishing = false ;
            this.designTypes = new List<DesignType>();
            this.eligibleForUnitFurnishing = false ;
            this.eligibleForPOD = false ;
            this.mandatorypremium = false;
            this.unitAddons = new map<string,list<SalesOfferUtility.UnitSubAddonWrapper>>();


        }
    }

    global class DesignType{
        public String designType ;
        public Id designId ;

        public DesignType(String designType,Id designId){
            this.designType = designType ;
            this.designId = designId ;
        }
    } 
   

}