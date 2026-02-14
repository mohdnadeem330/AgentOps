@RestResource (urlMapping = '/create/receipt')
global with sharing class ReceiptCreateWebService {
    @HTTPPost
    global static void doPost(){

        RestContextHandler handler = new RestContextHandler(false);
        System.debug('convertedData 1');

        try {
            RestRequest restRequest = RestContext.request;
            System.debug('convertedData 2');
            String jsonData = restRequest.requestbody.toString();
            System.debug('convertedData 3'+jsonData);

            CreateReceiptModel convertedData = (CreateReceiptModel)JSON.deserialize(jsonData,CreateReceiptModel.Class);

            System.debug('convertedData '+convertedData);

            ReceiptAcknowledgementController.ReceiptAcknowlegment receiptAcknowlegment =  ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(convertedData.recordId); 
            String wrapperString = JSON.Serialize(receiptAcknowlegment);
            System.debug('wrapperString '+wrapperString);

                if(convertedData.recieptRecord != null && convertedData.orderId != null)
                {
                    System.debug('fileToInsert '+convertedData.fileToInsert);
                    List<Object> filesToInsert = new List<Object>();
                    if(convertedData.fileToInsert != null)
                        filesToInsert.add(convertedData.fileToInsert);
                    System.debug('inside if');
                    ReceiptAcknowledgement__c receiptAcknowledgement = ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(convertedData.recieptRecord, convertedData.recordId, filesToInsert, wrapperString, false);
                    System.debug('inside if1');

                    handler.response.success = true;
                    handler.response.data = receiptAcknowledgement ;
                    handler.finalize();
                }
                
        }
        catch (DMLException exc) {
            System.debug('msg '+ exc.getLineNumber());
            System.debug('line no '+exc.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex)
        {      
            System.debug('msg '+ ex.getLineNumber());
            System.debug('line no '+ex.getMessage());      
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }

    }

    public class CreateReceiptModel{
        public ReceiptAcknowledgement__c recieptRecord {get;set;}
        public Id orderId							   {get;set;}
        public ReceiptAcknowledgementController.FileInfo fileToInsert {get;set;}
        public Id recordId 							   {get;set;}

        public CreateReceiptModel(ReceiptAcknowledgement__c recieptRecord,Id orderId, Id installMentLineId, ReceiptAcknowledgementController.FileInfo fileToInsert)
        {
            this.recieptRecord = recieptRecord;
            this.orderId = orderId;
            this.fileToInsert = fileToInsert;
            this.recordId = recordId;
        }
    }
}