@RestResource(urlMapping='/createAppointment')
    global class BP_CreateAppointment extends BP_BaseRestResource{
    
        @HttpPost
        global static void createAppointment() {
            RestContextHandler handler = new RestContextHandler(false);
            try {
                String requestBody = RestContext.request.requestBody.toString();
                
                if (!String.isEmpty(requestBody)) {
                    BP_CreateAppointment service = new BP_CreateAppointment();
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
                return new ApiResponse(true, 200, 'Appointment is created successfully', createAppointment(requestBody));
            } catch (Exception e) {
                return new ApiResponse(false, 400, 'Failed to Appointment creation: ' + e.getMessage(), null);
            }
        }
    
        public class BrokerAppointmentWrapper {
    
            public String appointmentLocation;
            public String appointmentSlotTime;
            public String appointmentStatus;
            public String appointmentId;
            public String broker;
            public String customerPresenceConfirmation;
            public Date appointmentDate;
            public String email;
            public String emirates;
            public String emiratesId;
            public String createdAppointmentRecordId;
            public String leadId;
            public String locationCode;
            public String nationality;
            public String ownerId;
            public String projectId;
            public String recordTypeId;
            public String residency;
            public String slot;
            public String status;
            public String mobile;
            public String passportNumber;
            public date passportExpiry;
            public string message;
            public String ProjectSFId;
             //public String locationNameArabic; 
            //public String locationName;       
            
            //public DateTime appointmentDateTime;      
    
            public BrokerAppointmentWrapper(){}
        }
    
        private static Appointment__c createAppointment(String requestBody){
            BrokerAppointmentWrapper responseWrapper = (BrokerAppointmentWrapper) JSON.deserialize(requestBody, BrokerAppointmentWrapper.class);
     
            
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
            
            Appointment__c requestAppointment = new Appointment__c(
                Appointment_Location__c = responseWrapper.appointmentLocation,
                Appointment_Slot_Time__c = responseWrapper.appointmentSlotTime,
                Appointment_Status__c = responseWrapper.appointmentStatus,
                AppointmentId__c = responseWrapper.appointmentId,
                PassportNumber__c=responseWrapper.passportNumber,
                PassportExpiryDate__c=responseWrapper.passportExpiry,
                Comments__c=responseWrapper.message,
                
                Broker__c = responseWrapper.broker,
                CustomerPresenceConfirmation__c = responseWrapper.customerPresenceConfirmation,
                Date__c = responseWrapper.appointmentDate,
                Email__c = responseWrapper.email,
                Emirates__c = responseWrapper.emirates,
                EmiratesId__c = responseWrapper.emiratesId,
                EncryptedRecordId__c = responseWrapper.createdAppointmentRecordId,
                Lead__c = responseWrapper.leadId,
                Location__c = responseWrapper.locationCode,
                Nationality__c = responseWrapper.nationality,
                OwnerId = responseWrapper.ownerId,
                Project__c = responseWrapper.ProjectSFId,
                //RecordTypeId = responseWrapper.recordTypeId,
                Residency__c = responseWrapper.residency,
                Slot__c = responseWrapper.slot,
                Status__c = responseWrapper.status,
                Mobile__c = responseWrapper.mobile,
                //AppointmentDateTime__c = responseWrapper.appointmentDateTime,
                //LocationNameArabic__c = responseWrapper.locationNameArabic,
                //LocationName__c = responseWrapper.locationName,
                StartTime__c = startTimeVal,
                EndTime__c = endTimeVal
            );
            
            insert requestAppointment;
            return requestAppointment;
        }
    }