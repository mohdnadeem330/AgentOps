public with sharing class DarnaServices {
    public static List<String> dontSkipWarning;
        static{
            dontSkipWarning  = System.label.Don_tSkipDarnaWarning.contains(',')?System.label.Don_tSkipDarnaWarning.split(','): new List<String>{System.label.Don_tSkipDarnaWarning};
        }
    //--- Callout method used with all DARNA callouts
    public static HttpResponse DARNACalloutHelper(String JSONBody, String darnaApiName, String authorizationHeaderString, String extraData) {
        
        //adding to get logger for request and response for DARNA
        List<Logger__c> loggerList = new List<Logger__c>();
        
        APISetting__mdt  darnaApiDetails = Utilities.getServiceDetails(darnaApiName);
        
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = darnaApiDetails.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = darnaApiDetails.ProductionURL__c ; 
        }
        
        if(darnaApiName.equals(Constants.DARNA_USER_POINTS) && extraData != null && extraData != ''){
            endPointURL = endPointURL.replace('{membership_number}', extraData);
            
        } else if(darnaApiName.equals(Constants.CAPILLARY_ACCESS_TOKEN)){
            AccessTokenRequestModel accessTokenModel = new AccessTokenRequestModel();
            
            //For Capillary - In Use
            accessTokenModel.key = darnaApiDetails.APIKey__c;
            accessTokenModel.secret = darnaApiDetails.APIId__c;
            
            JSONBody = json.serialize(accessTokenModel);
            
            //For DARNA - Deprecated
            /*Blob authorizationHeader = Blob.valueOf(darnaApiDetails.UserName__c + ':' + darnaApiDetails.Password__c);
authorizationHeaderString = 'Basic ' + EncodingUtil.base64Encode(authorizationHeader);*/
            
        } 
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setBody(JSONBody);
        
        Map<String,String> headers = darnaApiDetails.Headers__c == null ? null : (Map<String,String>)JSON.deserialize(darnaApiDetails.Headers__c, Map<String,String>.class);
        
        for(String headerName : headers.keySet()){
            request.setHeader(headerName, headers.get(headerName));
        }
        
        request.setEndpoint(endPointURL);
        request.setMethod(darnaApiDetails.Method__c);
        request.setTimeout(120000);
        if(string.isNotBlank(authorizationHeaderString)) {
            request.setHeader('Authorization', authorizationHeaderString);
        }
        
        HttpResponse response = http.send(request);
        /*loggerList.add(LoggerService.logSuccessResponse('DARNACalloutHelper', 'calloutService', String.valueof(darnaApiName), String.valueof(JSONBody), String.valueof(response.getBody()), '5002500000LAAIYAA5'));
if(!loggerList.isempty()){
insert loggerList;
}*/
        return response;
    }
    
    /*
*  retrieve the member profile
* 
*/
    
    
    @AuraEnabled
    public static String getAccessTokenAPI() {
        //For DARNA - Deprecated
        //HttpResponse response = DARNACalloutHelper('', Constants.DARNA_ACCESS_TOKEN, '', '');
        //For CAPILLARY - In Use
        HttpResponse response = DARNACalloutHelper('', Constants.CAPILLARY_ACCESS_TOKEN, '', '');
        
        system.debug(response);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        
        JSONParser parser = JSON.createParser(response.getBody());
        JSONParser dataParser;
        String newAccessToken='';
        
        while(parser.nextToken() != null){
            if('data'.equals(parser.getText())){
                dataParser = JSON.createParser(response.getBody());
                system.debug('dataParser: '+dataParser);
                break;
            }
        }
        
        while(dataParser.nextToken() != null){
            //For DARNA - Deprecated
            /*if('client_access_token'.equals(dataParser.getText())){
dataParser.nextToken();
newAccessToken = dataParser.getText();
}*/
            //For CAPILLARY - In Use
            if('accessToken'.equals(dataParser.getText())){
                dataParser.nextToken();
                newAccessToken = dataParser.getText();
            }       
        }
        return newAccessToken;
    }
    
    /*
*  capillaryVerifyCustomerAndPointsBalance
* 
*/
    //@AuraEnabled
    @future(Callout=true)
    public static void addPointsAPI(String reqBody,String projectConceptId) {
        // try{
        System.debug('projectConceptId:'+projectConceptId);
        //Code used for CAPILLARY(In-Use)
        APISetting__mdt addPoints = Utilities.getServiceDetails(Constants.CAPILLARY_ADD_POINT);
        
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = addPoints.SandboxURL__c;
        if(!org.IsSandbox) {
            endPointURL = addPoints.ProductionURL__c;
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setBody(reqBody);
        
        Map<String, String> headers = addPoints.Headers__c == null ? null : (Map<String, String>)JSON.deserialize(addPoints.Headers__c, Map<String,String>.class);
        for(String headerName: headers.keySet()) {
            request.setHeader(headerName, headers.get(headerName));
        }
        String accessToken = 'access';
        if(!Test.isRunningTest()){
            accessToken = getAccessTokenAPI();
        }
        request.setEndpoint(endPointURL);
        request.setMethod(addPoints.Method__c);
        request.setTimeout(120000);
        request.setHeader('X-CAP-API-OAUTH-TOKEN', accessToken);
        request.setHeader('X-CAP-API-ATTRIBUTION-ENTITY-TYPE', 'STORE_CODE');
        request.setHeader('X-CAP-API-ATTRIBUTION-ENTITY-CODE', projectConceptId <> null ? projectConceptId.toLowerCase():null);
        HttpResponse response = http.send(request);
        System.debug('response:'+response.getBody());
        if(response.getStatusCode() == Constants.SUCCESS_CODE_200) {
            
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            
            if(responseMap.containsKey('response') && responseMap.get('response') <> null) {
              
                String resultDataSet = JSON.serialize(responseMap.get('response'));
                system.debug('resultDataSet>>>' + JSON.serializePretty(responseMap.get('response')));
                // List<InstallmentLines__c> installmentsListToUpdate = new  List<InstallmentLines__c>();
                Map<Id,InstallmentLines__c> installmentsListToUpdateMap = new Map<Id,InstallmentLines__c>(); //****** newly added *****//
                Map<Id,ReceiptAllocation__c> rcptAllocationsListToUpdateMap = new Map<Id,ReceiptAllocation__c>(); //******** Newly Added ****//
                //List<ReceiptAllocation__c> rcptAllocationsListToUpdate = new  List<ReceiptAllocation__c>();
                Map<Id,Decimal> rcptAcknowledgementIdWithAmoutAwardedMap = new Map<Id,Decimal>();
                List<Logger__c> errorLogsToInsert = new List<Logger__c>();
                Set<Id> installmentLineIdSet = new Set<Id>();
                List<CapillaryAddPointsResponseModel> capillaryAddPointsResponseList = (List<CapillaryAddPointsResponseModel>)JSON.deserialize(resultDataSet, List<CapillaryAddPointsResponseModel>.class);
                for(CapillaryAddPointsResponseModel capillaryAddPointsResponse : capillaryAddPointsResponseList){
                    if(capillaryAddPointsResponse.result <> null && capillaryAddPointsResponse.result.sideEffects <> null && !capillaryAddPointsResponse.result.sideEffects.isEmpty()) {  //************ Added Empty Check *****//
                      // capillaryAddPointsResponse.result.billNumber = capillaryAddPointsResponse.result.grossAmount;
                        Id rcptAllocationIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringBefore('_');
                        Id rcptAcknowledgementIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringBetween('_');
                        Id installmentLineIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringAfterLast('_');
                        ReceiptAllocation__c receipt = new ReceiptAllocation__c(Id = rcptAllocationIdFromResponse);
                        receipt.IsReceiptAllocationForDarna__c = true;
                        receipt.DarnaErrorWarning__c = null;
                        //rcptAllocationsListToUpdate.add(receipt);
                        installmentLineIdSet.add(installmentLineIdFromResponse);
                        if(!capillaryAddPointsResponse.result.sideEffects.isEmpty()){
                            receipt.DarnaPointAllocated__c = capillaryAddPointsResponse.result.sideEffects[0].awardedPoints;
                            //installmentLine.DarnaPointAllocated__c = installmentLine.DarnaPointAllocated__c != null ? installmentLine.DarnaPointAllocated__c + capillaryAddPointsResponse.result.sideEffects[0].awardedPoints : capillaryAddPointsResponse.result.sideEffects[0].awardedPoints;
                        }
                        rcptAllocationsListToUpdateMap.put(receipt.Id,receipt);
                        if(rcptAcknowledgementIdWithAmoutAwardedMap.containsKey(rcptAcknowledgementIdFromResponse)){
                            rcptAcknowledgementIdWithAmoutAwardedMap.put(rcptAcknowledgementIdFromResponse,rcptAcknowledgementIdWithAmoutAwardedMap.get(rcptAcknowledgementIdFromResponse) + capillaryAddPointsResponse.result.billAmount);
                        }
                        else{
                            rcptAcknowledgementIdWithAmoutAwardedMap.put(rcptAcknowledgementIdFromResponse,capillaryAddPointsResponse.result.billAmount);
                        }
                    }
                    if(capillaryAddPointsResponse.result <> null && capillaryAddPointsResponse.warnings <> null && !capillaryAddPointsResponse.warnings.isEmpty() && capillaryAddPointsResponse.result.billNumber <> null){
                        Id rcptAllocationIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringBefore('_');
                        Id rcptAcknowledgementIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringBetween('_');
                        
                        ReceiptAllocation__c receipt = new ReceiptAllocation__c(Id = rcptAllocationIdFromResponse);
                        receipt.IsReceiptAllocationForDarna__c = true;
                        receipt.DarnaErrorWarning__c = String.valueOf(capillaryAddPointsResponse.warnings);
                        receipt.Don_tSkipDarnaWarning__c = checkValidWarning(receipt.DarnaErrorWarning__c); //receipt.DarnaErrorWarning__c <> null && dontSkipWarning.contains(receipt.DarnaErrorWarning__c.trim())?true:false;
                        //rcptAllocationsListToUpdate.add(receipt);
                        rcptAllocationsListToUpdateMap.put(receipt.Id,receipt);
                        
                        if(rcptAcknowledgementIdWithAmoutAwardedMap.containsKey(rcptAcknowledgementIdFromResponse)){
                            rcptAcknowledgementIdWithAmoutAwardedMap.put(rcptAcknowledgementIdFromResponse,rcptAcknowledgementIdWithAmoutAwardedMap.get(rcptAcknowledgementIdFromResponse) + capillaryAddPointsResponse.result.billAmount);
                        }
                        else{
                            rcptAcknowledgementIdWithAmoutAwardedMap.put(rcptAcknowledgementIdFromResponse,capillaryAddPointsResponse.result.billAmount);
                        }
                    }
                    if(capillaryAddPointsResponse.result <> null && capillaryAddPointsResponse.errors <> null && !capillaryAddPointsResponse.errors.isEmpty() && capillaryAddPointsResponse.result.billNumber <> null){
                        Id rcptAllocationIdFromResponse = capillaryAddPointsResponse.result.billNumber.substringBefore('_');
                        ReceiptAllocation__c receipt = new ReceiptAllocation__c(Id = rcptAllocationIdFromResponse);
                        receipt.DarnaErrorWarning__c = String.valueOf(capillaryAddPointsResponse.errors);
                        receipt.Don_tSkipDarnaWarning__c = checkValidWarning(receipt.DarnaErrorWarning__c); //receipt.DarnaErrorWarning__c <> null && dontSkipWarning.contains(receipt.DarnaErrorWarning__c.trim())?true:false;
                        //rcptAllocationsListToUpdate.add(receipt);
                        rcptAllocationsListToUpdateMap.put(receipt.Id,receipt);
                        
                        Logger__c newErrLog = new Logger__c();
                        newErrLog.Message__c = JSON.serialize(capillaryAddPointsResponse);
                        newErrLog.ExceptionMessage__c = JSON.serialize(capillaryAddPointsResponse.errors);
                        newErrLog.ExecutingProcessName__c = 'addPointsAPI';
                        newErrLog.ClassName__c = 'DarnaServices';
                        newErrLog.MethodName__c = 'addPointsAPI';
                        newErrLog.LogType__c = 'Callout Log';
                        errorLogsToInsert.add(newErrLog);
                    }
                }
                if(!rcptAllocationsListToUpdateMap.values().isEmpty()){
                   // System.debug('rcptAllocationsListToUpdate:'+rcptAllocationsListToUpdateMap);
                    //update rcptAllocationsListToUpdate;
                    update rcptAllocationsListToUpdateMap.values();
                }
                
                if(!installmentLineIdSet.isEmpty()){
                    Map<Id,decimal> totalDarnaPoints = new Map<Id,decimal>();
                    Map<Id,decimal> totalAmountMap = new Map<Id,decimal>();
                    List<InstallmentLines__c> installmentLineUpd = new List<InstallmentLines__c>();
                    for(ReceiptAllocation__c rAlloc:[SELECT Id,DarnaPointAllocated__c,InstallmentLine__c,AmountApplied__c FROM ReceiptAllocation__c WHERE InstallmentLine__c IN:installmentLineIdSet AND DarnaPointAllocated__c!=null AND IsReceiptAllocationForDarna__c = true]){
                        if(totalDarnaPoints.containsKey(rAlloc.InstallmentLine__c)){
                            totalDarnaPoints.put(rAlloc.InstallmentLine__c,totalDarnaPoints.get(rAlloc.InstallmentLine__c)+rAlloc.DarnaPointAllocated__c);
                        }else{
                            totalDarnaPoints.put(rAlloc.InstallmentLine__c,rAlloc.DarnaPointAllocated__c);
                        }
                        
                        if(totalAmountMap.containsKey(rAlloc.InstallmentLine__c)){
                            totalAmountMap.put(rAlloc.InstallmentLine__c,totalAmountMap.get(rAlloc.InstallmentLine__c)+rAlloc.AmountApplied__c);
                        }else{
                            totalAmountMap.put(rAlloc.InstallmentLine__c,rAlloc.AmountApplied__c);
                        }
                    }
                    
                    for(Id inv: totalDarnaPoints.keySet()){
                        InstallmentLines__c invOBJ = new InstallmentLines__c();
                        invOBJ.Id = inv;
                        invOBJ.DarnaPointAllocated__c = totalDarnaPoints.get(inv);
                        invOBJ.DarnaAmountProcessed__c = totalAmountMap.get(inv);
                        installmentLineUpd.add(invOBJ);
                    }
                    if(!installmentLineUpd.isEmpty()){
                        update installmentLineUpd; 
                    }
                }
                if(!errorLogsToInsert.isEmpty()){
                    insert errorLogsToInsert;
                }
                List<ReceiptAcknowledgement__c> rcptAcknowledgmentListToUpdate = new List<ReceiptAcknowledgement__c>();
                Map<Id,ReceiptAcknowledgement__c> ReceiptAckMap = new Map<Id,ReceiptAcknowledgement__c>();
                for(ReceiptAcknowledgement__c rck:[SELECT Id,Amount__c,DarnaAmountProcessed__c,Installment_Amount__c FROM ReceiptAcknowledgement__c WHERE Id IN: rcptAcknowledgementIdWithAmoutAwardedMap.keySet()]){
                    ReceiptAckMap.put(rck.Id,rck);
                }
                for(Id eachRcptAckId : rcptAcknowledgementIdWithAmoutAwardedMap.keySet()){
                    Decimal currentAmtProcceessed = ReceiptAckMap.get(eachRcptAckId).DarnaAmountProcessed__c!=null?ReceiptAckMap.get(eachRcptAckId).DarnaAmountProcessed__c:0;
                    rcptAcknowledgmentListToUpdate.add(new ReceiptAcknowledgement__c(Id = eachRcptAckId,DarnaAmountProcessed__c = rcptAcknowledgementIdWithAmoutAwardedMap.get(eachRcptAckId)+currentAmtProcceessed,IsDarnaAmountProcessed__c = (rcptAcknowledgementIdWithAmoutAwardedMap.get(eachRcptAckId)+currentAmtProcceessed) == ReceiptAckMap.get(eachRcptAckId).Installment_Amount__c?true:false));
                }
                if(!rcptAcknowledgmentListToUpdate.isEmpty()){
                    update rcptAcknowledgmentListToUpdate;
                }
            }
        }
        else {
            // System.debug('Error Message>>>' + String.valueOf(responseMap.get('message')));
            // LoggerService.save(LoggerService.addApexServiceCalls('DarnaService', 'addPointsAPI', Constants.DARNA_ADD_POINT, reqBody, response.getBody(), null));
        }
        /*  }catch(Exception ex){
Logger__c newErrLog = new Logger__c();
newErrLog.Message__c = ex.getMessage();
newErrLog.ExceptionMessage__c = reqBody;
newErrLog.ExecutingProcessName__c = 'addPointsAPI';
newErrLog.ClassName__c = 'DarnaServices';
newErrLog.MethodName__c = 'addPointsAPI';
newErrLog.LogType__c = 'Callout Log';
insert newErrLog;
}*/
    }
    
    Class AccessTokenRequestModel {
        //For DARNA - Deprecated
        String key;
        String secret;
    }
    
    
    public Class AddPointsResponseModel {
        @AuraEnabled public String email;
        @AuraEnabled public String business_category;
        @AuraEnabled public String business_trigger;
        @AuraEnabled public String concept_id;
        @AuraEnabled public String earn_transaction_id;
        @AuraEnabled public String external_transaction_id;
        @AuraEnabled public String creation_date;
        @AuraEnabled public Decimal earned_points;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal earn_rate;
        @AuraEnabled public Decimal bonus_points;
    }
    
    public static String getSignature(String keyIv, String key, String data) {
        
        Blob encrypted = Crypto.encrypt('AES256', Blob.valueOf(key), Blob.valueOf(keyIv), Blob.valueOf(data));
        return EncodingUtil.base64Encode(encrypted);
    }
    public static boolean checkValidWarning(String message){
        if(message <> null){
            for(String s:dontSkipWarning){
                if(message.contains(s)){
                    return true;
                }
            }
        }
        return false;
    }
}