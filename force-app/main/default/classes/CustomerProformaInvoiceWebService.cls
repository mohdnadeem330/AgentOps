/*
* Name               : CustomerProformaInvoiceWebService
* Description        : This class is used to generate Proforma Invoice of a Installment
*/
@RestResource (urlMapping = '/customer/proformainvoice')
global without sharing class CustomerProformaInvoiceWebService {

    public static Boolean isRunningTest = false;

    @HTTPPost
    global static void doPost(String installmentId, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            ProformaInvoiceModel proformaInvoiceModel = generateProformaInvoice(installmentId, referenceId);
            if (proformaInvoiceModel == null) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            } else {
                handler.response.success = true;
                handler.response.data = proformaInvoiceModel;
            }
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    global static ProformaInvoiceModel generateProformaInvoice(String installmentId, String referenceId) {
        ProformaInvoiceModel proformaInvoiceModel = new ProformaInvoiceModel();
        proformaInvoiceModel.installmentId = installmentId;

        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwnerWithEmail(referenceId);
        String soIdsStr = String.join(soIds, '\',\'');
        
        String salesOrderWhrClause = '';
        if (!soIds.isEmpty()) {
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ';
        } else {
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\') AND ';
        }
        salesOrderWhrClause += ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';

        String query = 'SELECT Id FROM SalesOrder__c WHERE ' + salesOrderWhrClause;
        List<Id> soIdList = new List<Id>();
        for(SalesOrder__c so: Database.query(query)) {
            soIdList.add(so.Id);
        }

        InstallmentLines__c installmentLine = [SELECT Id, Name, InstallmentNumber__c, SalesOrder__c, SalesOrder__r.Unit__r.Name FROM InstallmentLines__c WHERE Id =: installmentId];

        if (soIdList.isEmpty() || !soIdList.contains(installmentLine.SalesOrder__c)) {
            return null;
        }

        PageReference pdf = Page.ProformaInvoicePDFPage;
        pdf.getParameters().put('id', installmentId);
        pdf.setRedirect(true);

        Blob fileContent;
        if (!isRunningTest) {
            fileContent = pdf.getContent();
        }
        String fileName = 'ProformaInvoice-' + installmentLine.SalesOrder__r.Unit__r.Name + '-Installment-' + installmentLine.InstallmentNumber__c + '-' + System.now().format('dd-MM-yyyy') + '.pdf' ;
        
        proformaInvoiceModel.fileDetail = new DocumentQueryModel('pdf', fileContent, fileName);

        return proformaInvoiceModel;
    }
    
    global class ProformaInvoiceModel{
        public String installmentId                             {get;set;}
        public DocumentQueryModel fileDetail                    {get;set;}
    }
}