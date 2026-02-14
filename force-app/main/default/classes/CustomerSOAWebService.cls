/*
* Name               : CustomerSOAWebService
* Description        : This class is used to generate SOA of a Sales Order
*/
@RestResource (urlMapping = '/customer/generatesoa')
global without sharing class CustomerSOAWebService {

    public static Boolean isRunningTest = false;

    @HTTPPost
    global static void doPost(String orderId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = generateSOA(orderId);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    global static SOAModel generateSOA(String orderId) {
        SOAModel soaModel = new SOAModel();
        soaModel.orderId = orderId;

        SalesOrder__c salesOrder = [SELECT Id, Name, Unit__c, Unit__r.Name FROM SalesOrder__c WHERE Id =: orderId];

        PageReference pdf = Page.StatementOfAccountDocument;
        pdf.getParameters().put('id', orderId);
        pdf.setRedirect(true);

        Blob fileContent;
        if (!isRunningTest) {
            fileContent = pdf.getContent();
        }
        String fileName = 'SOA-' + salesOrder.Unit__r.Name + '-' + System.now().format('dd-MM-yyyy') + '.pdf' ;
        
        soaModel.fileDetail = new DocumentQueryModel('application/pdf', fileContent, fileName);

        return soaModel;
    }
    
    global class SOAModel{
        public String orderId                                   {get;set;}
        public DocumentQueryModel fileDetail                    {get;set;}
    }
}