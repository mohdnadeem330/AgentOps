public with sharing class EPRSOAController {
    
    public class SoaWrapperResp{
        @AuraEnabled
        public String soaPDFstr;
        @AuraEnabled
        public String unitNumber;
        @AuraEnabled
        public Boolean notEligible;
    }
    
    @AuraEnabled
    public static soaWrapperResp getERPSOA(String recordId) {
          System.debug('getERPSOA recordId ***'+recordId);
           SoaWrapperResp resp= new SoaWrapperResp();
          SalesOrder__c salesOrderRec=[select Id,Unit__r.Name,Status__c from SalesOrder__c where Id=:recordId];
            if(salesOrderRec.Status__c!='Sold' && salesOrderRec.Status__c!='Approve Pending' ){
                 resp.notEligible=true;
                 resp.soaPDFstr='';
                 return resp;
            }
         
          MuleSoftSetting__mdt  erpSOAAPIConfiguration = Utilities.getMuleSoftDetails('ERPSOA');
          Organization orgDetails = Utilities.getOrganizationDetails();
          String endPointURL = erpSOAAPIConfiguration.SandboxURL__c ;
          if(!orgDetails.IsSandbox){
              endPointURL = erpSOAAPIConfiguration.ProductionURL__c ; 
          }


          String finalEndPointURL =endPointURL+EncodingUtil.urlEncode(salesOrderRec.Id,'utf-8')+ '&pCallingFrom=' + EncodingUtil.urlEncode('SF', 'UTF-8');
          System.debug('End Point URL *****'+finalEndPointURL);
          Map<String, String> headerMap= new Map<String, String>();
          headerMap.put('Content-Type', 'application/json');
          headerMap.put('client_id', erpSOAAPIConfiguration.APIId__c);
          headerMap.put('client_secret', erpSOAAPIConfiguration.APIKey__c);
    
            HTTPResponse httpResp= Utilities.makeHHTTPCallout('GET', finalEndPointURL, null, headerMap ); 
            System.debug('httpResp  ***'+httpResp);
            System.debug('response.getBody()*******'+httpResp.getBody());
            boolean success = (httpResp!=null && httpResp.getStatusCode() == 200);
            if(success){
                    map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(httpResp.getBody());
                     object resultObj =responseMap.get('results');
                     Map<String, Object> soaStringMap = (Map<String, Object>)resultObj;
                     String soaString=String.valueOf(soaStringMap.get('soaFile'));
                     System.debug('soaString'+soaString);
                     resp.soaPDFstr=soaString;
                     resp.notEligible=false;
                     resp.unitNumber=salesOrderRec.Unit__r.Name;
                     return resp;
            }
             return null;
       }
}