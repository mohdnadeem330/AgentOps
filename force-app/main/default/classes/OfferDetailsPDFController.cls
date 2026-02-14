/**********************************************************************************************************************
* Name               : OfferDetailsPDFController                                                        
* Description        : This class is used to generate the PDF
* Usage              : OfferDetailsPDF VF Page                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class OfferDetailsPDFController {
    public SalesOfferUtility.SalesOfferDetails offerDetails {get; set;}
    public string todayDate {get; set;}
    public string randomString {get; set;}
    public string customerName {get; set;}
    public string floorPlanLink {get; set;}
    public string affectionPlanLink {get; set;}

    public boolean showAffectionPlanLink {get; set;}
    public boolean showMarketingPlanLink {get; set;}
    // Al faya sadiyat changes
    public Map<String,String> unitAddons {get; set;}
    public List<String> listOfAddOns {get; set;}

    public OfferDetailsPDFController(){
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        String currentOffer = ApexPages.currentPage().getParameters().get('currentOffer');
        String otherUnits = ApexPages.currentPage().getParameters().get('otherUnits');
        String selectedPayments = ApexPages.currentPage().getParameters().get('selectedPayments');
        String multiPurposeAmount = ApexPages.currentPage().getParameters().get('multiPurposeAmount');
        String selectedDesign = ApexPages.currentPage().getParameters().get('selectedDesign');
        String affectionPlan = ApexPages.currentPage().getParameters().get('affectionPlan');
        String PODSelection = ApexPages.currentPage().getParameters().get('PODSelection');
        // swimming pool related changes for yas riva
        String swimmingPoolSelection = ApexPages.currentPage().getParameters().get('swimmingPoolSelection');
        String marketingPlan = ApexPages.currentPage().getParameters().get('marketingPlan');

        customerName = ApexPages.currentPage().getParameters().get('customerName');
        
        if(currentUnit!=null && currentUnit!=''){
            list<SalesOfferUtility.SaleOfferInputParam> params = new list<SalesOfferUtility.SaleOfferInputParam>();
            
            //Other units
            if(otherUnits!=null && otherUnits!=''){ 
                for(String str: otherUnits.split('\\|')){
                    if(str!=null){
                        SalesOfferUtility.SaleOfferInputParam tempParamObj = new SalesOfferUtility.SaleOfferInputParam();
                        tempParamObj.unitId = str;
                        tempParamObj.offerId = null;
                        tempParamObj.designId=null;
                        tempParamObj.selectedPayments = new list<Id>();
                        params.add(tempParamObj);
                    }
                }
            }
            //Current Unit
            SalesOfferUtility.SaleOfferInputParam tempParamObj = new SalesOfferUtility.SaleOfferInputParam();
            tempParamObj.unitId = currentUnit;
            tempParamObj.offerId = (currentOffer!=null && currentOffer!='' )? currentOffer : null;
            tempParamObj.designId=(selectedDesign!=null && selectedDesign!='' )? selectedDesign : null;
            tempParamObj.selectedPayments = new list<Id>();
            system.debug('PODSelection++' + PODSelection);
            tempParamObj.podiumSelection = (PODSelection !=null &&  PODSelection!='')? PODSelection : null;
            // swimming pool related changes for yas riva
            tempParamObj.swimmingPoolSelection = (swimmingPoolSelection !=null &&  swimmingPoolSelection!='')? swimmingPoolSelection : null;
            tempParamObj.multiPurposeAmountApplicable = (multiPurposeAmount !=null &&  multiPurposeAmount!='' && multiPurposeAmount.equalsIgnoreCase('true'))?true:false; 
            showAffectionPlanLink = (affectionPlan !=null &&  affectionPlan!='' && affectionPlan.equalsIgnoreCase('false'))?false:true;
            showMarketingPlanLink = (marketingPlan !=null &&  marketingPlan!='' && marketingPlan.equalsIgnoreCase('false'))?false:true;
            if(selectedPayments!=null && selectedPayments!='' ){
                for(Id str: selectedPayments.split('\\|')){
                    if(str!=null){
                        tempParamObj.selectedPayments.add(str);
                    }
                }
            }
            params.add(tempParamObj);
            randomString = generateRandomString(7);
            offerDetails = OpportunityUnitSearchController.generateSalesOffer(params,opportunityId).get(currentUnit);
            // Al faya sadiyat changes
            unitAddons = new Map<String,String>();
            listOfAddOns = new List<String>();
            for(SalesOfferUtility.UnitAddonWrapper addon : offerDetails.unitAddons){
                if(ApexPages.currentPage().getParameters().keySet().contains(addon.UnitAddonName) && ApexPages.currentPage().getParameters().get(addon.UnitAddonName) != null){
                    for(SalesOfferUtility.UnitSubAddonWrapper subAddon: addon.UnitsubAddonWrapperList){
                        if(subAddon.value == ApexPages.currentPage().getParameters().get(addon.UnitAddonName)){
                            unitAddons.put(addon.UnitAddonName,subAddon.label);
                            listOfAddOns.add(subAddon.value);
                            
                        }
                    }
                }
            }
            todayDate = System.today().format();
            string fileName = 'Offer-'+offerDetails.unitRecord.Name+'-'+customerName+'-'+todayDate;
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+fileName+'.pdf');
        }
        
    }
    
    /**
    * createPublickLink 
    *
    * Create public link for the Floor plan if not available 
    * 
    * @usage OfferDetailsPDF VF page
    *
    * @param none
    * @return none
    * 
    */
    public  void createPublickLink(){
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        String selectedDesign = ApexPages.currentPage().getParameters().get('selectedDesign');
        if(currentUnit!=null && currentUnit!=''){
            string relatedrecordID = currentUnit;
            //if design is slected then fect design related floorplan
            if(selectedDesign!=null && selectedDesign!=''){
                relatedrecordID = selectedDesign;
            }
            // Al faya sadiyat changes for Affection plan on Unit Add on
            for(Document__c doc : [SELECT Id, Unit_Add_on__c FROM Document__c WHERE DocumentType__c =: Constants.DOCUMENT_TYPE_AFFECTION_PLAN  AND Unit_Add_on__c IN (SELECT Id FROM Unit_Add_on__c WHERE id IN:  listOfAddOns )]){
                relatedrecordID = doc.Unit_Add_on__c;
                break;
            }
            //Get public links
            for(ContentDistribution cdRec : [select id,Name, ContentDownloadUrl,RelatedRecordId from ContentDistribution where RelatedRecordId = :relatedrecordID ORDER BY CreatedDate ASC ]){
                if(cdRec.Name == Constants.DOCUMENT_TYPE_FLOOR_PLAN){
                    floorPlanLink=cdRec.ContentDownloadUrl;
                }else if(cdRec.Name == Constants.DOCUMENT_TYPE_AFFECTION_PLAN){
                    affectionPlanLink=cdRec.ContentDownloadUrl;
                }
            }
            //if not available try to create
            list<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
            set<String> documentCodesToCreate = new set<string>();
            if(floorPlanLink == null){
                documentCodesToCreate.add(Constants.DOCUMENT_TYPE_FLOOR_PLAN);
            }
            if(affectionPlanLink == null){
                documentCodesToCreate.add(Constants.DOCUMENT_TYPE_AFFECTION_PLAN);
            }
            system.debug('------>'+documentCodesToCreate);
            map<id,Document__c> documents = new map<id,Document__c>([select id,DocumentType__c from Document__c where (Unit__c = :relatedrecordID or UnitDesign__c = :relatedrecordID or Unit_Add_on__c = :relatedrecordID ) and DocumentType__c in :documentCodesToCreate and DocumentAttached__c=true]);
            system.debug('documents = '+documents);
            if(!documents.isEmpty()){
                map<id,id> contentDocumentParentId= new map<id,id>();
                for(ContentDocumentLink linkedDocs : [SELECT LinkedEntityId,ContentDocumentId  FROM ContentDocumentLink where LinkedEntityId in :documents.keySet()]){
                    contentDocumentParentId.put(linkedDocs.ContentDocumentId ,linkedDocs.LinkedEntityId);
                }
                system.debug('contentDocumentParentId = '+contentDocumentParentId);
                map<Id,ContentVersion> contentDocumentMap =new map<id,ContentVersion>();
                for(ContentVersion contentversionRecord :[SELECT Id,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in :contentDocumentParentId.keySet() and isLatest=true]){
                    //contentDocumentMap.put(contentversionRecord.ContentDocumentId,contentversionRecord);
                    distributionsToInsert.add( createContentDistribution( contentversionRecord.Id, relatedrecordID ,documents.get(contentDocumentParentId.get(contentversionRecord.ContentDocumentId)).DocumentType__c ));  
                }
                system.debug('distributionsToInsert = '+distributionsToInsert);
                if(!distributionsToInsert.isEmpty()){ 
                    insert distributionsToInsert;
                    //Get public links
                    for(ContentDistribution cdRec : [select id,Name, ContentDownloadUrl,RelatedRecordId from ContentDistribution where RelatedRecordId = :relatedrecordID ]){
                        if(cdRec.Name == Constants.DOCUMENT_TYPE_FLOOR_PLAN){
                            floorPlanLink=cdRec.ContentDownloadUrl;
                        }else if(cdRec.Name == Constants.DOCUMENT_TYPE_AFFECTION_PLAN){
                            affectionPlanLink=cdRec.ContentDownloadUrl;
                        }
                    }
                }
            }
        }
    }
    
    /**
    * generateRandomString 
    *
    * generate random string for offer letter
    * 
    * @usage OfferDetailsPDF VF page
    *
    * @param len number of random characters
    * @return String random string
    * 
    */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    /**
    * createContentDistribution
    *
    * This method used to create ContentDistribution object
    *
    * @param  contentVersionId 
    * @param  CaseID 
    * @return ContentDistribution
    */
    public static ContentDistribution createContentDistribution(Id contentVersionId,Id unitID , string fileName){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = fileName;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        newDist.RelatedRecordId= unitID;
        return newDist;
    }
   
}