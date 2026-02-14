/**
* @File Name : ALD_AMCReOpenCaseAPI.cls
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
@RestResource(urlMapping = '/LiveAldar/ReopenCase')
global class ALD_AMCReOpenCaseAPI  {
	@HttpPost
    global static void doPost(){ 
        RestContextHandler handler = new RestContextHandler(true);
        try {
			RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            // Validate required fields
			if (reqBodyMap == null || !reqBodyMap.containsKey('reqId')) {
                throw new CustomException('Invalid input');
            }
            
            // Fetch configurations and set the response data
            handler.response.data = OpenCase((String)reqBodyMap.get('reqId'));
            handler.response.success = true;handler.finalize();
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
	// Method to fetch configurations from various sources
    global static Map<String,String> OpenCase(String caseId) {
        Map<String,String> resp = new Map<String,String>();
		List<Case> lstCase = [SELECT Id,Status,AMC_Closure_Reason__c,DaysSinceCaseCreated__c,(SELECT Id,Status,Record_Type_Name__c,ServiceTerritoryId ,FSSK__FSK_Work_Order__r.Id,WorkTypeId FROM Service_Appointments__r WHERE Record_Type_Name__c ='AMC') FROM Case WHERE Id=: caseId AND Recordtype_Name__c='AMC' LIMIT 1];
        
		if (lstCase.size() > 0) {
            Case c = lstCase[0];
			if(c.AMC_Closure_Reason__c != 'Customer Not Available - No Access')  throw new CustomException('Request can not be re-open for completed appointment');

            if(c.Status != 'Closed' && c.DaysSinceCaseCreated__c > 45)  throw new CustomException('Request is not egligible for re-open');
			
            if(c.Service_Appointments__r.size() > 1)  throw new CustomException('You Request not re-open the case more than 1 time');
		
            WorkOrderLineItem woli = new WorkOrderLineItem (Case__c=c.Id,WorkOrderId=c.Service_Appointments__r[0].FSSK__FSK_Work_Order__r.Id,WorkTypeId =c.Service_Appointments__r[0].WorkTypeId);
			INSERT woli; 
            ServiceAppointment newApp = [SELECT Id,ServiceTerritoryId FROM ServiceAppointment WHERE Status!='Closed' AND Case__c=:c.Id ORDER By CreatedDate DESC LIMIT 1]; newApp.ServiceTerritoryId = c.Service_Appointments__r[0].ServiceTerritoryId;
            UPDATE newApp;
            c.Status = 'New'; UPDATE c; resp.put('msg', 'Request was re-open successfully!');
             
        }else{  throw new CustomException('Invalid input');  }
        return resp;
	}
}