/*
* Purpose: Initiate a Service Request using the Case Category and Sub Category.
*/
public with sharing class CreateSRFromCaseController {

    public class SRCreationException extends Exception {}

    @AuraEnabled
    public static HexaBPM__Service_Request__c createSR(String caseId) {
        List<FieldMapping__mdt> fieldMappingList = [SELECT Id, SourceObjectName__c, DestinationObjectName__c, SourceFieldName__c, DestinationFieldName__c, Condition__c FROM FieldMapping__mdt WHERE SourceObjectName__c = 'Case' AND DestinationObjectName__c = 'HexaBPM__Service_Request__c'];
        
        List<Case> caseList = CaseService.queryAllFieldsWithExtraFields(new List<Id>{caseId});

        //--- To run the validation role for Case Category
        if(String.isBlank(caseList[0].CaseCategory__c)){
            Case cs = caseList[0];
            cs.SRCreated__c = true;
            update cs;
        }

        List<SRAutomation__mdt> srAutomationList = SRAutomation__mdt.getall().values();
        SRAutomation__mdt srAuto = null;
        System.debug('srAutomationList '+srAutomationList);
        for(SRAutomation__mdt auto : srAutomationList){            
            if(auto.CaseCategoryMapping__c != null && caseList[0].get(auto.CaseCategoryMapping__c) != null){
                if((String)caseList[0].get(auto.CaseCategoryMapping__c) == auto.CaseCategory__c){
                    srAuto = auto;
                    break;
                }
            } 
        }

        if(srAuto == null){
            throw new SRCreationException(Utilities.getSystemMessages(Constants.CASE_SR_TYPE_NOT_EXIST).Message__c);
        }

        if(srAuto.InitiatedFromCase__c != 'Yes'){
            throw new SRCreationException(Utilities.getSystemMessages(Constants.CASE_INITIATED_FROM_CASE).Message__c);
        }

        String recordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', srAuto.SRRecordTypeName__c);
        HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();

        if(caseList[0].Initial_Condition__c == 'Re Sale' && caseList[0].CaseCategory__c == 'Property Transfer' && caseList[0].Opportunity__c != null) {
            /*newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_TYPE);
            newSR.BuyerName__c = caseList[0].Opportunity__r.AccountId;
            newSR.HexaBPM__Customer__c = caseList[0].AccountId;
            newSR.Unit__c	 = caseList[0].Unit__c;
            newSR.SalesOrder__c = caseList[0].SalesOrder__c;*/
            newSR = createCaseToPTSR(caseList[0].Opportunity__c, caseList[0].Id);
        } else {

            newSR.RecordTypeId = recordTypeId;
            /*
            * Logic: Get Custom Metadata Field Mapping to save data from Case to Service Request depending on Case Category.
            */
            for(FieldMapping__mdt fieldMapping: fieldMappingList) {
                List<String> conditionList = fieldMapping.Condition__c != null ? fieldMapping.Condition__c.split(',') : new List<String>{(String)caseList[0].get(srAuto.CaseCategoryMapping__c)};
                if (conditionList.isEmpty() || conditionList.contains((String)caseList[0].get(srAuto.CaseCategoryMapping__c))) {
                    if (((String)caseList[0].get(srAuto.CaseCategoryMapping__c) == Constants.PROPERTY_TRANSFER_TYPE || (String)caseList[0].get(srAuto.CaseCategoryMapping__c) == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE || (String)caseList[0].get(srAuto.CaseCategoryMapping__c) == Constants.RTO_TRANSFER_SR_TYPE) && fieldMapping.DestinationFieldName__c == 'SRType__c') {
                        /*
                        * Logic: If Case Category is Property Transfer and Title Deed Registration Number is available then it will create Property Transfer NOC or vice versa
                        */
                        if (String.isNotBlank(caseList[0].SalesOrder__r.TitleDeedRegistrationNumber__c)) {
                            newSR.put(fieldMapping.DestinationFieldName__c, Constants.PROPERTY_TRANSFER_NOC_SR_TYPE);
                            newSR.put('RecordTypeId', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_NOC_RT));
                        } else {
                            newSR.put(fieldMapping.DestinationFieldName__c, Constants.PROPERTY_TRANSFER_TYPE);
                            newSR.put('RecordTypeId', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT));
                        }
                    } else if (((String)caseList[0].CaseCategory__c == Constants.OWNERSHIP_CHANGE_TYPE || (String)caseList[0].CaseCategory__c == Constants.ADDITION_JOINT_OWNER_TYPE || (String)caseList[0].CaseCategory__c == Constants.DELETION_JOINT_OWNER_TYPE || (String)caseList[0].CaseCategory__c == Constants.SHARE_PERCENTAGE_CHANGE_TYPE) && fieldMapping.DestinationFieldName__c == 'HexaBPM__SR_Template__c') {
                        /*
                        * Logic: If Case Category is Joint Owner and Title Deed Registration Number is available then it will create Joint Owner NOC or vice versa
                        */
                        if (String.isNotBlank(caseList[0].SalesOrder__r.TitleDeedRegistrationNumber__c)) {
                            // newSR.put(fieldMapping.DestinationFieldName__c, getSRTemplate(Constants.JOINT_OWNER_NOC_RT));
                            newSR.put('RecordTypeId', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.JOINT_OWNER_NOC_RT));
                        } else {
                            // newSR.put(fieldMapping.DestinationFieldName__c, getSRTemplate(Constants.JOINT_OWNER_RT));
                            newSR.put('RecordTypeId', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.JOINT_OWNER_RT));
                        }
                    } else if(fieldMapping.DestinationFieldName__c == 'HexaBPM__SR_Template__c'){
                        newSR.put(fieldMapping.DestinationFieldName__c, getSRTemplate(String.valueOf(caseList[0].get(fieldMapping.SourceFieldName__c))));
                    } /*else if ((String)caseList[0].get(srAuto.CaseCategoryMapping__c) == Constants.CANCELLATION_TYPE && fieldMapping.DestinationFieldName__c == 'SRType__c') {
                        
                        * Logic: If Case Category is Cancellation then Service request will be initiate based on Sub Category
                        
                        if (caseList[0].SubCategory__c == Constants.MUTUAL_CANCELLATION_SUB_TYPE) {
                            newSR.put(fieldMapping.DestinationFieldName__c, Constants.MUTUAL_CANCELLATION_SR_TYPE);
                        } else if (caseList[0].SubCategory__c == Constants.CONSOLIDATION_SUB_TYPE) {
                            newSR.put(fieldMapping.DestinationFieldName__c, Constants.CONSOLIDATION_SR_TYPE);
                        }
                        
                    }*/ else {
                        /*
                        * Logic: If Case Category is Cancellation then Service request will be initiate based on Sub Category
                        */
                        newSR.put(fieldMapping.DestinationFieldName__c, caseList[0].get(fieldMapping.SourceFieldName__c));
                    }
                }
            }

            System.debug('newSR>>>' + newSR);
            insert newSR;

            //--- Map Supporting Documents to new SR
            ServiceRequestDocumentService.getCaseUploadedFiles(caseList[0].Id, newSR.Id, Constants.SUPPORTING_DOCUMENTS_SRDOC);

            //--- Submit SR
            if(srAuto.AutoSubmission__c){
                //SRUtility.submitSR(new List<HexaBPM__Service_Request__c>{newSR});
            }
        }

        //--- Update Case Status to closed
        Case cs = caseList[0];
        //cs.Status = 'Closed';
       // cs.StatusReason__c = 'With Resolution';
        cs.SRCreated__c = true;
        update cs;
        
        return newSR;
    }

    //--- Get SR Templete by name
    public static Id getSRTemplate(String name){
        HexaBPM__SR_Template__c srTemp = [Select Id from HexaBPM__SR_Template__c where Name=: name];
        return srTemp.Id;
    }

    //upload document from Account to SR
  /*  @future
    public static void uploadDocumentFromAccount(Id srId) {
        HexaBPM__Service_Request__c sr = [SELECT Id, BuyerName__c, HexaBPM__Customer__c FROM HexaBPM__Service_Request__c WHERE Id =:srId];
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        //fetch account documents
        List<String> docType = new List<String>{'Passport Copy', 'Emirates ID Copy'};
        List<String> srDocType = new List<String>{'Buyer Passport Copy', 'Buyer Emirates ID Copy', 'Seller Passport Copy', 'Seller Emirates ID Copy'};
        List<Document__c> docList = [SELECT Id, DocumentType__c, Account__c, (SELECT Id, ContentDocumentId FROM ContentDocumentLinks) FROM Document__c WHERE DocumentType__c IN :docType AND (Account__c =:sr.BuyerName__c OR Account__c =:sr.HexaBPM__Customer__c)]; 

        List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, Name, (SELECT Id, ContentDocumentId FROM ContentDocumentLinks) FROM HexaBPM__SR_Doc__c WHERE /*Name IN :srDocType AND HexaBPM__Service_Request__c =:sr.Id];
        //can be nested because it always be 2
		String prefix = '';
        
        for(Document__c doc : docList) {
            prefix = doc.Account__c == sr.BuyerName__c ? 'Buyer' : 'Seller';
            
            for(HexaBPM__SR_Doc__c srDoc : srDocList) {
                if(srDoc.Name == (prefix + ' ' + doc.DocumentType__c)) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = srDoc.Id;
                    cdl.ContentDocumentId = doc.ContentDocumentLinks[0].ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    contentDocumentLinkList.add(cdl);
                }
            }
        }

        if(!contentDocumentLinkList.isEmpty()) {
            insert contentDocumentLinkList;
        }
    }*/

    public static HexaBPM__Service_Request__c createCaseToPTSR(String recordId, String caseId) {
        HexaBPM__Service_Request__c thisSR = new HexaBPM__Service_Request__c();
        Opportunity thisOpp = getOppDetails(recordId);

        String propertyTransferTemplateId = [SELECT Id FROM HexaBPM__SR_Template__c WHERE HexaBPM__SR_RecordType_API_Name__c =: ResaleConstants.SR_RT_PROPERTY_TRANSFER LIMIT 1].Id;
        thisSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_TYPE);
        thisSR.HexaBPM__SR_Template__c = propertyTransferTemplateId;
        thisSR.SRType__c = ResaleConstants.SR_TYPE_PROPERTY_TRANSFER;
        thisSR.ChargeType__c = ResaleConstants.SR_CHARGETYPE_TRANSFER_NORMAL;
        thisSR.MOUSigned__c = ResaleConstants.YES;
        thisSR.CreatedFromResaleOpportunity__c = true;
        thisSR.ResaleOpportunity__c = thisOpp.Id;
        thisSR.SalesOrder__c = thisOpp.SalesOrder__c;
        thisSR.Unit__c = thisOpp.Unit__c;
        thisSR.TransferSellingPrice__c = thisOpp.Amount;
        thisSR.HexaBPM__Customer__c = thisOpp.Seller__c;
        thisSR.BuyerName__c = thisOpp.AccountId;
        thisSR.Resale_Initiated_By__c = thisOpp.OwnerId;
        thisSR.Case__c = caseId;
        insert thisSR;

        List<JointOwner__c> jointOwnersList = getJointOwners(thisOpp.Seller__c);
        if(jointOwnersList.size() > 0) {
            List<AgencyTeam__c> agencyTeamInsertList = new List<AgencyTeam__c>();
            for(JointOwner__c thisJointOwner : jointOwnersList) {
                AgencyTeam__c thisRec = new AgencyTeam__c();
                thisRec.Name = thisJointOwner.Name;
                thisRec.Account__c = thisJointOwner.Account__c;
                thisRec.JointOwner__c = thisJointOwner.Id;
                thisRec.ServiceRequest__c = thisSR.Id;
                thisRec.ShareHoldingPercentage__c = thisJointOwner.SharePercentage__c;

                agencyTeamInsertList.add(thisRec);
            }

            if(agencyTeamInsertList.size() > 0){
                insert agencyTeamInsertList;
            }
        }
        
        return thisSR;

        //uploadDocumentFromAccount(thisSR.Id);
    }

    private static List<JointOwner__c> getJointOwners(Id accountId) {
        return [SELECT Id, Name, SharePercentage__c, RelationshipType__c, Account__c
                FROM JointOwner__c 
                WHERE Account__c =: accountId];                  
    }

    private static Opportunity getOppDetails(Id recordId){
        return [SELECT Id, AccountId, SalesOrder__c, Unit__c, Seller__c, Amount, OwnerId, Equity_Paid__c
                FROM Opportunity
                WHERE Id =: recordId
                LIMIT 1];
    }
}