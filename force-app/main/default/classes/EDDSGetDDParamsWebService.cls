@RestResource (urlMapping = '/edds/getDDParamsForAccount')
global with sharing class EDDSGetDDParamsWebService {
    
    @HTTPPost
    global static void doPost(String relatedRecordId, List<String> accountIds, String journeyType){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            Boolean isError = false;
            String errorMessage = '';
            RestRequest req = RestContext.request;
            //validate enum value
            if(EDDSService.isValidJourneyType(journeyType)==false){
                isError = true;
                errorMessage += 'Provide a valid Journey Type. ';
            }else{
                if(EDDSService.isValidSalesforceIds(accountIds,'Account')==false) {
                    isError = true;
                    errorMessage += 'Provide valid Account Ids. ';
                }
                if(journeyType == EDDSService.JOURNEY_TYPE.NewSale.name()  || journeyType == EDDSService.JOURNEY_TYPE.OffPlanTransfer.name() /*|| journeyType == EDDSService.JOURNEY_TYPE.NewLeasing.name()*/){
                    if(EDDSService.isValidSalesforceId(relatedRecordId,'SalesOrder__c')==false) {
                        isError = true;
                        errorMessage += 'Provide a valid Sales Order Id. ';
                    }
                }else if(journeyType == EDDSService.JOURNEY_TYPE.NewLeasing.name()){
                    // TODO: Add validation for related record id
                    /*if(EDDSService.isValidSalesforceId(relatedRecordId,'Contract')==false) {
                        isError = true;
                        errorMessage += 'Provide a valid Contract Id. ';
                    }*/
                }else if(journeyType == EDDSService.JOURNEY_TYPE.Retail.name()){
                    // TODO: Add validation for related record id
                }
            }
            if(isError) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = errorMessage.trim();
                handler.setResponseStatusCode(Constants.STATUS_CODE_NOT_FOUND);
                handler.finalize();
                return;
            }
            handler.response.data = EDDSService.getDDParams(relatedRecordId, accountIds, journeyType);
            handler.response.success = true;
            handler.response.message = Constants.SUCCESS_MESSAGE;
            handler.finalize();
        } catch(Exception ex){handler.response.success = false;
                handler.setResponseStatusCode(Constants.STATUS_CODE_SYSTEM_ERROR);handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;handler.finalize(ex);}
    }
}