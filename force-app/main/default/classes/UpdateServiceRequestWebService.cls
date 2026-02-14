@RestResource (urlMapping = '/customer/UpdateServiceRequest') 
global without sharing class UpdateServiceRequestWebService {
    
    
    global class StandardResponse {
        public Boolean success;
        public Integer statusCode;
        public String requestId;
        public String message;
        public Object data;
        
        public StandardResponse(Boolean success, Integer statusCode, String message, Object data) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
        }
    }
    
    private static void sendResponse(Boolean success, Integer code, String msg, Object data) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        StandardResponse sr = new StandardResponse(success, code, msg, data);
        res.responseBody = Blob.valueOf(JSON.serialize(sr));
    }
    
    global class ServiceRequestModel{
        public String requestId                                     {get;set;}                                
        public String location                                      {get;set;}
        public String requestType                                   {get;set;}
        public String pdcCollectionLocation						{get;set;}
        public Date pdcCollectionDate								{get;set;}
    }
    
    global class LocationInfo {
        public Id id;
        public String name;
        public String address;  
        public String mapLink;  
        public String workingDays;
        public String workingHours;
    }
    
    global class ResponseData {
        public List<LocationInfo> locations;
        public List<Date> availableDates;
    }
    
    @HttpGet
    global static void 	getData(){
        try{
            ResponseData resp = new ResponseData();
            resp.locations = new List<LocationInfo>();
            resp.availableDates = new List<Date>();
            
            Integer startOffSet = Integer.valueOf(Label.PDCCollectionStartDays);
            Integer totalDated  = Integer.valueOf(Label.PDCCollectionNumberOfDates);
            
            for(ServiceTerritory st: [SELECT Id, Name, Type__c, Street, City, State, Country, PostalCode FROM ServiceTerritory WHERE Type__c = 'Property Transfer']){
                LocationInfo loc = new LocationInfo();
                loc.id = st.Id;
                loc.name = st.Name;
                loc.workingDays = Label.WorkingDays;
                loc.workingHours = Label.WorkingHours;
                List<String> addressParts = new List<String>();
                if (st.Street != null) addressParts.add(st.Street);
                if (st.City != null) addressParts.add(st.City);
                if (st.State != null) addressParts.add(st.State);
                if (st.Country != null) addressParts.add(st.Country);
                if (st.PostalCode != null) addressParts.add(st.PostalCode);
                loc.address = String.join(addressParts, ', ');
                loc.mapLink = 'https://maps.google.com?q=' + EncodingUtil.urlEncode(loc.address, 'UTF-8');
                resp.locations.add(loc);
            }
            
            Date tempDate = Date.today().addDays(startOffSet);
            Integer count = 0;
            
            while(count	< totalDated){
                Datetime dt = Datetime.newInstance(tempDate,Time.newInstance(0, 0, 0, 0));
                Integer dayOfWeek = Integer.valueOf(dt.format('u'));
                if(dayOfWeek != 6 && dayOfWeek != 7){
                    resp.availableDates.add(tempDate);
                    count++;
                }
                tempDate = tempDate.addDays(1);
            }
            
            sendResponse(true,200,'Success', resp);
            
        }catch (Exception e) {
            sendResponse(false, 500, e.getMessage(), null);
        }
            
    }
    
    
    @HttpPost
    global static void doPost() {       
        
        try{
            
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            ServiceRequestModel serviceRequestModel = (ServiceRequestModel)JSON.deserializeStrict(jsonBody, ServiceRequestModel.class);
            if (serviceRequestModel.requestType == 'PropertyTransferOffPlan'){
                if(serviceRequestModel.pdcCollectionLocation == null && serviceRequestModel.pdcCollectionDate == null){
                    HexaBPM__Service_Request__c updateSR =new HexaBPM__Service_Request__c();
                    updateSR.Id =  serviceRequestModel.requestId;
                    updateSR.Service_Territory__c = serviceRequestModel.location; 
                    Update updateSR;
                    sendResponse(true, 200, 'Record Updated Successfully', updateSR.Id);
                }else{
                    String pdcLocationName = [SELECT Id, Name FROM ServiceTerritory WHERE Id=:serviceRequestModel.pdcCollectionLocation].Name;
                    HexaBPM__Service_Request__c updateSR =new HexaBPM__Service_Request__c();updateSR.Id =  serviceRequestModel.requestId;updateSR.PDC_Collection_Location__c = pdcLocationName; updateSR.PDC_Collection_date__c = serviceRequestModel.pdcCollectionDate;Update updateSR;sendResponse(true, 200, 'Record Updated Successfully', updateSR.Id);
                }
            }
        } catch (Exception e) {
            sendResponse(false, 500, e.getMessage(), null);
            Logger__c log = LoggerService.createApexLog(e, '', 'UpdateServiceRequestWebService', 'doPost');
            Insert log;
        }
        
    }
    
}