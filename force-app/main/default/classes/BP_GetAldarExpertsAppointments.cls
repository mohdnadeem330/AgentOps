@RestResource(urlMapping='/getAldarExpertsAppointments')
global class BP_GetAldarExpertsAppointments extends BP_BaseRestResource{
    
    @HttpGet
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try{
            BP_GetAldarExpertsAppointments service = new BP_GetAldarExpertsAppointments();
            Map<String, String> params = RestContext.request.params;
            ApiResponse response = service.processRequest(params, null);
            
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        }catch (Exception ex) {
            handler.response.success = false; handler.response.statusCode = 500; handler.response.message = ex.getMessage();
            
        } finally {
            handler.finalize();
        }
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            String contactId = [SELECT Id,ContactId FROM User WHERE Id =: UserInfo.getUserId()].ContactId;
            // contactId = '003FW000005kvd9YAA';
            if(String.isBlank(contactId)){ return new ApiResponse(false, 400, 'This user is not related with any agency', null); }

            List<Appointment__c> listAppointments = AppointmentController.getEventAllAppointments(contactId);
            if(listAppointments == null || listAppointments.isEmpty()){
               return new ApiResponse(true, 200, 'No Appointment related to this User', new List<Appointment__c>());
            }
            return new ApiResponse(true, 200, 'Data fetched successfully', AppointmentController.getEventAllAppointments(contactId));
            
        }catch (Exception e) {  return new ApiResponse(false, 400, 'Failed to process the request: ' + e.getMessage(), null); }
    }
}