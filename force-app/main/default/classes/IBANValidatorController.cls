/*
    * IBANValidatorController.cls
    * FIN-51 IBAN Validation - ADCB - Cancellation SR
    * Created on: 2025-05-06
    * Author: Anuroop Vipin
    * Description: Controller class for ibanValidationForSR lwc component, used for validating IBAN numbers.
*/
public with sharing class IBANValidatorController {

    @AuraEnabled
    public static Map<String, Object> getServiceRequest(String srId){
        Map<String, Object> returnMap = new Map<String, Object>();
        returnMap.put('success', false);
        returnMap.put('error', false);
        try {
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
            returnMap.put('sr', serviceRequest);
            returnMap.put('success', true);            
        } catch (Exception ex) {returnMap.put('error', true);returnMap.put('message', ex.getMessage());}

        return returnMap;
    }

    
    @AuraEnabled
    public static Map<String, Object> updateServiceRequest(String srId, String iban){
        Map<String, Object> returnMap = new Map<String, Object>();
        returnMap.put('success', false);
        returnMap.put('error', false);
        try {
            HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c(Id = srId,
                                                                IBANNumber__c = iban,
                                                                IBANValidated__c = true);
            update serviceRequest;
            returnMap.put('success', true);            
        } catch (Exception ex) {returnMap.put('error', true);returnMap.put('message', ex.getMessage());}

        return returnMap;
    }


    @AuraEnabled
    public static Map<String,Object> validateIBANCallout(String iban){
        Map<String,Object> returnMap = new Map<String,Object>();
        returnMap.put('success',false);
        try {
            String muleRes = '';
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('IBANValidationADCB');
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type','application/json');
            request.setHeader('client_secret',mulesoftAPI.APIKey__c);
            request.setHeader('client_id',mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            if(endPointURL.right(1)=='/'){
                request.setEndpoint(endPointURL+iban);
            }else{
                request.setEndpoint(endPointURL+'/'+iban);
            }
            request.setMethod(mulesoftAPI.Method__c);
            //System.debug('**Request Body**'+requestBody);
            //request.setBody(requestBody);

            HttpResponse response = http.send(request);
            
            muleRes = response.getBody();
            system.debug(muleRes);
            IBANValidationResponse validationResponse = (IBANValidationResponse)System.JSON.deserialize(muleRes, IBANValidationResponse.class);
            system.debug(validationResponse);
            system.debug(validationResponse.Data);
            if(validationResponse.Data!=null&&validationResponse.Data.IBANAccountTitle!=null){
                returnMap.put('success',true);
                returnMap.put('IBANAccountTitle',validationResponse.Data.IBANAccountTitle);
                returnMap.put('Restrict_Cancellation_SR_On_IBAN_Validation',System.Label.Restrict_Cancellation_SR_On_IBAN_Validation);//FIN-74 - Anuroop Vipin
                returnMap.put('Restrict_DD_Request_On_IBAN_Validation',System.Label.Restrict_DD_Request_On_IBAN_Validation);//FIN-74 - Anuroop Vipin
            }            

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return returnMap;
    }

    public class IBANValidationResponse {
        public clsData Data;
    }

    public class clsData{
        public String IBANAccountNumber;
        public String IBANAccountTitle;
    }

}