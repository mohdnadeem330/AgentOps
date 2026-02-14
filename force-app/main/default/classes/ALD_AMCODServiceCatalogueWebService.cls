/**
* @File Name : ALD_AMCODServiceCatalogueWebService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 9, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 9, 2024 |   | Initial Version
**/
@RestResource(urlMapping = '/LiveAldar/AMCOnDemandServiceCatalogue')
Global class ALD_AMCODServiceCatalogueWebService {
    @HttpPost
    global static void doPost(){
        RestContextHandler handler = new RestContextHandler(true);
         try {
			RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            // Validate required fields
			if (reqBodyMap == null || !reqBodyMap.containsKey('customerId')) {
                throw new CustomException('Invalid input');
            }
            
            // Fetch configurations and set the response data
            handler.response.data = FetchCustomerUnitDetails((String)reqBodyMap.get('customerId'));
            handler.response.success = true;
            handler.finalize();
        } 
        catch(CustomException ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    public static List<ResponseWrapper> FetchCustomerUnitDetails(String customerId){
        List<ResponseWrapper> lstResp = new List<ResponseWrapper>();
        for( SalesOrder__c so : [SELECT Id,Unit__r.Name,ProjectName__c,AMCStartDate__c,AMCEndDate__c,AMCStatus__c,(SELECT Id,QuantityOnHand__c,ConsumedQuantity__c,QuantityInProgress__c,BalanceQuantity__c,Product_Item__r.Product2.Name,Product_Item__r.Product2.DisplayUrl, Product_Item__r.Product2.Alias_Name__c FROM OpportunityOfferLines__r WHERE Product_Item__c != NULL AND Product_Item__r.Product2.Type__c = 'On Demand' AND Product_Item__r.Product2.isActive = True) FROM SalesOrder__c WHERE Account__c=:customerId AND AMCStatus__c='Active']){
            ResponseWrapper respWrap = new ResponseWrapper();
            respWrap.unitNumber = so.Unit__r.Name;
            respWrap.projectName = so.ProjectName__c;
            respWrap.amcStartDate = so.AMCStartDate__c;
            respWrap.amcEndDate = so.AMCEndDate__c;
            respWrap.amcStatus = so.AMCStatus__c;
            List<ServiceInfo> lstServInfo = new List<ServiceInfo>();
            for(OpportunityOfferLine__c line :so.OpportunityOfferLines__r){
                ServiceInfo serv = new ServiceInfo(line);
                lstServInfo.add(serv);
            }
            respWrap.services = lstServInfo;
            lstResp.add(respWrap);
        }
        return lstResp;
    }
     
    Global class ResponseWrapper{
        Public string unitNumber            {get;set;}
        Public string projectName           {get;set;}
        Public Date amcStartDate            {get;set;}
        Public Date amcEndDate              {get;set;}
        Public string amcStatus             {get;set;}
        Public List<ServiceInfo> services   {get;set;}
    }

    Global class ServiceInfo{
        Public string serviceName              {get;set;}
        Public Integer avlQty                  {get;set;}
        Public Integer consumedQty             {get;set;}
        Public Integer balanceQty              {get;set;}
        Public Integer inProgressQty           {get;set;}
		public String icon					   {get;set;}
        public String displayName				{get;set;}

        Public ServiceInfo(OpportunityOfferLine__c offLine){
            this.serviceName = (offLine.Product_Item__r.Product2.Name == 'Façade Cleaning' ?  'Facade Cleaning' : offLine.Product_Item__r.Product2.Name);
            this.avlQty = (offLine.QuantityOnHand__c  != null ? Integer.valueOf(offLine.QuantityOnHand__c) : 0);
            this.consumedQty = (offLine.ConsumedQuantity__c != null ? Integer.valueOf(offLine.ConsumedQuantity__c) : 0);
            this.balanceQty = (offLine.BalanceQuantity__c != null ? Integer.valueOf(offLine.BalanceQuantity__c) : 0);
            this.inProgressQty = (offLine.QuantityInProgress__c != null ? Integer.valueOf(offLine.QuantityInProgress__c) : 0);
			this.icon =(offLine.Product_Item__r.Product2.DisplayUrl !=null  ? offLine.Product_Item__r.Product2.DisplayUrl : '');
            this.displayName = (offLine.Product_Item__r.Product2.Alias_Name__c !=null  ? offLine.Product_Item__r.Product2.Alias_Name__c : offLine.Product_Item__r.Product2.Name);			
        }
    }
}