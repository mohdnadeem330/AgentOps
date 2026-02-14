@RestResource (urlMapping = '/getPromotions')
global with sharing class BP_GetPromotions extends BP_BaseRestResource{

@HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            
            String requestBody = RestContext.request.requestBody.toString();   
             
           
            if(!String.isEmpty(requestBody)){   
                BP_GetPromotions service = new BP_GetPromotions ();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            String unitId = (String) requestBodyData.get('unitId');
            String opportunityOrLedId = (String) requestBodyData.get('opportunityOrLedId');
      
           	//List<Map<String,String>> listPromotions = execute(unitId, opportunityOrLedId);
           	List<ResponseWrapper> listWrapper = execute(unitId, opportunityOrLedId);
            
            if(listWrapper != null && !listWrapper.isEmpty()){
           		return new ApiResponse(true, 200, 'Offer and Promotions are fetched successfully', listWrapper);
            }else{
            	return new ApiResponse(true, 200, 'NO Offer and Promotions related with this Unit/Project', listWrapper);
            }
        } catch (Exception e) {
            return new ApiResponse(false, 400,'Failed to fetch Offer and Promotions: ' + e.getLineNumber(), null);
        }
    }

    private List<ResponseWrapper> execute(String unitId, Id opportunityOrLedId){
        Map<Id, List<OffersPromotions__c>> buildingOrProjectToOfferMap = new Map<Id, List<OffersPromotions__c>>();
        List<Map<String,String>> availableOffers = new List<Map<String,String>>();
        Map<Id,OfferLines__c> offerLineMap = new Map<Id,OfferLines__c>();
        List<Map<String,String>> availableWithMemoOffers = new List<Map<String,String>>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        Map<Id,Lead> leadMap = new Map<Id,Lead>();
        Boolean hasLead = false;
        Boolean hasOpportunity = false;
        Decimal totalOfAllUnitSalesPrice = 0;
		
        User loggedInUser = Utilities.getLoggedInUserDetail();
        String userProfileName = loggedInUser.ProfileName__c;
        if(Test.isRunningTest()){
            userProfileName = Constants.AGENCY_PROFILE;
        }
        
        //Decide Lead or Opportunity
        if(opportunityOrLedId!=null){
            if(opportunityOrLedId.getsobjecttype() == Lead.sobjecttype){
                hasLead = true;
            }else if(opportunityOrLedId.getsobjecttype() == Opportunity.sobjecttype){
                hasOpportunity = true;
            }
        }
        
        //Get Opportunity/Lead Details
        if(hasOpportunity){
            opportunityMap = OpportunityService.getOpportunityDetailsMapbyId(opportunityOrLedId);
        }else if(hasLead){
            leadMap = LeadService.getLeadDetailsMapbyId(opportunityOrLedId);
        }

        //String recordId = '';
        //Unit__c unitRecord = [SELECT ID,Project__c  FROM Unit__c WHERE Id = : unitId];

        List<Unit__c> allUnitsData = UnitServiceWithoutSharing.getAllUnitsById(new Set<Id>{unitId} );
        for(Unit__c tempUnitRec :  allUnitsData){

            totalOfAllUnitSalesPrice = (totalOfAllUnitSalesPrice + tempUnitRec.SellingPrice__c).setScale(2);
            if(tempUnitRec.BuildingSectionName__c != null){
                // buildingToPaymentPlanIdsMap.put(tempUnitRec.BuildingSectionName__c,new set<Id>());
                buildingOrProjectToOfferMap.put(tempUnitRec.BuildingSectionName__c,new list<OffersPromotions__c>());
            }
            if(tempUnitRec.Project__c!=null){
                buildingOrProjectToOfferMap.put(tempUnitRec.Project__c,new list<OffersPromotions__c>());
            }
        }

        Map<Id, OffersPromotions__c> offersMap = new map<Id, OffersPromotions__c>(OffersPromotionsService.getActiveOffersAndPromotions(buildingOrProjectToOfferMap.keySet(), buildingOrProjectToOfferMap.keySet()));
        
        for(OffersPromotions__c tempOfferRec : offersMap.values()){
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.BuildingSectionName__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.BuildingSectionName__c).add(tempOfferRec);
            }
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.Project__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.Project__c).add(tempOfferRec);
            }
        }


        if(allUnitsData[0].Project__c!=null && buildingOrProjectToOfferMap.containsKey(allUnitsData[0].Project__c) ){
                
            for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(allUnitsData[0].Project__c) ){
                
                if(tempOfferRec.BuildingSectionName__c == null && allUnitsData[0].Project__c == tempOfferRec.Project__c ){
                    if (userProfileName.contains(Constants.AGENCY_PROFILE)) {
                        if (tempOfferRec.BrokerPortalFlag__c == true ) {

                            availableOffers.add(new map<String, String>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    } else if (tempOfferRec.BookingMemo__c == null ) {
                        availableOffers.add(new Map<String,String>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                    }
                    if (tempOfferRec.BookingMemo__c !=null ) {
                        if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == allUnitsData[0].Id) {
                            availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }else{
                        availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                    }
                }

            }
        }

        if(allUnitsData[0].BuildingSectionName__c!=null && buildingOrProjectToOfferMap.containsKey(allUnitsData[0].BuildingSectionName__c) ){
            for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(allUnitsData[0].BuildingSectionName__c) ){
                if(allUnitsData[0].BuildingSectionName__c == tempOfferRec.BuildingSectionName__c ){
                    if (userProfileName.contains(Constants.AGENCY_PROFILE)) {
                        if (tempOfferRec.BrokerPortalFlag__c == true ) { 
                            availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }else if (tempOfferRec.BookingMemo__c==null ) {
                        availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                    }
                    if (tempOfferRec.BookingMemo__c != null) {                
                        if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == allUnitsData[0].Id) {
                            availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }else{
                        availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                    }
                }
            }
        }
        
        List<OfferLines__c> listOffers = new List<OfferLines__c>();
        
        for(Id ofrMap : offersMap.keySet()){
            listOffers.addAll(offersMap.get(ofrMap).Offers_Lines__r);
        }
        
        List<OfferLines__c> allApplicableOfferLines = SalesOfferUtility.getApplicableOfferLines(
            																listOffers,
            																allUnitsData[0],
                                                                            opportunityMap.size()> 0 ? opportunityMap.values()[0] : new Opportunity(),
                                                                            leadMap.size() > 0 ? leadMap.values()[0] : new Lead(),
                                                                            allUnitsData.size(), 
                                                                            totalOfAllUnitSalesPrice );    
        
        if(allApplicableOfferLines != null && !allApplicableOfferLines.isEmpty()){
        	Boolean isDirectPresent = false;
            Map<String, String> applicableOffersByCustomerType = new Map<String, String>();
            for(OfferLines__c oli : allApplicableOfferLines ){
                if(oli.CustomerType__c != null && oli.OfferType__c != null){
                    applicableOffersByCustomerType.put(oli.OfferType__c,oli.CustomerType__c);
                }
                if(oli.AgentType__c != null && oli.AgentType__c == System.Label.Direct){
                    isDirectPresent = true;
                }
            }
         
            List<OfferLines__c> tempOfferLineList = new List<OfferLines__c>();
            if(isDirectPresent && applicableOffersByCustomerType.containsKey(System.Label.Rebate)){
                Boolean isOtherRebatePresent = false;
                List<String> customerTypeFromLabel = System.Label.OfferCustomerTypes.split(',');
                if(customerTypeFromLabel != null){
                    for(String type : customerTypeFromLabel){
                        if(applicableOffersByCustomerType.get(System.Label.Rebate).equalsIgnoreCase(type.trim())){
                            isOtherRebatePresent = true;
                        }
                    }
                }
                if(isOtherRebatePresent){
                    for(OfferLines__c oli : allApplicableOfferLines ){
                        if(oli.OfferType__c == System.Label.Rebate && oli.AgentType__c == System.Label.Direct){
                            continue;    
                        }else{
                            tempOfferLineList.add(oli);  
                        }
                    }
                }else{
                    tempOfferLineList = allApplicableOfferLines;
                }
            }else{ 
                tempOfferLineList = allApplicableOfferLines;
            }
            allApplicableOfferLines = tempOfferLineList;
            //offerLineMap = new Map<Id, OfferLines__c>(allApplicableOfferLines);
        
        }
        
        Map<Id, List<OfferLines__c>> mapOfferIdToListOfferLines = new Map<Id, List<OfferLines__c>>();
        for(OfferLines__c eachOfferLine : allApplicableOfferLines){
            if(!mapOfferIdToListOfferLines.containsKey(eachOfferLine.OfferName__c)){
                mapOfferIdToListOfferLines.put(eachOfferLine.OfferName__c, new List<OfferLines__c>{eachOfferLine});
            }else{
                List<OfferLines__c> tempListofferline = mapOfferIdToListOfferLines.get(eachOfferLine.OfferName__c);
                tempListofferline.add(eachOfferLine);
                mapOfferIdToListOfferLines.put(eachOfferLine.OfferName__c, tempListofferline);
            }
        }
        
        List<ResponseWrapper> listWrapperToReturn = new  List<ResponseWrapper>();
        for(Map<String,String> eachMap : availableOffers){
            ResponseWrapper response = new ResponseWrapper();
            response.offerAndPromotion = eachMap;
            
            if(mapOfferIdToListOfferLines.containsKey(eachMap.get('value'))){
           		response.allApplicableOfferLines = mapOfferIdToListOfferLines.get(eachMap.get('value'));
            }else{
                response.allApplicableOfferLines = new List<OfferLines__c>();
            }
            listWrapperToReturn.add(response);
        }
        
        
        // salesOfferObj.applicableOfferLinesCalculated = allApplicableOfferLines;
        //ResponseWrapper response = new ResponseWrapper();
        //response.allApplicableOfferLines = allApplicableOfferLines != null ? allApplicableOfferLines : new List<OfferLines__c>();
        //response.availableOffers = availableOffers;
        //response.availableWithMemoOffers = availableWithMemoOffers;
   
        return listWrapperToReturn;
    }
    
    public class ResponseWrapper {
        public Map<String,String> offerAndPromotion {set; get;}
        public List<OfferLines__c> allApplicableOfferLines {set; get;} 
    }
}