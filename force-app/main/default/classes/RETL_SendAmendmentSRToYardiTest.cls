@IsTest
public class RETL_SendAmendmentSRToYardiTest {
    //
    // ---------------------- MOCK CALLOUT -------------------------
    //
    private class MockYardiCallout implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        String reqBody = req.getBody();

        // Determine whether this is a WorkOrder callout or an Attachment callout
        if (reqBody.contains('"WorkOrder"')) {
            // ------------------ WorkOrder Callout ------------------
            retl_CalloutMuleToSendAmendmentSRToYardi.WorkOrderResponseWrapper outWrap =
                new retl_CalloutMuleToSendAmendmentSRToYardi.WorkOrderResponseWrapper();
            outWrap.Status = 'Success';
            outWrap.Yardi_WO_Code = 'YARDI-12345';

            retl_CalloutMuleToSendAmendmentSRToYardi.SRCaseLeaseAmendmentRequestWrapper wrap =
                (retl_CalloutMuleToSendAmendmentSRToYardi.SRCaseLeaseAmendmentRequestWrapper)
                JSON.deserialize(reqBody,
                    retl_CalloutMuleToSendAmendmentSRToYardi.SRCaseLeaseAmendmentRequestWrapper.class);

            String caseId = (wrap != null && wrap.WorkOrder != null && !wrap.WorkOrder.isEmpty())
                ? wrap.WorkOrder[0].SF_Ref_WO_Id
                : null;
            outWrap.SF_Ref_WO_Id = caseId;

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody(JSON.serialize(outWrap));
            return res;

        } else if (reqBody.contains('"Attachments"')) {
            // ------------------ Attachment Callout ------------------
            retl_CalloutMuleToSendAmendmentSRToYardi.AttachmentRequestWrapper wrap =
                (retl_CalloutMuleToSendAmendmentSRToYardi.AttachmentRequestWrapper)
                JSON.deserialize(reqBody,
                    retl_CalloutMuleToSendAmendmentSRToYardi.AttachmentRequestWrapper.class);

            String sfAttachmentId = null;
            if (wrap != null && wrap.Attachments != null && wrap.Attachments.size() > 0) {
                sfAttachmentId = wrap.Attachments[0].SF_Ref_Attachment_Id;
            }

            retl_CalloutMuleToSendAmendmentSRToYardi.AttachmentResponseWrapper resWrap =
                new retl_CalloutMuleToSendAmendmentSRToYardi.AttachmentResponseWrapper();
            resWrap.Status = 'Success';
            resWrap.Yardi_Attachment_id = 'ATTACH-9999';
            resWrap.SF_Ref_Attachment_Id = sfAttachmentId;
            resWrap.ErrorMessage = '';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type','application/json');
            res.setBody(JSON.serialize(resWrap));
            return res;
        } else {
            // default fallback
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Unknown request type');
            return res;
        }
    }
}
    //
    // ---------------------- MOCK ERROR CALLOUT ---------------------
    //
    private class MockYardiErrorCallout implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"Status":"Error","Message":"Bad Request"}');
            return res;
        }
    }


    //
    // ---------------------- TEST DATA SETUP -------------------------
    //
    private static Case makeCase() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert ord;

        // Dynamic population of fields if they exist
        SObject ordDyn = ord;
        try { ordDyn.put('RETL_Yardi_Id__c', 'TEN-001'); } catch (Exception e) {}
        try { ordDyn.put('RETL_Property_Name__c', 'PROP-001'); } catch (Exception e) {}
        update ordDyn;

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId();

        Case c = new Case(
            Subject = 'Amendment Request',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            RecordTypeId = recordTypeId,
            AccountId = acc.Id
        );
        insert c;
        
        
        Document__c docRec = new Document__c(
            DocumentType__c='Attach Document',
            Case__c = c.Id
        );
        insert docRec;
        
        // -----------------------------
        // 3. Create ContentVersion (auto-creates ContentDocument & CDL)
        // -----------------------------
        ContentVersion cv = new ContentVersion(
            Title = 'File1',
            PathOnClient = 'file1.txt',
            VersionData = Blob.valueOf('Test File'),
            FirstPublishLocationId = docRec.Id
        );
        insert cv;
        
        // Re-query to get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        SObject cDyn = c;
        try { cDyn.put('RETL_SR_Order__c', ord.Id); } catch (Exception e) {}
        try { cDyn.put('RETL_SR_Unit_Number__c', 'UNIT-101'); } catch (Exception e) {}
        try { cDyn.put('RETL_Yardi_Work_Order_Category__c', 'Lease'); } catch (Exception e) {}
        try { cDyn.put('RETL_Yardi_Work_Order_Sub_Category__c', 'Amendment'); } catch (Exception e) {}
        try { cDyn.put('Contact_Name__c', 'Caller Name'); } catch (Exception e) {}
        try { cDyn.put('ContactPhone', '1234567890'); } catch (Exception e) {}
        try { cDyn.put('ContactEmail', 'caller@example.com'); } catch (Exception e) {}
        try { cDyn.put('Description', 'Full description here'); } catch (Exception e) {}
        try { cDyn.put('RETL_SR_Type_Of_Request__c', 'Lease Amendment Reason'); } catch (Exception e) {}
        update cDyn;

        return [SELECT Id, RETL_SR_Yardi_Work_Order_Id__c FROM Case WHERE Id = :c.Id LIMIT 1];
    }


    //
    // ---------------------- TEST #1: SUCCESS CALL OUT -------------------------
    //
    @IsTest
    static void test_pushToYardi_success_updatesCase() {
        Case c = makeCase();

        retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest req =
            new retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest();
        req.caseId = c.Id;

        Test.setMock(HttpCalloutMock.class, new MockYardiCallout());

        Test.startTest();
        retl_CalloutMuleToSendAmendmentSRToYardi.pushToYardiAndUpdate(
            new List<retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest>{ req }
        );
        Test.stopTest();

        Case updatedCase = [SELECT Id, RETL_SR_Yardi_Work_Order_Id__c FROM Case WHERE Id = :c.Id Limit 1];
        System.assertEquals('YARDI-12345', updatedCase.RETL_SR_Yardi_Work_Order_Id__c);
    }


    //
    // ---------------------- TEST #2: WRAPPER BUILD -------------------------
    //
    @IsTest
    static void test_buildCaseWrapper() {
        Case c = makeCase();

        Test.startTest();
        retl_CalloutMuleToSendAmendmentSRToYardi.SRCaseLeaseAmendmentRequestWrapper wrapper =
            retl_CalloutMuleToSendAmendmentSRToYardi.buildCaseWrapper(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals(1, wrapper.WorkOrder.size());
        System.assertEquals(c.Id, wrapper.WorkOrder[0].SF_Ref_WO_Id);
    }


    //
    // ---------------------- TEST #3: ERROR CALL OUT -------------------------
    //
    @IsTest
    static void test_pushToYardi_error_logging() {
        Case c = makeCase();

        retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest req =
            new retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest();
        req.caseId = c.Id;

        Test.setMock(HttpCalloutMock.class, new MockYardiErrorCallout());

        Test.startTest();
        retl_CalloutMuleToSendAmendmentSRToYardi.pushToYardiAndUpdate(
            new List<retl_CalloutMuleToSendAmendmentSRToYardi.PushToYardiRequest>{ req }
        );
        Test.stopTest();

        // No exception expected; just verify case did NOT update
        Case cAfter = [SELECT RETL_SR_Yardi_Work_Order_Id__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, cAfter.RETL_SR_Yardi_Work_Order_Id__c);
    }


}