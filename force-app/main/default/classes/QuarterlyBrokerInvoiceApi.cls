/**********************************************************************************************************************
* Name               : QuarterlyBrokerInvoiceApi                                                       
* Description        : Controller to make ERP API call
* Usage              : ERP Mulesoft Integration                                               
* Created By         : Sanket Kumar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           sajkumar@aldar.com      10 April 2023   Initial Draft       
******************************************************************************************************************/
public class QuarterlyBrokerInvoiceApi {
    
    @InvocableMethod(label='Generate Invoice')
    public static void generateInvoice(List<QuarterlyBonusCommission__c> quarterlyBonusList){
        Id recordId = quarterlyBonusList[0].Id;
        generateInvoiceFromFlow(recordId);
    }
    
    @Future(callout=true)
    public static void generateInvoiceFromFlow(Id recordId){
        try{
            //Id recordId = quarterlyBonusList[0].Id;
            String reqBody = QuarterlyBrokerInvoiceRequest.generateJSONContent(recordId);
            System.debug(reqBody);
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Accept', 'application/json');
            headerConfiguration.put('Content-Type', 'application/json');
            
            HttpResponse response = QuarterlyBrokerInvoiceCalloutHelper(headerConfiguration, reqBody, 'brokerInvoice');
            system.debug('response '+response);
            system.debug('response.getBody() '+response.getBody());
            QuarterlyBrokerInvoiceResponse parsedResponse = (QuarterlyBrokerInvoiceResponse)JSON.deserialize(response.getBody(), QuarterlyBrokerInvoiceResponse.class);
            system.debug('parsedResponse '+parsedResponse);
            Map<Id,CommissionLineItem__c> mapOfSOIdWIthCLI = new Map<Id,CommissionLineItem__c>();
            List<CommissionLineItem__c> cliListToUpdate = new List<CommissionLineItem__c>();
            if(parsedResponse != null){
                for(CommissionLineItem__c cli : [SELECT 
                                                 Id,
                                                 SalesOrder__c,
                                                 ERPID__c,
                                                 ErpErrorMessage__c,
                                                 InvoiceNumber__c 
                                                 FROM CommissionLineItem__c 
                                                 WHERE QuarterlyBonusCommission__c = : recordId] ) {
                    mapOfSOIdWIthCLI.put(cli.SalesOrder__c,cli);
                }
                system.debug('parsedResponse.BonusInvRes '+parsedResponse.results.BonusInvRes);
                for(QuarterlyBrokerInvoiceResponse.BonusInvRes bonus: parsedResponse.results.BonusInvRes){
                    system.debug('mapOfSOIdWIthCLI.containskey(bonus.SFID) '+mapOfSOIdWIthCLI.containskey(bonus.SFID));
                    if(mapOfSOIdWIthCLI.containskey(bonus.SFID)){
                        CommissionLineItem__c cliToUpdate = mapOfSOIdWIthCLI.get(bonus.SFID);
                        cliToUpdate.ERPID__c = bonus.ErpId;
                        cliToUpdate.ErpErrorMessage__c = bonus.errorMsg;
                        cliToUpdate.InvoiceNumber__c = bonus.invoiceNum;
                        cliListToUpdate.add(cliToUpdate);
                    }
                }
                if(!cliListToUpdate.isempty()){
                    update cliListToUpdate;
                }
            }
            
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'Quarterly Broker Invoice Api','QuarterlyBrokerInvoiceApi','generateInvoice'));
        }
    }
    
    public static HttpResponse QuarterlyBrokerInvoiceCalloutHelper(Map<String,String> headerConfiguration, String JSONBody, String muleConfig) {
        //Just make the callout, if error code log in logger object
        
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setBody(JSONBody);
        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        }
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        return response;
    }
}