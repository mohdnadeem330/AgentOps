@isTest
public class BatchToDirectDebitCalloutAPITest {
    
    public static string ADCBBankName   		           = 'Abu Dhabi Commercial Bank';
    public static string ADIBBankName   		           = 'Abu Dhabi Islamic Bank';
    public static string FABBankName   		           	   = 'Abu Dhabi FAB Bank';
    
    
    @testSetup
    static void makeData(){
        // Account acc = TestObjectsFactory.getPersonAccountRecord();
        // insert acc;

        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.SourceofFunds__pc = 'Employment Income';
        acc.Company__pc = 'AbuDhabi investment Authority';
        acc.Position__pc = 'Manager';
        acc.CompanyAddress__pc = 'AbuDhabi investment 211 corniche AD';
        acc.AnnualIncome__pc = 130000;
        acc.NoofYearswithCompany__pc = 32;
        acc.Industry = 'Government';
        acc.CustomerBankName__c = 'Abhu Dhabi';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        acc.NationalIdNumber__pc = '784198363604806';
        acc.EmploymentStatus__pc  = 'Employed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = acc.id;
        ddr.AmountType__c  = 'Variable';
        ddr.DebitRequestInstanceAllowed__c = '5';
        ddr.CustomerAccountName__c = acc.Name;
        ddr.PayingBankRoutingCode__c = '050';
        ddr.CustomerIdType__c = 'UAE Emirates Identity Card';
        ddr.CustomerIDNumber__c = '784123123123123';
        
        insert ddr;
        
        Document__c document = TestObjectsFactory.getDDRDocument(ddr.id);
        insert document;
        List<DDTransaction__c> lstDDT = new List<DDTransaction__c>();
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, ADCBBankName);
        lstDDT.add(ddt);
        DDTransaction__c ddt1 = TestObjectsFactory.createDDTransactions(ddr.id, ADCBBankName);
        ddt1.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.AMENDMENT;
        lstDDT.add(ddt1);
        DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr.id, ADCBBankName);
        ddt2.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.CANCELLATION;
        lstDDT.add(ddt2);
        insert lstDDT; 
        
        List<DDTransaction__c> listOfDDTForADIB = new List<DDTransaction__c>();
        DDTransaction__c ddt11 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt11.DDAFileName__c = 'test.pdf';
        listOfDDTForADIB.add(ddt11);
        DDTransaction__c ddt12 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt12.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.COLLECTION;
        listOfDDTForADIB.add(ddt12);
        DDTransaction__c ddt13 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt13.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.CANCELLATION;
        
        listOfDDTForADIB.add(ddt13);
        insert listOfDDTForADIB;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = ddt.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        ContentVersion content1=new ContentVersion(); 
        content1.Title='Header_Picture1'; 
        content1.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob1=Blob.valueOf('Unit Test ContentVersion Body'); 
        content1.VersionData=bodyBlob1; 
        content1.origin = 'H';
        insert content1;
        ContentDocumentLink contentlink1=new ContentDocumentLink();
        contentlink1.LinkedEntityId = ddt11.id;
        contentlink1.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink1.ShareType = 'I';
        contentlink1.Visibility = 'AllUsers'; 
        insert contentlink1;
    }
    @isTest
    public static void testDirectDebitBatchRegistration() {
        Test.startTest();
        Account acc = [SELECT Id,Name From Account Limit 1];
        DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        ddr.CustomerBankName__c = ADIBBankName;
        ddr.PayerAccount__c = acc.id;
        ddr.AmountType__c  = 'Variable';
        ddr.DebitRequestInstanceAllowed__c = '5';
        ddr.CustomerAccountName__c = acc.Name;
        ddr.PayingBankRoutingCode__c = '050';
        ddr.CustomerIdType__c = 'UAE Emirates Identity Card';
        ddr.CustomerIDNumber__c = '784123123123123';
        
        update ddr;
       
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        insert ddt;
        List<Id> lstDDTs = new List<Id>();
        lstDDTs.add(ddt.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_REGISTRATION, 'New Registration');
        database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    public static void testDDBatchFileUploadADIB() {
        Test.startTest();
        
        DirectDebitRequest__c ddr = [SELECT Id,CustomerBankName__c FROM DirectDebitRequest__c Limit 1];
        ddr.CustomerBankName__c = ADIBBankName;
        
        update ddr;
        
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        insert ddt;
        
        DDTransaction__c ddt1 = [SELECT Id FROM DDTransaction__c WHERE Requesttype__c = 'New Registration' AND DDBank__c =:ADIBBankName Limit 1];
                                
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.pdf'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = ddt1.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        List<Id> lstDDTs = new List<Id>();
        lstDDTs.add(ddt.id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_FILE_UPLOAD, 'New Registration');
        database.executeBatch(batch);
        Test.stopTest();
    }
    @isTest
    public static void testDDBatchFileUploadADCB() {
        Test.startTest();
        
        DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c WHERE Requesttype__c = 'New Registration' AND DDBank__c =:ADCBBankName];
                                
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.pdf'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = ddt.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        List<Id> lstDDTs = new List<Id>();
        lstDDTs.add(ddt.id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_FILE_UPLOAD, 'New Registration');
        database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    public static void testDirectDebitBatchCollection() {
        Test.startTest();
            List<Id> lstDDTs = new List<Id>();
            for (DDTransaction__c ddt : [SELECT Id FROM DDTransaction__c]) {
                lstDDTs.add(ddt.Id);
            }
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_BULK_COLLECTION_MANDATE, 'Collection');
        	database.executeBatch(batch);
            //BAtchToDirectDebitEnquiryCalloutAPI bt = new BAtchToDirectDebitEnquiryCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_MANDATE_ENQUIRY, 'Cancellation');
            //database.executeBatch(bt);
        Test.stopTest();
    }
    @isTest
    public static void testDirectDebitBatchCancellation() {
        Test.startTest();
            List<Id> lstDDTs = new List<Id>();
            for (DDTransaction__c ddt : [SELECT Id FROM DDTransaction__c]) {
                lstDDTs.add(ddt.Id);
            }
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_REGISTRATION, 'Cancellation');
            database.executeBatch(batch);
            //BAtchToDirectDebitEnquiryCalloutAPI bt = new BAtchToDirectDebitEnquiryCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_REGISTRATION, 'Cancellation');
            //database.executeBatch(bt);  
        BatchToDirectDebitCalloutHelper.PrepareDataForCallout(lstDDTs);
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransaction() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"ddsRequest": [{"soReferenceNumber": "OU#00000173", "fileName_req": "C300003-360000067-270423-000101.txt","fileName_pdf": "C300003-360000067-270423-000101.pdf", "fileExtention_req": "TEXT", "fileExtention_pdf": "PDF", "ddTransactionStatus": "Unprocessed","ddTransactionNumber": "DDT-000101", "ddTransactionId": "'+ddt.id+'","ddResponseFileName": "050003C3100033002305010101.DDR","ddRequestType": "New Registration","ddrequestNumber": "DDT-000101","ddBankingReferenceNumber": "00331023510101","ddBank": "First Abu Dhabi Bank","base64_req": "UmVxdWVzdCBUeX", "base64_pdf":  "UmVxdWVzdCBUeX" }]}';
            String responseBody = '{ "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "55881770-e7e6-11ed-8eb8-067717201602",  "results": { "ddsRes": [{ "sfRequestId": "55881770-e7e6-11ed-8eb8-067717201602", "ddTransactionId": "'+ddt.id+'", "status": "Failure","errorMsg": "Error while creating DD ,Error:Exception :ORA-00001: unique constraint (XXCONV.SFDDSINT_PK) violated"} ]}}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADCBRegistrationMandate' ,'201');
        Test.stopTest();
    }
    
    @isTest
    public static void testupdateDDTransactionRegResponse() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"RQST","PreApprovalReference":"","PayerId":"SUS01","PayerDetails":{"MobileNumber":"+971123456789","FullName":"Abeer HaAbeer AbeerAbeer Al Hajri Al Hajri","EmailId":"abc@youpmail.com","BankCode":"050"},"MandateReferenceNumber":"9901000000016","MandateDetails":{"PaymentDetails":{"PaymentFrequency":"D","MinimumAmount":{"Currency":"AED","Amount":"1.00"},"MaximumAmount":{"Currency":"AED","Amount":"434031.90"},"IBAN":"AE070500000000017222004","DefinedDays":""},"OICCode":"940000331","FundingAccountType":"C","DDAIssuedFor":"404","DDAInstancesAllowed":"5","DDAFileName":"0033000007262404.pdf","DDAExpiryDate":"31-05-2027","DDACommencementDate":"02-04-2024","DDAAmountType":"V"},"CustomerReference":"YasParkViews-NY2_03-V-120-DD-00442","CustomerDetails":{"CustomerType":"IN","CustomerIdType":"EIDAC","CustomerId":"784198363604806"},"CaptureMode":"P","CancellationCode":"P50"}}';
            String responseBody = '{"Data":{"BankReference":"202404010009323","CustomerReference":"YasParkViews-NY2_03-V-120-DD-00442","OICCode":"940000331","DDAFileName":"0033000007262404.pdf","MandateReferenceNumber":"9901000000016"}}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADCBRegistrationMandate' ,'201');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionRegResponseFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"RQST","PreApprovalReference":"","PayerId":"SUS01","PayerDetails":{"MobileNumber":"+971123456789","FullName":"Abeer HaAbeer AbeerAbeer Al Hajri Al Hajri","EmailId":"abc@youpmail.com","BankCode":"050"},"MandateReferenceNumber":"9901000000016","MandateDetails":{"PaymentDetails":{"PaymentFrequency":"D","MinimumAmount":{"Currency":"AED","Amount":"1.00"},"MaximumAmount":{"Currency":"AED","Amount":"434031.90"},"IBAN":"AE070500000000017222004","DefinedDays":""},"OICCode":"940000331","FundingAccountType":"C","DDAIssuedFor":"404","DDAInstancesAllowed":"5","DDAFileName":"0033000007262404.pdf","DDAExpiryDate":"31-05-2027","DDACommencementDate":"02-04-2024","DDAAmountType":"V"},"CustomerReference":"YasParkViews-NY2_03-V-120-DD-00442","CustomerDetails":{"CustomerType":"IN","CustomerIdType":"EIDAC","CustomerId":"784198363604806"},"CaptureMode":"P","CancellationCode":"P50"}}';
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADCBRegistrationMandate' ,'500');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionFileUpload() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"RQST","OICCode":"940000331","FileName":"0033000007262404.pdf","File": "wwewewsfsfsfssdsd"';
            String responseBody = '{ "Data": { "BankReference": " ADCB74158963587", "OICCode": "12345678", "fileName": " testsFile1.pdf" } }';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADIBRegistrationMandateFileUpload' ,'201');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionFileUploadFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"RQST","OICCode":"940000331","FileName":"0033000007262404.pdf","File": "wwewewsfsfsfssdsd"';
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADCBRegistrationMandate' ,'500');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionCollection() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"COLL","OICCode":"940000331","Collection":[{"RepresentmentFlag":"","MandateReferenceNumber":"9901000000112","Instruction":{"OriginatorAccountNumber":"12961810","IBAN":"AE710500000000028153237","DueDate":"18-04-2024","ClaimedAmount":{"Currency":"AED","Amount":"200.00"}},"DDRReference":"94000033142024000004242","CustomerReference":"0045800749"}]}}';
            String responseBody = '{"Data":{"CollectionBatchId":"54500189851","Collection":[{"BankReference":"I4O00009644","CustomerReference":"0045800749","OriginatorAccountNumber":"12961810","MandateReferenceNumber":"9901000000112"}]}}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADIBCollectionMandate' ,'201');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionCollectionFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"COLL","OICCode":"940000331","Collection":[{"RepresentmentFlag":"","MandateReferenceNumber":"9901000000112","Instruction":{"OriginatorAccountNumber":"12961810","IBAN":"AE710500000000028153237","DueDate":"18-04-2024","ClaimedAmount":{"Currency":"AED","Amount":"200.00"}},"DDRReference":"94000033142024000004242","CustomerReference":"0045800749"}]}}';
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADIBCollectionMandate' ,'500');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionCancellation() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"CNCL","PreApprovalReference":"","PayerId":"SUS01","PayerDetails":{"MobileNumber":"+971586312767","FullName":"Fahad Farooq","EmailId":"rsrivastava@aldar.com","BankCode":"050"},"MandateReferenceNumber":"9901000000112","MandateDetails":{"PaymentDetails":{"PaymentFrequency":"D","MinimumAmount":{"Currency":"AED","Amount":"1.00"},"MaximumAmount":{"Currency":"AED","Amount":"445226.80"},"IBAN":"AE710500000000028153237","DefinedDays":""},"OICCode":"940000331","FundingAccountType":"C","DDAIssuedFor":"404","DDAInstancesAllowed":"5","DDAFileName":"0033000007532404.pdf","DDAExpiryDate":"31-05-2027","DDACommencementDate":"18-04-2024","DDAAmountType":"V"},"CustomerReference":"YasParkViews-NY2_03-V-054-DD-00458","CustomerDetails":{"CustomerType":"IN","CustomerIdType":"EIDAC","CustomerId":"784198363604806"},"CaptureMode":"P","CancellationCode":"P50"}}';
            String responseBody = '{"Data":{"BankReference":"202404180009428","CustomerReference":"YasParkViews-NY2_03-V-054-DD-00458","OICCode":"940000331","DDAFileName":"0033000007532404.pdf","MandateReferenceNumber":"9901000000112"}}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADIBRegistrationCancel' ,'201');
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionCancellationFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String requestBody = '{"Data":{"RequestType":"COLL","OICCode":"940000331","Collection":[{"RepresentmentFlag":"","MandateReferenceNumber":"9901000000112","Instruction":{"OriginatorAccountNumber":"12961810","IBAN":"AE710500000000028153237","DueDate":"18-04-2024","ClaimedAmount":{"Currency":"AED","Amount":"200.00"}},"DDRReference":"94000033142024000004242","CustomerReference":"0045800749"}]}}';
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}';
            BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(responseBody, new List<Id>{ddt.id}, requestBody,'ADIBRegistrationCancel' ,'500');
        Test.stopTest();
    }
    
     @isTest
    public static void testDDBatchCollectionEnquiryADIB() {
        Test.startTest();
        List<Id> lstDDTs = new List<Id>();
        for (DDTransaction__c ddt : [SELECT Id FROM DDTransaction__c WHERE Requesttype__c =: BatchToDirectDebitCalloutAPIHelper.COLLECTION]) {
            lstDDTs.add(ddt.Id);
        }
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        BAtchToDirectDebitEnquiryCalloutAPI bt = new BAtchToDirectDebitEnquiryCalloutAPI(lstDDTs, BatchToDirectDebitCalloutAPI.DDAPI_BULK_COLLECTION_MANDATE, 'Collection');
        database.executeBatch(bt);
        Test.stopTest();
    }
    
    @isTest
    public static void testDDBatchMandateEnquiryADIB() {
        Test.startTest();
        Account acc = [SELECT Id,Name From Account Limit 1];
        DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        ddr.CustomerBankName__c = ADIBBankName;
        ddr.PayerAccount__c = acc.id;
        ddr.AmountType__c  = 'Variable';
        ddr.DebitRequestInstanceAllowed__c = '5';
        ddr.CustomerAccountName__c = acc.Name;
        ddr.PayingBankRoutingCode__c = '050';
        ddr.CustomerIdType__c = 'UAE Emirates Identity Card';
        ddr.CustomerIDNumber__c = '784123123123123';
        
        update ddr;
       
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt.BankReferenceNumber__c = '123456';
        ddt.TransactionStatus__c = 'Processed by Salesforce';
        insert ddt;
        List<Id> lstDDTs = new List<Id>();
        lstDDTs.add(ddt.Id);        
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        BAtchToDirectDebitEnquiryCalloutAPI bt = new BAtchToDirectDebitEnquiryCalloutAPI(lstDDTs, 'MandateEnquiry', 'New Registration');
        database.executeBatch(bt);
        Test.stopTest();
    }
    
    @isTest
    public static void testupdateDDTransactionEnquiry() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String responseBody = '{"Data":{"CustomerReference":"YasParkViews-NY2_03-V-054-DD-00458","BankReference":"202404180009426","MandateReferenceNumber":"9901000000112","RequestType":"RQST","PayerId":"SUS01","DDRReference":"","CustomerDetails":{"CustomerType":"IN","CustomerId":"784198363604806","CustomerIdType":"UAE Emirates Identity Card"},"PayerDetails":{"FullName":"Fahad Farooq","MobileNumber":"+971586312767","EmailId":"rsrivastava@aldar.com"},"MandateDetails":{"OICCode":"940000331","FundingAccountType":"CUR","DDAIssuedFor":"404","DDACommencementDate":"18-04-2024","DDAExpiryDate":"31-05-2027","DDAAmountType":"P","DDAInstancesAllowed":"5","DDAFileName":"0033000007492404.pdf","PaymentDetails":{"PaymentFrequency":"Daily","DefinedDays":"","IBAN":"AE710500000000028153237","MinimumAmount":{"Amount":"1","Currency":"AED"},"MaximumAmount":{"Amount":"445226.8","Currency":"AED"}}},"Status":{"Code":"S","Message":"Sent to Central MMS"}}}';
            BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse('ADIBRegistrationMandateEnquiry',200,responseBody,new List<Id>{ddt.id});
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionEnquiryFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}}';
            BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse('ADIBRegistrationMandateEnquiry',500,responseBody,new List<Id>{ddt.id});
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionEnquiryFail200() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}}';
            BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse('ADIBRegistrationMandateEnquiry',200,responseBody,new List<Id>{ddt.id});
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionEnquiryColl() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String responseBody = '{"Data":{"RequestType":"COLL","Collection":[{"CustomerReference":"0045800749","BankReference":"54500189851","MandateReferenceNumber":"9901000000112","DDRReference":"94000033142024000004242","Instruction":{"OICCode":"940000331","OriginatorAccountNumber":"12961810","IBAN":"AE710500000000028153237","DueDate":"2024-04-18 00:00:00","ClaimedAmount":{"Amount":"200","Currency":"AED"}},"Status":{"Code":"S","Message":"Sent For Clearing"}}]}}';
            BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse('ADIBRegistrationMandateCollectionEnquiry',200,responseBody,new List<Id>{ddt.id});
        Test.stopTest();
    }
    @isTest
    public static void testupdateDDTransactionEnquiryCollFail() {
        Test.startTest();
            DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
            String responseBody = '{"Code":"API401","Id":"","Message":"Authentication Failed","Errors":[{"ErrorCode":"","Message":""}]}}';
            //BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse('ADIBRegistrationMandateCollectionEnquiry',500,responseBody,new List<Id>{ddt.id});
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock{
        DDTransaction__c ddt = [SELECT Id FROM DDTransaction__c LIMIT 1];
        
        public HTTPResponse respond(HTTPRequest req){   
            HttpResponse res = new HttpResponse();
            String jsonInput = '{ "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "55881770-e7e6-11ed-8eb8-067717201602",  "results": { "ddsRes": [{ "sfRequestId": "55881770-e7e6-11ed-8eb8-067717201602", "ddTransactionId": "'+ddt.id+'", "status": "Success","errorMsg": ""} ]}}';
            res.setHeader('Content-Type', 'application/json');
            res.setBody(jsonInput);            
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    public static void testMandateCodeMessage(){
        Test.startTest();
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('C');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('M');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('A');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('F');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('K');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('N');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('R');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('U');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('Y');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('V');
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCodeMessage('P');
        Test.stopTest();
    }
    @isTest
    public static void testCollectionCodeMessage(){
        Test.startTest();
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('P');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('int');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('NK');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('R');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('PP');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('K');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('S');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('C');
        BatchToDirectDebitEnquiryCalloutHelper.getCollectionCodeMessage('SP');
        Test.stopTest();
    }
        
    @isTest
    public static void testcalloutService(){
        Test.startTest();
        DDTransaction__c ddt = [SELECT Id,Name FROM DDTransaction__c LIMIT 1];
        Map<String, String> paramToBeReplacedInEndPoint = new Map<String, String>();
        Map<String, String> queryParams = new Map<String, String>();
        paramToBeReplacedInEndPoint.put('(OICCode)', 'test123');
        paramToBeReplacedInEndPoint.put('(RequestType)', 'RQST');
        queryParams.put('customerReference', ddt.Name);
        BatchToDirectDebitEnquiryCalloutHelper.calloutService('ADIBRegistrationMandateEnquiry',true,paramToBeReplacedInEndPoint,queryParams,new List<Id>{ddt.id});
        BatchToDirectDebitEnquiryCalloutHelper.getMandateCollectionEnquiryResult(new List<DDTransaction__c>{ddt},BatchToDirectDebitCalloutAPIHelper.COLLECTION);
        Test.stopTest();
    } 
    
    @isTest
    public static void testWrapper1(){
        // Prepare test JSON data
        String jsonData = '{"Data":{"RequestType":"Type1","CustomerReference":"Ref1","PayerId":"Payer1","CancellationCode":"Code1","CustomerDetails":{"CustomerType":"Type1","CustomerId":"ID1","CustomerIdType":"TypeID1"},"PayerDetails":{"FullName":"Name1","MobileNumber":"1234567890","EmailId":"email@example.com","BankCode":"Bank1"},"MandateDetails":{"OICCode":"OIC1","FundingAccountType":"Type1","DDAIssuedFor":"For1","DDACommencementDate":"2024-04-24","DDAExpiryDate":"2025-04-24","DDAAmountType":"Amount1","DDAInstancesAllowed":"Allowed1","DDAFileName":"File1","PaymentDetails":{"PaymentFrequency":"Frequency1","IBAN":"IBAN1","DefinedDays":"Days1","MinimumAmount":{"Amount":"MinAmount1","min_Currency":"Currency1"},"MaximumAmount":{"Amount":"MaxAmount1","max_Currency":"Currency2"}}},"CaptureMode":"Mode1","PreApprovalReference":"Ref2","MandateReferenceNumber":"MandateRef1"}}';
        
        // Call the parse method
        ADCBAndADIBMandateWrapperClass result = ADCBAndADIBMandateWrapperClass.parse(jsonData);
        
        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.Data, 'Data should not be null');
        System.assertEquals('Type1', result.Data.RequestType, 'RequestType should match');
        System.assertEquals('Ref1', result.Data.CustomerReference, 'CustomerReference should match');
        System.assertEquals('Payer1', result.Data.PayerId, 'PayerId should match');
        // Add more assertions for other fields if needed
    
    }
}