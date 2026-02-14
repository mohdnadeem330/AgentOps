/*
* Name               : CustomerServiceChargeWebSerice
* Description        : This class is used to get the Service charge Amount
*/
@RestResource (urlMapping = '/getServiceCharge')
global without sharing class CustomerServiceChargeWebSerice {
    
    @HttpPost
    global static void getCalculatedServiceCharge() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
             Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            system.debug('mapFieldApiFieldValues  '+mapFieldApiFieldValues);
            Map<String, Object> responseData = new Map<String, Object>(); 
           	String UnitName =  mapFieldApiFieldValues.get('unitName');
            String customerId = mapFieldApiFieldValues.get('customerId');
            String SRType = mapFieldApiFieldValues.get('SRType');
            String ChargeType = mapFieldApiFieldValues.get('ChargeType');
            handler.response.data = getservicechargeData(UnitName,customerId,SRType,ChargeType);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){
             System.debug('Ex'+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    public static ChargeWrapper getservicechargeData(String UnitName,String CustomerId,String SRType,String ChargeType){
        Decimal chargeAmount = 0;
            Decimal amountWithoutVAT = 0;
            Decimal vatAmount = 0;
        List<HexaBPM__Service_Request__c> SRrequest =new List<HexaBPM__Service_Request__c>();
       // SRrequest = [SELECT Id,SRType__c,InstallmentLine__c,Payment_Extension_Period_In_Days__c,Calculated_Service_Charge__c FROM HexaBPM__Service_Request__c WHERE UnitName__c=:UnitName And HexaBPM__Customer__c =:CustomerId AND SRType__c =:SRType];
        Map<String,ChargeRule__c> SRTypeChargeDetailsMap = new Map<String,ChargeRule__c>();
        Map<Id,InstallmentLines__c> InstallmentLineMap = new Map<Id,InstallmentLines__c>();
        List<ChargeRule__c> chargeruleList = new List<ChargeRule__c>();
        
        if(SRType =='Investor Certificate' || SRType =='Letter Issuance' ){
            chargeruleList = [SELECT SRType__c,ChargePercentage__c,VATChanges__c,ChargeAmount__c from ChargeRule__c WHERE SRType__c=:SRType AND IsActive__c = True];
        }else{
            System.debug('SRType'+SRType+'Charge'+ChargeType);
            chargeruleList = [SELECT SRType__c,ChargePercentage__c,VATChanges__c,ChargeAmount__c from ChargeRule__c WHERE SRType__c=:SRType AND ChargeType__c =:ChargeType AND IsActive__c = True];
        } 
            for(ChargeRule__c chargeRule :chargeruleList ){
                SRTypeChargeDetailsMap.put(chargeRule.SRType__c,chargeRule);
            }
             
        
    	ChargeRule__c chargeRule = SRTypeChargeDetailsMap.get(SRType);
        System.debug('chargeRule:'+chargeRule); 
        //PAYMENT EXTENSION CHARGE CALC
        /*if(SRrequest[0].SRType__c == Constants.PAYMENT_EXTENSION_TYPE && chargeRule <> null) {
            if(SRrequest[0].InstallmentLine__c <> NULL && InstallmentLineMap.containsKey(SRrequest[0].InstallmentLine__c) && InstallmentLineMap.get(SRrequest[0].InstallmentLine__c).OutstandingAmount__c <> NULL){
                amountWithoutVAT = SRrequest[0].Payment_Extension_Period_In_Days__c <> 0 && SRrequest[0].Payment_Extension_Period_In_Days__c <> null ? (chargeRule.ChargePercentage__c * InstallmentLineMap.get(SRrequest[0].InstallmentLine__c).OutstandingAmount__c * SRrequest[0].Payment_Extension_Period_In_Days__c)/100 : (chargeRule.ChargePercentage__c * InstallmentLineMap.get(SRrequest[0].InstallmentLine__c).OutstandingAmount__c)/100;
                vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
                chargeAmount = amountWithoutVAT + vatAmount;
                ChargeWrapper ch = new ChargeWrapper();
                ch.SRId = SRrequest[0].Id;
                ch.SRType = SRrequest[0].SRType__c;
                ch.ChargeAmount = chargeAmount;
                return ch;
            }
            return null;
        }*/
        //ALL OTHERS
        if(chargeRule <> null){
            amountWithoutVAT = chargeRule.ChargeAmount__c;
            vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
            chargeAmount = amountWithoutVAT + vatAmount;
            
            ChargeWrapper ch = new ChargeWrapper();
            ch.SRId = '';
            ch.SRType = SRType;
            ch.ChargeAmount = chargeAmount;
            return ch;
        } 
        
            return null;
        
        
    }
    public class ChargeWrapper{
        public String SRId ='';
        public String SRType ='';
        public Decimal ChargeAmount = 0.00;
    }
}