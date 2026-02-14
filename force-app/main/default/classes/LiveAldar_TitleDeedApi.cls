@RestResource (urlMapping = '/query/titledeed')
global without sharing class LiveAldar_TitleDeedApi {
    
    @HttpPost
    global static void doPost(String AccountId, String UnitName) { 
        RestContextHandler handler = new RestContextHandler(false);
        try{
            String titledeedLabel = System.Label.titledeedDate;
           //Added by Tajinkumar as in Custom Label we have Date format as DD-MM-YYYY & in SF we need the Reverse and it was throwing an error while triggering the API.
            Date createdDateTitledeed = Date.valueOf(titledeedLabel.split('/')[2] + '-' + titledeedLabel.split('/')[1] + '-' + titledeedLabel.split('/')[0]);
            Boolean isCOmpleted =  false;
            List<HexaBPM__Service_Request__c> SRequest =[SELECT Id,HexaBPM__External_Status_Name__c,HexaBPM__Parent_SR__c,HexaBPM__Closed_Date_Time__c,CreatedDate FROM HexaBPM__Service_Request__c WHERE  UnitName__c =:UnitName AND HexaBPM__Customer__c=:AccountId AND HexaBPM__External_Status_Name__c!='Draft' AND HexaBPM__External_Status_Name__c !='Cancelled' AND RecordTypeName__c ='Title Deed Registration' AND SalesOrder__c != null AND Proceed_with_Offline__c = false AND HexaBPM__Parent_SR__c != null ORDER BY CreatedDate DESC LIMIT 1 ];
            List<HexaBPM__Service_Request__c> SRequestdata =[SELECT Id,HexaBPM__External_Status_Name__c,HexaBPM__Parent_SR__c,HexaBPM__Closed_Date_Time__c,HandoverDetail__r.HandoverCompletionDate__c FROM HexaBPM__Service_Request__c WHERE  UnitName__c =:UnitName AND HexaBPM__Customer__c=:AccountId AND HexaBPM__External_Status_Name__c!='Draft' AND HexaBPM__External_Status_Name__c !='Cancelled' AND SRType__c ='Handover' ORDER BY CreatedDate DESC LIMIT 1 ];
            List<HexaBPM__SR_Doc__c> titledeedDocList = [SELECT Id,HexaBPM__Document_Name__c,LastModifiedDate FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Document_Name__c ='Title Deed Copy' AND HexaBPM__Service_Request__c =:SRequestdata AND HexaBPM__Status__c ='Uploaded'];
            
            if(SRequest.size() >0 && SRequest[0].CreatedDate <=createdDateTitledeed){
                
                handler.response.data = getresponse();
                isCOmpleted = true;
            }

            if(isCOmpleted ==false && SRequestdata.size() >0 && (SRequestdata[0].HexaBPM__External_Status_Name__c == 'Closed' || SRequestdata[0].HandoverDetail__r.HandoverCompletionDate__c != null || (titledeedDocList.size() >0  && titledeedDocList[0].LastModifiedDate < SRequest[0].HexaBPM__Closed_Date_Time__c && SRequest[0].HexaBPM__Closed_Date_Time__c!= null))) {
                handler.response.data =  getresponse();
                isCOmpleted = true;
            }
            

           if(SRequest.size() >0 && SRequest[0].CreatedDate >=createdDateTitledeed && isCOmpleted ==false){
                if(SRequest[0].HexaBPM__Parent_SR__c != null){
                    if(titledeedDocList.size() >0){
                        if((SRequest[0].HexaBPM__Closed_Date_Time__c == null && titledeedDocList[0].LastModifiedDate != null) || (titledeedDocList[0].LastModifiedDate < SRequest[0].HexaBPM__Closed_Date_Time__c && SRequest[0].HexaBPM__Closed_Date_Time__c!= null)){
                           
                            handler.response.data =  getresponse();
                            isCOmpleted = true;
                        }
                    }
                }
            }

            if(isCOmpleted == false){
            if(SRequestdata.size() >0 || Test.isRunningTest()){
                List<HexaBPM__Step__c> steps = [SELECT Id,HexaBPM__Summary__c,HexaBPM__SR__c,HexaBPM__Step_Status__c,HexaBPM__SR__r.TitleDeedRegistrationFee__c,HexaBPM__SR__r.Pay_By__c,HexaBPM__SR__r.MortgageApplicable__c,HexaBPM__Closed_Date__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =:SRequestdata AND  HexaBPM__Summary__c ='Upload Titldeed' ORDER BY Name DESC];
                if((steps.size() >0 && SRequest.size() ==0 && steps[0].HexaBPM__Closed_Date__c != null && titledeedDocList.size() >0) || (steps.size() >0 && SRequest.size() >0 && steps[0].HexaBPM__Closed_Date__c != null && SRequest[0].HexaBPM__External_Status_Name__c != 'Closed' && titledeedDocList.size() >0)){
                    
                    handler.response.data =  getresponse();
                    isCOmpleted = true;
                }
                if(steps.size() == 0 && SRequest.size() ==0 && titledeedDocList.size() ==0){
                    List<titledeedStep> titleList = new List<titledeedStep>();
                    ServiceRequest sr = new ServiceRequest();
                    sr.UnitName = null;
                    sr.AccountId = null;
                    sr.SRId = null;
                    sr.titledeedSteps =titleList;  
                    handler.response.data = sr;
                    isCOmpleted = true;
                }
            }
        }
        


            if(isCOmpleted == false){
            List<Titledeed_LiveAldar__mdt> titledeed = [SELECT Applicable_values__c,Step_Name__c,StepStatus__c,Step_Number__c,Last_Step__c,Description__c FROM Titledeed_LiveAldar__mdt];
            List<HexaBPM__Step__c> steps = [SELECT Id,HexaBPM__Summary__c,HexaBPM__SR__c,HexaBPM__Step_Status__c,HexaBPM__SR__r.TitleDeedRegistrationFee__c,HexaBPM__SR__r.Pay_By__c,HexaBPM__SR__r.MortgageApplicable__c,HexaBPM__Closed_Date__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =:SRequest  ORDER BY Name DESC];
            List<SalesOrderOtherCharges__c> otherChargeList = [SELECT Id,PendingAmount__c FROM SalesOrderOtherCharges__c WHERE ServiceRequest__c =:SRequest AND TypeOfCharge__c='Title Deed Registration Fee'];
            List<HexaBPM__SR_Doc__c> srdocList = [SELECT Id,HexaBPM__Document_Name__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Document_Name__c ='Title Deed Copy' AND HexaBPM__Service_Request__c =:SRequest];
            if(steps.size() >0){
                ServiceRequest sr = new ServiceRequest();
                sr.UnitName = UnitName;
                sr.AccountId = AccountId;
                sr.SRId = SRequest[0].Id;
                List<titledeedStep> titleList = new List<titledeedStep>();
                for(Titledeed_LiveAldar__mdt tla :titledeed){
                    for(HexaBPM__Step__c stp :steps){
                        if(tla.Applicable_values__c != null && tla.Applicable_values__c.contains(stp.HexaBPM__Summary__c)){
                            if(tla.StepStatus__c == '' || tla.StepStatus__c == null || tla.StepStatus__c.contains(stp.HexaBPM__Step_Status__c)){
                                titledeedStep tl = new titledeedStep();
                                tl.stepName = tla.Step_Name__c;
                                tl.stepNo = tla.Step_Number__c;
                                tl.stepUniqueName = stp.HexaBPM__Summary__c;
                                tl.description =tla.Description__c;
                                if(tla.Last_Step__c == stp.HexaBPM__Summary__c){
                                    tl.isStepCompleted = stp.HexaBPM__Closed_Date__c != null ?true:false;
                                }else{
                                    tl.isStepCompleted = false;
                                }
                                tl.Amount = stp.HexaBPM__SR__r.TitleDeedRegistrationFee__c;
                                if(tla.Step_Name__c =='Payment Pending'){
                                    tl.description ='Your title deed request has been approved. Please pay AED'+stp.HexaBPM__SR__r.TitleDeedRegistrationFee__c+' for Title Deed Registration';
                                    if(otherChargeList.size() >0){
                                        tl.PaymentId = otherChargeList[0].Id;
                                    }
                                }
                                if(srdocList.size() >0){
                                	tl.DocumentId = srdocList[0].Id;
                                    tl.DocumentType = srdocList[0].HexaBPM__Document_Name__c;
                                }
                                tl.Otherpaymentrequired = stp.HexaBPM__SR__r.MortgageApplicable__c =='Yes' ?true:false;
                                
                                    titleList.add(tl);
                                    break;
                                
                                
                            }
                            
                        }
                    }
                }
                sr.titledeedSteps = titleList;
                handler.response.data = sr;
                
            }else{
                List<titledeedStep> titleList = new List<titledeedStep>();
                ServiceRequest sr = new ServiceRequest();
                if(SRequest.size() > 0 && SRequest[0].HexaBPM__External_Status_Name__c =='Closed'){
                   sr = getresponse();
                }
                
                 handler.response.data = sr;
            }
               
        }   
        handler.response.success = true;
            handler.response.statusCode = 200;
            handler.response.message = '';
            handler.finalize();      
        }catch(Exception ex)
        {            
            System.debug('ex'+ex.getMessage()+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    public static ServiceRequest getresponse(){
        List<titledeedStep> titleList = new List<titledeedStep>();
        ServiceRequest sr = new ServiceRequest();
        sr.UnitName = null;
        sr.AccountId = null;
        sr.SRId = null;
        titledeedStep tl = new titledeedStep();
        tl.stepName ='';
        tl.stepUniqueName = 'step0';
        tl.stepNo = 0;
        tl.isStepCompleted = true;
        tl.description ='The document/letter is delivered via email';
        titleList.add(tl);
        sr.titledeedSteps =titleList;
        return sr;

    }
    public class ServiceRequest{
         public String UnitName;
        public String AccountId;
        public String SRId;
        public titledeedStep[] titledeedSteps;
    }
    public class titledeedStep{
        public String stepName;
        public Decimal stepNo;
        public String stepUniqueName;
        public Boolean isStepCompleted;
        public Decimal Amount;
        public String PaymentId;
        public String DocumentId;
        public String DocumentType;
        public Boolean Otherpaymentrequired;
        public String description;
    }
}