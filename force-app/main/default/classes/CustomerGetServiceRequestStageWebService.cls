/*
* Name               : GetServiceRequestStage
* Description        : This class is used to get the Service Request Step
*/
@RestResource (urlMapping = '/getServiceRequestStage')
global without sharing class CustomerGetServiceRequestStageWebService {
    
    @HttpGet
    global static void getstage() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            RestRequest req = RestContext.request;
           	String UnitName = req.params.get('unitName');
            String customerId = req.params.get('customerId');
            handler.response.data = getServiceRequestStatus(UnitName,customerId);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){
            handler.response.success = false;handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;handler.finalize(ex);
        }
    }
    public static titledeedStep getServiceRequestStatus(String UnitName,String customerId){
        System.debug(UnitName);
        List<HexaBPM__Service_Request__c> SRequest =[SELECT Id,HexaBPM__External_Status_Name__c,No_Charge_Fee_Required__c FROM HexaBPM__Service_Request__c WHERE Id=:UnitName And SalesOrder__r.Status__c != 'Cancelled' AND HexaBPM__Customer__c =:CustomerId];
        if(SRequest.size() >0){
            List<HexaBPM__Step__c> steps = [SELECT Id,HexaBPM__Summary__c,HexaBPM__SR__c,HexaBPM__Step_Status__c,HexaBPM__SR__r.No_Charge_Fee_Required__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =:SRequest  ORDER BY CreatedDate DESC];
            List<SalesOrderOtherCharges__c> otherCharge = [SELECT Id,PendingAmount__c FROM SalesOrderOtherCharges__c WHERE ServiceRequest__c =:SRequest];
            if(steps.size() >0){
                for(HexaBPM__Step__c step : steps){
                    if(SRequest[0].No_Charge_Fee_Required__c == false){
                    if(step.HexaBPM__Summary__c =='Charge Fees'){
                        titledeedStep tl = new titledeedStep();
                        tl.Status = step.HexaBPM__Step_Status__c;
                        tl.StepName = step.HexaBPM__Summary__c;
                        tl.isCompleted = step.HexaBPM__Step_Status__c =='Completed' ?true:false;
                        tl.NOChargeFeeRequired = step.HexaBPM__SR__r.No_Charge_Fee_Required__c;
                        if(otherCharge.size() >0){
                        tl.paymentId = otherCharge[0].Id;
                        tl.PaymentAmount = otherCharge[0].PendingAmount__c;
                        }
                        return tl;
                    }
                    }else{
                         titledeedStep tl = new titledeedStep();
                         tl.NOChargeFeeRequired = step.HexaBPM__SR__r.No_Charge_Fee_Required__c;
                        return tl;
                    }
                }
            }
            return null;
            
        }
        return null;
    }
    public class titledeedStep{
        public String Status;
        public String StepName;
        public Boolean isCompleted;
        public String paymentId;
        public Decimal PaymentAmount;
        public Boolean NOChargeFeeRequired;
    }
}