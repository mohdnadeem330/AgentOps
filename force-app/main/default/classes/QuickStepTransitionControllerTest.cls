/******************************************************************************************
 *  Author      : Rajil
 *  Company     : Pwc
 *  Date        : 09/02/2021
 *  Description : Test Class for QuickStepTransitionController
*******************************************************************************************/
@isTest
private class QuickStepTransitionControllerTest {

        static testMethod void TestQuickStepTransition() {

        map<string,string> mapQueue = new map<string,string>();
        for(Group grp:[select id,name,developername from Group where type='Queue']){
            mapQueue.put(grp.developername,grp.Id);
        }

        Group g1 = new Group(Name='Client Approver',DeveloperName='Client_Approver',type='Queue');
        if(mapQueue.get('Client_Approver')!=null)
            g1.Id = mapQueue.get('Client_Approver');
        upsert g1;

        Group g2 = new Group(Name='Client Entry User',DeveloperName='Client_Entry_User',type='Queue');
        if(mapQueue.get('Client_Entry_User')!=null)
            g2.Id = mapQueue.get('Client_Entry_User');
        upsert g2;

        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__Step__c');
        insert q1;

        QueuesObject q2 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__SR_Steps__c');
        insert q2;

        QueuesObject q3 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__Step_Template__c');
        insert q3;

        QueuesObject ITq1 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__Step__c');
        insert ITq1;

        QueuesObject ITq2 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__SR_Steps__c');
        insert ITq2;

        QueuesObject ITq3 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__Step_Template__c');
        insert ITq3;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            
            Account objAccount = new Account();
            objAccount.Name = 'Test Account';
            objAccount.Phone = '1234567890';
            insert objAccount;

            Contact objContact = new Contact();
            objContact.LastName = 'Test Contact';
            objContact.FirstName = 'test';
            objContact.AccountId = objAccount.Id;
            objContact.Email = 'test@NSI.com';
            objContact.Phone = '1234567890';
            insert objContact;

            Product2 objProduct = new Product2();
            objProduct.Name = 'Product';
            objProduct.IsActive = true;
            insert objProduct;

            Pricebook2 objPricebook = new Pricebook2();
            objPricebook.Name = 'Test Price Book';
            objPricebook.IsActive = true;
            objPricebook.Description = 'Test Description';
            insert objPricebook;

            PricebookEntry objPBE = new PricebookEntry();

            for(Pricebook2 objPB : [select Id,Name,IsActive from Pricebook2 where IsStandard = true]){
            objPricebook = objPB;
            objPBE.Product2Id = objProduct.Id;
            objPBE.Pricebook2Id = objPB.Id;
            objPBE.UnitPrice = 12000;
            objPBE.IsActive = true;
            }

            if(objPricebook.IsActive == false){
                objPricebook.IsActive = true;
                update objPricebook;
            }

            HexaBPM__SR_Template__c objTemplate = new HexaBPM__SR_Template__c();
            objTemplate.Name = 'General Letter in Arabic';
            objTemplate.HexaBPM__SR_RecordType_API_Name__c ='General_Letter_in_Arabic';
            objTemplate.HexaBPM__Menutext__c = 'Arabic Letter to Third Party (New)';
            objTemplate.HexaBPM__Available_for_menu__c = true;
            objTemplate.HexaBPM__Template_Sequence_No__c = 123;
            objTemplate.HexaBPM__Menu__c = 'Company';
            objTemplate.HexaBPM__Active__c = true;
            objTemplate.HexaBPM__Refund_Item__c = objProduct.Id;
            insert objTemplate;

            HexaBPM__Step_Template__c objStepType = new HexaBPM__Step_Template__c();
            objStepType.Name = 'Approve Request';
            objStepType.HexaBPM__Code__c = 'APPROVE_REQUEST';
            objStepType.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objStepType.HexaBPM__Summary__c = 'Approve Request';
            insert objStepType;
            /*
            SR_Template_Item__c objSRTempItem = new SR_Template_Item__c();
            objSRTempItem.Product__c = objProduct.Id;
            objSRTempItem.SR_Template__c = objTemplate.Id;
            objSRTempItem.On_Submit__c = true;
            insert objSRTempItem;
            */

            HexaBPM__Pricing_Line__c objPricingLine = new HexaBPM__Pricing_Line__c();
            objPricingLine.HexaBPM__Product__c = objProduct.Id;
            objPricingLine.HexaBPM__Active__c = true;
            objPricingLine.HexaBPM__Priority__c = 12;
            objPricingLine.HexaBPM__Price_Line_Condition__c ='HexaBPM__Service_Request__c->Id#!=#Null';
            objPricingLine.HexaBPM__Conditions__c = '1';
            insert objPricingLine;

            HexaBPM__Dated_Pricing__c objDP = new HexaBPM__Dated_Pricing__c();
            objDP.HexaBPM__Pricing_Line__c = objPricingLine.Id;
            objDP.HexaBPM__Unit_Price__c = 1200;
            objDP.HexaBPM__Appllication_Type__c = 'Add';
            objDP.HexaBPM__Date_From__c = system.today().addYears(-2);
            objDP.HexaBPM__Date_To__c = system.today().addYears(2);
            objDP.HexaBPM__Use_List_Price__c = false;
            insert objDP;

            HexaBPM__Pricing_Range__c objPriceRange = new HexaBPM__Pricing_Range__c();
            objPriceRange.HexaBPM__Dated_Pricing__c = objDP.Id;
            objPriceRange.HexaBPM__Range_Start__c = 0;
            objPriceRange.HexaBPM__Range_End__c = 2000;
            objPriceRange.HexaBPM__Unit_Price__c = 1200;
            insert objPriceRange;

            HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
            objDocMaster.Name = 'AR Third Party NOC';
            insert objDocMaster;

            HexaBPM__SR_Template_Docs__c objTempDocs = new HexaBPM__SR_Template_Docs__c();
            objTempDocs.HexaBPM__SR_Template__c = objTemplate.Id;
            objTempDocs.HexaBPM__Document_Master__c = objDocMaster.Id;
            objTempDocs.HexaBPM__On_Submit__c = true;
            objTempDocs.HexaBPM__Generate_Document__c = true;
            insert objTempDocs;

            list<HexaBPM__Status__c> lstStatus = new list<HexaBPM__Status__c>();
            HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Awaiting Approval';
            objStatus.HexaBPM__Type__c = 'Start';
            objStatus.HexaBPM__Code__c = 'AWAITING_APPROVAL';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Approved';
            objStatus.HexaBPM__Type__c = 'Intermediate';
            objStatus.HexaBPM__Code__c = 'APPROVED';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Rejected';
            objStatus.HexaBPM__Type__c = 'End';
            objStatus.HexaBPM__Code__c = 'REJECTED';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'REUPLOAD_DOCUMENT';
            objStatus.HexaBPM__Type__c = 'End';
            objStatus.HexaBPM__Code__c = 'REUPLOAD_DOCUMENT';
            lstStatus.add(objStatus);

            insert lstStatus;

            map<string,string> mapStpStatus = new map<string,string>();
            for(HexaBPM__Status__c status:[select id,HexaBPM__Code__c,Name,HexaBPM__Type__c from HexaBPM__Status__c]){
                mapStpStatus.put(status.HexaBPM__Code__c,status.Id);
            }

            List<HexaBPM__Transition__c> lstTRansitions2 = new list<HexaBPM__Transition__c>();
            HexaBPM__Transition__c Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('APPROVED');
            lstTRansitions2.add(Trans);

            Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('REJECTED');
            lstTRansitions2.add(Trans);

            Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('REUPLOAD_DOCUMENT');
            lstTRansitions2.add(Trans);

            insert lstTRansitions2;

            list<HexaBPM__SR_Status__c> lstSRStatus = new list<HexaBPM__SR_Status__c>();
            HexaBPM__SR_Status__c objCloseStat = new HexaBPM__SR_Status__c();
            objCloseStat.Name = 'Closed';
            objCloseStat.HexaBPM__Code__c = 'CLOSED';
            objCloseStat.HexaBPM__Type__c = 'End';
            lstSRStatus.add(objCloseStat);

            HexaBPM__SR_Status__c objCloseStat2 = new HexaBPM__SR_Status__c();
            objCloseStat2.Name = 'AWAITING_APPROVAL';
            objCloseStat2.HexaBPM__Code__c = 'AWAITING_APPROVAL';
            lstSRStatus.add(objCloseStat2);

            HexaBPM__SR_Status__c objCloseStat3 = new HexaBPM__SR_Status__c();
            objCloseStat3.Name = 'REJECTED';
            objCloseStat3.HexaBPM__Code__c = 'REJECTED';
            objCloseStat3.HexaBPM__Type__c = 'End';
            lstSRStatus.add(objCloseStat3);

            HexaBPM__SR_Status__c objCloseStat4 = new HexaBPM__SR_Status__c();
            objCloseStat4.Name = 'SUBMITTED';
            objCloseStat4.HexaBPM__Code__c = 'SUBMITTED';
            lstSRStatus.add(objCloseStat4);

            HexaBPM__SR_Status__c objCloseStat5 = new HexaBPM__SR_Status__c();
            objCloseStat5.Name = 'APPROVED_BY_nsiA';
            objCloseStat5.HexaBPM__Code__c = 'APPROVED_BY_nsiA';
            lstSRStatus.add(objCloseStat5);


            HexaBPM__SR_Status__c objCloseStat6 = new HexaBPM__SR_Status__c();
            objCloseStat6.Name = 'Draft';
            objCloseStat6.HexaBPM__Code__c = 'DRAFT';
            lstSRStatus.add(objCloseStat6);


            insert lstSRStatus;

            HexaBPM__SR_Steps__c objSRStep = new HexaBPM__SR_Steps__c();
            objSRStep.HexaBPM__SR_Template__c = objTemplate.Id;
            objSRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objSRStep.HexaBPM__Step_Template__c = objStepType.Id; // Step Type
            objSRStep.HexaBPM__Summary__c = 'Approve Request';
            objSRStep.HexaBPM__Step_No__c = 1.0;
            objSRStep.HexaBPM__Start_Status__c = mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objSRStep.HexaBPM__Active__c = true;
            objSRStep.HexaBPM__Sys_Create_Condition__c = true;
            insert objSRStep;

            HexaBPM__SR_Steps__c objAssignNextOwnerSRStep = new HexaBPM__SR_Steps__c();
            objAssignNextOwnerSRStep.HexaBPM__SR_Template__c = objTemplate.Id;
            objAssignNextOwnerSRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objAssignNextOwnerSRStep.HexaBPM__Step_Template__c = objStepType.Id; // Step Type
            objAssignNextOwnerSRStep.HexaBPM__Summary__c = 'Approve Request';
            objAssignNextOwnerSRStep.HexaBPM__Step_No__c = 1.0;
            objAssignNextOwnerSRStep.HexaBPM__Start_Status__c = mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objAssignNextOwnerSRStep.HexaBPM__Active__c = true;
            objAssignNextOwnerSRStep.HexaBPM__Sys_Create_Condition__c = true;
            insert objAssignNextOwnerSRStep;

            HexaBPM__SR_Steps__c objAssignNextStepQueueSRStep = new HexaBPM__SR_Steps__c();
            objAssignNextStepQueueSRStep.HexaBPM__SR_Template__c =objTemplate.Id;
            objAssignNextStepQueueSRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objAssignNextStepQueueSRStep.HexaBPM__Step_Template__c =objStepType.Id; // Step Type
            objAssignNextStepQueueSRStep.HexaBPM__Summary__c = 'Approve Request';
            objAssignNextStepQueueSRStep.HexaBPM__Step_No__c = 1.0;
            objAssignNextStepQueueSRStep.HexaBPM__Start_Status__c =mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objAssignNextStepQueueSRStep.HexaBPM__Active__c = true;
            objAssignNextStepQueueSRStep.HexaBPM__Sys_Create_Condition__c =true;
            insert objAssignNextStepQueueSRStep;

            list<HexaBPM__Step_Transition__c> lstStpTrans = new list<HexaBPM__Step_Transition__c>();
            for(HexaBPM__Transition__c trns:lstTRansitions2){
                HexaBPM__Step_Transition__c stpTr = new HexaBPM__Step_Transition__c();
                stpTr.HexaBPM__SR_Step__c = objSRStep.Id;
                stpTr.HexaBPM__SR_Status_Internal__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__SR_Status_External__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__Parent_SR_Status__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__Parent_Step_Status__c = trns.HexaBPM__To__c;
                lstStpTrans.add(stpTr);
            }
            insert lstStpTrans;

            map<string,HexaBPM__SR_Status__c> mapSRStatus = new map<string,HexaBPM__SR_Status__c>();
            for(HexaBPM__SR_Status__c obj : [select Id,Name,HexaBPM__Code__c,HexaBPM__Type__c from HexaBPM__SR_Status__c where HexaBPM__Code__c='CLOSED' OR HexaBPM__Code__c='REJECTED' OR HexaBPM__Code__c='AWAITING_APPROVAL' OR HexaBPM__Code__c = 'SUBMITTED' OR HexaBPM__Code__c='APPROVED_BY_NSIA' OR HexaBPM__Code__c='DRAFT']){
                mapSRStatus.put(obj.HexaBPM__Code__c,obj);
            }

            list<HexaBPM__Transition__c> lstTransitions = new list<HexaBPM__Transition__c>();
            HexaBPM__Transition__c objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[0].Id; // awaiting approval
            objTransition.HexaBPM__To__c = lstStatus[1].Id; // approved
            lstTransitions.add(objTransition);

            objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[1].Id; // approved
            objTransition.HexaBPM__To__c = lstStatus[2].Id; // Rejected
            lstTransitions.add(objTransition);

            objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[1].Id; // approved
            objTransition.HexaBPM__To__c = lstStatus[3].Id; // Rejected
            lstTransitions.add(objTransition);

            insert lstTransitions;

            list<HexaBPM__Step_Transition__c> lstStepTransitions = new list<HexaBPM__Step_Transition__c>();
            HexaBPM__Step_Transition__c objStepTran;
            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[0].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[0].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[0].Id;
            lstStepTransitions.add(objStepTran);

            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[1].Id;
            lstStepTransitions.add(objStepTran);

            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[2].Id;
            lstStepTransitions.add(objStepTran);

            insert lstStepTransitions;

            /*HexaBPM__Step__c objStepParent = new HexaBPM__Step__c();
            insert objStepParent;*/

            HexaBPM__Service_Request__c objSRPatent = new HexaBPM__Service_Request__c();
            objSRPatent.HexaBPM__Customer__c = objAccount.Id;
            objSRPatent.HexaBPM__Email__c = 'testsr@NSI.com';
            objSRPatent.HexaBPM__Internal_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSRPatent.HexaBPM__External_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSRPatent.HexaBPM__Contact__c = objContact.Id;
            objSRPatent.HexaBPM__SR_Template__c = objTemplate.Id;
            //objSRPatent.HexaBPM__Parent_Step__c = objStepParent.Id;
            insert objSRPatent;

            HexaBPM__Service_Request__c objSR = new HexaBPM__Service_Request__c();
            objSR.HexaBPM__Customer__c = objAccount.Id;
            objSR.HexaBPM__Email__c = 'testsr@NSI.com';
            objSR.HexaBPM__Internal_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSR.HexaBPM__External_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSR.HexaBPM__Contact__c = objContact.Id;
            objSR.HexaBPM__SR_Template__c = objTemplate.Id;
            objSR.HexaBPM__Parent_SR__c = objSRPatent.Id;
            insert objSR;


            map<string,Id> mapNameOwnerId = new map<string,Id>();
            for(QueueSobject q :[Select q.Queue.OwnerId, q.Queue.Name, q.QueueId From QueueSobject q WHERE q.Queue.Name ='Client Approver' OR  q.Queue.Name ='Client Entry User'])
            {
                mapNameOwnerId.put(q.Queue.Name,q.QueueId);
            }

            list<HexaBPM__Step__c> lstStep = new list<HexaBPM__Step__c>();

            HexaBPM__Step__c objStep = new HexaBPM__Step__c();
            objStep.HexaBPM__SR__c = objSR.Id;
            objStep.HexaBPM__SR_Step__c = objSRStep.Id;
            objStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objStep;

            QuickStepTransitionController.externalCommentsProvided(objStep.Id);

            HexaBPM__Step__c objAssignNextOwnerStep = new HexaBPM__Step__c();
            objAssignNextOwnerStep.HexaBPM__SR__c = objSR.Id;
            objAssignNextOwnerStep.HexaBPM__SR_Step__c =objAssignNextOwnerSRStep.Id;
            objAssignNextOwnerStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objAssignNextOwnerStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objAssignNextOwnerStep;

            HexaBPM__Step__c objAssignNextQueueStep = new HexaBPM__Step__c();
            objAssignNextQueueStep.HexaBPM__SR__c = objSR.Id;
            objAssignNextQueueStep.HexaBPM__SR_Step__c =objAssignNextStepQueueSRStep.Id;
            objAssignNextQueueStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objAssignNextQueueStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objAssignNextQueueStep;

            System.assertNOTEquals(null,objStep.Id);

            HexaBPM__Step__c objStep2 = new HexaBPM__Step__c();
            objStep2.HexaBPM__SR__c = objSR.Id;
            objStep2.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objStep2.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objStep2;

            System.assertNOTEquals(null,objStep2.HexaBPM__SR__c);

            set<id> setValidSteps = new set<id>();
            map<id,HexaBPM__Step_Transition__c> mapStepTransition = new map<id,HexaBPM__Step_Transition__c>();
            for(HexaBPM__Step_Transition__c trans2:[select HexaBPM__From__c,HexaBPM__To__c,HexaBPM__Transition__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__SR_Step__c,HexaBPM__SR_Status_External__c,HexaBPM__SR_Status_Internal__c from HexaBPM__Step_Transition__c where HexaBPM__Transition__c!=null and HexaBPM__From__c='Awaiting Approval' and HexaBPM__SR_Step__c=:objStep.HexaBPM__SR_Step__c and IsDeleted=false]){
                setValidSteps.add(trans2.HexaBPM__Transition__r.HexaBPM__To__c);
                mapStepTransition.put(trans2.HexaBPM__Transition__r.HexaBPM__To__c,trans2);
            }

            //Creating Price Items
            HexaBPM__Pricing_Line__c pricingLine = new HexaBPM__Pricing_Line__c();
            pricingLine = TestObjectsFactory.createSRPriceItem();
            insert pricingLine;
            List<Product2> products = new List<Product2>();
            products = TestObjectsFactory.createProduct(new list<string>{'test'});
            insert products;
            List<HexaBPM__SR_Price_Item__c> srPriceItem = new List<HexaBPM__SR_Price_Item__c>();
            srPriceItem = TestObjectsFactory.createSRPriceItem(products,objSR.Id, pricingLine.Id);
            insert srPriceItem;


            //V1.1 start
            system.test.startTest();


            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
            User u = new User(Alias = 'standt', Email='standarduser@testorg2.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@aldarprod.com');

            //System.runAs(u){

                Apexpages.currentPage().getParameters().put('Id',objStep.Id);
                Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(objStep);
                QuickStepTransitionController ltngObjStepTransitionCls = new QuickStepTransitionController(objSR.Id,objStep.Id);
                QuickStepTransitionController.getLstTransWrapper(objSR.Id,objStep.Id);
                QuickStepTransitionController.SaveChanges(mapStpStatus.get('APPROVED'),'RejReason','StepNotes', objSR.id, objStep, mapStepTransition,'null','null','contactPersonEmail',null);
                QuickStepTransitionController.SaveChanges(mapStpStatus.get('APPROVED'),'RejReason','StepNotes', objSR.id, objStep, mapStepTransition,null,null,'contactPersonEmail',null);

            //}
                QuickStepTransitionController.acceptAction(objStep.Id,true);
                QuickStepTransitionController.CancelAction(objSR.id);
                QuickStepTransitionController.ViewStep(objStep.Id);
                QuickStepTransitionController.getQueueMembersByDeveloperName(new list<string>{'Client_Entry_User'});
                QuickStepTransitionController.getQueueMembers(new list<string>{'Client Entry User'});
                QuickStepTransitionController.getFileExtension('test.pdf');
                QuickStepTransitionController.updateOwner(objStep.Id,userinfo.getuserid(),'comment');

                u.IsActive = false;
                insert u;
                QuickStepTransitionController.updateOwner(objStep.Id,u.Id,'comment');

                 QuickStepTransitionController.SaveChanges(null,'RejReason','StepNotes', objSR.id, objStep, mapStepTransition,null,null, 'contactPersonEmail',null);

                //Assign Next Step Owner
                QuickStepTransitionController.getLstTransWrapper(objSR.Id,objAssignNextOwnerStep.Id);

                //Assign next step queue
                QuickStepTransitionController.getLstTransWrapper(objSR.Id,objAssignNextQueueStep.Id);
                //Exception handling
                ltngObjStepTransitionCls.userType = 'Community';
                ltngObjStepTransitionCls.StepID = objStep.Id;
                ltngObjStepTransitionCls.Prepare_Transitions();
                ltngObjStepTransitionCls.Check_Permissions();
                ltngObjStepTransitionCls.Prepare_Transitions();
                system.test.stopTest();
            }
        }


    

    static testMethod void TestQuickStepTransition2() {
        
        map<string,string> mapQueue = new map<string,string>();
        for(Group grp:[select id,name,developername from Group where type='Queue']){
            mapQueue.put(grp.developername,grp.Id);
        }

        Group g1 = new Group(Name='Client Approver',DeveloperName='Client_Approver',type='Queue');
        if(mapQueue.get('Client_Approver')!=null)
            g1.Id = mapQueue.get('Client_Approver');
        upsert g1;

        Group g2 = new Group(Name='Client Entry User',DeveloperName='Client_Entry_User',type='Queue');
        if(mapQueue.get('Client_Entry_User')!=null)
            g2.Id = mapQueue.get('Client_Entry_User');
        upsert g2;

        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__Step__c');
        insert q1;

        QueuesObject q2 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__SR_Steps__c');
        insert q2;

        QueuesObject q3 = new QueueSObject(QueueID = g1.id, SobjectType ='HexaBPM__Step_Template__c');
        insert q3;

        QueuesObject ITq1 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__Step__c');
        insert ITq1;

        QueuesObject ITq2 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__SR_Steps__c');
        insert ITq2;

        QueuesObject ITq3 = new QueueSObject(QueueID = g2.id, SobjectType ='HexaBPM__Step_Template__c');
        insert ITq3;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            
            Account objAccount = new Account();
            objAccount.Name = 'Test Account';
            objAccount.Phone = '1234567890';
            insert objAccount;

            Contact objContact = new Contact();
            objContact.LastName = 'Test Contact';
            objContact.FirstName = 'test';
            objContact.AccountId = objAccount.Id;
            objContact.Email = 'test@NSI.com';
            objContact.Phone = '1234567890';
            insert objContact;

            Product2 objProduct = new Product2();
            objProduct.Name = 'Product';
            objProduct.IsActive = true;
            insert objProduct;

            Pricebook2 objPricebook = new Pricebook2();
            objPricebook.Name = 'Test Price Book';
            objPricebook.IsActive = true;
            objPricebook.Description = 'Test Description';
            insert objPricebook;

            PricebookEntry objPBE = new PricebookEntry();

            for(Pricebook2 objPB : [select Id,Name,IsActive from Pricebook2 where IsStandard = true]){
            objPricebook = objPB;
            objPBE.Product2Id = objProduct.Id;
            objPBE.Pricebook2Id = objPB.Id;
            objPBE.UnitPrice = 12000;
            objPBE.IsActive = true;
            }

            if(objPricebook.IsActive == false){
                objPricebook.IsActive = true;
                update objPricebook;
            }

            HexaBPM__SR_Template__c objTemplate = new HexaBPM__SR_Template__c();
            objTemplate.Name = 'General Letter in Arabic';
            objTemplate.HexaBPM__SR_RecordType_API_Name__c ='General_Letter_in_Arabic';
            objTemplate.HexaBPM__Menutext__c = 'Arabic Letter to Third Party (New)';
            objTemplate.HexaBPM__Available_for_menu__c = true;
            objTemplate.HexaBPM__Template_Sequence_No__c = 123;
            objTemplate.HexaBPM__Menu__c = 'Company';
            objTemplate.HexaBPM__Active__c = true;
            objTemplate.HexaBPM__Refund_Item__c = objProduct.Id;
            insert objTemplate;

            HexaBPM__Step_Template__c objStepType = new HexaBPM__Step_Template__c();
            objStepType.Name = 'Approve Request';
            objStepType.HexaBPM__Code__c = 'APPROVE_REQUEST';
            objStepType.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objStepType.HexaBPM__Summary__c = 'Approve Request';
            insert objStepType;
            /*
            SR_Template_Item__c objSRTempItem = new SR_Template_Item__c();
            objSRTempItem.Product__c = objProduct.Id;
            objSRTempItem.SR_Template__c = objTemplate.Id;
            objSRTempItem.On_Submit__c = true;
            insert objSRTempItem;
            */

            HexaBPM__Pricing_Line__c objPricingLine = new HexaBPM__Pricing_Line__c();
            objPricingLine.HexaBPM__Product__c = objProduct.Id;
            objPricingLine.HexaBPM__Active__c = true;
            objPricingLine.HexaBPM__Priority__c = 12;
            objPricingLine.HexaBPM__Price_Line_Condition__c ='HexaBPM__Service_Request__c->Id#!=#Null';
            objPricingLine.HexaBPM__Conditions__c = '1';
            insert objPricingLine;

            HexaBPM__Dated_Pricing__c objDP = new HexaBPM__Dated_Pricing__c();
            objDP.HexaBPM__Pricing_Line__c = objPricingLine.Id;
            objDP.HexaBPM__Unit_Price__c = 1200;
            objDP.HexaBPM__Appllication_Type__c = 'Add';
            objDP.HexaBPM__Date_From__c = system.today().addYears(-2);
            objDP.HexaBPM__Date_To__c = system.today().addYears(2);
            objDP.HexaBPM__Use_List_Price__c = false;
            insert objDP;

            HexaBPM__Pricing_Range__c objPriceRange = new HexaBPM__Pricing_Range__c();
            objPriceRange.HexaBPM__Dated_Pricing__c = objDP.Id;
            objPriceRange.HexaBPM__Range_Start__c = 0;
            objPriceRange.HexaBPM__Range_End__c = 2000;
            objPriceRange.HexaBPM__Unit_Price__c = 1200;
            insert objPriceRange;

            HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
            objDocMaster.Name = 'AR Third Party NOC';
            insert objDocMaster;

            HexaBPM__SR_Template_Docs__c objTempDocs = new HexaBPM__SR_Template_Docs__c();
            objTempDocs.HexaBPM__SR_Template__c = objTemplate.Id;
            objTempDocs.HexaBPM__Document_Master__c = objDocMaster.Id;
            objTempDocs.HexaBPM__On_Submit__c = true;
            objTempDocs.HexaBPM__Generate_Document__c = true;
            insert objTempDocs;

            list<HexaBPM__Status__c> lstStatus = new list<HexaBPM__Status__c>();
            HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Awaiting Approval';
            objStatus.HexaBPM__Type__c = 'Start';
            objStatus.HexaBPM__Code__c = 'AWAITING_APPROVAL';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Approved';
            objStatus.HexaBPM__Type__c = 'Intermediate';
            objStatus.HexaBPM__Code__c = 'APPROVED';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'Rejected';
            objStatus.HexaBPM__Type__c = 'End';
            objStatus.HexaBPM__Code__c = 'REJECTED';
            lstStatus.add(objStatus);

            objStatus = new HexaBPM__Status__c();
            objStatus.Name = 'REUPLOAD_DOCUMENT';
            objStatus.HexaBPM__Type__c = 'End';
            objStatus.HexaBPM__Code__c = 'REUPLOAD_DOCUMENT';
            lstStatus.add(objStatus);

            insert lstStatus;

            map<string,string> mapStpStatus = new map<string,string>();
            for(HexaBPM__Status__c status:[select id,HexaBPM__Code__c,Name,HexaBPM__Type__c from HexaBPM__Status__c]){
                mapStpStatus.put(status.HexaBPM__Code__c,status.Id);
            }

            List<HexaBPM__Transition__c> lstTRansitions2 = new list<HexaBPM__Transition__c>();
            HexaBPM__Transition__c Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('APPROVED');
            lstTRansitions2.add(Trans);

            Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('REJECTED');
            lstTRansitions2.add(Trans);

            Trans = new HexaBPM__Transition__c();
            Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
            Trans.HexaBPM__To__c = mapStpStatus.get('REUPLOAD_DOCUMENT');
            lstTRansitions2.add(Trans);

            insert lstTRansitions2;

            list<HexaBPM__SR_Status__c> lstSRStatus = new list<HexaBPM__SR_Status__c>();
            HexaBPM__SR_Status__c objCloseStat = new HexaBPM__SR_Status__c();
            objCloseStat.Name = 'Closed';
            objCloseStat.HexaBPM__Code__c = 'CLOSED';
            objCloseStat.HexaBPM__Type__c = 'End';
            lstSRStatus.add(objCloseStat);

            HexaBPM__SR_Status__c objCloseStat2 = new HexaBPM__SR_Status__c();
            objCloseStat2.Name = 'AWAITING_APPROVAL';
            objCloseStat2.HexaBPM__Code__c = 'AWAITING_APPROVAL';
            lstSRStatus.add(objCloseStat2);

            HexaBPM__SR_Status__c objCloseStat3 = new HexaBPM__SR_Status__c();
            objCloseStat3.Name = 'REJECTED';
            objCloseStat3.HexaBPM__Code__c = 'REJECTED';
            objCloseStat3.HexaBPM__Type__c = 'End';
            lstSRStatus.add(objCloseStat3);

            HexaBPM__SR_Status__c objCloseStat4 = new HexaBPM__SR_Status__c();
            objCloseStat4.Name = 'SUBMITTED';
            objCloseStat4.HexaBPM__Code__c = 'SUBMITTED';
            lstSRStatus.add(objCloseStat4);

            HexaBPM__SR_Status__c objCloseStat5 = new HexaBPM__SR_Status__c();
            objCloseStat5.Name = 'APPROVED_BY_nsiA';
            objCloseStat5.HexaBPM__Code__c = 'APPROVED_BY_nsiA';
            lstSRStatus.add(objCloseStat5);


            HexaBPM__SR_Status__c objCloseStat6 = new HexaBPM__SR_Status__c();
            objCloseStat6.Name = 'Draft';
            objCloseStat6.HexaBPM__Code__c = 'DRAFT';
            lstSRStatus.add(objCloseStat6);


            insert lstSRStatus;

            HexaBPM__SR_Steps__c objSRStep = new HexaBPM__SR_Steps__c();
            objSRStep.HexaBPM__SR_Template__c = objTemplate.Id;
            objSRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objSRStep.HexaBPM__Step_Template__c = objStepType.Id; // Step Type
            objSRStep.HexaBPM__Summary__c = 'Approve Request';
            objSRStep.HexaBPM__Step_No__c = 1.0;
            objSRStep.HexaBPM__Start_Status__c = mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objSRStep.HexaBPM__Active__c = true;
            objSRStep.HexaBPM__Sys_Create_Condition__c = true;
            insert objSRStep;

            HexaBPM__SR_Steps__c objAssignNextOwnerSRStep = new HexaBPM__SR_Steps__c();
            objAssignNextOwnerSRStep.HexaBPM__SR_Template__c = objTemplate.Id;
            objAssignNextOwnerSRStep.HexaBPM__Step_RecordType_API_Name__c ='General';
            objAssignNextOwnerSRStep.HexaBPM__Step_Template__c = objStepType.Id; // Step Type
            objAssignNextOwnerSRStep.HexaBPM__Summary__c = 'Approve Request';
            objAssignNextOwnerSRStep.HexaBPM__Step_No__c = 1.0;
            objAssignNextOwnerSRStep.HexaBPM__Start_Status__c = mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objAssignNextOwnerSRStep.HexaBPM__Active__c = true;
            objAssignNextOwnerSRStep.HexaBPM__Sys_Create_Condition__c = true;
            insert objAssignNextOwnerSRStep;

            HexaBPM__SR_Steps__c objAssignNextStepQueueSRStep = new HexaBPM__SR_Steps__c();
            objAssignNextStepQueueSRStep.HexaBPM__SR_Template__c =objTemplate.Id;
            objAssignNextStepQueueSRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            objAssignNextStepQueueSRStep.HexaBPM__Step_Template__c =objStepType.Id; // Step Type
            objAssignNextStepQueueSRStep.HexaBPM__Summary__c = 'Approve Request';
            objAssignNextStepQueueSRStep.HexaBPM__Step_No__c = 1.0;
            objAssignNextStepQueueSRStep.HexaBPM__Start_Status__c =mapStpStatus.get('AWAITING_APPROVAL'); // Default Step Status
            objAssignNextStepQueueSRStep.HexaBPM__Active__c = true;
            objAssignNextStepQueueSRStep.HexaBPM__Sys_Create_Condition__c =true;
            insert objAssignNextStepQueueSRStep;

            list<HexaBPM__Step_Transition__c> lstStpTrans = new list<HexaBPM__Step_Transition__c>();
            for(HexaBPM__Transition__c trns:lstTRansitions2){
                HexaBPM__Step_Transition__c stpTr = new HexaBPM__Step_Transition__c();
                stpTr.HexaBPM__SR_Step__c = objSRStep.Id;
                stpTr.HexaBPM__SR_Status_Internal__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__SR_Status_External__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__Parent_SR_Status__c = lstSRStatus[0].Id;
                stpTr.HexaBPM__Parent_Step_Status__c = trns.HexaBPM__To__c;
                lstStpTrans.add(stpTr);
            }
            insert lstStpTrans;

            map<string,HexaBPM__SR_Status__c> mapSRStatus = new map<string,HexaBPM__SR_Status__c>();
            for(HexaBPM__SR_Status__c obj : [select Id,Name,HexaBPM__Code__c,HexaBPM__Type__c from HexaBPM__SR_Status__c where HexaBPM__Code__c='CLOSED' OR HexaBPM__Code__c='REJECTED' OR HexaBPM__Code__c='AWAITING_APPROVAL' OR HexaBPM__Code__c = 'SUBMITTED' OR HexaBPM__Code__c='APPROVED_BY_NSIA' OR HexaBPM__Code__c='DRAFT']){
                mapSRStatus.put(obj.HexaBPM__Code__c,obj);
            }

            list<HexaBPM__Transition__c> lstTransitions = new list<HexaBPM__Transition__c>();
            HexaBPM__Transition__c objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[0].Id; // awaiting approval
            objTransition.HexaBPM__To__c = lstStatus[1].Id; // approved
            lstTransitions.add(objTransition);

            objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[1].Id; // approved
            objTransition.HexaBPM__To__c = lstStatus[2].Id; // Rejected
            lstTransitions.add(objTransition);

            objTransition = new HexaBPM__Transition__c();
            objTransition.HexaBPM__From__c = lstStatus[1].Id; // approved
            objTransition.HexaBPM__To__c = lstStatus[3].Id; // Rejected
            lstTransitions.add(objTransition);

            insert lstTransitions;

            list<HexaBPM__Step_Transition__c> lstStepTransitions = new list<HexaBPM__Step_Transition__c>();
            HexaBPM__Step_Transition__c objStepTran;
            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[0].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[0].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[0].Id;
            lstStepTransitions.add(objStepTran);

            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[1].Id;
            lstStepTransitions.add(objStepTran);

            objStepTran = new HexaBPM__Step_Transition__c();
            objStepTran.HexaBPM__SR_Step__c = objSRStep.Id;
            objStepTran.HexaBPM__SR_Status_Internal__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__SR_Status_External__c = lstSRStatus[1].Id;
            objStepTran.HexaBPM__Transition__c = lstTransitions[2].Id;
            lstStepTransitions.add(objStepTran);

            insert lstStepTransitions;

            /*HexaBPM__Step__c objStepParent = new HexaBPM__Step__c();
            insert objStepParent;*/

            HexaBPM__Service_Request__c objSRPatent = new HexaBPM__Service_Request__c();
            objSRPatent.HexaBPM__Customer__c = objAccount.Id;
            objSRPatent.HexaBPM__Email__c = 'testsr@NSI.com';
            objSRPatent.HexaBPM__Internal_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSRPatent.HexaBPM__External_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSRPatent.HexaBPM__Contact__c = objContact.Id;
            objSRPatent.HexaBPM__SR_Template__c = objTemplate.Id;
            //objSRPatent.HexaBPM__Parent_Step__c = objStepParent.Id;
            insert objSRPatent;

            HexaBPM__Service_Request__c objSR = new HexaBPM__Service_Request__c();
            objSR.HexaBPM__Customer__c = objAccount.Id;
            objSR.HexaBPM__Email__c = 'testsr@NSI.com';
            objSR.HexaBPM__Internal_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSR.HexaBPM__External_SR_Status__c = lstSRStatus[5].Id; //changing the status to Draft
            objSR.HexaBPM__Contact__c = objContact.Id;
            objSR.HexaBPM__SR_Template__c = objTemplate.Id;
            objSR.HexaBPM__Parent_SR__c = objSRPatent.Id;
            insert objSR;


            map<string,Id> mapNameOwnerId = new map<string,Id>();
            for(QueueSobject q :[Select q.Queue.OwnerId, q.Queue.Name, q.QueueId From QueueSobject q WHERE q.Queue.Name ='Client Approver' OR  q.Queue.Name ='Client Entry User'])
            {
                mapNameOwnerId.put(q.Queue.Name,q.QueueId);
            }

            list<HexaBPM__Step__c> lstStep = new list<HexaBPM__Step__c>();

            HexaBPM__Step__c objStep = new HexaBPM__Step__c();
            objStep.HexaBPM__SR__c = objSR.Id;
            objStep.HexaBPM__SR_Step__c = objSRStep.Id;
            objStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objStep;

            HexaBPM__Step__c objAssignNextOwnerStep = new HexaBPM__Step__c();
            objAssignNextOwnerStep.HexaBPM__SR__c = objSR.Id;
            objAssignNextOwnerStep.HexaBPM__SR_Step__c =objAssignNextOwnerSRStep.Id;
            objAssignNextOwnerStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objAssignNextOwnerStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objAssignNextOwnerStep;

            HexaBPM__Step__c objAssignNextQueueStep = new HexaBPM__Step__c();
            objAssignNextQueueStep.HexaBPM__SR__c = objSR.Id;
            objAssignNextQueueStep.HexaBPM__SR_Step__c =objAssignNextStepQueueSRStep.Id;
            objAssignNextQueueStep.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objAssignNextQueueStep.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objAssignNextQueueStep;

            System.assertNOTEquals(null,objStep.Id);

            HexaBPM__Step__c objStep2 = new HexaBPM__Step__c();
            objStep2.HexaBPM__SR__c = objSR.Id;
            objStep2.HexaBPM__Status__c = mapStpStatus.get('AWAITING_APPROVAL');
            //objStep2.OwnerId = mapNameOwnerId.get('Client Entry User');
            insert objStep2;

            System.assertNOTEquals(null,objStep2.HexaBPM__SR__c);

            set<id> setValidSteps = new set<id>();
            map<id,HexaBPM__Step_Transition__c> mapStepTransition = new map<id,HexaBPM__Step_Transition__c>();
            for(HexaBPM__Step_Transition__c trans2:[select HexaBPM__From__c,HexaBPM__To__c, HexaBPM__Transition__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__SR_Step__c,HexaBPM__SR_Status_External__c,HexaBPM__SR_Status_Internal__c from HexaBPM__Step_Transition__c where HexaBPM__Transition__c!=null and HexaBPM__From__c='Awaiting Approval' and HexaBPM__SR_Step__c=:objStep.HexaBPM__SR_Step__c and IsDeleted=false]){
                setValidSteps.add(trans2.HexaBPM__Transition__r.HexaBPM__To__c);
                mapStepTransition.put(trans2.HexaBPM__Transition__r.HexaBPM__To__c,trans2);
            }

            //Creating Price Items
            HexaBPM__Pricing_Line__c pricingLine = new HexaBPM__Pricing_Line__c();
            pricingLine = TestObjectsFactory.createSRPriceItem();
            insert pricingLine;
            List<Product2> products = new List<Product2>();
            products = TestObjectsFactory.createProduct(new list<string>{'test'});
            insert products;
            List<HexaBPM__SR_Price_Item__c> srPriceItem = new List<HexaBPM__SR_Price_Item__c>();
            srPriceItem = TestObjectsFactory.createSRPriceItem(products,objSR.Id, pricingLine.Id);
            insert srPriceItem;


            //V1.1 start
            system.test.startTest();


            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
            User u = new User(Alias = 'standt', Email='standarduser@testorg2.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@aldarorg2.com');



                QuickStepTransitionController.updateAuthCaseOfficer(objStep.Id,userinfo.getuserid());


                QuickStepTransitionController.SaveChanges(mapStpStatus.get('REUPLOAD_DOCUMENT'),'RejReason','StepNotes', objSR.id, objStep,mapStepTransition,null,null,'email',null);

                QuickStepTransitionController.acceptAction(objStep.Id,false);

                QuickStepTransitionController.getQueueMembers(new list<string>{'Client Approver'});

                HexaBPM__SR_Price_Item__c objSRP = new HexaBPM__SR_Price_Item__c();
                objSRP.HexaBPM__ServiceRequest__c = objSR.Id;
                objSRP.HexaBPM__Status__c = 'Invoiced';
                objSRP.HexaBPM__Non_Reevaluate__c = true;
                objSRP.HexaBPM__Price__c = 1000;
                insert objSRP;

                QuickStepTransitionController.getLstTransWrapper(objSR.Id,objStep.Id);

                QuickStepTransitionController.SaveChanges(lstStepTransitions[2].id,'RejReason','StepNotes', objSR.id, objStep, new Map<Id,HexaBPM__Step_Transition__c>{lstStepTransitions[2].id => lstStepTransitions[2]},null,null,'email',null);
                HexaBPM__Step_Transition__c st = [select id,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c from HexaBPM__Step_Transition__c WHERE id =: lstStepTransitions[2].id];
                System.debug(st.HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c);
                QuickStepTransitionController.SaveChanges(lstStepTransitions[2].id,'RejReason','StepNotes', objSR.id, objStep, new Map<Id,HexaBPM__Step_Transition__c>{lstStepTransitions[2].id => st},null,null,'email',null);
                QuickStepTransitionController.SaveChanges(lstStepTransitions[2].id,'RejReason','StepNotes', objSR.id, objStep, new Map<Id,HexaBPM__Step_Transition__c>{lstStepTransitions[2].id => st},'xyz',null,'email',null);
                QuickStepTransitionController.updateOwner(objStep.Id,userinfo.getuserid(),'error');
                QuickStepTransitionController.updateAuthCaseOfficer(objStep.Id,null);
                system.test.stopTest();
        }
    }


    static testMethod void newTest() {
        try{
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        TestObjectsFactory.ResponseWrapper initDataWrapper =  TestObjectsFactory.createInitialData(Constants.ORGANISATION_ACCOUNT_RT,'Banking and Insurance','Banking and Insurance');
        TestObjectsFactory.ResponseWrapper srDataWrapper =  TestObjectsFactory.createSrData('LPCWaiver','Banking and Insurance',
          initDataWrapper.acc.Id,'General_Information_for_Regulated_Activities');

         HexaBPM__Pricing_Line__c pricingRecord = TestObjectsFactory.createSRPriceItem();
        insert pricingRecord;
        List<String> stringList = new List<String>{'Supervision'};
        List<Product2> productRecordList = TestObjectsFactory.createProduct(stringList);
        for(Product2 prod : productRecordList){
            prod.name = 'Supervision';
        }
        insert productRecordList;

        List<HexaBPM__SR_Price_Item__c> feeList = TestObjectsFactory.createSRPriceItem(productRecordList,srDataWrapper.srObj.Id,pricingRecord.Id);
        for(HexaBPM__SR_Price_Item__c fee : feeList){
            fee.HexaBPM__Status__c = 'Invoiced';
        }
        insert feeList;

            system.test.startTest();


                QuickStepTransitionController.RequestWrap reqWrap = new QuickStepTransitionController.RequestWrap();
                reqWrap.sobjLst = new list<map<string,string>>{new map<string,string>{'id' => srDataWrapper.srObj.Id,'HexaBPM__Submitted_DateTime__c' => '1993-06-06T10:03:03.000+0000'}};

            QuickStepTransitionController.saveDynamicForm(JSON.serialize(reqWrap));

            srDataWrapper.stptemp.HexaBPM__Code__c ='Verify_New_Source_of_Payment';
            update srDataWrapper.stptemp;
            update srDataWrapper.srSteps;

            //QuickStepTransitionController.getLstTransWrapper(srDataWrapper.srObj.Id, srDataWrapper.stpObj.Id);


            system.test.stopTest();
        
        }catch(exception e){}
    }
    
    @isTest
    public static void coveringOtherLines() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        String convStr = '{ "sObjLst": [ { "id": "'+acc.Id+'" } ] }';


        QuickStepTransitionController.saveDynamicForm(convStr);
    }
}