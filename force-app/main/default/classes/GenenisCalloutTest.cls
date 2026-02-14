@isTest
public class GenenisCalloutTest {
    @isTest
    public static void test1() {
       List<ID> TaskVoice = new List<ID>();      
     
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"4531e080-2305-11ef-ac21-02225c1f2725","results":[{"id":"8990fd1c-dd9f-49e9-b780-fb8a7c546595","conversationId":"313ce41b-7f24-4ed1-aa35-51b5d6561210","startTime":"2024-05-21T09:51:00.472Z","endTime":"2024-05-21T09:57:57.422Z","media":"audio","annotations":[],"fileState":"AVAILABLE","mediaUris":{"0":{"mediaUri":"www.google.com","waveformData":[]},"1":{"mediaUri":"www.google.com","waveformData":[]}},"actualTranscodeTimeMs":11716,"maxAllowedRestorationsForOrg":100,"remainingRestorationsAllowedForOrg":100,"sessionId":"7f95f6b0-2547-465a-8993-735d45494218","users":[{"id":"6081208b-6f61-4747-b14d-e5513111a810","name":"Ayman Mostafa","username":"amostafa@aldar.com","selfUri":"/api/v2/users/6081208b-6f61-4747-b14d-e5513111a810"}],"externalContacts":[{"id":"6c47b71f-d892-48a9-8716-edbaa03146b3","selfUri":"/api/v2/externalcontacts/contacts/6c47b71f-d892-48a9-8716-edbaa03146b3"}],"recordingFileRole":"CUSTOMER_EXPERIENCE","originalRecordingStartTime":"2024-05-21T09:51:00.472Z","creationTime":"2024-05-21T09:57:57.819Z","selfUri":"/api/v2/conversations/313ce41b-7f24-4ed1-aa35-51b5d6561210/recordings/8990fd1c-dd9f-49e9-b780-fb8a7c546595"}]}';


          GenenisCalloutMockTest mock = new GenenisCalloutMockTest(responseBody, 201);
          Test.setMock(HttpCalloutMock.class, mock);
        
        Id standardRecordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        
        Case newCase = new Case();
        newCase.recordTypeId = standardRecordTypeId;
        newCase.Type = Constants.PAYMENT_EXTENSION_TYPE;
        newCase.Origin = 'Phone';
        newCase.CustomerType__c = 'Visitor';
        newCase.Subject = 'Test';
        insert newCase;

        Task task = new Task();
        task.Subject = 'Call';
        task.WhatId = newCase.Id;
        task.ActivityDate = Date.today();
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.AgentActivityHistory__c = true;
        task.softphone_it__IWS_Interaction_ID__c = '313ce41b-7f24-4ed1-aa35-51b5d6561210';
        insert task;

        TaskVoice.add(task.Id);

        Test.startTest();
        List<String> mediaUris = GenenisCallout.Sendrequest(TaskVoice);
        Test.stopTest();

       
        System.assertNotEquals(null, mediaUris);
        System.assert(mediaUris.size() > 0, 'Expected at least one media URI to be returned');
        
    }

   }