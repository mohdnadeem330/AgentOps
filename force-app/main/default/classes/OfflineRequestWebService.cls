@RestResource (urlMapping = '/insert/offlinerequest')
global with sharing class OfflineRequestWebService {
	/*
	 * Using to Create new offline request or can edit the offline request.
	 * If pass the offline Request Id then will get update the details.
	 * To cancel pass Status variable than offline request will get canceld. 
	 * 
	 */
    @HttpPost
    global static void doPost(dateTime startTime, dateTime endTime, String reason, String status, String OfflineRequestId) {
    	RestContextHandler handler = new RestContextHandler(true);
        Savepoint savePoint = null;
       try {
            savePoint = Database.setSavepoint();
            OfflineRequest__c objOffLineRequest = new OfflineRequest__c();
            if(String.isNotBlank(OfflineRequestId)){
                objOffLineRequest.Id = OfflineRequestId;
            }
            if(String.isNotBlank(status)){
                objOffLineRequest.Status__c = status;
            }
            if(String.isNotBlank(reason)){
               objOffLineRequest.Reason__c = reason; 
            }
       
            if(startTime != null){
                objOffLineRequest.StartTime__c = startTime;
            }
            if(endTime != null){
                objOffLineRequest.EndTime__c = endTime;
            }
         
        objOffLineRequest.User__c = userInfo.getUserId();
        Map<String, object> businesshours = new Map<String, object>();
         
        
        boolean isValidated = false;
    if(startTime != null && endTime != null ){
        businesshours = OfflineRequestController.validateOfflineRequest(objOffLineRequest);
        if(businesshours.get('endTime') == false){
            isValidated = true;
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'End Time cannot be less than Start time and must be in future.';
            handler.finalize();   
            system.debug('handler::'+handler);
        }
        
        if(businesshours.get('startTime') == false && startTime != null){
            isValidated = true;
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'Start Date must be in future.';
            handler.finalize();   
            system.debug('handler::'+handler);
        }
        if(businesshours.get('startTimeValidate') == false && startTime != null){
          
            isValidated = true;
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'Start time is not with in the business hours.';
            handler.finalize();
        }
        if(businesshours.get('endTimeValidate') == false && endTime != null){
            isValidated = true;
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'End time is not with in the business hours.';
            handler.finalize(); 
        }
        if(((List<OfflineRequest__c>)businesshours.get('existingOfflineRequest')).size() > 0){
            isValidated = true;
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'Existing Offline Request still in progress.';
            handler.finalize(); 
        }
    } 
       
        if(status == 'Cancelled'){
            OfflineRequestController.cancelOffRequest(objOffLineRequest);
            handler.response.success = true;
            handler.response.data = objOffLineRequest;
        }else{
            if(!isValidated){
                upsert objOffLineRequest;
                OfflineRequestController.sendManagerApprovel(objOffLineRequest.Id);
                handler.response.success = true;
                handler.response.data = objOffLineRequest;
            }
        }
        
       
        handler.finalize();
        
        system.debug('handler::'+handler);
        }catch (DMLException exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch (Exception exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        } 
    }
    /*
	 * Using to Deelte offline request 
	 * Input is the Id of the OfflineRequest.
	 * 
	 */
   /* @HttpDelete
    global static void deleteOfflineRequest(){
        RestContextHandler handler = new RestContextHandler(true);
        RestRequest req	=	RestContext.request;
        String offlineRequestId = req.params.get('Id');
        Savepoint savePoint = null;
        try {
            savePoint = Database.setSavepoint();
            OfflineRequestController.deleteOffRequest(new OfflineRequest__c(Id = offlineRequestId));
            handler.response.success = true;
            handler.response.data = 'Successfully Deleted';
            handler.finalize();
        }catch (DMLException exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }catch (Exception exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
            
     } */ 
}