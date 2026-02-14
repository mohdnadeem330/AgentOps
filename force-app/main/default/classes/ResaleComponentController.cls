/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Controller class for Resale LWC on Opportunity.
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
public without sharing class ResaleComponentController {

    /**
     * Developed by Harsh@Aldar 08Jun23 ASF-924
     * @description Get resale unit info for unitsearch
     * @param  unitId unitId 
     * @return        return wrapper
     */
    @AuraEnabled(cacheable=true)
    public static ResaleUnitInfoWrap getResaleUnitInfo(Id unitId){
        ResaleUnitInfoWrap wrap;
        try {
            Unit__c thisUnit = ResaleComponentService.getUnitDetailsById(unitId);
            wrap = new ResaleUnitInfoWrap(thisUnit); 
            return wrap;
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'Resale Opportunity Search Controller','ResaleComponentController','getResaleUnitInfo'));
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description getsObjectType return sobjectType and relevent fields
     * @param  recordID recordID description
     * @return          return description
     */
    @AuraEnabled(cacheable=true)
    public static map<String,object> getsObjectType(Id recordID){
        map<String,sObject> mapToReturn = new map<String,sObject>();
        Schema.SObjectType sobjectType = recordID.getSObjectType();
        string sobjectName = sobjectType.getDescribe().getName();
        if(sobjectName.equalsIgnoreCase('Opportunity')){
            mapToReturn.put(sobjectName, ResaleComponentService.getOppDetailsById(recordID));
        }

        return mapToReturn;
    }

    /**
     * @description getResaleUnitDetails Get List of Resale Units under Buildings 
     * ASF-936 Developed by Harsh@Aldar 12/06/23
     * @param  buildingsId buildingsId description
     * @return             return description
     */ 
    @AuraEnabled(cacheable=true)
    public static UnitWrapper getResaleUnitDetails(ID buildingsId){ 
        UnitWrapper unitsToReturn;
        unitsToReturn = new UnitWrapper(ResaleComponentService.getAvailableResaleUnits(new Set<Id>{buildingsId}));
        return unitsToReturn;
    }

    /**
     * @description getAllBuildings return available Buildings for given Project
     * @param  projectId projectId description
     * @return           return description
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllBuildings(String projectId){
        List<Map<String, String>> filtersToReturn = new List<Map<String, String>>();
        
        for(BuildingSection__c tempBuilding: BuildingSectionService.prepareBuildingsNames(projectId) ){
            Map<String, String> tempMap = new Map<String, String>();
            tempMap.put('label', tempBuilding.Name);
            tempMap.put('value', tempBuilding.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }

    /**
     * @description getAllProjects description
     * @return   return description
     */ 
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllProjects(){
        List<Map<String, String>> filtersToReturn = new List<Map<String, String>>();

        //ASF 936 Harsh@Aldar
        List<Project__c> projectList = ResaleComponentService.getAllProjects();
        
        for(Project__c tempProject: projectList ){
            Map<String, String> tempMap = new Map<String, String>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    
    /**
     * @description fetchSalesOrderId description
     * @param  unitId unitId description
     * @return        return description
     */
    @AuraEnabled
    public static sObject fetchSalesOrderId(string unitId){
        // ASF 936
        list<Resale_Offers__c> approvedOfferList = ResaleComponentService.getApprovedResaleOffersByUnitId(unitId);
        if(approvedOfferList.size() > 0){
            return null;
        }else{
            return ResaleComponentService.getAllSalesOrdersRelatedtoUnit(unitId);
        }
        
    }
    
    /**
     * @description Create Resale Offer records after Send Offer
     * @param  sObjMap    sObjMap description
     * @param  actionMode actionMode description
     * @return            return description
     */
    @AuraEnabled
    public static sObject updateSobject(Map<String, Object> sObjMap){
        String oppId = String.valueOf((object) sObjMap.get('Opportunity__c'));
        String unitId = String.valueOf((object) sObjMap.get('Unit__c'));
        String accountId = String.valueOf((object) sObjMap.get('Buyer_Account__c'));

        Resale_Offers__c thisOffer = new Resale_Offers__c();
        List<Unit__c> unitUpdateList = new List<Unit__c>();

        if(!String.isBlank(oppId) && !String.isBlank(unitId) && !String.isBlank(accountId)){
            //if existing offer is present for this seller and unit combo
            if(checkExistingOffer(unitId, accountId)){
                throw new AuraHandledException('An offer for this Buyer and Unit is already present.');
            }else{
                thisOffer.Unit__c = String.valueOf((object) sObjMap.get('Unit__c'));
                thisOffer.Opportunity__c = String.valueOf((object) sObjMap.get('Opportunity__c'));
                String commentString = String.valueOf((object) sObjMap.get('Comments__c'));
                thisOffer.Comments__c = commentString.length() > 100000 ? commentString.substring(0, 100000) : commentString;
                thisOffer.Offer_Price__c = Decimal.valueOf(String.valueOf((object) sObjMap.get('Offer_Price__c')));
                thisOffer.Status__c = 'Sent for Approval';
                thisOffer.Case__c = String.valueOf((object) sObjMap.get('Case__c'));
                thisOffer.Sales_Order__c = String.valueOf((object) sObjMap.get('Sales_Order__c'));
                thisOffer.Buyer_Account__c = String.valueOf((object) sObjMap.get('Buyer_Account__c'));
                thisOffer.BuyerEmail__c = String.valueOf((object) sObjMap.get('BuyerEmail__c'));
                thisOffer.BuyerPhone__c = String.valueOf((object) sObjMap.get('BuyerPhone__c'));
                thisOffer.Seller_Account__c = String.valueOf((object) sObjMap.get('Seller_Account__c'));
                thisOffer.SellerEmail__c = String.valueOf((object) sObjMap.get('SellerEmail__c'));
                thisOffer.SellerPhone__c = String.valueOf((object) sObjMap.get('SellerPhone__c'));
                //since sales order can be blank on opp, get it from unit
                if(thisOffer.Unit__c != null){
                    Unit__c thisUnit = [SELECT Id, RelatedSalesOrder__r.Account__c, ResaleStatus__c FROM Unit__c WHERE Id =: thisOffer.Unit__c LIMIT 1];
                    if(thisOffer.Seller_Account__c == null){
                        thisOffer.Seller_Account__c = thisUnit.RelatedSalesOrder__r.Account__c;
                    }
                    thisUnit.ResaleStatus__c = ResaleConstants.UNIT_RESALESTATUS_OFFER_PROGRESS;
                    unitUpdateList.add(thisUnit);
                }
                insert thisOffer;
                if(unitUpdateList.size() > 0){
                    update unitUpdateList;
                }
                //ASF-936 Harsh@Aldar
                //Commented by Harsh@Aldar 10/08 : We wont be using the email service, instead the RM would approve / reject the Resale Offers
                //Harsh@Aldar 14/08/2023 : We'll be sending the email but email service wont be used
                // sendEmailToSeller(thisOffer);
            }
        }
        return thisOffer;
    }

    //check existing offer, if present show error
    //Restrict one offer per buyer per unit
    //added by Harsh@Aldar 16/08/2023
    private static Boolean checkExistingOffer(String unitId, String accountId){
        Set<String> validOfferStrings = new Set<String>{'Accepted', 'Sent for Approval'};
        List<Resale_Offers__c> resaleOffersList = [SELECT Id FROM Resale_Offers__c 
                                                    WHERE Buyer_Account__c =: accountId 
                                                    AND UNIT__c =: unitId
                                                    AND Status__c IN: validOfferStrings];
        return (resaleOffersList != null && resaleOffersList.size() > 0) ? true : false;
    }

    //------------------------------------- RESALE OFFER EMAIL COMMENTED BY HARSH 10/08/2023------------------------------------------
    //------------------------------------- RESALE OFFER EMAIL UNCOMMENTED BY HARSH 14/08/2023------------------------------------------

    /**
     * @description sendEmailToSeller description ASF-936
     * @param  thisOffer   thisOffer description
     * @param  sellerEmail sellerEmail description
     */ 
    /*private static void sendEmailToSeller (Resale_Offers__c thisOffer){
        if(thisOffer != null){
            OrgWideEmailAddress orgWideAddress; 
            String emailTemplateId;
            String toEmailAddress;
            String relatedAccountId;
            String personContactId;
            try {
                emailTemplateId = Utilities.getEmailtemplateIdByName('ResaleOfferToSeller');
                orgWideAddress = [SELECT Id, Address 
                                FROM OrgWideEmailAddress 
                                WHERE DisplayName =: ResaleConstants.ALDAR_PROPERTIES_ORGWIDEEMAIL_NO_REPLY 
                                LIMIT 1];

                Resale_Offers__c thisOfferRecord = [SELECT Id, Opportunity__r.Id, 
                                                    // Opportunity__r.AccountId, 
                                                    // Opportunity__r.CustomerEmailFormula__c,
                                                    Seller_Account__c,
                                                    Seller_Account__r.PersonEmail
                                                    FROM Resale_Offers__c 
                                                    WHERE Id =: thisOffer.Id 
                                                    LIMIT 1];
                
                toEmailAddress = thisOfferRecord.Seller_Account__r.PersonEmail;
                relatedAccountId = thisOfferRecord.Seller_Account__c;

                Account accRecord = [SELECT PersonContactId 
                                     FROM Account 
                                     WHERE Id =: relatedAccountId 
                                     LIMIT 1];

                personContactId = accRecord.PersonContactId;
            } catch (Exception e) {
                LoggerService.save(LoggerService.addApexLog(e,'Send Resale Apporoval Email to the Seller','ResaleComponentService','sendEmailToSeller'));
            }
            
            if(orgWideAddress != null && toEmailAddress != null && personContactId != null && emailTemplateId != null){
                Messaging.SingleEmailMessage thisEmail = new Messaging.SingleEmailMessage();

                thisEmail = Utilities.getEmailInstance(personContactId,//thisOffer.Id, //sobject Id
                                                       emailTemplateId, //template Id
                                                       thisOffer.Id, //what Id
                                                       new List<String>{toEmailAddress}, //List<String> recepients
                                                       null, //List<String> bccRecipient
                                                       null, //List<String> ccRecipients
                                                       null,//'Potential Offer for Your Property: Approval/Rejection Request', //String emailSubject
                                                       null, //String body
                                                       null, //String htmlBody
                                                       null, //List<Messaging.EmailFileAttachment> fileAttachments
                                                       orgWideAddress.Id); //string orgWideEmailAddressID

                thisEmail.setSaveAsActivity(true);
                thisEmail.setReplyTo('resale_offer@b8g8so0ym5c6whkany7oqmd7j69wz68lyabwcvsxd4pu0g44x.2z-5woreaa.cs119.apex.sandbox.salesforce.com');
                System.debug('####thisEmail: '+thisEmail);
                Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{thisEmail});
            }
            
        }
    }*/

    @AuraEnabled
    public static list<Resale_Offers__c> fetchResaleData(string unitId){
        
        list<Resale_Offers__c> sObj = new list<sObject>();
        sObj = [select Id ,Status__c,Opportunity__c,Opportunity__r.name,Unit__r.name,Comments__c, CreatedDate, Offer_Price__c, CurrencyISOCode from Resale_Offers__c where Unit__c =: UnitId ORDER BY CreatedDate DESC];
        return sObj;
    }

    /**
    * UnitWrapper 
    *
    * Wrapper class used to render the Unit list on the OpportunityUnitSearch Screen
    */
    public with sharing class UnitWrapper{
        @AuraEnabled
        public list<map<String,string>> propertyUsageList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitTypesSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitModelSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> floorNumberSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitBedRoomsSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<map<String,string>> unitViewSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
        @AuraEnabled
        public list<UnitDetilsWrapper> unitDetailList=new list<UnitDetilsWrapper>();
        public UnitWrapper(list<Unit__c> unitData){
            set<String> propertyUsageSet=new Set<String>();
            set<String> unitTypesSet=new Set<String>();
            set<String> unitModelSet=new Set<String>();
            set<String> floorNumberSet=new Set<String>();
            set<String> unitBedRoomsSet=new Set<String>();
            set<String> unitViewSet=new Set<String>();
           
            for(Unit__c tempUnit : unitData){
                if(tempUnit.PropertyUsage__c !=null ){
                    propertyUsageSet.add(tempUnit.PropertyUsage__c );
                }
                if(tempUnit.UnitType__c !=null ){
                    unitTypesSet.add(tempUnit.UnitType__c );
                }
                if(tempUnit.UnitModel__c !=null ){
                    unitModelSet.add(tempUnit.UnitModel__c );
                }
                if(tempUnit.FloorNumber__c !=null ){
                    floorNumberSet.add(tempUnit.FloorNumber__c );
                }
                if(tempUnit.NumberOfBedrooms__c !=null ){
                    unitBedRoomsSet.add(String.ValueOf(tempUnit.NumberOfBedrooms__c ));
                }
                if(tempUnit.UnitView__c !=null ){
                    unitViewSet.add(tempUnit.UnitView__c );
                } 
                unitDetailList.add( new UnitDetilsWrapper(tempUnit) );
    
            }
            List<String> sortedPropertyUsageSet = new List<String>(propertyUsageSet);
            sortedPropertyUsageSet.sort();
            for(String tempS : sortedPropertyUsageSet){
                propertyUsageList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitTypesSet = new List<String>(unitTypesSet);
            sortedunitTypesSet.sort();
            for(String tempS : sortedunitTypesSet){
                unitTypesSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitModelSet = new List<String>(unitModelSet);
            sortedunitModelSet.sort();
            for(String tempS : sortedunitModelSet){
                unitModelSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedfloorNumberSet = new List<String>(floorNumberSet);
            sortedfloorNumberSet.sort();
            for(String tempS : sortedfloorNumberSet){
                floorNumberSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitBedRoomsSet = new List<String>(unitBedRoomsSet);
            sortedunitBedRoomsSet.sort();
            for(String tempS :sortedunitBedRoomsSet){
                unitBedRoomsSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitViewSet = new List<String>(unitViewSet);
            sortedunitViewSet.sort();
            for(String tempS : sortedunitViewSet){
                unitViewSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
        }
    
    }
    
    /**
    * UnitDetilsWrapper 
    *
    * Wrapper class used to render the Unit details on the OpportunityUnitSearch Screen
    */
    public with sharing class UnitDetilsWrapper{
        @AuraEnabled
        public boolean isSelected; 
        @AuraEnabled
        public Unit__c unitDetails;
        public UnitDetilsWrapper(Unit__c tempUnit){
            isSelected=false;
            unitDetails=tempUnit;
        }
    }

    /**
     * Developed by Harsh@Aldar 08Jun23 ASF-924
     */
    public with sharing class ResaleUnitInfoWrap{
        @AuraEnabled
        public String buildingName;
        @AuraEnabled
        public String projectName;
        @AuraEnabled
        public String buildingId;
        @AuraEnabled
        public String projectId;

        public ResaleUnitInfoWrap(Unit__c thisUnit){
            buildingName = thisUnit.BuildingSectionName__r.Name;
            projectName = thisUnit.Project__r.Name;
            buildingId = thisUnit.BuildingSectionName__c;
            projectId = thisUnit.Project__c;
        }
    }

}