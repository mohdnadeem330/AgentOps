/**********************************************************************************************************************
* Name              : ALD_ServiceRequestDetailWebService                                                        
* Description       : Webservice fetch and return case detail
* Method            : doGet()
* Created By        : nborse@aldar.com - Nilesh    
******************************************************************************************************************/
@RestResource(urlMapping = '/LiveAldar/GetRequest') 
global with sharing class ALD_ServiceRequestDetailWebService {
    // HTTP POST method to handle incoming requests
    @HttpPost
    global static void doPost(){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> reqBody = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            if (reqBody == null || !reqBody.containsKey('reqId') || String.isBlank((String)reqBody.get('reqId'))) {
                throw new CustomException('Parameter is required and cannot be empty');
            }
            String reqId =(String)reqBody.get('reqId'); 
            // Fetch configurations and set the response data
            handler.response.data = fetchRequestDetail(reqId);
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
    
     // Method to fetch configurations from various sources
    global static CustomerServiceRequestWebService.CaseReturnModel fetchRequestDetail(String reqId){
        Case requestDet = CustomerServiceUtility.getCaseDetail(' (Id = \'' + reqId + '\') ')[0];
        CustomerServiceRequestWebService.CaseReturnModel caseReturnModel = new CustomerServiceRequestWebService.CaseReturnModel(requestDet);
         String saId = ALD_LiveAldarUtilityCtrl.getServiceAppointmentByType(reqId, requestDet!= null && requestDet.SubVertical__c.equalsIgnoreCase('AMC') ? 'AMC' : 'Assessment');
        ServiceAppointment appointment = ALD_LiveAldarUtilityCtrl.getAppointmentDetail(saId);
        CustomerServiceRequestWebService.AppointmentModel appt = new CustomerServiceRequestWebService.AppointmentModel(appointment);
        caseReturnModel.appointment = appt;

        List<DocumentQueryModel> lstDocs = new List<DocumentQueryModel>();
         
        for(External_Files__c  fl : requestDet.External_Files__r){  DocumentQueryModel dc = new DocumentQueryModel(fl);  lstDocs.add(dc);
        }

        if(!lstDocs.isEmpty())  caseReturnModel.documents = lstDocs;
        return caseReturnModel;
    }
    
}