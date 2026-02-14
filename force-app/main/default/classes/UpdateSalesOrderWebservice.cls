@RestResource (urlMapping = '/update/SalesOrder')
global with sharing class UpdateSalesOrderWebservice {
    @HTTPPost
    global static void doPost(){
        
        
        RestContextHandler handler = new RestContextHandler(true);
        try{

            RestRequest restRequest = RestContext.request;
            String jsonData = restRequest.requestbody.toString();

            SalesOrderUpdateModel convertedData = (SalesOrderUpdateModel)JSON.deserialize(jsonData,SalesOrderUpdateModel.Class);

            SalesOrder__c salesOrderRecord = new SalesOrder__c();
            List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();

            System.debug('so null'+String.isNotBlank(convertedData.salesOrderId));
            
            if(convertedData.salesOrderId != null && String.isNotBlank(convertedData.salesOrderId)){
                system.debug('convertedData.orderSubStatus '+convertedData.orderSubStatus);
                 
                
                    if(convertedData.orderSubStatus == null || convertedData.orderSubStatus == ''){
                        if(convertedData.mortageRequest != null && convertedData.mortageRequest.MortgageApplicable__c != null)  {
                            salesOrderRecord = convertedData.mortageRequest;
                        }
                        
                        if(convertedData.specialCondition != null && convertedData.specialCondition.SpecialConditionApplicable__c != null) {
                            salesOrderRecord = convertedData.specialCondition;
                        }
                        salesOrderRecord.Id = convertedData.salesOrderId; 
                        if(convertedData.customerSignedtheSPA != null && convertedData.customerSignedtheSPADate != null) {
                            salesOrderRecord.CustomerSPASigned__c = Boolean.valueOf(convertedData.customerSignedtheSPA);
                            salesOrderRecord.CustomerSignedSPADate__c = convertedData.customerSignedtheSPADate;
                            
                        }
                        else if (convertedData.customerSignedtheSPA != null){
                            salesOrderRecord.CustomerSPASigned__c = Boolean.valueOf(convertedData.customerSignedtheSPA);
                            salesOrderRecord.CustomerSignedSPADate__c = null;                    
                        }
                        
                        //Added By Tharun for SPA Signature - 02/02/2023
                        if(convertedData.spaSignatureType != null && convertedData.spaSignatureType != ''){
                            salesOrderRecord.SignatureType__c = convertedData.spaSignatureType;
                        }
                        // Digital to Physical SPA changes by bashim
                        if( convertedData.spaSignatureTypeReason != null  && convertedData.spaSignatureTypeReason != ''){
                            salesOrderRecord.SPASignaturetypechangereasonpicklist__c = convertedData.spaSignatureTypeReason;
                            if (!String.isBlank(convertedData.salesOrderId) && !String.isBlank(convertedData.fileName) && !String.isBlank(convertedData.fileBody)) {                                
                                      
                                ContentVersion contentVersion = new ContentVersion();
                                contentVersion.Title = convertedData.fileName;
                                contentVersion.PathOnClient = convertedData.fileName;
                                contentVersion.VersionData = EncodingUtil.base64Decode(convertedData.fileBody);
                                contentVersion.FirstPublishLocationId = convertedData.salesOrderId;
                                insert contentVersion;
                            }
                        }
                        if( convertedData.spaSignatureTypeComments != null  && convertedData.spaSignatureTypeComments != ''){
                            salesOrderRecord.Signaturetypechangereason__c = convertedData.spaSignatureTypeComments;
                        }
                        
                        List<Document__c> updateDocumentList = new List<Document__c>();
                        if(convertedData.generateDocuments == 'TRUE'){
                            List<Document__c> documentList = DocumentService.getSalesOrderDocuments(convertedData.salesOrderId);
                            
                            For(Document__c document : documentList){
                                document.GenerateDocument__c = TRUE;
                                updateDocumentList.add(document);
                            }
                            
                            
                            if(updateDocumentList.size() > 0)
                                update updateDocumentList;
                            
                        }
                        update salesOrderRecord;
                    }
                    else if( convertedData.orderSubStatus != null ){
                        String msg = SalesOrderSubStatusController.saveSubStatus(convertedData.salesOrderId, convertedData.orderSubStatus, '', '', '');
                    }  if(convertedData.ddOptOutReason != null){
                        system.debug('ddOptOutReason::'+convertedData.ddOptOutReason);
                        salesOrderRecord.DDOptOutReason__c = convertedData.ddOptOutReason;
                        update salesOrderRecord;
                    }  
                
            handler.response.success = true;
            handler.response.data = salesOrderRecord;
            handler.finalize();

            }
            else {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = Constants.INVALID_REQUEST_BODY;
            }            
            
        } catch (DMLException exc) {
            System.debug('line number '+exc.getLineNumber());
            System.debug('msg '+exc.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception e) {
            System.debug('line number '+e.getLineNumber());
            System.debug('msg '+e.getMessage());
            system.debug('EXCEPTION '+e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public class SalesOrderUpdateModel{
        public SalesOrder__c specialCondition   {get;set;}
        public SalesOrder__c mortageRequest     {get;set;}
        public String orderSubStatus            {get;set;}
        public Id salesOrderId                  {get;set;}
        public String generateDocuments         {get;set;}
        public String customerSignedtheSPA      {get;set;}
        public Date customerSignedtheSPADate  	{get;set;}
        public String spaSignatureType			{get;set;} //Added By Tharun for SPA Signature - 02/02/2023
        public String spaSignatureTypeReason	{get;set;} //Added By Tharun for SPA Signature - 02/02/2023
        // digital to physical signature changes
        public String spaSignatureTypeComments		{get;set;}
        // digital to physical signature changes
        public String fileName  {get;set;}
        public String fileBody  {get;set;}
        public boolean isDDOptoutUpdate         {get;set;}
        public String ddOptOutReason        	{get;set;}
        public SalesOrderUpdateModel(SalesOrder__c specialCondition, SalesOrder__c mortageRequest, String orderSubStatus, Id salesOrderId, String generateDocuments, String customerSignedtheSPA, Date customerSignedtheSPADate, String spaSignatureType,String spaSignatureTypeReason, String spaSignatureTypeComments, Boolean isDDOptoutUpdate, String ddOptOutReason, String fileName, String fileBody){
            this.specialCondition = specialCondition;
            this.mortageRequest = mortageRequest;
            this.orderSubStatus = orderSubStatus;
            this.salesOrderId = salesOrderId;
            this.generateDocuments = generateDocuments;
            this.customerSignedtheSPA = customerSignedtheSPA;
            this.customerSignedtheSPADate = customerSignedtheSPADate;
            this.spaSignatureType = spaSignatureType;
            this.spaSignatureTypeReason = spaSignatureTypeReason;
             // digital to physical signature changes
            this.spaSignatureTypeComments = spaSignatureTypeComments;
            // digital to physical signature changes
            this.fileName = fileName;
            this.fileBody = fileBody;
            this.isDDOptoutUpdate = isDDOptoutUpdate;
            this.ddOptOutReason = ddOptOutReason;
        }
    }
}