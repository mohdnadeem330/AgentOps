global without sharing class CC_RebateRequestController implements HexaBPM.iCustomCodeExecutable {

global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
    HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
    string result ='Success';
    try{      
        if(stp == null || stp.HexaBPM__SR__c == null){
            result='CC_RebateRequestController: Invalid SR or SR Step';
        }
        else{
            String srId = stp.HexaBPM__SR__c ;  
            HexaBPM__Service_Request__c srVal = [Select id, Additional_Rebate_Offered__c,ReceiptRebete__c,HexaBPM__External_SR_Status__c from HexaBPM__Service_Request__c where id = :srId];

            if( stp.Step_Template_Code__c == 'Approval of the Request By D&T'){              
                set<id> soIdList = new set<Id>();
                Decimal splitpercent = 0.00;
                List<SalesOrder__c> SOrderList = new List<SalesOrder__c>();
                for(SRUnitSelected__c unit : [Select id, ServiceRequest__c, SalesOrder__c,Rebate_Percentage__c from SRUnitSelected__c where ServiceRequest__c =:srId]){
                    SOrderList.add(new SalesOrder__c(id = unit.SalesOrder__c));
                    soIdList.add(unit.SalesOrder__c);
                    if(unit.Rebate_Percentage__c > 0)
                    {
                        splitpercent+= unit.Rebate_Percentage__c;
                    }
                }
                system.debug('SOrderList' + SOrderList);
                if(SOrderList.isEmpty() || soIdList.isEmpty()){
                    return 'Error: Rebate Units are not selected';
                } 
                if(splitpercent.setScale(2)!= 100.00){
                    return 'Error: Total split % for selected Unit is ' + splitpercent+'%, it should be 100% .';
                }              
                
                if(srVal.Additional_Rebate_Offered__c ==null || srVal.Additional_Rebate_Offered__c <= 0){
                  return 'Error! Rebate Offered Amount is not entered';
                }              
            }

            if(stp.Step_Template_Code__c == 'Payment Step'){
                
                if(srVal.ReceiptRebete__c != 'Receipt Entered' && stp.HexaBPM__Step_Status__c == Constants.COMPLETED_STATUS)
                {
                return 'Enter Receipt - Please create Outstanding Receipt';                
                }
                else if(stp.HexaBPM__Step_Status__c == Constants.COMPLETED_STATUS){
                 List<HexaBPM__Service_Request__c> srList=  [SELECT Id,ReceiptAcknowledgement__r.Name,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentSubType__c,ReceiptAcknowledgement__r.Status__c from HexaBPM__Service_Request__c where Id =:srId and ReceiptAcknowledgement__r.Status__c !='Cleared' and ReceiptAcknowledgement__r.PaymentSubType__c !='Rebate'];
                    if(!srList.isEmpty()){
                        return 'Outstanding amount to be cleared'; 
                    }                                  
                }        
            }
            
            if(stp.Step_Template_Code__c == 'Verification by Finance'){

                if(stp.HexaBPM__Step_Status__c == Constants.PENDING_STATUS && !Test.isRunningTest())
                {
                    CustomRulesHelper.handleAdditionalRebateReceipt(srId); 
                }
                if(stp.HexaBPM__Step_Status__c == Constants.COMPLETED_STATUS && !Test.isRunningTest())  
                {
                    CustomRulesHelper.getDataForCallout(new List<Id>{srId});
                }
                          
                 //  
            }
            

            
        }
        
    }catch(Exception e){
        result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_RebateRequestController';
      }  
    
    return result;
}

}