/*
* Name               : CustomerDocumentWebService
* Description        : This class is used to get all Customer's documents like Passport, National Id and others
*/
@RestResource (urlMapping = '/customer/document')
global without sharing class CustomerDocumentWebService {
    
    @HTTPPost
    global static void doPost(String customerId, String documentType, String unitName, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getDocuments(customerId, documentType, unitName);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public static DocumentModel getDocuments(String customerId, String documentType, String unitName) {
        Constant__mdt spaFullForm = Utilities.getConstant('SPA_Full_Form');
        
        DocumentModel documentModel = new DocumentModel();
        
        documentModel.filterUnitNo = unitName;

        unitName = unitName == CustomerAPIConstants.ALL || unitName == CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT ? '' : unitName;

        Set<String> documentPlaceHolderAccountSet = new Set<String>();
        Set<String> documentPlaceHolderSalesOrderSet = new Set<String>();
        for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
            if ((documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT || documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING || documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION) && (documentPlaceHolder.AvailableForCustomer__c || Test.isRunningTest())) {
                if (documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT) {
                    documentPlaceHolderAccountSet.add(documentPlaceHolder.DocumentType__c);
                } else if (documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING || documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION) {
                    documentPlaceHolderSalesOrderSet.add(documentPlaceHolder.DocumentType__c);
                }
            }
        }

        // Get Account Document if Type is blank or Customer Document 
        List<Account> accountList = CustomerServiceUtility.getAccountDetail(' (Id = \'' + customerId + '\') ');
        if (String.isBlank(unitName) || unitName == CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT) {
            
            documentModel.filterUnitNo = String.isNotBlank(documentModel.filterUnitNo) ? documentModel.filterUnitNo : '';
            documentModel.unitName.put(CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT, CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT);
            
            if(!accountList[0].Documents__r.isEmpty()) {
                Boolean isCISSheet = false;
                for (Document__c doc: accountList[0].Documents__r) {
                    if (doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_OTHERS) {
                        continue;
                    }
                    if (documentModel.filterUnitNo != CustomerAPIConstants.ALL && documentModel.filterUnitNo != CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT) {
                        continue;
                    }

                    if (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED ) {//|| doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED
                        DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                        documentQueryModel.title = accountList[0].Name + '_' + documentQueryModel.type;
                        documentQueryModel.isUploaded = true;
                        documentQueryModel.isUploadable = false;
                        documentQueryModel.documentCategory = CustomerAPIConstants.DOCUMENT_CATEGORY_PERSONAL_DOCUMENT;
                        documentQueryModel.unitName = '';
                        documentQueryModel.expiryDate = documentQueryModel.type == CustomerAPIConstants.DOCUMENT_NATIONAL_ID_FRONT_COPY || documentQueryModel.type == CustomerAPIConstants.DOCUMENT_NATIONAL_ID_BACK_COPY ? accountList[0].NationalIdExpiryDate__pc : documentQueryModel.type == CustomerAPIConstants.DOCUMENT_PASSPORT_COPY ? accountList[0].PassportExpiryDate__pc : documentQueryModel.type == CustomerAPIConstants.DOCUMENT_VISA_COPY ? accountList[0].VisaExpiryDate__pc : null;
                        if ((documentPlaceHolderAccountSet.contains(doc.DocumentType__c) || (doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_SIGNED_CIS_SHEET && !isCISSheet)) && (String.isBlank(documentType) || documentQueryModel.type == documentType)) {
                            documentModel.documentType.add(doc.DocumentType__c);
                            isCISSheet = documentQueryModel.type == CustomerAPIConstants.DOCUMENT_TYPE_SIGNED_CIS_SHEET ? true: isCISSheet;
                            documentModel.documents.add(documentQueryModel);
                        }
                    }
                }
            }
        }
		
        // Get Sales Order Document if Type is blank or based on Sales Order
        String salesOrderWhrClause = '';
        String srSalesOrderWhrClause = ' HexaBPM__Document_Master__r.AvailableForCustomer__c = true AND (HexaBPM__Status__c =  \'' + Constants.DOCUMENT_STATUS_UPLOADED + '\' OR HexaBPM__Status__c =  \'' + Constants.DOCUMENT_STATUS_GENERATED + '\' ) ';//OR HexaBPM__Status__c =  \'' + Constants.DOCUMENT_STATUS_COMPLETED + '\'
        
        list<HexaBPM__Service_Request__c>  matchingSR = [SELECT Id, BuyerName__c FROM HexaBPM__Service_Request__c  WHERE BuyerName__c = : accountList[0].Id  AND SRType__c = 'Property Transfer NOC'  AND Origin__c = 'Customer Portal' AND HexaBPM__External_Status_Name__c !='Cancelled' LIMIT 1];
		list<HexaBPM__Service_Request__c> jointOwnerSR = [SELECT Id  FROM HexaBPM__Service_Request__c   WHERE SRType__c = 'Property Transfer NOC'   AND Origin__c = 'Customer Portal'   AND Id IN ( SELECT ServiceRequest__c FROM AgencyTeam__c WHERE Account__c = :accountList[0].Id AND ServiceRequest__r.HexaBPM__External_Status_Name__c !='Cancelled') AND HexaBPM__External_Status_Name__c != 'Cancelled' LIMIT 1];

      
        if (String.isBlank(unitName)) {
            List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{accountList[0].Id});
            String soIdsStr = String.join(soIds, '\',\'');
            salesOrderWhrClause = '(Account__c = \'' + accountList[0].Id + '\' ' +
                (soIds.isEmpty() ? '' : ' OR Id IN (\'' + soIdsStr + '\') ') + ') AND Status__c NOT IN (\'' + Constants.SO_STATUS_CANCELLED + '\', \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\')';
            system.debug('salesOrderWhrClause::'+salesOrderWhrClause);
            // Dynamic where clause for Ind Buyer,Joint buyer and Customer
            if (matchingSR.size()>0) {
                srSalesOrderWhrClause += ' AND HexaBPM__Service_Request__r.BuyerName__c = \'' + matchingSR[0].BuyerName__c + '\'';
            } else if (jointOwnerSR.size()>0) {
                srSalesOrderWhrClause += ' AND HexaBPM__Service_Request__c  = \'' + jointOwnerSR[0].Id + '\'';
            } else {
                srSalesOrderWhrClause += 
                    ' AND (HexaBPM__Service_Request__r.HexaBPM__Customer__c = \'' + accountList[0].Id + '\' ' +
                    (soIds.isEmpty() ? '' : ' OR HexaBPM__Service_Request__r.SalesOrder__c IN (\'' + soIdsStr + '\') ') +
                    ')';
            }
            
        } else {
            salesOrderWhrClause = ' (Id = \'' + unitName + '\') ';
            
            if (matchingSR.size()>0) {
                srSalesOrderWhrClause += ' AND HexaBPM__Service_Request__r.BuyerName__c = \'' + matchingSR[0].BuyerName__c + '\'';
            } else if (jointOwnerSR.size()>0) {
                srSalesOrderWhrClause += ' AND HexaBPM__Service_Request__c  = \'' + jointOwnerSR[0].Id + '\'';
            } else {
                srSalesOrderWhrClause += 
                    ' AND (HexaBPM__Service_Request__r.SalesOrder__c = \'' + unitName + '\') ';
            }
        }
        
        srSalesOrderWhrClause += 
            ' AND HexaBPM__Service_Request__r.SalesOrder__r.Status__c NOT IN (\'' + Constants.SO_STATUS_CANCELLED + '\', \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\')' +
            ' AND HexaBPM__Service_Request__r.HexaBPM__External_Status_Name__c NOT IN (\'' + Constants.SO_STATUS_CANCELLED + '\', \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\')';

        system.debug('where clause::'+srSalesOrderWhrClause);
        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetail(salesOrderWhrClause + ' ORDER BY Unit__r.Name ');

        Constant__mdt constant = Utilities.getConstant('OtherDocumentForCustomerPortalApp');
        List<String> otherDocList = constant != null && constant.ConstantValue__c != null ? constant.ConstantValue__c.split(',') : new List<String>();
        
        List<String> unitIds = new List<String>();
        String filterUnitId = documentModel.filterUnitNo;

        Set<Id> salesOrderIdss = new Set<Id>();
        List<String> salesOrderIds = new List<String>();
		Set<Id> unitIdss = new Set<Id>();
		for (SalesOrder__c salesOrder : salesOrderList) {
             unitIds.add(salesOrder.Unit__c);
    		 salesOrderIdss.add(salesOrder.Id);
             String siD = '\''+salesOrder.Id+'\'';
            SalesorderIds.add(siD);
    		 
		}
        LIst<TransferHistory__c> transferHistoryList = [SELECT Id,FromAccount__c, ToAccount__c,SalesOrder__c,SRNumber__c  FROM TransferHistory__c WHERE SalesOrder__c =:salesOrderIdss ORDER BY CreatedDate DESC LIMIT 1];

        List<HexaBPM__Service_Request__c> transferSRLists = new List<HexaBPM__Service_Request__c>();
        if(transferHistoryList.size() >0){
            transferSRLists = CustomerServiceUtility.getServiceRequestDetail('SalesOrder__c IN ('+string.join(SalesorderIds,',')+') AND HexaBPM__IsClosedStatus__c= true AND Name IN (\'' + transferHistoryList[0].SRNumber__c + '\')');
        }
        System.debug('Chirag'+transferSRLists);
        Map<Id, HexaBPM__Service_Request__c> transferSRMaps = new Map<Id, HexaBPM__Service_Request__c>();
        Set<Id> salesorderAcccSets = new Set<Id>();
        Map<Id,TransferHistory__c>transferMap = new Map<Id,TransferHistory__c>();
        for (HexaBPM__Service_Request__c sr : transferSRLists) {
            transferSRMaps.put(sr.SalesOrder__c, sr);
        }
        for(TransferHistory__c tf:transferHistoryList){
            transferMap.put(tf.SalesOrder__c,tf);
        }

        for (SalesOrder__c salesOrder: salesOrderList) {
            unitIds.add(salesOrder.Unit__c);
            documentModel.filterUnitNo = String.isNotBlank(documentModel.filterUnitNo) ? documentModel.filterUnitNo : salesOrderList[0].Id;
            if (documentModel.filterUnitNo == (String)salesOrder.Id) {
                filterUnitId = salesOrder.Unit__c;
            }
            // Filters
            documentModel.unitName.put(salesOrder.Unit__r.Name, salesOrder.Id);
            HexaBPM__Service_Request__c transferSR = transferSRMaps.get(salesOrder.Id);
           
            Boolean matchFound = transferMap != null && transferSR != null && transferSR.BuyerName__c != null && salesOrder.Account__c ==transferSR.BuyerName__c && transferMap.get(salesOrder.Id)!= null && transferMap.get(salesOrder.Id).ToAccount__c ==salesOrder.Account__c;
			
            Map<Id, Document__c> documentDetailMap = new Map<Id, Document__c>(salesOrder.Documents__r);
            if (!matchFound) {
                for (Document__c doc: salesOrder.Documents__r) {
                    if (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED ) {//|| doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED
                        DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                        documentQueryModel.type = documentQueryModel.type.contains('SPA') ? documentQueryModel.type.replace('SPA', spaFullForm.ConstantValue__c) : documentQueryModel.type;

                        if (documentModel.filterUnitNo != CustomerAPIConstants.ALL && documentModel.filterUnitNo != (String)salesOrder.Id) {
                            continue;
                        }

                        documentQueryModel.title = salesOrder.Unit__r.Name + '_' + documentQueryModel.type;
                        documentQueryModel.isUploaded = true;
                        documentQueryModel.isUploadable = false;
                        documentQueryModel.documentCategory = CustomerAPIConstants.DOCUMENT_CATEGORY_PROPERTY_DOCUMENT;
                        documentQueryModel.unitName = salesOrder.Unit__r.Name;
                        if ((documentPlaceHolderSalesOrderSet.contains(doc.DocumentType__c) || otherDocList.contains(doc.DocumentType__c)) && (String.isBlank(documentType) || documentQueryModel.type == documentType)) {
                            documentModel.documentType.add(documentQueryModel.type);
                            documentModel.documents.add(documentQueryModel);
                        }
                    }
                }
            }
        }

        System.debug('unitIds>>>' + JSON.serialize(unitIds));
        if (!unitIds.isEmpty()) {
            String unitIdsStr = String.join(unitIds, '\',\'');
            String unitWhereClause = ' Unit__c IN (\'' + unitIdsStr + '\') AND DocumentType__c = \'' + Constants.DOCUMENT_TYPE_FLOOR_PLAN + '\' '; 
            List<Document__c> docList = CustomerServiceUtility.getDocumentDetail(unitWhereClause + ' ORDER BY Name ');
            for (Document__c doc: docList) {
                DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);

                if (filterUnitId != CustomerAPIConstants.ALL && filterUnitId != (String)doc.Unit__c) {
                    continue;
                }

                documentQueryModel.title = doc.Unit__r.Name + '_' + documentQueryModel.type;
                documentQueryModel.isUploaded = true;
                documentQueryModel.isUploadable = false;
                documentQueryModel.documentCategory = CustomerAPIConstants.DOCUMENT_CATEGORY_PROPERTY_DOCUMENT;
                documentQueryModel.unitName = doc.Unit__r.Name;
                if (String.isBlank(documentType) || documentQueryModel.type == documentType) {
                    documentModel.documentType.add(documentQueryModel.type);
                    documentModel.documents.add(documentQueryModel);
                }
            }
        }

        List<HexaBPM__SR_Doc__c> srDocList = CustomerServiceUtility.getSRDocDetail(srSalesOrderWhrClause + ' ORDER BY HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name ');
        for (HexaBPM__SR_Doc__c srDoc: srDocList) {
            if (!documentModel.unitName.containsKey(srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name)) {
                documentModel.unitName.put(srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name, srDoc.HexaBPM__Service_Request__r.SalesOrder__c);
            }
            DocumentQueryModel documentQueryModel = new DocumentQueryModel(srDoc);
            
            //Added by Tajinkumar
            if(srDoc.HexaBPM__Document_Master__r.AvailableForCustomer__c && String.isNotBlank(srDoc.HexaBPM__Document_Master__r.Live_Aldar_Display_Name__c)) {
                documentQueryModel.type = srDoc.HexaBPM__Document_Master__r.Live_Aldar_Display_Name__c;
            } else {
                documentQueryModel.type = documentQueryModel.type.contains('SPA') ? documentQueryModel.type.replace('SPA', spaFullForm.ConstantValue__c) : documentQueryModel.type;
            }
            
            if (documentModel.filterUnitNo != CustomerAPIConstants.ALL && documentModel.filterUnitNo != (String)srDoc.HexaBPM__Service_Request__r.SalesOrder__c) {
                continue;
            }

            documentQueryModel.title = documentQueryModel.type;
            documentQueryModel.isUploaded = true;
            documentQueryModel.isUploadable = false;
            documentQueryModel.documentCategory = CustomerAPIConstants.DOCUMENT_CATEGORY_PROPERTY_DOCUMENT;
            documentQueryModel.unitName = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name;
            if (String.isBlank(documentType) || documentQueryModel.type == documentType) {
                if((srDoc.name == 'Provis NOC' || srDoc.name == 'Signed NOC Copy' || srDoc.name== 'NOC Copy') && srDoc.HexaBPM__Status__c == 'Pending Upload'){
                    continue;
                }
                if(srDoc.name == 'Provis NOC'){
                     continue;
                }
                 //Added by Tajinkumar
                if(srDoc.HexaBPM__Service_Request__r != null && srDoc.HexaBPM__Service_Request__r.SRType__c == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE && (srDoc.name == 'Existing Title Deed' || srDoc.name == 'Title Deed Copy')){
                    continue;
                }
               
                documentModel.documentType.add(documentQueryModel.type);
                documentModel.documents.add(documentQueryModel);
            }
        }
		system.debug('documentModel::'+documentModel);
        return documentModel;
    }

    public class DocumentModel {
        public List<DocumentQueryModel> documents                   {get;set;}
        public Map<String, String> unitName                         {get;set;}
        public Set<String> documentType                             {get;set;}
        public String filterUnitNo                                  {get;set;}
        
        public DocumentModel() {
            this.documents = new List<DocumentQueryModel>();
            this.unitName = new Map<String, String>();
            this.documentType = new Set<String>();
            this.filterUnitNo = '';
        }
    }
}