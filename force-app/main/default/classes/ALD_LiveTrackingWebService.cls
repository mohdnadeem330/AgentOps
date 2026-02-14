/**********************************************************************************************************************
* Name              : ALD_LiveTrackingWebService                                                        
* Description       : Webservice class to get the Executive/ Technicial live location 
* Method            : doPost()
* Created By        : nborse@aldar.com - Nilesh    
******************************************************************************************************************/
@RestResource(urlMapping = '/LiveAldar/LiveTracking')
global with sharing class ALD_LiveTrackingWebService {
     @HttpPost
    global static void doPost(){ 
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            // Validate required fields
            if (reqBodyMap == null || !reqBodyMap.containsKey('reqId') || String.isBlank((String)reqBodyMap.get('reqId'))) {
                throw new CustomException('Parameter is required and cannot be empty');
            }
            handler.response.data = getTrackingMap(reqBodyMap );
            handler.response.success = true;
            handler.finalize();
         }
        catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400; // Bad Request
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
         catch(Exception ex){
            // Handle any exceptions that occur
             
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    global static appointmentSchResponse getTrackingMap(Map<String, Object> reqBodyMap ){
      
        String saId = ALD_LiveAldarUtilityCtrl.getServiceAppointmentByType((String)reqBodyMap.get('reqId'),'Assessment');
        ServiceAppointment saAppointment = ALD_LiveAldarUtilityCtrl.getAppointmentDetail(saId); 
         
        return new appointmentSchResponse (saAppointment );
    }

    global class appointmentSchResponse{
        public String appointmentId                     {get;set;}    
        public String appointmentNumber                 {get;set;}    
        public String status                            {get;set;}   
        public String schedStartTime                    {get;set;}
        public String schedEndTime                      {get;set;}
        public String resourceId                        {get;set;}    
        public String resourceName                      {get;set;}   
        public String trackingURL                       {get;set;}  
        public String estimatedTime                     {get;set;} 
        Public appointmentSchResponse(ServiceAppointment servApp){
            this.appointmentId     = servApp.Id;
            this.appointmentNumber = servApp.AppointmentNumber;
            this.status            = servApp.Status;
            this.schedStartTime    = String.valueOf(servApp.SchedStartTime);
            this.schedEndTime      =  String.valueOf(servApp.SchedEndTime);
            this.resourceId        = servApp.FSSK__FSK_Assigned_Service_Resource__c;
            this.resourceName      = servApp.FSSK__FSK_Assigned_Service_Resource__r.Name;
            
            if(!servApp.ServiceResources.isEmpty()){
                String mpURL = servApp.ServiceResources[0].ApptAssistantInfoUrl;
                this.trackingURL = (!String.isBlank(mpURL) ? mpURL.replace(System.Label.LocationPage, System.Label.LiveAldarLocationPageURL) : '');
                this.estimatedTime = String.valueOf(servApp.ServiceResources[0].EstimatedTravelTime);
            }
        } 
    }    
}