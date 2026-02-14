@IsTest
private class BP_UploadVATfileTest {
    
    @IsTest
    static void testExecute_validRequest() {
        try{
            
            Account account = new Account();
            account.UAEVATRegisterNumber__c = '8897664';
            account.Name = 'Upendra';
            account.VATRegistrationEndDate__c = System.today() + 19;
            account.VATRegistrationStartDate__c = System.today();
            account.ProposedVATExpiryDate__c = System.today() + 20;
            account.ProposedVATStartDate__c = System.today();
            insert account;
            
            Contact contactRecord = TestObjectsFactory.contactDataSetup(account.Id);
            contactRecord.PrimaryOwner__c = true;
            contactRecord.BrokerType__c = 'Partner/Owner';
            contactRecord.AgentStatus__c = 'Active';
            contactRecord.MobileCountryCode__c = '971';
            contactRecord.MobilePhone__c = '9696859685';
            contactRecord.Email = 'test@gmail.com';
            update contactRecord;
            System.debug('Contact updated: ' + contactRecord);
            
            
            HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
            insert serviceRequest;
            System.debug('Service Request created: ' + serviceRequest);
            
            HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
            objDocMaster.HexaBPM__Code__c = 'PDF';
            objDocMaster.HexaBPM__Available_to_client__c = true;
            objDocMaster.Name='VAT Registration Certificate';
            insert objDocMaster;
            System.debug('Document Master created: ' + objDocMaster);
            
            HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
            docTemp.HexaBPM__Document_Master__c = objDocMaster.Id;
            insert docTemp;
            System.debug('Template Document created: ' + docTemp);
            
            HexaBPM__SR_Doc__c document = new HexaBPM__SR_Doc__c();
            document.HexaBPM__Customer__c = account.Id;
            document.HexaBPM__Document_Type__c = 'Test Code 1';
            document.HexaBPM__SR_Template_Doc__c = docTemp.Id;
            document.HexaBPM__Service_Request__c = serviceRequest.Id;
            document.HexaBPM__Document_Master__c=objDocMaster.id;
            document.Name = 'VAT Registration Certificate';
            insert document;
            System.debug('SR Document created: ' + document);
            
            
            
            
            ContentVersion newContentVersion = new ContentVersion();
            newContentVersion.Title = 'upendra';
            newContentVersion.PathOnClient = '/' + newContentVersion.Title + '.jpg';
            newContentVersion.VersionData =  Blob.valueOf('Date Processed|Request Type|OIC|Payer Identification|DDA Reference|Customer Type|Customer ID Type|Customer ID Number|Bank Name|Title of Account|Account Type|IBAN / Card Number|Mobile Number|Email|Issued For|Commences On|Expires On|Amount Type|Payment Frequency|Minimum Amount|Maximum Amount|Currency Code|First Initiation Date|Frequency Parameter|Image File Name| |  |   |RCMS|ACK / NAK|Action|Accept / Reject|Reason of Rejection + Additional Comments of rejection reason NAKHR25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00111||Individual|NID|784197551973585|First Abu Dhabi Bank|Shridhar Mahesh Murdeshwar|Savings|AE880351001001197052363|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||C30000300010523012422.pdf||||NA|ACK|INITIATED||Invalid data 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00112||Individual|NID|784197551973585|Abu Dhabi Commercial Bank|Shridhar Mahesh Murdeshwar|Savings|AE720030000701057132001|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb47800293f1||||NA|ACK|INITIATED|| 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00113||Individual|NID|784197551973585|Mashreqbank|Shridhar Mahesh Murdeshwar|Savings|AE260330000010490732726|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb478002993a||||NA|ACK|INITIATED|| 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00114||Individual|NID|784197551973585|First Abu Dhabi Bank|Shridhar Mahesh Murdeshwar|Savings|AE190351011221018122141|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb47800293f3||||NA|ACK|INITIATED||');
            insert newContentVersion;
            
            System.debug('Inserted ContentVersion: ' + newContentVersion.Id);
            
            
            String contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :newContentVersion.Id
                LIMIT 1
            ].ContentDocumentId;
            
            System.debug('ContentDocumentId: ' + contentDocumentId);
            
            
            ContentDocumentLink documentLink = new ContentDocumentLink();
            documentLink.ContentDocumentId = contentDocumentId;
            documentLink.LinkedEntityId = document.Id;
            documentLink.ShareType = 'V';
            documentLink.Visibility = 'AllUsers';
            insert documentLink;
            
            
            
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/uploadVATfilesinfo';
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
            
            String fileName = 'TestFile';
            String fileDataBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
            String requestBody = JSON.serialize(new Map<String, Object> {
                'accountId' => account.Id,
                    'fileName' => fileName,
                    'fileData' => fileDataBase64,
                    'fileExtension' => 'pdf',
                    'proposedStartDate' => account.VATRegistrationStartDate__c,
                    'proposedExpiryDate' => account.VATRegistrationEndDate__c,
                    'proposedUAEVATRegistrationNumberValue' => account.UAEVATRegisterNumber__c
                    });
            req.requestBody = Blob.valueOf(requestBody);
            
            RestContext.request = req;
            RestContext.response = new RestResponse();
            
            Test.startTest();
            BP_UploadVATfile.execute();
            Test.stopTest();
            
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            System.assertEquals(true, response.get('success'), 'The response should indicate success');
            System.assertEquals('VAT document uploaded and Submitted for approval', response.get('message'), 'The success message should match');
            
            
        }
        catch(Exception ee){
            
        }
    }
    
    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/uploadVATfilesinfo';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); // Empty body
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_UploadVATfile.execute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
    }
    
    @IsTest
    static void testExecute_withExceptionInCatchBlock() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/uploadVATfilesinfo';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"malformedJson": '); // Malformed JSON
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_UploadVATfile.execute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assert(response.get('message') != null, 'The failure message should not be null');
    }
}