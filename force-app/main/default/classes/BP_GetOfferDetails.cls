@RestResource(urlMapping='/getOfferDetails')
global without sharing class BP_GetOfferDetails extends BP_BaseRestResource{
    
    @HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        // try {
        Map<String, String> params = RestContext.request.params;
       
        String requestBody = RestContext.request.requestBody.toString();   
        
        if(!String.isEmpty(requestBody)){   
            BP_GetOfferDetails service = new BP_GetOfferDetails();
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
        
        handler.finalize();
        
    }
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            SalesOfferUtility.SalesOfferDetails offerDetails = new SalesOfferUtility.SalesOfferDetails();
            String opportunityId = (String) requestBodyData.get('opportunityId');
            String currentUnit = (String) requestBodyData.get('currentUnit');
            String currentOffer = (String) requestBodyData.get('currentOffer');
            String otherUnits = (String) requestBodyData.get('otherUnits');
            String selectedPayments = (String) requestBodyData.get('selectedPayments');
            String multiPurposeAmount =  (String) requestBodyData.get('multiPurposeAmount');
            String selectedDesign = (String) requestBodyData.get('selectedDesign');
            String affectionPlan = (String) requestBodyData.get('affectionPlan');
            String PODSelection = (String) requestBodyData.get('PODSelection');
            String swimmingPoolSelection =(String) requestBodyData.get('swimmingPoolSelection');
            String marketingPlan = (String) requestBodyData.get('marketingPlan');
            
            
            if(currentUnit!=null && currentUnit!=''){
                list<SalesOfferUtility.SaleOfferInputParam> parameters = new list<SalesOfferUtility.SaleOfferInputParam>();
                
                //Other units
                if(otherUnits!=null && otherUnits!=''){ 
                    for(String str: otherUnits.split('\\|')){
                        if(str!=null){
                            SalesOfferUtility.SaleOfferInputParam tempParamObj = new SalesOfferUtility.SaleOfferInputParam();
                            tempParamObj.unitId = str;
                            tempParamObj.offerId = null;
                            tempParamObj.designId=null;
                            tempParamObj.selectedPayments = new list<Id>();
                            parameters.add(tempParamObj);
                        }
                    }
                }
                //Current Unit
                SalesOfferUtility.SaleOfferInputParam tempParamObj = new SalesOfferUtility.SaleOfferInputParam();
                tempParamObj.unitId = currentUnit;
                tempParamObj.offerId = (currentOffer!=null && currentOffer!='' )? currentOffer : null;
                tempParamObj.designId=(selectedDesign!=null && selectedDesign!='' )? selectedDesign : null;
                tempParamObj.selectedPayments = new list<Id>();
                
                tempParamObj.podiumSelection = (PODSelection !=null &&  PODSelection!='')? PODSelection : null;
               
                tempParamObj.swimmingPoolSelection = (swimmingPoolSelection !=null &&  swimmingPoolSelection!='')? swimmingPoolSelection : null;
                tempParamObj.multiPurposeAmountApplicable = (multiPurposeAmount !=null &&  multiPurposeAmount!='' && multiPurposeAmount.equalsIgnoreCase('true'))?true:false; 
            if(selectedPayments!=null && selectedPayments!='' ){
                    for(Id str: selectedPayments.split('\\|')){
                        if(str!=null){
                            tempParamObj.selectedPayments.add(str);
                        }
                    }
                }
                parameters.add(tempParamObj);
                offerDetails = OpportunityUnitSearchController.generateSalesOffer(parameters,opportunityId).get(currentUnit);
            }
            return new ApiResponse(true,  200,  'Offer Details are fetched',  offerDetails);
            
        } catch (Exception e) {
            return new ApiResponse(false, 400,'Failed to load Offer Details: ' + e.getMessage(), null);
        } 
    }
}