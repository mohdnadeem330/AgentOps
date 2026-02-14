@RestResource (urlMapping = '/generateSalesOffer')
global with sharing class BP_GenerateSalesOfferWebservice extends BP_BaseRestResource{
    @HttpPost
    global static void excute(){ 
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            if(!String.isEmpty(requestBody)){   
                BP_GenerateSalesOfferWebservice service = new BP_GenerateSalesOfferWebservice();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else{
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
        
            List<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam =  new List<SalesOfferUtility.SaleOfferInputParam>();
           
            Map<String, Object> jsonList = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            JSONWrapperClass data = (JSONWrapperClass) JSON.deserialize(requestBody, JSONWrapperClass.class);
            system.debug('requestBody:::'+requestBody);
            //List<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam = (List<SalesOfferUtility.SaleOfferInputParam>)jsonList.get('SaleOfferInputParam'); 
            
            for(SaleOfferInputParam item : data.SaleOfferInputParam) {
                SalesOfferUtility.SaleOfferInputParam wrp = new SalesOfferUtility.SaleOfferInputParam();
                List<String> selectedPaymentList = new List<String>();
                wrp.unitId = (String) item.unitId;
                // wrp.unitName = (String) item.unitName;
                wrp.offerId = (String) item.offerId;
                wrp.amount = (Decimal) item.amount;
                wrp.amountType = (String) item.amountType;
                for(SelectedPayments sp : item.selectedPayments){
                    selectedPaymentList.add(sp.paymentId);
                }
                wrp.selectedPayments = selectedPaymentList;
                saleOfferInputParam.add(wrp);
            } 
            
            Id opportunityId = (String) data.opportunityId;
            String customerName = (String) data.CustomerName; 
            Id singleUnitId = (String) data.singleUnitId;
            boolean MarketingPlan = (boolean) data.MarketingPlan;
            return new ApiResponse(true, 200,'Offer sent', BP_GenerateSalesOfferWebservice.sendSalesOfferPDF(saleOfferInputParam,opportunityId,customerName, singleUnitId));
            
        } catch (Exception e) {
            //    //logger as well
            return new ApiResponse(false, 500,'Failed to load generate Offer: ' + e.getMessage(), null);
        } 
    }
    
    public class JSONWrapperClass{
        public List<SaleOfferInputParam> SaleOfferInputParam{get;set;}
        public String singleUnitId{get;set;}
        public String opportunityId{get;set;}
        public Boolean MarketingPlan{get;set;}
        public String CustomerName{get;set;}
    }
    
    public class SaleOfferInputParam{
        public String offerId{get;set;}
        public List<SelectedPayments> selectedPayments{get;set;}
        public Decimal amount{get;set;}
        public String unitName{get;set;}
        public String amountType{get;set;}
        public String unitId{get;set;}
    }
    
    public class SelectedPayments{
        public String paymentId{get;set;}
    }
    
    public static object sendSalesOfferPDF(list<SalesOfferUtility.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, String customerName, Id singleUnitId){
        try{
            OpportunityUnitSearchController.sendSalesOfferPDF(saleOfferInputParam, opportunityId, customerName, singleUnitId);
            return 'Success';
        }catch(exception ex){
            return 'Failed'; 
        }
    }
}