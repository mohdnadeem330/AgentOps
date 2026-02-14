/*
* Purpose:  Performing actions after Request approval
* SR Type: Mortgage Discharge
*/
global without sharing class CC_SRMortgageDischargeController implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        string result ='Success';

        try{
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
            
            SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];

            //Actions After SR Request has been Approved  
            if(serviceRequest.HexaBPM__External_Status_Name__c == 'Request Approved'){

                String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
                
                string emailTemplateId = Utilities.getEmailtemplateIdByName('Mortgage_Discharge_Mortgage_Release_Approved');
                
                String fileName = 'SOA - '+serviceRequest.Unit__r.Name+' - Generated On - '+Date.Today();
                //SRUtility.generatePdfAndSendEmail(serviceRequest.SalesOrder__r.Contact__c, emailTemplateId, serviceRequest.Id, orgWideEmailAddress, serviceRequest.SalesOrder__c, fileName);

                if(serviceRequest.HexaBPM__Contact__c != null){
                    Set<Id> idsSet = new Set<Id>{serviceRequest.Id};
                    List<SMSModel> smsModel = SMSUtility.prepareSMS('Mortgage_Release_Approval', idsSet);
                    SMSUtility.sendSMS(smsModel);
                }
                MortgageCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
                salesOrder.MortgageApplicable__c = 'No';
                salesOrder.MortgageBank__c = null;
                salesOrder.MortgageAmount__c = null;
                salesOrder.MortgageStartDate__c = null;
                salesOrder.MortgageEndDate__c = null;
                salesOrder.MortgageApplicationNumber__c = null;
                salesOrder.MortgageBankAccount__c = null;
                update salesOrder;                
            }           
            return result;
        }        catch(Exception e){
            result = e.getMessage()+' :CC_SRMortgageDischargeController '+e.getLineNumber();
            System.debug('line no '+e.getLineNumber());        }
        return result;
    }
}