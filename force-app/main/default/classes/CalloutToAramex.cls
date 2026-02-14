public with sharing class CalloutToAramex {
    @future(callout = true)
    public static void calloutFutureService(String requestBody, Boolean processResponse, String processName){
        calloutService(requestBody, processResponse, processName);
    }
    
    public static String calloutService(String requestBody, Boolean processResponse, String processName){
        String aramexRes = '';
        try{
            ShipmentSetting__mdt aramexAPI = Utilities.getAramexDetails(processName);
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = aramexAPI.SandboxURL__c ;
            
            if(!org.IsSandbox){
                endPointURL = aramexAPI.ProductionURL__c ; 
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(aramexAPI.Method__c);
            System.debug('**Request Body**' + requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            aramexRes = response.getBody() ;
            System.debug('**Response Body**' + aramexRes);
            AramexResponeWrapper responseBody = parse(aramexRes);
            if(responseBody.HasErrors){
                AramexResponeWrapper.SResponse ship = responseBody.Shipments[0];
                ShipmentRequest__c sr = new ShipmentRequest__c();
                sr.Id = ship.Reference1;
                sr.SyncStatus__c = Constants.STATUS_FAILED;
                update sr;
                LoggerService.save(LoggerService.addApexServiceCalls('CalloutToAramex', 'calloutService', processName, requestBody, aramexRes, ship.Reference1));
            } else if (processName == Constants.ARAMEX_TRACk_SHIPMENTS_INTEGRATION) {
                return aramexRes;
            } else {
                processAramexResponse(responseBody, processName, processResponse);
            }
            return '';
        } catch(Exception e) {
            LoggerService.save(LoggerService.addApexServiceCallsLog(e, 'CalloutToAramex', 'calloutService', processName, requestBody, aramexRes));
            return '';
        }
    }

    public static void processAramexResponse(AramexResponeWrapper responseBody, String processName, Boolean processResponse) {
        List<AramexResponeWrapper.SResponse> Shipments = responseBody.Shipments;
        if (processResponse) {
            if (processName == Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION) {
                List<ShipmentRequest__c> srList = new List<ShipmentRequest__c>();
                for (AramexResponeWrapper.SResponse ship: Shipments) {
                    ShipmentRequest__c sr = new ShipmentRequest__c();
                    sr.Id = ship.Reference1;
                    sr.AWBNumber__c = ship.ID;
                    sr.SyncStatus__c = Constants.STATUS_SYNCED;

                    AramexResponeWrapper.SLResponse ShipmentLabel = ship.ShipmentLabel;
                    sr.LabelURL__c = ShipmentLabel.LabelURL;
                    srList.add(sr);
                }
                if (!srList.isEmpty()) {
                    update srList;
                }
            }
        }
    }

    public static AramexResponeWrapper parse(String json){
        return (AramexResponeWrapper)System.JSON.deserialize(json, AramexResponeWrapper.class);
    }
}