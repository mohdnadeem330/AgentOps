@RestResource(urlMapping='/createAldarExpertsAppointment') 
global class BP_CreateEventAppointment  extends BP_BaseRestResource {
    @HttpPost
    global static void createAppointment() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            String requestBody = RestContext.request.requestBody.toString();
            
            if (!String.isEmpty(requestBody)) {
                BP_CreateEventAppointment service = new BP_CreateEventAppointment();
                Map<String, String> params = RestContext.request.params;
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } 
        catch (Exception ex) { handler.response.success = false; handler.response.statusCode = 500; handler.response.message = 'Error: ' + ex.getMessage(); }
        
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            BrokerAppointmentWrapper responseWrapper = (BrokerAppointmentWrapper) JSON.deserialize(requestBody, BrokerAppointmentWrapper.class);
      
            if(responseWrapper.appointmentStatus == null){
                return new ApiResponse(false, 400, 'Appointment status can not be blank', null);
            }
            
            if(responseWrapper.appointmentStatus == 'Cancelled' && String.isBlank(responseWrapper.Id)){
                return new ApiResponse(false, 400, 'Appointment Id can not be blank', null);
            }
            
            Appointment__c existingAppointment;
            if (!String.isEmpty(responseWrapper.Id)) {
                List<Appointment__c> existingList = [
                    SELECT Id, AppointmentId__c FROM Appointment__c WHERE id = :responseWrapper.Id LIMIT 1
                ];
                if (!existingList.isEmpty()) {
                    existingAppointment = existingList[0];
                }else{
                    return new ApiResponse(false, 400, 'Invalid Appointment Id', null);
                }
            }
            
            AppointmentResult result = createAppointment(responseWrapper, existingAppointment);
            String message = 'Appointment is ' + result.action.toLowerCase() + ' successfully';
            return new ApiResponse(true, 200, message, result.appointment);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to process Appointment: ' + e.getMessage(), null);
        }
    }
    
    private static AppointmentResult createAppointment(BrokerAppointmentWrapper responseWrapper, Appointment__c existingAppointment){
        System.debug('Received Appointment Request Data: ' + JSON.serializePretty(responseWrapper));
        
        Time startTimeVal;
        Time endTimeVal;
        
        if (!String.isEmpty(responseWrapper.appointmentSlotTime)) {
            List<String> timeParts = responseWrapper.appointmentSlotTime.split(' - ');
            if (timeParts.size() == 2) {
                String startPart = timeParts[0].trim(); 
                String endPart = timeParts[1].trim();  
                List<String> stSplit = startPart.split(' '); 
                List<String> edSplit = endPart.split(' ');   
                if (stSplit.size() == 2 && edSplit.size() == 2) {
                    startTimeVal = Datetime.valueOf('2025-01-01 ' + stSplit[0] + ':00 ' + stSplit[1]).time();
                    endTimeVal = Datetime.valueOf('2025-01-01 ' + edSplit[0] + ':00 ' + edSplit[1]).time();
                }
            }
        }
        
        String recordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();
                
        Boolean isUpdate = (existingAppointment == null || String.isBlank(existingAppointment.Id)) ? false : true;
        Appointment__c appointment = isUpdate ? existingAppointment : new Appointment__c();
        appointment.RecordTypeId = recordTypeId;
        if(responseWrapper.ownerId != null){
            appointment.OwnerId = responseWrapper.ownerId;
            appointment.Broker__c = responseWrapper.ownerId;
        } 
        
        if (responseWrapper.appointmentStatus == 'Cancelled') {
            appointment.Appointment_Status__c = responseWrapper.appointmentStatus;
            appointment.Cancellation_Reason__c = responseWrapper.cancelReason;
            appointment.Cancellation_Comment__c = responseWrapper.cancelComments;
        }else if(responseWrapper.appointmentStatus != null){
            appointment.Appointment_Location__c = responseWrapper.appointmentLocation;
            appointment.Appointment_Slot_Time__c = responseWrapper.appointmentSlotTime;
            appointment.Appointment_Status__c = responseWrapper.appointmentStatus;
            appointment.AppointmentId__c = responseWrapper.appointmentId;
            appointment.PassportNumber__c = responseWrapper.passportNumber;
            appointment.PassportExpiryDate__c = responseWrapper.passportExpiry;
            appointment.Date__c = responseWrapper.appointmentDate;
            appointment.Email__c = responseWrapper.email;
            appointment.Emirates__c = responseWrapper.emirates;
            appointment.EmiratesId__c = responseWrapper.emiratesId;
            appointment.EncryptedRecordId__c = responseWrapper.createdAppointmentRecordId;
            appointment.Location__c = responseWrapper.locationCode;
            appointment.Nationality__c = responseWrapper.nationality;
            appointment.EventName__c = responseWrapper.eventName;       
            appointment.Residency__c = responseWrapper.residency;
            appointment.Slot__c = responseWrapper.slot;
            appointment.Contact__c = responseWrapper.ContactId;        
            appointment.Mobile__c = responseWrapper.mobile;
            appointment.StartTime__c = startTimeVal;
            appointment.EndTime__c = endTimeVal;
        }
        
        upsert appointment;
       
        AppointmentResult result = new AppointmentResult();
        result.appointment = appointment;
        result.action = isUpdate ? 'Updated' : 'Inserted';
        return result;
    }

    public class BrokerAppointmentWrapper {
        public String appointmentLocation;
        public String appointmentSlotTime;
        public String appointmentStatus;
        public String appointmentId;
        public String passportNumber;
        public date passportExpiry;
        public String broker;
        public Date appointmentDate;
        public String email;
        public String emirates;
        public String emiratesId;
        public String createdAppointmentRecordId;
        public String locationCode;
        public String nationality;
        public String eventName;
        public String residency;
        public String slot;
        public String ownerId;
        public String ContactId;
        public String mobile;
        public String startTime;
        public String endTime;
        public String status;   
        
        public String cancelReason;
        public String cancelComments;
        public String Id;
        
        public BrokerAppointmentWrapper(){}
    }
    
    public class AppointmentResult {
        public Appointment__c appointment;
        public String action; 
    }
}