@RestResource (urlMapping = '/query/unitdetail')
global with sharing class UnitDetailWebService {

    @HttpPost
    global static void doPost(Id unitId,Boolean digitalSales) {   ////DIGITAL SALES
        
        RestContextHandler handler = new RestContextHandler(false);
        
        try {
            
            UnitDetailModel response = new UnitDetailModel();

            User loggedInUser = Utilities.getLoggedInUserDetail();
            List<Unit__c> unitDetails = new List<Unit__c>();
            //Added by Chirag DIGITAL SALES
            if(digitalSales == true){
                unitDetails = UnitService.getAllOnlineUnitsById(new Set<Id>{unitId});
            }else{
                unitDetails = UnitService.getAllUnitsById(new Set<Id>{unitId});
            }
            List<Id>AffectionIds = new List<Id>();
            for(Document__c Document :[SELECT Id,Name FROM Document__c WHERE DocumentType__c ='Affection Plan' AND Unit__c=:unitId]){
                AffectionIds.add(Document.Id);
            }
            

            Map<Id,List<DesignType>> unitDesignTypeMap = new Map<Id,List<DesignType>>();
            if(unitDetails.size() >0){
                for(UnitDesign__c unitDesignRec : UnitServiceWithoutSharing.getAllUnitDesign(new Set<Id>{unitId})){
                    String MedLabel;
                    List<DesignType> designTypeList = new List<DesignType>{new DesignType(unitDesignRec.DesignType__c,unitDesignRec.Id)};
                    if(unitDesignTypeMap.containsKey(unitDesignRec.Unit__c)){
                        designTypeList.addAll(unitDesignTypeMap.get(unitDesignRec.Unit__c));
                    }
                    else{
                        MedLabel = (unitDesignRec.Unit__r.ProjectName__c == 'Fay Alreeman')? Constants.DESIGNTYPE_MEDITERRANEAN : 'Modern'; 
                        designTypeList.add(new DesignType(MedLabel,null));
                    }
                    unitDesignTypeMap.put(unitDesignRec.Unit__c,designTypeList); 
                }
            }
            system.debug('unitDetailsP' + unitDetails);

            if(unitDetails.size() >0 && unitDetails != null && unitDetails[0]!=null){
                Unit__c unitDetail = unitDetails[0];
                Map<Id,List<PaymentPlan__c>> unitPaymentPlanMap = new Map<Id,List<PaymentPlan__c>>();
                Map<Id,List<OffersPromotions__c>> unitOfferMap  = new Map<Id,List<OffersPromotions__c>>();
                //DIGITAL SALES Chirag
                Map<Id,List<PaymentPlan__c>> unitPaymentPlanMapDigital = new Map<Id,List<PaymentPlan__c>>();
                Map<Id,List<OffersPromotions__c>> unitOfferMapDigital  = new Map<Id,List<OffersPromotions__c>>();
                
                if(digitalSales ==false){
                unitPaymentPlanMap = PaymentPlanService.getListOfPaymentPlans(null,unitDetails,loggedInUser);
                unitOfferMap = OffersPromotionsService.getActiveOffersPromotions(null,unitDetails,loggedInUser);
                }else{
                    unitPaymentPlanMap = PaymentPlanService.getListOfPaymentPlans(null,unitDetails,loggedInUser);
                    unitOfferMap = OffersPromotionsService.getActiveOffersPromotions(null,unitDetails,loggedInUser);
                    for(Id uniId :unitPaymentPlanMap.keySet()){
                        for(PaymentPlan__c pl :unitPaymentPlanMap.get(uniId)){
                            if(pl.DigitalSales__c==true){
                                if(unitPaymentPlanMapDigital.containsKey(pl.Unit__c)){
                                    List<PaymentPlan__c> plList = unitPaymentPlanMapDigital.get(pl.Unit__c);
                                    plList.add(pl);
                                    unitPaymentPlanMapDigital.put(pl.Unit__c,plList);
                                }else{
                                    List<PaymentPlan__c> plList = new List<PaymentPlan__c>();
                                    plList.add(pl);
                                    unitPaymentPlanMapDigital.put(pl.Unit__c,plList);
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
                //DIGITAL SALES END
                List<ProjectDocumentUtility.ProjectDetails> projectDetailList = ProjectDocumentUtility.getProjectDetailsRecords(new List<Id>{unitDetail.Project__c}, false);

                System.debug('**projectDetailList**'+projectDetailList);
                response.publicLinksMap = projectDetailList[0].relatedDocuments;
                response.AffectionPlanId =AffectionIds;
                response.unitId = unitId ;
                response.unitDetail = unitDetail ;
                response.paymentPlans = digitalSales ==true  ? unitPaymentPlanMapDigital.get(unitId) :unitPaymentPlanMap.get(unitId);//DIGITAL SALES
                response.offerAndPromotions = digitalSales ==true  ?unitOfferMapDigital.get(unitId): unitOfferMap.get(unitId) ;//DIGITAL SALES
                response.eligibleForMultiPurpose = unitDetail.BuildingSectionName__r.EligibileforMultiPurposeRoom__c ;
                response.eligibleForUnitFinishing = unitDetail.BuildingSectionName__r.EligibleforUnitFinishes__c ;
                response.eligibleForPOD = unitDetail.BuildingSectionName__r.EligibleforPodium__c;
                // swimming pool related changes for yas riva
                response.eligibleForSwimmingPool = unitDetail.Swimming_Pool_Price__c > 0? true:false;
                response.mandatorypremium = unitDetail.Mandatory_Premium__c;
                
                if(unitDetail.BuildingSectionName__r.EligibleforPodium__c){
                    if(!unitdetail.Mandatory_POD__c){
                        response.PODTypes.add('None');
                    }
                    if(unitdetail.PODMultiPurposeRoomPrice__c>0){
                        response.PODTypes.add('Multi Purpose Room');
                    }
                    if(unitdetail.PODkitchenPrice__c>0){
                        response.PODTypes.add('Kitchen');
                    }
                }
                // swimming pool related changes for yas riva
                if(unitDetail.Swimming_Pool_Price__c > 0){
                    if(!unitdetail.Mandatory_Swimming_Pool__c){
                        response.SwimmingPoolOptions.add('No');
                    }
                    response.SwimmingPoolOptions.add('Yes');
                }
            
                if(unitDetail !=null){
                    String amenities = unitDetail.Project__r.Amenities__c ;
                    response.amenities = (amenities!=null ? amenities.split(';') : null); 
                }

                Map<String, List<String>> projectUnitFinishingMap = SalesOfferUtility.getUnitFurnishingBasedOnProject();
                response.unitFinishes = projectUnitFinishingMap.get(unitDetail.Project__r.Name);
               
                //Schema.DescribeFieldResult fieldResult = SalesOrder__c.UnitFinishing__c.getDescribe();
                //for(Schema.PicklistEntry picklist: fieldResult.getPicklistValues()){
                //    response.unitFinishes.add(picklist.getValue());
                //}
                response.designTypes = (unitDesignTypeMap.containsKey(unitId) ? unitDesignTypeMap.get(unitId) : null);
                system.debug('response' + response);
                handler.response.data = response;
                handler.response.success = true;
                handler.finalize();
            }
            
            
        }
        catch (Exception exc) {
        
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    } 

    
    global class UnitDetailModel{

        public Id unitId ;
        public Unit__c unitDetail ;
        public List<PaymentPlan__c> paymentPlans ;
        public List<OffersPromotions__c> offerAndPromotions ;
        public Boolean eligibleForMultiPurpose ;
        public boolean eligibleForPOD;
        // swimming pool related changes for yas riva
        public boolean eligibleForSwimmingPool;
        public boolean mandatorypremium;
        public Boolean eligibleForUnitFinishing ;
        public List<String> amenities ;
        public List<String> PODTypes ; 
        // swimming pool related changes for yas riva
        public List<String> SwimmingPoolOptions ; 
        public Map<String,List<ProjectDocumentUtility.PublicLinkDetails>> publicLinksMap;
        public List<String> unitFinishes ; 
        public List<DesignType> designTypes ;
        public List<Id> AffectionPlanId;

        public UnitDetailModel(){
            this.UnitId = null ;
            this.unitDetail = new Unit__c();
            this.paymentPlans = new List<PaymentPlan__c>() ;
            this.offerAndPromotions = new List<OffersPromotions__c>() ;
            this.eligibleForMultiPurpose = false ;
            this.eligibleForPOD = false;
            // swimming pool related changes for yas riva
            this.eligibleForSwimmingPool = false;
            this.mandatorypremium = false;
            this.eligibleForUnitFinishing = false ;
            this.amenities = new List<String>();
            this.PODTypes = new list<String>();
            // swimming pool related changes for yas riva
            this.SwimmingPoolOptions = new list<String>();
            this.publicLinksMap = new Map<String,List<ProjectDocumentUtility.PublicLinkDetails>>();
            this.unitFinishes = new List<String>();
            this.designTypes = new List<DesignType>();
            this.AffectionPlanId = new List<Id>();
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